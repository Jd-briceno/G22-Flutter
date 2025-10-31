import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:melodymuse/components/backstage_card.dart';
import 'package:melodymuse/components/mini_song_reproductor.dart';
import 'package:melodymuse/components/navbar.dart';
import 'package:heroicons/heroicons.dart';
import 'package:melodymuse/pages/edit_profile_screen.dart';
import 'package:melodymuse/pages/all_achievements_screen.dart'; // 👈 importa la nueva página
import 'package:melodymuse/pages/settings_page.dart';
import 'package:provider/provider.dart';
import 'package:melodymuse/services/playback_manager_service.dart';
import 'package:melodymuse/pages/music_detail_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'dart:convert';
import 'dart:io'; // for FileImage

class ProfileBackstagePage extends StatefulWidget {
  const ProfileBackstagePage({super.key});

  @override
  State<ProfileBackstagePage> createState() => _ProfileBackstagePageState();
}

class _ProfileBackstagePageState extends State<ProfileBackstagePage> {

  bool isOffline = false;
  late Future<Map<String, dynamic>> _userFuture;

  @override
  void initState() {
    super.initState();
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser != null) {
      _userFuture = _getUserData(currentUser.uid);
    } else {
      _userFuture = Future.value({});
    }
  }

  // Keep a tiny JSON-safe cache with only the fields the UI needs
  Map<String, dynamic> _toCache(Map<String, dynamic> data) {
    Map<String, dynamic> out = {
      'nickname': data['nickname']?.toString(),
      'fullName': data['fullName']?.toString(),
      'title': data['title']?.toString(),
      'profileStage': data['profileStage']?.toString(),
      'description': data['description']?.toString(),
      'bio': data['bio']?.toString(),
      'about': data['about']?.toString(),
      'profileImageUrl': data['profileImageUrl']?.toString(),
      'updatedAt': (data['updatedAt'] is Timestamp)
          ? (data['updatedAt'] as Timestamp).millisecondsSinceEpoch
          : (data['updatedAt'] is int ? data['updatedAt'] : null),
    };
    // drop nulls to keep it clean
    out.removeWhere((k, v) => v == null);
    return out;
  }

  Map<String, dynamic> _fromCache(Map<String, dynamic> cache) {
    final out = Map<String, dynamic>.from(cache);
    final ts = out['updatedAt'];
    if (ts is int) {
      out['updatedAt'] = Timestamp.fromMillisecondsSinceEpoch(ts);
    }
    return out;
  }

  Future<Map<String, dynamic>> _getUserData(String userId) async {
    final prefs = await SharedPreferences.getInstance();

    // Simplified: always return a valid map (never null, never throws)
    Map<String, dynamic> loadFromCache({bool markOffline = false}) {
      final cachedString = prefs.getString('cached_user_data');
      if (cachedString == null || cachedString.isEmpty) {
        if (markOffline) isOffline = true;
        return <String, dynamic>{};
      }
      try {
        final raw = jsonDecode(cachedString);
        if (raw is Map<String, dynamic>) {
          if (markOffline) isOffline = true;
          return _fromCache(raw);
        }
      } catch (_) {}
      if (markOffline) isOffline = true;
      return <String, dynamic>{};
    }

    // 1. Always show cached data instantly if available, before any network call
    final cachedUser = loadFromCache();
    if (cachedUser.isNotEmpty) {
      // Mark offline only if we end up using cache as fallback, not here
      // Show cached data immediately
      if (mounted) setState(() {});
    }

    // 2. Continue with normal logic, but always run Firestore fetch after showing cache
    // --- Sincronización local incremental y verificación de último fetch ---
    final lastFetchMillis = prefs.getInt('last_fetch_user_data') ?? 0;
    final now = DateTime.now().millisecondsSinceEpoch;
    if (now - lastFetchMillis < 30000) {
      final cachedString = prefs.getString('cached_user_data');
      if (cachedString != null) {
        print("🕒 Datos recientes en caché (<30s), usando versión local.");
        // Already setState above if cache was present
        return _fromCache(jsonDecode(cachedString));
      }
    }

    try {
      final connectivity = await Connectivity().checkConnectivity();
      if (connectivity == ConnectivityResult.none) {
        print("📡 Sin conexión. Usando datos en caché.");
        isOffline = true;
        if (mounted) setState(() {}); // 🔧 Muestra el banner inmediatamente
        return loadFromCache(markOffline: true);
      }

      // Intento principal: leer desde Firestore con fallback local si hay fallo
      DocumentSnapshot<Map<String, dynamic>>? doc;
      try {
        doc = await FirebaseFirestore.instance
            .collection('users')
            .doc(userId)
            .get(const GetOptions(source: Source.serverAndCache));
      } on FirebaseException catch (e) {
        if (e.code == 'unavailable') {
          print("⚠️ Firestore no disponible. Intentando leer desde caché...");
          doc = await FirebaseFirestore.instance
              .collection('users')
              .doc(userId)
              .get(const GetOptions(source: Source.cache));
        } else {
          rethrow;
        }
      }

      final data = doc?.data();
      if (data == null) {
        print("⚠️ Documento del usuario no existe o está vacío. Recurriendo a caché.");
        isOffline = true;
        return loadFromCache(markOffline: true);
      }

      // Cachear los datos obtenidos
      final compact = _toCache(Map<String, dynamic>.from(data));
      await prefs.setString('cached_user_data', jsonEncode(compact));
      await prefs.setInt('last_fetch_user_data', DateTime.now().millisecondsSinceEpoch);
      isOffline = false;
      print("✅ Datos del usuario obtenidos desde Firestore y cacheados correctamente.");
      // If new data is different, update UI
      if (mounted) setState(() {});
      return data;
    } catch (e) {
      print("❌ Error al obtener datos del usuario (Firestore): $e");
      final cached = loadFromCache(markOffline: true);
      if (cached.isNotEmpty) {
        print("📦 Mostrando datos del usuario desde caché tras error.");
        isOffline = true;
        if (mounted) setState(() {});
        return cached;
      }
      print("⚠️ Sin datos en caché válidos. Devolviendo mapa vacío.");
      isOffline = true;
      // --- Cola de reintentos para reconexión eventual ---
      Connectivity().onConnectivityChanged.listen((result) async {
        if (result != ConnectivityResult.none) {
          print("🌐 Conectividad restaurada. Reintentando sincronización de perfil...");
          await _getUserData(userId);
          // Refresca la UI para mostrar/hide el banner offline al volver de otras pantallas
          if (mounted) setState(() {});
        }
      });
      return <String, dynamic>{};
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) {
      return const Scaffold(
        backgroundColor: Colors.black,
        body: Center(
          child: Text(
            'No estás autenticado.',
            style: TextStyle(color: Colors.white),
          ),
        ),
      );
    }

    final userId = currentUser.uid;

    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: FutureBuilder<Map<String, dynamic>>(
          future: _userFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(
                child: CircularProgressIndicator(color: Colors.white),
              );
            }

            if (snapshot.hasError) {
              return const Center(
                child: Text(
                  "Error al cargar los datos del usuario.",
                  style: TextStyle(color: Colors.redAccent),
                ),
              );
            }

            if (!snapshot.hasData) {
              return const Center(
                child: CircularProgressIndicator(color: Colors.white),
              );
            }

            final userData = snapshot.data ?? <String, dynamic>{};

            // Debug prints for userData keys
            print("🟢 userData keys: ${userData.keys}");
            print("🟢 nickname: ${userData['nickname']}");
            print("🟢 title: ${userData['title']}");
            print("🟢 description: ${userData['description']}");
            print("🟢 fullName: ${userData['fullName']}");
            print("🟢 bio: ${userData['bio']}");
            print("🟢 about: ${userData['about']}");
            print("🟢 profileImageUrl: ${userData['profileImageUrl']}");

            // Banner offline persistente
            Widget offlineBanner = Container();
            if (isOffline) {
              offlineBanner = Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 8),
                color: Colors.amberAccent,
                child: const Center(
                  child: Text(
                    "🛰️ Modo offline",
                    style: TextStyle(
                      color: Colors.black,
                      fontWeight: FontWeight.w700,
                      fontSize: 15,
                    ),
                  ),
                ),
              );
            }

            return SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              child: Padding(
                padding: const EdgeInsets.only(bottom: 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    // Siempre muestra el banner offline arriba si está offline, incluso tras volver de otras pantallas
                    offlineBanner,
                    const SizedBox(height: 20),
                    Navbar(
                      username: userData['nickname']?.toString().isNotEmpty == true
                          ? userData['nickname']
                          : (userData['fullName']?.toString().isNotEmpty == true
                              ? userData['fullName']
                              : 'Sin nombre'),
                      title: userData['title']?.toString().isNotEmpty == true
                          ? userData['title']
                          : (userData['profileStage']?.toString().isNotEmpty == true
                              ? userData['profileStage']
                              : 'Sin título'),
                      subtitle: "Command Profile",
                      profileWidget: GestureDetector(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (_) => const SettingsPage()),
                          );
                        },
                        child: const HeroIcon(
                          HeroIcons.cog,
                          style: HeroIconStyle.outline,
                          color: Color(0xFFE9E8EE),
                          size: 28,
                        ),
                      ),
                    ),
                    const SizedBox(height: 0),
                    BackstageCard(
                      isPremium: false,
                      avatarUrl: userData['profileImageUrl'] ?? 'assets/images/default_avatar.png',
                      isAsset: false,
                      username: userData['nickname']?.toString().isNotEmpty == true
                          ? userData['nickname']
                          : (userData['fullName']?.toString().isNotEmpty == true
                              ? userData['fullName']
                              : 'Sin nombre'),
                      title: userData['title']?.toString().isNotEmpty == true
                          ? userData['title']
                          : (userData['profileStage']?.toString().isNotEmpty == true
                              ? userData['profileStage']
                              : 'Sin título'),
                      description: userData['description']?.toString().isNotEmpty == true
                          ? userData['description']
                          : (userData['bio']?.toString().isNotEmpty == true
                              ? userData['bio']
                              : (userData['about']?.toString().isNotEmpty == true
                                  ? userData['about']
                                  : 'Sin descripción')),
                      qrData: "https://tuapp.com/user/${userData['nickname'] ?? 'user'}",
                      onEditPressed: () async {
                        await Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => EditProfilePage(userData: userData),
                          ),
                        );
                        setState(() {});
                      },
                      customImageProvider: () {
                        final path = userData['profileImageUrl']?.toString() ?? '';
                        if (path.isEmpty) {
                          return const AssetImage('assets/images/default_avatar.png');
                        } else if (path.startsWith('http')) {
                          return NetworkImage(path) as ImageProvider<Object>;
                        } else if (File(path).existsSync()) {
                          return FileImage(File(path)) as ImageProvider<Object>;
                        } else {
                          return const AssetImage('assets/images/default_avatar.png');
                        }
                      }(),
                    ),
                    CustomPaint(
                      size: const Size(320, 2),
                      painter: DottedLinePainter(),
                    ),
                    Container(
                      width: 320,
                      height: 390,
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: const Color(0xFF010B19),
                        border: Border.all(color: Color(0xFFB4B1B8)),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Column(
                        children: [
                          const SectionTitle(title: "Achievements"),
                          const SizedBox(height: 14),
                          _buildAchievements(context, userId), // 👈 actualizado
                          const SizedBox(height: 28),
                          const SectionTitle(title: "Friends"),
                          const SizedBox(height: 14),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            children: const [
                              FriendCircle(
                                image: "assets/images/X.jpg",
                                status: FriendStatus.online,
                              ),
                              FriendCircle(
                                image: "assets/images/Lin ling.jpg",
                                status: FriendStatus.away,
                              ),
                              FriendCircle(
                                image: "assets/images/E-soul.jpg",
                                status: FriendStatus.offline,
                              ),
                              PlusIcon(),
                            ],
                          ),
                          const SizedBox(height: 28),
                          const SectionTitle(title: "Now Listening"),
                          const SizedBox(height: 14),
                          _buildPlayer(context),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  // 🎵 Mini reproductor sincronizado con TrackDetailScreen
  static Widget _buildPlayer(BuildContext context) {
    final playback = context.watch<PlaybackManagerService>();
    final track = playback.currentTrack;
    final isPlaying = playback.isPlaying;

    // 🟡 Si no hay canción, mostrar placeholder con callbacks vacíos
    if (track == null) {
      return const MiniSongReproductor(
        albumImage: "assets/images/Coldrain.jpg",
        songTitle: "No hay canción",
        artistName: "Desconocido",
        isPlaying: false,
        onPlayPause: _noop,
        onNext: _noop,
        onPrevious: _noop,
      );
    }

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => TrackDetailScreen(
              tracks: playback.playlist,
              currentIndex: playback.currentIndex,
              genre: playback.genre.isNotEmpty ? playback.genre : "rock",
            ),
          ),
        );
      },
      child: MiniSongReproductor(
        albumImage: (track.albumArt.isNotEmpty)
            ? track.albumArt
            : "assets/images/Coldrain.jpg",
        songTitle: track.title,
        artistName: track.artist,
        isPlaying: isPlaying,
        onPlayPause: () =>
            isPlaying ? playback.pause() : playback.play(),
        onNext: playback.next,
        onPrevious: playback.previous,
      ),
    );
  }

  // 👇 Callback vacío para evitar errores de tipo
  static void _noop() {}


  // 🏅 Logros desde Firestore (actualizado con navegación)
  static Widget _buildAchievements(BuildContext context, String userId) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .collection('achievements')
          .orderBy('unlockedAt', descending: true)
          .limit(3)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const SizedBox(
            height: 52,
            child: Center(
              child: CircularProgressIndicator(color: Colors.white),
            ),
          );
        }

        if (snapshot.hasError) {
          return const Text(
            "Error al cargar logros.",
            style: TextStyle(color: Colors.redAccent),
          );
        }

        final docs = snapshot.data?.docs ?? [];
        final List<String> images = [];

        for (var doc in docs) {
          final data = doc.data() as Map<String, dynamic>;
          final icon = data['icon'] as String?;
          images.add(icon ?? "assets/images/X.jpg");
        }

        while (images.length < 3) {
          images.add("assets/images/X.jpg");
        }

        return Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            for (var img in images.take(3)) AchievementCircle(image: img),
            PlusIcon(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => AllAchievementsPage(userId: userId),
                  ),
                );
              },
            ),
          ],
        );
      },
    );
  }
}

/// Línea punteada horizontal
class DottedLinePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0XFFB4B1B8)
      ..strokeWidth = 2;

    const dashWidth = 6;
    const dashSpace = 4;
    double startX = 0;

    while (startX < size.width) {
      canvas.drawLine(Offset(startX, 0), Offset(startX + dashWidth, 0), paint);
      startX += dashWidth + dashSpace;
    }
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}

class SectionTitle extends StatelessWidget {
  final String title;
  const SectionTitle({super.key, required this.title});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const Expanded(child: Divider(color: Colors.white54, thickness: 1)),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8),
          child: Text(
            title,
            style: const TextStyle(
              fontFamily: "RobotoMono",
              color: Colors.white,
              fontSize: 15,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        const Expanded(child: Divider(color: Colors.white54, thickness: 1)),
      ],
    );
  }
}

class AchievementCircle extends StatelessWidget {
  final String image;
  const AchievementCircle({super.key, required this.image});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 52,
      height: 52,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white, width: 2),
        image: DecorationImage(
          image: image.startsWith("assets/")
              ? AssetImage(image) as ImageProvider
              : NetworkImage(image),
          fit: BoxFit.cover,
        ),
      ),
    );
  }
}

class PlusIcon extends StatelessWidget {
  final VoidCallback? onTap;
  const PlusIcon({super.key, this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: const SizedBox(
        width: 60,
        height: 60,
        child: HeroIcon(
          HeroIcons.plusCircle,
          color: Colors.white70,
          size: 60,
        ),
      ),
    );
  }
}

enum FriendStatus { online, away, offline }

class FriendCircle extends StatelessWidget {
  final String image;
  final FriendStatus status;
  const FriendCircle({super.key, required this.image, required this.status});

  Color get borderColor {
    switch (status) {
      case FriendStatus.online:
        return Colors.greenAccent;
      case FriendStatus.away:
        return Colors.amberAccent;
      case FriendStatus.offline:
        return Colors.red;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 52,
      height: 52,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: borderColor, width: 2),
        image: DecorationImage(image: AssetImage(image), fit: BoxFit.cover),
      ),
    );
  }
}

// fix black/white medals

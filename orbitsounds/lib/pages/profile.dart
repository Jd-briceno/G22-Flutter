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

class ProfileBackstagePage extends StatefulWidget {
  const ProfileBackstagePage({super.key});

  @override
  State<ProfileBackstagePage> createState() => _ProfileBackstagePageState();
}

class _ProfileBackstagePageState extends State<ProfileBackstagePage> {
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
        child: FutureBuilder<DocumentSnapshot>(
          future:
              FirebaseFirestore.instance.collection('users').doc(userId).get(),
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

            if (!snapshot.hasData || !snapshot.data!.exists) {
              return const Center(
                child: Text(
                  "No se encontraron datos del usuario.",
                  style: TextStyle(color: Colors.white),
                ),
              );
            }

            final userData = snapshot.data!.data() as Map<String, dynamic>;

            return SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              child: Padding(
                padding: const EdgeInsets.only(bottom: 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    const SizedBox(height: 20),
                    Navbar(
                      username: "Jay Walker",
                      title: "Lightning Ninja",
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
                      avatarUrl: userData['profileImageUrl'] ??
                          'assets/images/default_avatar.png',
                      isAsset: userData['profileImageUrl']
                              ?.startsWith('assets/') ??
                          false,
                      username: userData['nickname'] ?? 'Sin nombre',
                      title: userData['title'] ?? 'Sin título',
                      description: userData['description'] ?? 'Sin descripción',
                      qrData:
                          "https://tuapp.com/user/${userData['nickname'] ?? 'user'}",
                      onEditPressed: () async {
                        await Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) =>
                                EditProfilePage(userData: userData),
                          ),
                        );
                        setState(() {}); // 🔁 Refresca al volver
                      },
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
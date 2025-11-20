import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:melodymuse/components/achivement_popup.dart';
import 'package:melodymuse/views/home_screen.dart';
import 'package:melodymuse/views/playlist_screen.dart';
import 'package:heroicons/heroicons.dart';
import 'dart:io'; // 👈 necesario para exit(0)
import 'package:flutter/services.dart'; // 👈 necesario para SystemNavigator.pop()
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Space Genre Selector',
      home: const GenreSelectorPage(),
    );
  }
}

/// 🎶 Centralized genre names
class Genres {
  static const String punk = "Punk";
  static const String kpop = "K-Pop";
  static const String jrock = "J-Rock";
  static const String pop = "Pop";
  static const String jazz = "Jazz";
  static const String rock = "Rock";
  static const String classical = "Classical";
  static const String metal = "Heavy Metal";
  static const String edm = "EDM";
  static const String rap = "Rap";
  static const String medieval = "Medieval";
  static const String anisong = "Anisong";
  static const String musical = "Musical";
}

class GenreSelectorPage extends StatefulWidget {
  const GenreSelectorPage({super.key});

  @override
  State<GenreSelectorPage> createState() => _GenreSelectorPageState();
}

class _GenreSelectorPageState extends State<GenreSelectorPage> {
  late final PageController _pageController;
  int _currentPage = 0;
  final FirebaseAnalytics analytics = FirebaseAnalytics.instance;

  //Desbloquear logro
  Future<void> unlockAchievement(BuildContext context, String genreName) async {
    final user = FirebaseAuth.instance.currentUser;
    final achievement = genreAchievements[genreName]!;
    final offlineService = OfflineAchievementsService();
    final uid = user?.uid ?? "guest";

    try {
      final connected = await Connectivity().checkConnectivity();
      final online = connected != ConnectivityResult.none;

      bool alreadyUnlocked = false;

      if (online && user != null) {
        // 🔍 Verificar si ya existe el logro en Firestore
        final existing = await FirebaseFirestore.instance
            .collection('users')
            .doc(uid)
            .collection('achievements')
            .where('target', isEqualTo: genreName)
            .limit(1)
            .get();

        alreadyUnlocked = existing.docs.isNotEmpty;

        if (!alreadyUnlocked) {
          await offlineService.saveAchievementOnline(genreName, achievement);
        }
      } else {
        // 🔍 Revisar si está en caché local
        final prefs = await SharedPreferences.getInstance();
        final cached = prefs.getStringList('cached_achievements') ?? [];
        alreadyUnlocked = cached.any((e) => e.startsWith("$genreName|"));

        if (!alreadyUnlocked) {
          await offlineService.cacheAchievement(genreName, achievement);
        }
      }

      // 🎖️ Mostrar popup solo si es NUEVO
      if (!alreadyUnlocked && context.mounted) {
        showDialog(
          context: context,
          barrierDismissible: true,
          builder: (_) => AchievementPopup(
            genre: genreName,
            title: achievement["title"]!,
            iconPath: achievement["icon"]!,
          ),
        );
      } else {
        print("✅ Logro '$genreName' ya desbloqueado, no se muestra popup.");
      }
    } catch (e) {
      print("⚠️ Error guardando logro: $e");
      // En caso de error, lo cacheamos igualmente
      await offlineService.cacheAchievement(genreName, achievement);
    }
  }




  final List<Map<String, dynamic>> genres = [
    {
      "name": Genres.medieval,
      "planet": "assets/images/Medieval.png",
      "colors":[Color.fromRGBO(189, 0, 27, 0.8), Color.fromRGBO(211, 164, 46, 0.3)],
      "description":"Echoes of ancient times — Medieval music brings the sounds of castles, battles, and legends to life through chants, lutes, and epic melodies.",
      "subgenres":["Celtic","Medieval","Fantasy"],
      "fontFamily":"Medieval"
    },
    {
      "name": Genres.punk,
      "planet": "assets/images/Punk.png",
      "colors": [Color.fromRGBO(30, 30, 30, 0.8), Color.fromRGBO(251, 11, 11, 0.3)],
      "description": "A musical style that emerged in the mid-1970s, characterised by its raw energy, rebellious lyrics and rebellious aesthetic. It tends to be fast, direct and DIY in attitude.",
      "subgenres": ["Punk Rock", "Hardcore", "Post-Punk"],
      "fontFamily": "Punk"
    },
    {
      "name": Genres.kpop,
      "planet": "assets/images/Kpop.png",
      "colors": [Color.fromRGBO(163,140,205, 0.8), Color.fromRGBO(0,0,0, 0.3)],
      "description": "Colorful, polished, and full of choreography — K-Pop blends pop hooks with dazzling visuals.",
      "subgenres": ["Idol Pop", "K-R&B", "K-Hip Hop", "Girl/Boy Groups"],
      "fontFamily": "Kpop"
    },
    {
      "name": Genres.jrock,
      "planet": "assets/images/JRock.png",
      "colors": [Color.fromRGBO(94,2,0, 0.8), Color.fromRGBO(222,5,0, 0.3)],
      "description": "Japanese Rock mixes powerful guitar riffs with melodic vocals and theatrical flair.",
      "subgenres": ["Visual Kei", "Alternative", "Anime Rock", "Post-Rock"],
      "fontFamily": "JRock"
    },
    {
      "name": Genres.pop,
      "planet": "assets/images/Pop.png",
      "colors": [Color.fromRGBO(214,15,132, 0.8), Color.fromRGBO(255,212,0, 0.3)],
      "description": "Catchy, mainstream, and always evolving — Pop is built to dominate the charts.",
      "subgenres": ["Dance Pop", "Synth Pop", "Electro Pop", "Indie Pop"],
      "fontFamily": "Pop"
    },
    {
      "name": Genres.rap,
      "planet": "assets/images/Rap.png",
      "colors": [Color.fromRGBO(0, 0, 0, 0.8), Color.fromRGBO(212, 175, 55, 0.6)],
      "description": "Raw, powerful, and expressive — Rap tells stories of struggle, triumph, and culture through rhythm and rhyme.",
      "subgenres": ["Trap", "Boom Bap", "Gangsta Rap", "Conscious Rap"],
      "fontFamily": "Rap"
    },
    {
      "name": Genres.jazz,
      "planet": "assets/images/Jazz.png",
      "colors": [Color.fromRGBO(23,77,38, 0.8), Color.fromRGBO(77,134,87, 0.3)],
      "description": "Smooth improvisation and soulful grooves — Jazz is freedom in music form.",
      "subgenres": ["Bebop", "Swing", "Cool Jazz", "Fusion"],
      "fontFamily": "Jazz"
    },
    {
      "name": Genres.rock,
      "planet": "assets/images/Rock.png",
      "colors": [Color.fromRGBO(52,42,29, 0.8), Color.fromRGBO(255, 69, 0, 0.3)],
      "description": "Guitars, drums, and raw passion — Rock is the heartbeat of rebellion.",
      "subgenres": ["Classic Rock", "Alternative", "Indie Rock", "Progressive"],
      "fontFamily": "Rock"
    },
    {
      "name": Genres.classical,
      "planet": "assets/images/Classical.png",
      "colors": [Color.fromRGBO(255,201,0, 0.8), Color.fromRGBO(234,234,234, 0.3)],
      "description": "Timeless orchestras and elegant compositions — Classical is music’s pure foundation.",
      "subgenres": ["Baroque", "Romantic", "Opera", "Symphony"],
      "fontFamily": "Classical"
    },
    {
      "name": Genres.metal,
      "planet": "assets/images/Metal.png",
      "colors": [Color.fromRGBO(20, 20, 20, 0.8), Color.fromRGBO(169, 169, 169, 0.3)],
      "description": "Loud, powerful, and intense — Metal is headbanging riffs and thundering drums.",
      "subgenres": ["Thrash", "Death", "Power Metal", "Black Metal"],
      "fontFamily": "Metal"
    },
    {
      "name": Genres.anisong,
      "planet": "assets/images/Anisong.png",
      "colors": [Color.fromRGBO(0,191,198, 0.8),Color.fromRGBO(255,191,0, 0.4)],
      "description": "Emotional, vibrant, and unforgettable — Anisong captures the spirit of anime worlds through powerful melodies and heartfelt lyrics.",
      "subgenres": ["Anime Openings", "Anime Endings", "Character Songs"],
      "fontFamily": "Anime"
    },
    {
      "name": Genres.edm,
      "planet": "assets/images/EDM.png",
      "colors": [Color.fromRGBO(4, 217, 255, 0.8), Color.fromRGBO(138,0,196, 0.3)],
      "description": "High-energy beats for the dancefloor — EDM is the pulse of festivals worldwide.",
      "subgenres": ["House", "Techno", "Dubstep"],
      "fontFamily": "EDM"
    },
    {
      "name": Genres.musical,
      "planet": "assets/images/Musical.png",
      "colors": [Color.fromRGBO(1, 29, 107, 0.8), Color.fromRGBO(255,191,0, 0.4)],
      "description": "A glanze to the past.",
      "subgenres": ["Musical", "Hamilton", "Epic"],
      "fontFamily": "Musical"
    },
  ];

  /// 🎖️ Logros y títulos por género
  final Map<String, Map<String, String>> genreAchievements = {
    Genres.medieval: {"title": "Knight of Ballads", "icon": "assets/medals/medieval.png"},
    Genres.punk: {"title": "Rebel of Noise", "icon": "assets/medals/punk.png"},
    Genres.kpop: {"title": "Idol Dreamer", "icon": "assets/medals/kpop.png"},
    Genres.jrock: {"title": "Samurai of Rock", "icon": "assets/medals/jrock.png"},
    Genres.pop: {"title": "Chart Conqueror", "icon": "assets/medals/pop.png"},
    Genres.rap: {"title": "Lyrical Warrior", "icon": "assets/medals/rap.png"},
    Genres.jazz: {"title": "Smooth Maestro", "icon": "assets/medals/jazz.png"},
    Genres.rock: {"title": "Lord of Guitars", "icon": "assets/medals/rock.png"},
    Genres.classical: {"title": "Symphony Sage", "icon": "assets/medals/classical.png"},
    Genres.metal: {"title": "Headbanging Berserker", "icon": "assets/medals/metal.png"},
    Genres.anisong: {"title": "Otaku Hero", "icon": "assets/medals/anisong.png"},
    Genres.edm: {"title": "Festival Summoner", "icon": "assets/medals/edm.png"},
    Genres.musical: {"title": "Stage Performer", "icon": "assets/medals/musical.png"},
  };


  @override
  void initState() {
    super.initState();
    int startPage = 1000 * genres.length;
    _pageController = PageController(
      viewportFraction: 0.5,
      initialPage: startPage,
    );
    _currentPage = startPage % genres.length;
  }

  void _goToPage(int index) {
    _pageController.animateToPage(
      index,
      duration: const Duration(milliseconds: 400),
      curve: Curves.easeInOut,
    );
  }

  void _showPlanetPopup(Map<String, dynamic> genre) {
    final List<Color> gradientColors = genre["colors"];
    final String description = genre["description"];
    final List<String> subgenres = genre["subgenres"];

    showDialog(
      context: context,
      barrierDismissible: true,
      barrierColor: Color(0xFF010B19).withOpacity(0.8),
      builder: (context) {
        return Center(
          child: Container(
            width: 360,
            height: 760,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              gradient: LinearGradient(
                begin: Alignment.topRight,
                end: Alignment.bottomLeft,
                colors: gradientColors,
              ),
              border: Border.all(color: Colors.white24),
            ),
            child: Stack(
              children: [
                Padding(
                  padding: const EdgeInsets.all(10),
                  child: SingleChildScrollView(
                    child: Column(
                      children: [
                        const SizedBox(height: 40),
                        Text(
                          genre["name"],
                          style: TextStyle(
                            fontSize: genre["name"] == Genres.medieval ? 48 : 60,
                            fontWeight: FontWeight.bold,
                            fontFamily: genre["fontFamily"],
                            color: Colors.white,
                            decoration: TextDecoration.none,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 12),
                        Text(
                          description,
                          style: const TextStyle(
                            fontSize: 16,
                            color: Colors.white70,
                            height: 1.4,
                            decoration: TextDecoration.none,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 12),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          alignment: WrapAlignment.center,
                          children: subgenres.map((sub) {
                            return Container(
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(22),
                                border: Border.all(color: Colors.white70),
                              ),
                              child: Text(
                                sub,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 14,
                                  decoration: TextDecoration.none,
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                        const SizedBox(height: 20),
                        Image.asset(
                          genre["planet"],
                          height: 360,
                        ),
                        const SizedBox(height: 16),
                        Column(
                          children: [
                            GestureDetector(
                              onTap: () async {
                                // 🎖️ Desbloqueo de logro y analytics en paralelo (sin bloquear la UI)
                                unawaited(unlockAchievement(context, genre["name"]));
                                unawaited(analytics.logEvent(
                                  name: 'explore_songs_clicked',
                                  parameters: {
                                    'genre': genre["name"],
                                    'timestamp': DateTime.now().toIso8601String(),
                                  },
                                ));

                                // 🕒 Marca de inicio
                                final startTime = DateTime.now();

                                // 🚀 Navega inmediatamente
                                if (context.mounted) {
                                  await Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => PlaylistScreen(
                                        genre: genre["name"],
                                        colors: List<Color>.from(genre["colors"]),
                                        fontFamily: genre["fontFamily"],
                                        startTime: startTime,
                                      ),
                                    ),
                                  );
                                }
                              },

                              child: Container(
                                width: double.infinity,
                                padding: const EdgeInsets.symmetric(vertical: 14),
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(22),
                                  border: Border.all(color: Colors.white),
                                  gradient: LinearGradient(
                                    begin: Alignment.topRight,
                                    end: Alignment.bottomLeft,
                                    colors: gradientColors,
                                  ),
                                ),
                                child: const Center(
                                  child: Text(
                                    "Explore Songs",
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                      decoration: TextDecoration.none,
                                      fontFamily: 'RobotoMono',
                                    ),
                                  ),
                                ),
                              ),
                            ),


                            const SizedBox(height: 12),
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(22),
                                border: Border.all(color: Colors.white),
                                gradient: LinearGradient(
                                  begin: Alignment.bottomLeft,
                                  end: Alignment.topRight,
                                  colors: gradientColors,
                                ),
                              ),
                              child: const Center(
                                child: Text(
                                  "Listen to Preview",
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    decoration: TextDecoration.none,
                                    fontFamily: 'RobotoMono',
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                Positioned(
                  top: 8,
                  right: 8,
                  child: IconButton(
                    icon: const Icon(Icons.close, size: 36, color: Colors.white),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF010B19),
      body: SafeArea(
        child: Stack(
          children: [
            PageView.builder(
              controller: _pageController,
              scrollDirection: Axis.vertical,
              onPageChanged: (index) {
                setState(() {
                  _currentPage = index % genres.length;
                });
              },
              itemBuilder: (context, index) {
                final genre = genres[index % genres.length];
                return AnimatedBuilder(
                  animation: _pageController,
                  builder: (context, child) {
                    double scale = 0.6;
                    if (_pageController.position.haveDimensions) {
                      double pageOffset = _pageController.page! - index;
                      scale = (1 - (pageOffset.abs() * 0.4)).clamp(0.6, 1.0);
                    } else {
                      if (index % genres.length == _currentPage) scale = 1.0;
                    }
                    return Transform.scale(
                      scale: scale,
                      child: GestureDetector(
                        onTap: () async {
                          final genre = genres[index % genres.length];
                          if (index % genres.length == _currentPage) {
                            // 📊 Log: el usuario seleccionó un planeta
                            await analytics.logEvent(
                              name: 'genre_planet_selected',
                              parameters: {
                                'genre': genre["name"],
                                'timestamp': DateTime.now().toIso8601String(),
                              },
                            );
                            _showPlanetPopup(genre);
                          } else {
                            _goToPage(index);
                          }
                        },
                        child: PlanetWidget(
                          genreName: genre["name"],
                          planetImage: genre["planet"],
                          isSelected: index % genres.length == _currentPage,
                        ),
                      ),
                    );
                  },
                );
              },
            ),
            // 🏠 Botón de Home (HeroIcon)
            Positioned(
              top: 16,
              left: 16,
              child: GestureDetector(
                onTap: () {
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(builder: (context) => const HomeScreen()),
                  );
                },
                child: const HeroIcon(
                  HeroIcons.home,
                  style: HeroIconStyle.outline,
                  color: Colors.white,
                  size: 45,
                ),
              ),
            ),
            // 🕳️ Agujero negro (derecha arriba, cierre con confirmación)
            Positioned(
              top: 16,
              right: 16,
              child: GestureDetector(
                onTap: () {
                  if (Platform.isAndroid) {
                    // ⚡ Android: confirmación antes de cerrar
                    showDialog(
                      context: context,
                      builder: (BuildContext context) {
                        return AlertDialog(
                          backgroundColor: const Color(0xFF010B19),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          title: const Text(
                            "¿Salir?",
                            style: TextStyle(color: Colors.white),
                          ),
                          content: const Text(
                            "¿Seguro que quieres cerrar la aplicación?",
                            style: TextStyle(color: Colors.white70),
                          ),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.of(context).pop(),
                              child: const Text("Cancelar", style: TextStyle(color: Colors.white)),
                            ),
                            TextButton(
                              onPressed: () {
                                SystemNavigator.pop(); // ✅ cierre en Android
                              },
                              child: const Text("Salir", style: TextStyle(color: Colors.redAccent)),
                            ),
                          ],
                        );
                      },
                    );
                  } else if (Platform.isIOS) {
                    // 🍎 iOS: confirmación antes de salir
                    showDialog(
                      context: context,
                      builder: (BuildContext context) {
                        return AlertDialog(
                          backgroundColor: const Color(0xFF010B19),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          title: const Text(
                            "¿Salir?",
                            style: TextStyle(color: Colors.white),
                          ),
                          content: const Text(
                            "¿Seguro que quieres cerrar la aplicación?",
                            style: TextStyle(color: Colors.white70),
                          ),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.of(context).pop(),
                              child: const Text("Cancelar", style: TextStyle(color: Colors.white)),
                            ),
                            TextButton(
                              onPressed: () {
                                exit(0); // ✅ cierre forzado en iOS
                              },
                              child: const Text("Salir", style: TextStyle(color: Colors.redAccent)),
                            ),
                          ],
                        );
                      },
                    );
                  }
                },
                child: Image.asset(
                  "assets/images/black-hole.png",
                  width: 60,
                  height: 60,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class PlanetWidget extends StatelessWidget {
  final String genreName;
  final String planetImage;
  final bool isSelected;

  const PlanetWidget({
    super.key,
    required this.genreName,
    required this.planetImage,
    required this.isSelected,
  });

  @override
  Widget build(BuildContext context) {
    const double planetSize = 380;

    return SizedBox(
      height: planetSize + 100,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Container(
            width: planetSize,
            height: planetSize,
            decoration: BoxDecoration(
              image: DecorationImage(
                image: AssetImage(planetImage),
                fit: BoxFit.contain,
              ),
            ),
          ),
          if (isSelected)
            Positioned(
              bottom: -7,
              child: Text(
                genreName,
                style: const TextStyle(
                  fontSize: 40,
                  color: Color(0xFFE9E8EE),
                  fontWeight: FontWeight.bold,
                  fontFamily: 'RobotoMono', // 👈 siempre RobotoMono
                  decoration: TextDecoration.none,
                ),
                textAlign: TextAlign.center,
              ),
            ),
        ],
      ),
    );
  }
}

/// Minimal offline achievements helper (inlined to avoid missing import)
class OfflineAchievementsService {
  /// Save achievement online under: users/{uid}/achievements
  Future<void> saveAchievementOnline(String genre, Map<String, String> achievement) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;
      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('achievements')
          .add({
        'target': genre,
        'title': achievement['title'],
        'icon': achievement['icon'],
        'unlockedAt': DateTime.now().toIso8601String(),
        'source': 'genre_selector',
      });
    } catch (e) {
      // Best-effort: if online save fails, cache locally so it can be synced later
      await cacheAchievement(genre, achievement);
    }
  }

  /// Cache achievement locally in SharedPreferences under key 'cached_achievements'
  Future<void> cacheAchievement(String genre, Map<String, String> achievement) async {
    final prefs = await SharedPreferences.getInstance();
    final cached = prefs.getStringList('cached_achievements') ?? [];
    final record = [
      genre,
      achievement['title'] ?? '',
      achievement['icon'] ?? '',
      DateTime.now().toIso8601String(),
    ].join('|');
    // avoid duplicates for same genre
    if (!cached.any((e) => e.startsWith("$genre|"))) {
      cached.add(record);
      await prefs.setStringList('cached_achievements', cached);
    }
  }
}


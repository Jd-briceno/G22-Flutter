import 'dart:async';
import 'package:flutter/material.dart';
import 'package:heroicons/heroicons.dart';
import 'package:flutter_feather_icons/flutter_feather_icons.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:melodymuse/main.dart';
import '../models/playlist_model.dart';
import '../services/ares_playlist_generator_service.dart';

class AresRecommendationsScreen extends StatefulWidget {
  const AresRecommendationsScreen({super.key});

  @override
  State<AresRecommendationsScreen> createState() =>
      _AresRecommendationsScreenState();
}

class _AresRecommendationsScreenState extends State<AresRecommendationsScreen> {
  final AresPlaylistGeneratorService _ares = AresPlaylistGeneratorService();
  Playlist? _playlist;
  bool _loading = false;
  StreamSubscription<double>? _progressSub;

  // ✅ Variables movidas a nivel de clase
  List<String> _likedSongs = [];
  List<String> _likedGenres = [];
  List<String> _interests = [];

  Future<void> _generatePlaylist() async {
    await _progressSub?.cancel();

    setState(() {
      _loading = true;
      _playlist = null;
    });

    _progressSub = _ares.progressStream.listen((p) {
      if (!mounted) return;
    });

    try {
      final uid = FirebaseAuth.instance.currentUser?.uid;
      if (uid == null) throw Exception("User not authenticated");

      // 🔹 Obtener documento del usuario
      final userDoc =
          await FirebaseFirestore.instance.collection('users').doc(uid).get();
      if (!userDoc.exists) throw Exception("User document not found");

      final userData = userDoc.data()!;
      _interests = List<String>.from(userData['interests'] ?? []);

      // 🔹 Liked Songs
      final likedSongsSnap = await FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .collection('liked_songs')
          .where('liked', isEqualTo: true)
          .get();

      _likedSongs = likedSongsSnap.docs
          .map((d) => d['title'] as String)
          .where((title) => title.isNotEmpty)
          .toList();

      // 🔹 Favorite Genres (achieved == true)
      final goalsSnap = await FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .collection('listening_goals')
          .where('achieved', isEqualTo: true)
          .get();

      _likedGenres = goalsSnap.docs
          .map((d) => d['genre'] as String)
          .where((g) => g.isNotEmpty)
          .toList();

      // 🔹 Generar playlist personalizada
      final playlist = await _ares.generatePersonalizedPlaylist(
        likedGenres: _likedGenres,
        likedSongs: _likedSongs,
        interests: _interests,
      );

      if (!mounted) return;
      setState(() {
        _playlist = playlist;
      });

      await analytics.logEvent(
        name: 'ares_playlist_generated',
        parameters: {
          'user_id': uid,
          'timestamp': DateTime.now().toIso8601String(),
          'playlist_title': 'ARES Playlist',
        },
      );

      await FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .update({
        'ares_usage_count': FieldValue.increment(1),
      });
    } catch (e, st) {
      debugPrint('Error generating playlist: $e\n$st');
      if (!mounted) return;
      setState(() => _playlist = null);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error generating playlist: ${e.toString()}')),
      );
    } finally {
      if (!mounted) return;
      setState(() => _loading = false);
      await _askFeedbackForAres();
    }
  }

  Future<void> _askFeedbackForAres() async {
    double rating = 4;

    await showDialog<double>(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: Colors.black,
          title: const Text(
            "How much did this ARES-playlist match your mood?",
            style: TextStyle(
              color: Color(0xFFBD001B),
              fontSize: 16,
              fontFamily: 'RobotoMono',
            ),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                "1 = not at all | 5 = exactly how I feel",
                style: TextStyle(
                  color: Color(0xFFBD001B),
                  fontSize: 10,
                  fontFamily: 'RobotoMono',
                ),
              ),
              const SizedBox(height: 18),
              StatefulBuilder(
                builder: (context, setState) {
                  return Column(
                    children: [
                      Slider(
                        value: rating,
                        min: 1,
                        max: 5,
                        divisions: 4,
                        label: rating.round().toString(),
                        activeColor: const Color(0xFFBD001B),
                        inactiveColor: Colors.white24,
                        onChanged: (value) {
                          setState(() => rating = value);
                        },
                      ),
                      Text(
                        "${rating.round()} / 5",
                        style: const TextStyle(
                          color: Color(0xFFBD001B),
                          fontSize: 14,
                          fontFamily: 'RobotoMono',
                        ),
                      ),
                    ],
                  );
                },
              ),
            ],
          ),
          actions: [
            TextButton(
              child:
                  const Text("Cancel", style: TextStyle(color: Colors.white54)),
              onPressed: () => Navigator.pop(context),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFBD001B),
              ),
              child: const Text("Submit",
                  style: TextStyle(color: Colors.black)),
              onPressed: () => Navigator.pop(context, rating),
            ),
          ],
        );
      },
    ).then((result) async {
      if (result != null) {
        final uid = FirebaseAuth.instance.currentUser?.uid ?? 'anonymous';
        await FirebaseFirestore.instance
            .collection('users')
            .doc(uid)
            .collection('ares_feedback')
            .add({
          'rating': result.round(),
          'timestamp': DateTime.now().toIso8601String(),
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Thanks for your feedback! 🎧"),
            backgroundColor: Color(0xFFBD001B),
          ),
        );
      }
    });
  }

  @override
  void initState() {
    super.initState();
    _generatePlaylist();
  }

  @override
  void dispose() {
    _progressSub?.cancel();
    _ares.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Scaffold(
      body: Stack(
        children: [
          CustomPaint(size: size, painter: _AresBackgroundPainter()),

          // 🔹 Header
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                children: [
                  IconButton(
                    icon: const HeroIcon(
                      HeroIcons.arrowLeftCircle,
                      color: Colors.black,
                      style: HeroIconStyle.outline,
                      size: 40,
                    ),
                    onPressed: () => Navigator.pop(context),
                  ),
                  const SizedBox(width: 8),
                  const Text(
                    "Discover",
                    style: TextStyle(
                      fontFamily: "EncodeSansExpanded",
                      fontWeight: FontWeight.bold,
                      fontSize: 28,
                      color: Colors.black,
                    ),
                  ),
                ],
              ),
            ),
          ),

          // 🔹 Imagen principal
          Align(
            alignment: const Alignment(0, -0.25),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Transform.translate(
                  offset: const Offset(0, -76),
                  child: RotatedBox(
                    quarterTurns: -1,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: const [
                        Text(
                          "Your personal playlist ",
                          style: TextStyle(
                            color: Colors.black,
                            fontFamily: "RobotoMono",
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Icon(
                          FeatherIcons.disc,
                          color: Colors.black,
                          size: 20,
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 12),

                Stack(
                  children: [
                    Container(
                      width: size.width * 0.65,
                      height: size.height * 0.44,
                      clipBehavior: Clip.hardEdge,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(32),
                        color: Colors.black,
                      ),
                      child: Stack(
                        children: [
                          Opacity(
                            opacity: 0.3,
                            child: Image.asset(
                              "assets/images/ARES.jpg",
                              width: double.infinity,
                              height: double.infinity,
                              fit: BoxFit.cover,
                            ),
                          ),
                          Positioned.fill(
                            child: Container(
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(32),
                                border: Border.all(
                                  color: const Color(0xFF8C1007),
                                  width: 3,
                                ),
                              ),
                            ),
                          ),
                          const Positioned(
                            bottom: 12,
                            left: 16,
                            child: Text(
                              "ARES",
                              style: TextStyle(
                                color: Color(0xFFBD001B),
                                fontFamily: "RobotoMono",
                                fontWeight: FontWeight.bold,
                                fontSize: 20,
                                letterSpacing: 1.5,
                              ),
                            ),
                          ),
                          const Positioned(
                            bottom: 12,
                            right: 16,
                            child: CircleAvatar(
                              radius: 32,
                              backgroundColor: Color(0xFFBD001B),
                              child: HeroIcon(
                                HeroIcons.play,
                                color: Colors.black,
                                size: 36,
                                style: HeroIconStyle.outline,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // 🔹 Contenido inferior dinámico
          Positioned(
            top: size.height * 0.64,
            left: 16,
            right: 16,
            bottom: 0,
            child: _loading
                ? Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: const [
                      CircularProgressIndicator(color: Color(0xFFBD001B)),
                      SizedBox(height: 16),
                      Text(
                        "Generating your mix...",
                        style: TextStyle(
                          color: Color(0xFF8C1007),
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  )
                : _playlist == null
                    ? Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Text(
                              "Couldn’t generate playlist, try again",
                              style: TextStyle(color: Color(0xFF8C1007)),
                            ),
                            const SizedBox(height: 12),
                            ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFFBD001B),
                                foregroundColor: Colors.white,
                              ),
                              onPressed: _generatePlaylist,
                              child: const Text("Try again"),
                            ),
                          ],
                        ),
                      )
                    : ListView(
                        padding: const EdgeInsets.only(bottom: 20),
                        children: [
                          Text(
                            _playlist!.title,
                            style: const TextStyle(
                              fontSize: 30,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFFBD001B),
                              fontFamily: "EncodeSansExpanded",
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            "Based on your recommendations, interests, liked songs and most listened genres. Because you've been listening to ${_likedGenres.isNotEmpty ? _likedGenres.first : 'your favorite genres'} and songs like ${_likedSongs.isNotEmpty ? _likedSongs.first : 'your recent favorites'} 🎧",
                            style: const TextStyle(
                              color: Color(0xFF8C1007),
                              fontFamily: "RobotoMono",
                              fontSize: 14,
                              height: 1.4,
                            ),
                          ),
                          const SizedBox(height: 20),

                          // 🔹 Lista de tracks
                          ..._playlist!.tracks.map(
                            (t) => Card(
                              color: Colors.black.withOpacity(0.8),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                                side: const BorderSide(
                                  color: Color(0xFFBD001B),
                                  width: 1.5,
                                ),
                              ),
                              child: ListTile(
                                leading: Container(
                                  decoration: BoxDecoration(
                                    border: Border.all(
                                        color: const Color(0xFFBD001B),
                                        width: 2),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(8),
                                    child: Image.network(
                                      t.albumArt,
                                      width: 50,
                                      height: 50,
                                      fit: BoxFit.cover,
                                      errorBuilder: (_, __, ___) => const Icon(
                                        Icons.broken_image,
                                        color: Color(0xFF8C1007),
                                      ),
                                    ),
                                  ),
                                ),
                                title: Text(
                                  t.title,
                                  style: const TextStyle(
                                    fontFamily: "EncodeSansExpanded",
                                    color: Color(0xFFBD001B),
                                    fontWeight: FontWeight.w700,
                                    fontSize: 16,
                                  ),
                                ),
                                subtitle: Text(
                                  t.artist,
                                  style: const TextStyle(
                                    fontFamily: "RobotoMono",
                                    color: Color(0xFF8C1007),
                                    fontSize: 14,
                                  ),
                                ),
                                trailing: (t.duration.isNotEmpty)
                                    ? Text(
                                        t.duration,
                                        style: const TextStyle(
                                          color: Color(0xFF8C1007),
                                          fontFamily: "RobotoMono",
                                          fontSize: 12,
                                        ),
                                      )
                                    : null,
                              ),
                            ),
                          ),
                        ],
                      ),
          ),
        ],
      ),
    );
  }
}

/// 🎨 Fondo con rectángulo rojo superior
class _AresBackgroundPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint();

    paint.color = Colors.black;
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), paint);

    final redRect = RRect.fromRectAndCorners(
      Rect.fromLTWH(0, 0, size.width, size.height * 0.5),
      bottomLeft: const Radius.circular(30),
      bottomRight: const Radius.circular(30),
    );

    paint.color = const Color(0xFF8C1007);
    canvas.drawRRect(redRect, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

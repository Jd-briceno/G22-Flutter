import 'dart:async';
import 'package:flutter/material.dart';
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
  double _progress = 0;
  bool _loading = false;
  StreamSubscription<double>? _progressSub;

  Future<void> _generatePlaylist() async {
    setState(() => _loading = true);

    // 🔹 Suscribirse al stream de progreso
    _progressSub = _ares.progressStream.listen((p) {
      setState(() => _progress = p);
    });

    final playlist = await _ares.generatePersonalizedPlaylist(
      likedGenres: ["J-Rock", "K-Pop"],
      likedSongs: ["Hold them down", "Thunder Bringer", "WONDERLAND", "IGNITE"],
      interests: ["DnD", "Anime", "Chill"],
    );

    setState(() {
      _playlist = playlist;
      _loading = false;
      _progress = 1.0;
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
    return Scaffold(
      backgroundColor: const Color(0xFF010B19),
      appBar: AppBar(
        backgroundColor: Colors.black,
        title: const Text("Ares AI Recommends"),
      ),
      body: Center(
        child: _loading
            ? Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const CircularProgressIndicator(color: Colors.greenAccent),
                  const SizedBox(height: 16),
                  Text(
                    "Generando playlist... ${(100 * _progress).toInt()}%",
                    style: const TextStyle(color: Colors.white),
                  ),
                ],
              )
            : _playlist == null
                ? const Text(
                    "No se pudo generar playlist 😕",
                    style: TextStyle(color: Colors.white),
                  )
                : ListView(
                    padding: const EdgeInsets.all(16),
                    children: [
                      Text(
                        _playlist!.title,
                        style: const TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        _playlist!.description,
                        style: const TextStyle(color: Colors.white70),
                      ),
                      const SizedBox(height: 16),
                      ..._playlist!.tracks.map(
                        (t) => ListTile(
                          leading: Image.network(
                            t.albumArt,
                            width: 50,
                            height: 50,
                            fit: BoxFit.cover,
                          ),
                          title: Text(
                            t.title,
                            style: const TextStyle(color: Colors.white),
                          ),
                          subtitle: Text(
                            t.artist,
                            style: const TextStyle(color: Colors.white70),
                          ),
                        ),
                      ),
                    ],
                  ),
      ),
    );
  }
}

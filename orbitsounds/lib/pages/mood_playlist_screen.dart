import 'dart:io';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import '../services/ares_playlist_generator_service.dart';
import '../models/track_model.dart';
import '../services/hive_service.dart';

class MoodPlaylistScreen extends StatefulWidget {
  const MoodPlaylistScreen({super.key});

  @override
  State<MoodPlaylistScreen> createState() => _MoodPlaylistScreenState();
}

class _MoodPlaylistScreenState extends State<MoodPlaylistScreen> {
  final AresPlaylistGeneratorService _generator = AresPlaylistGeneratorService();
  final FirebaseAnalytics _analytics = FirebaseAnalytics.instance;

  String _userInput = "";
  bool _loading = false;
  double _progress = 0.0;
  List<Track> _tracks = [];

  @override
  void initState() {
    super.initState();

    _generator.progressStream.listen(
      (p) {
        if (mounted) setState(() => _progress = p);
      },
      onError: (err) => debugPrint("❌ Error en el stream de progreso: $err"),
      onDone: () => debugPrint("✔️ Stream de progreso finalizado"),
    );

    // 🧠 NUEVO → Cargar última playlist cacheada
    _loadLastCachedPlaylist();
  }

  /// 🧠 Cargar última playlist guardada en Hive
  Future<void> _loadLastCachedPlaylist() async {
    final cached = HiveService.getLastMoodPlaylist();

    if (cached != null && cached.isNotEmpty) {
      setState(() {
        _tracks = cached
            .map((m) => Track.fromMap(Map<String, dynamic>.from(m)))
            .toList();
        _progress = 1.0;
      });

      print("⚡ Última playlist cargada desde Hive.");

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("⚡ Mostrando tu última playlist generada."),
          backgroundColor: Colors.deepPurpleAccent,
        ),
      );
    }
  }

  Future<void> _generatePlaylist() async {
    if (_userInput.trim().isEmpty) return;

    setState(() {
      _loading = true;
      _progress = 0;
      _tracks.clear();
    });

    try {
      final playlist = await _generator.generateMoodBasedPlaylist(_userInput);

      if (!mounted) return;

      final generatedTracks = playlist?.tracks ?? [];

      setState(() {
        _tracks = generatedTracks;
        _progress = 1.0;
      });

      // 🧠 NUEVO → Guardar en Hive como *última playlist*
      await HiveService.saveLastMoodPlaylist(
        generatedTracks.map((t) => t.toMap()).toList(),
      );

      final user = FirebaseAuth.instance.currentUser;

      await _analytics.logEvent(
        name: 'mood_playlist_generated',
        parameters: {
          'user_id': user?.uid ?? 'anonymous',
          'user_mood_input': _userInput,
          'track_count': _tracks.length,
          'timestamp': DateTime.now().toIso8601String(),
        },
      );

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("🎶 Playlist generada con éxito")),
      );
    } on SocketException {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Sin conexión. Cargando playlist guardada…"),
          backgroundColor: Colors.orangeAccent,
        ),
      );

      // 🧠 NUEVO fallback offline
      await _loadLastCachedPlaylist();
    } catch (e, st) {
      debugPrint("❌ Error generando playlist: $e\n$st");

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Ocurrió un error generando tu playlist 😔"),
          backgroundColor: Colors.redAccent,
        ),
      );
    } finally {
      if (!mounted) return;
      setState(() => _loading = false);
    }
  }

  Future<void> _askFeedback() async {
    double rating = 3;

    await showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text("¿Qué tan bien refleja esta playlist tu estado de ánimo?"),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text("1 = Nada que ver | 5 = Muy precisa"),
              const SizedBox(height: 16),
              StatefulBuilder(
                builder: (context, setState) {
                  return Column(
                    children: [
                      Slider(
                        value: rating,
                        min: 1,
                        max: 5,
                        divisions: 4,
                        label: rating.toStringAsFixed(0),
                        onChanged: (v) => setState(() => rating = v),
                      ),
                      Text("Valor: ${rating.toStringAsFixed(0)}"),
                    ],
                  );
                },
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Cancelar"),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, rating),
              child: const Text("Enviar"),
            ),
          ],
        );
      },
    ).then((result) async {
      if (result != null) {
        await _analytics.logEvent(
          name: 'playlist_feedback',
          parameters: {
            'user_mood_input': _userInput,
            'accuracy_rating': (result as double).round(),
            'track_count': _tracks.length,
            'timestamp': DateTime.now().toIso8601String(),
          },
        );

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text("¡Gracias por tu feedback! 🎧"),
              backgroundColor: Colors.greenAccent,
            ),
          );
        }
      }
    });
  }

  @override
  void dispose() {
    _generator.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Ares: Modo Emocional 🎭"),
        backgroundColor: Colors.deepPurpleAccent,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(
              decoration: const InputDecoration(
                labelText: "¿Cómo te sientes o cómo te quieres sentir?",
                border: OutlineInputBorder(),
              ),
              onChanged: (value) => _userInput = value,
            ),

            const SizedBox(height: 12),

            ElevatedButton.icon(
              onPressed: _generatePlaylist,
              icon: const Icon(Icons.music_note),
              label: const Text("Generar Playlist"),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.deepPurpleAccent,
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              ),
            ),

            if (_loading) ...[
              const SizedBox(height: 20),
              LinearProgressIndicator(value: _progress, color: Colors.deepPurpleAccent),
              const SizedBox(height: 10),
              const Text("Generando tu playlist... 🎶"),
            ],

            const SizedBox(height: 20),

            Expanded(
              child: _tracks.isEmpty
                  ? const Center(
                      child: Text(
                        "Aún no hay canciones.\nEscribe cómo te sientes 🎧",
                        textAlign: TextAlign.center,
                      ),
                    )
                  : Column(
                      children: [
                        Expanded(
                          child: ListView.builder(
                            itemCount: _tracks.length,
                            itemBuilder: (context, index) {
                              final t = _tracks[index];
                              return ListTile(
                                leading: Image.network(
                                  t.albumArt,
                                  width: 48,
                                  height: 48,
                                  fit: BoxFit.cover,
                                ),
                                title: Text(t.title),
                                subtitle: Text(t.artist),
                              );
                            },
                          ),
                        ),

                        const SizedBox(height: 12),

                        ElevatedButton.icon(
                          onPressed: _askFeedback,
                          icon: const Icon(Icons.feedback),
                          label: const Text("¿Coincide con tu estado de ánimo?"),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.purpleAccent,
                          ),
                        ),
                      ],
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

import 'dart:io';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import '../services/ares_playlist_generator_service.dart';
import '../models/track_model.dart';

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
        if (mounted) {
          setState(() => _progress = p);
        }
      },
      onError: (err) {
        debugPrint("❌ Error en el stream de progreso: $err");
      },
      onDone: () {
        debugPrint("✔️ Stream de progreso finalizado");
      },
    );
  }

  Future<void> _generatePlaylist() async {
    if (_userInput.trim().isEmpty) return;

    setState(() {
      _loading = true;
      _progress = 0;
      _tracks.clear();
    });

    try {
      // 🔹 Future + async/await
      final playlist = await _generator.generateMoodBasedPlaylist(_userInput);

      if (!mounted) return;

      setState(() {
        _tracks = playlist?.tracks ?? [];
        _progress = 1.0;
      });

      final user = FirebaseAuth.instance.currentUser;

      // 🔹 Registro de analytics
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
        const SnackBar(
          content: Text("🎶 Playlist generada con éxito"),
        ),
      );
    } on SocketException {
      // 🔹 Future con handler (error de red / offline)
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Sin conexión a internet. Inténtalo de nuevo más tarde."),
          backgroundColor: Colors.redAccent,
        ),
      );
    } catch (e, st) {
      // 🔹 Future con handler genérico
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
      setState(() {
        _loading = false;
        // Si hubo error, dejas _progress como lo haya ido marcando el Stream
        // o lo puedes resetear:
        // _progress = _tracks.isEmpty ? 0.0 : 1.0;
      });
    }
  }


  Future<void> _askFeedback() async {
    double rating = 3; // valor por defecto

    await showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text("¿Qué tan bien refleja esta playlist tu estado de ánimo?"),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text("1 = nada que ver | 5 = totalmente mi estado"),
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
                        onChanged: (value) => setState(() => rating = value),
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
              onPressed: () {
                Navigator.pop(context, rating);
              },
              child: const Text("Enviar"),
            ),
          ],
        );
      },
    ).then((result) async {
      if (result != null) {
        // Guardar feedback en Firebase Analytics
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
        padding: const EdgeInsets.all(16.0),
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
              LinearProgressIndicator(
                value: _progress,
                color: Colors.deepPurpleAccent,
              ),
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

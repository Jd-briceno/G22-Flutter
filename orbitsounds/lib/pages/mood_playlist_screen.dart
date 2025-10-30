import 'package:flutter/material.dart';
import '../services/ares_playlist_generator_service.dart';
import '../models/track_model.dart';

class MoodPlaylistScreen extends StatefulWidget {
  const MoodPlaylistScreen({super.key});

  @override
  State<MoodPlaylistScreen> createState() => _MoodPlaylistScreenState();
}

class _MoodPlaylistScreenState extends State<MoodPlaylistScreen> {
  final AresPlaylistGeneratorService _generator = AresPlaylistGeneratorService();

  String _userInput = "";
  bool _loading = false;
  double _progress = 0.0;
  List<Track> _tracks = [];

  @override
  void initState() {
    super.initState();
    _generator.progressStream.listen((p) {
      setState(() => _progress = p);
    });
  }

  Future<void> _generatePlaylist() async {
    if (_userInput.trim().isEmpty) return;
    setState(() {
      _loading = true;
      _progress = 0;
      _tracks.clear();
    });

    // Llama al generador para crear una playlist basada en el estado emocional
    final playlist = await _generator.generateMoodBasedPlaylist(_userInput);

    setState(() {
      _tracks = playlist?.tracks ?? [];
      _loading = false;
      _progress = 1.0;
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
                  : ListView.builder(
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
          ],
        ),
      ),
    );
  }
}

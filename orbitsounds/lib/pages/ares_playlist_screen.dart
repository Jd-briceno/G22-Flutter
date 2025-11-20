import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:heroicons/heroicons.dart';
import '../models/track_model.dart';
import '../services/spotify_service.dart';

class AresPlaylistScreen extends StatefulWidget {
  final String title;
  final String description;
  final String coverUrl;
  final List<dynamic> tracks; // puede venir vacío o con ids/refs de Firestore
  final String? playlistId; // si guardaste el ID de Spotify en Firestore

  const AresPlaylistScreen({
    super.key,
    required this.title,
    required this.description,
    required this.coverUrl,
    required this.tracks,
    this.playlistId,
  });

  @override
  State<AresPlaylistScreen> createState() => _AresPlaylistScreenState();
}

class _AresPlaylistScreenState extends State<AresPlaylistScreen> {
  final SpotifyService _spotifyService = SpotifyService();
  bool _loading = true;
  List<Track> _tracks = [];
  Duration _totalDuration = Duration.zero;

  @override
  void initState() {
    super.initState();
    _loadTracks();
  }

  Future<void> _loadTracks() async {
    try {
      List<Track> fetched = [];

      // 1️⃣ Si la playlist viene con un ID real de Spotify
      if (widget.playlistId != null && widget.playlistId!.isNotEmpty) {
        fetched = await _spotifyService.getPlaylistTracks(widget.playlistId!);
      }

      // 2️⃣ Si viene con una lista de objetos (de Firestore)
      else if (widget.tracks.isNotEmpty &&
          widget.tracks.first is Map<String, dynamic>) {
        fetched = widget.tracks.map((t) {
          return Track(
            title: t['title'] ?? '',
            artist: t['artist'] ?? '',
            albumArt: t['albumArt'] ??
                widget.coverUrl, // usa la carátula del mix si no hay
            duration: _formatMsToDuration(t['durationMs']),
            durationMs: t['durationMs'] ?? 180000,
          );
        }).toList();
      }

      final totalMs = fetched.fold<int>(0, (sum, t) => sum + t.durationMs);
      setState(() {
        _tracks = fetched;
        _totalDuration = Duration(milliseconds: totalMs);
        _loading = false;
      });
    } catch (e) {
      debugPrint("⚠️ Error cargando tracks del mix: $e");
      setState(() => _loading = false);
    }
  }

  String _formatMsToDuration(int? ms) {
    if (ms == null) return "3:00";
    final d = Duration(milliseconds: ms);
    final min = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final sec = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return "$min:$sec";
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF010B19),
      body: Stack(
        children: [
          // 🌌 Fondo difuminado
          Positioned.fill(
            child: CachedNetworkImage(
              imageUrl: widget.coverUrl,
              fit: BoxFit.cover,
              errorWidget: (_, __, ___) =>
                  const Icon(Icons.music_note, color: Colors.white30),
            ),
          ),
          Container(color: Colors.black.withOpacity(0.8)),

          SafeArea(
            child: Column(
              children: [
                // 🔙 Barra superior
                Padding(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16.0, vertical: 8.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      IconButton(
                        onPressed: () => Navigator.pop(context),
                        icon: const HeroIcon(
                          HeroIcons.arrowLeftCircle,
                          color: Colors.white,
                          size: 38,
                        ),
                      ),
                      Text(
                        "ARES SMART MIX",
                        style: GoogleFonts.encodeSansExpanded(
                          color: Colors.white70,
                          fontSize: 14,
                          letterSpacing: 2,
                        ),
                      ),
                      const SizedBox(width: 38),
                    ],
                  ),
                ),

                // 🌠 Portada
                ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: CachedNetworkImage(
                    imageUrl: widget.coverUrl,
                    width: 180,
                    height: 180,
                    fit: BoxFit.cover,
                    placeholder: (_, __) => const Center(
                      child: CircularProgressIndicator(
                        color: Color(0xFFE9E8EE),
                        strokeWidth: 2,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                Text(
                  widget.title,
                  style: GoogleFonts.encodeSansExpanded(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 24,
                  ),
                ),
                const SizedBox(height: 8),

                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Text(
                    widget.description,
                    textAlign: TextAlign.center,
                    style: GoogleFonts.robotoMono(
                      color: Colors.white70,
                      fontSize: 13,
                    ),
                  ),
                ),

                const SizedBox(height: 16),

                // 🕓 Duración total
                if (!_loading && _tracks.isNotEmpty)
                  Text(
                    "Total duration: ${_formatTotal(_totalDuration)}",
                    style: GoogleFonts.robotoMono(
                      color: Colors.greenAccent,
                      fontSize: 12,
                    ),
                  ),

                const SizedBox(height: 16),

                // 🎧 Botones principales
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      ElevatedButton.icon(
                        onPressed: _tracks.isEmpty
                            ? null
                            : () {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text("🚀 Playing Ares Mix..."),
                                  ),
                                );
                              },
                        icon: const HeroIcon(
                          HeroIcons.playCircle,
                          color: Colors.white,
                          size: 22,
                        ),
                        label: Text(
                          "Play Mix",
                          style: GoogleFonts.encodeSansExpanded(
                            color: Colors.white,
                            fontSize: 14,
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFBD001B),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 20, vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(30),
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      OutlinedButton.icon(
                        onPressed: () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text("💾 Mix saved to your library"),
                            ),
                          );
                        },
                        icon: const HeroIcon(
                          HeroIcons.heart,
                          color: Color(0xFFBD001B),
                          size: 22,
                        ),
                        label: Text(
                          "Save",
                          style: GoogleFonts.encodeSansExpanded(
                            color: const Color(0xFFBD001B),
                            fontSize: 14,
                          ),
                        ),
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: Color(0xFFBD001B)),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 20, vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(30),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 16),

                // 🎶 Lista de canciones
                Expanded(
                  child: _loading
                      ? const Center(
                          child: CircularProgressIndicator(
                            color: Color(0xFFE9E8EE),
                          ),
                        )
                      : _tracks.isEmpty
                          ? Center(
                              child: Text(
                                "No songs found in this mix.",
                                style: GoogleFonts.robotoMono(
                                  color: Colors.white70,
                                  fontSize: 13,
                                ),
                              ),
                            )
                          : ListView.builder(
                              itemCount: _tracks.length,
                              itemBuilder: (context, index) {
                                final t = _tracks[index];
                                return ListTile(
                                  leading: ClipRRect(
                                    borderRadius: BorderRadius.circular(8),
                                    child: CachedNetworkImage(
                                      imageUrl: t.albumArt,
                                      width: 55,
                                      height: 55,
                                      fit: BoxFit.cover,
                                      errorWidget: (_, __, ___) => Container(
                                        width: 55,
                                        height: 55,
                                        color: Colors.white10,
                                        child: const Icon(Icons.music_note,
                                            color: Colors.white54),
                                      ),
                                    ),
                                  ),
                                  title: Text(
                                    t.title,
                                    style: GoogleFonts.encodeSansExpanded(
                                      color: Colors.white,
                                      fontSize: 15,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                  subtitle: Text(
                                    t.artist,
                                    style: GoogleFonts.robotoMono(
                                      color: Colors.white70,
                                      fontSize: 12,
                                    ),
                                  ),
                                  trailing: Text(
                                    t.duration,
                                    style: GoogleFonts.robotoMono(
                                      color: Colors.white54,
                                      fontSize: 12,
                                    ),
                                  ),
                                );
                              },
                            ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _formatTotal(Duration d) {
    final m = d.inMinutes;
    final s = d.inSeconds.remainder(60);
    return "${m}m ${s}s";
  }
}

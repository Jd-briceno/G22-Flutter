import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:heroicons/heroicons.dart';
import '../models/track_model.dart';
import '../services/spotify_service.dart';
import '../services/hive_service.dart';

class AresPlaylistScreen extends StatefulWidget {
  final String title;
  final String description;
  final String coverUrl;
  final List<dynamic> tracks;
  final String? playlistId;

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

  final String _cacheKey = "ares_mix";

  @override
  void initState() {
    super.initState();
    _loadInitialTracks(); // <<--- cambio CLAVE
  }

  Future<bool> hasInternetConnection() async {
    try {
      final result = await InternetAddress.lookup('example.com');
      return result.isNotEmpty && result[0].rawAddress.isNotEmpty;
    } catch (_) {
      return false;
    }
  }

  // 🚀 Nuevo: decide si cargar cache o llamar a _loadTracks()
  Future<void> _loadInitialTracks() async {
    final bool online = await hasInternetConnection();

    if (!online) {
      debugPrint("📴 No internet. Loading cached playlist...");
      final cached = HiveService.getLastAresMix(_cacheKey);

      if (cached != null && cached.isNotEmpty) {
        final fetched = cached
            .map((m) => Track.fromMap(Map<String, dynamic>.from(m)))
            .toList();

        final totalMs = fetched.fold<int>(0, (sum, t) => sum + t.durationMs);

        setState(() {
          _tracks = fetched;
          _totalDuration = Duration(milliseconds: totalMs);
          _loading = false;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("📴 Offline mode: loaded last saved Ares Mix."),
            backgroundColor: Colors.orangeAccent,
          ),
        );

        return;
      }

      setState(() => _loading = false);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("❌ No connection and no cached Ares Mix available"),
          backgroundColor: Colors.redAccent,
        ),
      );

      return;
    }

    // Si hay internet → carga normal
    _loadTracks();
  }

  // 🔥 Solo se ejecuta cuando sí hay internet
  Future<void> _loadTracks() async {
    List<Track> fetched = [];
    bool success = false;

    try {
      if (widget.playlistId != null && widget.playlistId!.isNotEmpty) {
        fetched = await _spotifyService.getPlaylistTracks(widget.playlistId!);
        success = fetched.isNotEmpty;
      } else if (widget.tracks.isNotEmpty &&
          widget.tracks.first is Map<String, dynamic>) {
        fetched = widget.tracks.map((t) {
          return Track(
            title: t['title'] ?? '',
            artist: t['artist'] ?? '',
            albumArt: t['albumArt'] ?? widget.coverUrl,
            duration: _formatMsToDuration(t['durationMs']),
            durationMs: t['durationMs'] ?? 180000,
          );
        }).toList();
        success = fetched.isNotEmpty;
      }

      if (success) {
        await HiveService.saveLastAresMix(
          _cacheKey,
          fetched.map((t) => t.toMap()).toList(),
        );
      } else {
        throw Exception("Empty playlist");
      }
    } catch (e) {
      debugPrint("❌ Error loading mix online: $e");

      final cached = HiveService.getLastAresMix(_cacheKey);
      if (cached != null && cached.isNotEmpty) {
        fetched = cached
            .map((m) => Track.fromMap(Map<String, dynamic>.from(m)))
            .toList();

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("⚠️ Online failed. Loaded cached mix."),
            backgroundColor: Colors.orangeAccent,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("❌ No mix available"),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    }

    final totalMs = fetched.fold<int>(0, (sum, t) => sum + t.durationMs);

    setState(() {
      _tracks = fetched;
      _totalDuration = Duration(milliseconds: totalMs);
      _loading = false;
    });
  }

  String _formatMsToDuration(int? ms) {
    if (ms == null) return "3:00";
    final d = Duration(milliseconds: ms);
    final min = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final sec = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return "$min:$sec";
  }

  String _formatTotal(Duration d) {
    final m = d.inMinutes;
    final s = d.inSeconds.remainder(60);
    return "${m}m ${s}s";
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF010B19),
      body: Stack(
        children: [
          Positioned.fill(
            child: CachedNetworkImage(
              imageUrl: widget.coverUrl,
              fit: BoxFit.cover,
              errorWidget: (_, __, ___) => Image.asset(
                "assets/images/default_mix.jpg",
                fit: BoxFit.cover,
              ),
            ),
          ),
          Container(color: Colors.black.withOpacity(0.8)),

          SafeArea(
            child: Column(
              children: [
                // === HEADER ===
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
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
                          letterSpacing: 2,
                        ),
                      ),
                      const SizedBox(width: 38),
                    ],
                  ),
                ),

                // === COVER ===
                ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: CachedNetworkImage(
                    imageUrl: widget.coverUrl,
                    width: 180,
                    height: 180,
                    fit: BoxFit.cover,
                    errorWidget: (_, __, ___) => Image.asset(
                      "assets/images/default_mix.jpg",
                      width: 180,
                      height: 180,
                      fit: BoxFit.cover,
                    ),
                  ),
                ),

                const SizedBox(height: 16),

                Text(
                  widget.title,
                  style: GoogleFonts.encodeSansExpanded(
                    fontSize: 24,
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
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

                if (!_loading && _tracks.isNotEmpty)
                  Text(
                    "Total duration: ${_formatTotal(_totalDuration)}",
                    style: GoogleFonts.robotoMono(
                      color: Colors.greenAccent,
                      fontSize: 12,
                    ),
                  ),

                const SizedBox(height: 16),

                Expanded(
                  child: _loading
                      ? const Center(
                          child: CircularProgressIndicator(color: Color(0xFFE9E8EE)),
                        )
                      : _tracks.isEmpty
                          ? Center(
                              child: Text(
                                "No songs found.",
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
          )
        ],
      ),
    );
  }
}

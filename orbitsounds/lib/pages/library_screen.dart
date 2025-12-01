import 'dart:async';
import 'dart:io';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:melodymuse/cache/ares_playlist_cache.dart';
import 'package:melodymuse/components/vinyl_cover.dart';
import 'package:melodymuse/models/playlist_model.dart';
import 'package:melodymuse/pages/ares_recommendations_screen.dart';
import 'package:melodymuse/pages/ares_playlist_screen.dart';
import '../components/search_bar.dart';
import '../components/navbar.dart';
import '../models/track_model.dart';
import '../services/spotify_service.dart';
import '../services/ares_service.dart';
import 'package:heroicons/heroicons.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cached_network_image/cached_network_image.dart';

class LibraryScreen extends StatefulWidget {
  const LibraryScreen({super.key});

  @override
  State<LibraryScreen> createState() => _LibraryScreenState();
}

class _LibraryScreenState extends State<LibraryScreen>
    with AutomaticKeepAliveClientMixin {
  final SpotifyService _spotifyService = SpotifyService();
  final AresService _ares = AresService();

  bool _loadingAresMixes = false;
  List<Map<String, dynamic>> _aresPlaylists = [];

  final StreamController<List<Track>> _searchStream =
      StreamController<List<Track>>.broadcast();

  bool _loading = false;

  // 🎨 Estilos centralizados
  static final TextStyle _sectionTitleStyle = GoogleFonts.encodeSansExpanded(
    color: const Color(0XFFE9E8EE),
    fontSize: 20,
    fontWeight: FontWeight.bold,
  );

  static final TextStyle _playlistTitleStyle = GoogleFonts.robotoMono(
    color: const Color(0XFFE9E8EE),
    fontSize: 13,
    fontWeight: FontWeight.w500,
  );

  static final TextStyle _songTextStyle = GoogleFonts.robotoMono(
    color: const Color(0XFFE9E8EE),
    fontSize: 12,
  );

  final _djRecommendations = const [
    {"title": "Hunting soul", "cover": "assets/images/Hunting.jpg"},
    {"title": "Ruined King", "cover": "assets/images/Ruined.jpg"},
  ];

  final _friendsPlaylists = const [
    {"title": "I Believe", "cover": "assets/images/UFO.jpg"},
    {"title": "Indie Dreams", "cover": "assets/images/Indie.jpg"},
  ];

  final _myPlaylists = const [
    {"title": "Roll a d20", "cover": "assets/images/Dungeons.jpg"},
    {"title": "Good Vibes", "cover": "assets/images/Good.jpg"},
    {
      "title": "Jazz Nights",
      "cover":
          "https://i.scdn.co/image/ab67616d0000b27333a4c2bd3a4a5edcabcdef123"
    },
  ];

  final _recommendedPlaylists = const [
    {"title": "Lofi", "cover": "assets/images/Lofi.jpg"},
    {"title": "Study", "cover": "assets/images/Study.jpg"},
    {
      "title": "Jazz Nights",
      "cover":
          "https://i.scdn.co/image/ab67616d0000b27333a4c2bd3a4a5edcabcdef123"
    },
  ];

  @override
  void initState() {
    super.initState();
    _logLibraryOpened();
    _loadAresPlaylists();
  }

  Future<void> _logLibraryOpened() async {
    final user = FirebaseAuth.instance.currentUser;

    await FirebaseAnalytics.instance.logEvent(
      name: 'library_opened',
      parameters: {
        'user_id': ?user?.uid,
        'timestamp': DateTime.now().toIso8601String(),
      },
    );
  }

  Future<void> _loadAresPlaylists() async {
    setState(() => _loadingAresMixes = true);
    try {
      final mixes = await _ares.generateSmartMixesFromFirestore();
      setState(() => _aresPlaylists = mixes);

      // NUEVO → guardar cada playlist en el LRU
      for (var mix in mixes) {
        final playlist = Playlist(
          id: mix['id'] ?? DateTime.now().millisecondsSinceEpoch.toString(),
          title: mix['title'] ?? 'Untitled',
          description: mix['description'] ?? '',
          coverUrl: mix['coverUrl'] ?? '',
          tracks: (mix['tracks'] as List<dynamic>? ?? [])
              .map((t) => Track.fromMap(Map<String, dynamic>.from(t)))
              .toList(),
        );

        await AresPlaylistCache.save(playlist);
      }
    } catch (e) {
      debugPrint("⚠️ Error generando Smart Mixes: $e");
    } finally {
      setState(() => _loadingAresMixes = false);
    }
  }

  Future<void> _searchSongs(String query) async {
    if (query.isEmpty) return;
    _searchStream.add([]);
    setState(() => _loading = true);

    try {
      final results = await _spotifyService.searchTracks(query);
      _searchStream.add(results);
    } catch (e) {
      debugPrint("❌ Error buscando canciones: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Error buscando canciones")),
      );
    } finally {
      setState(() => _loading = false);
    }
  }

  Future<bool> _hasInternetConnection() async {
    try {
      final result = await InternetAddress.lookup('example.com');
      return result.isNotEmpty && result[0].rawAddress.isNotEmpty;
    } catch (_) {
      return false;
    }
  }

  @override
  void dispose() {
    _searchStream.close();
    super.dispose();
  }

  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);

    return Scaffold(
      backgroundColor: const Color(0xFF010B19),
      body: CustomScrollView(
        physics: Theme.of(context).platform == TargetPlatform.iOS
            ? const BouncingScrollPhysics()
            : const ClampingScrollPhysics(),
        slivers: [
          const SliverToBoxAdapter(child: SizedBox(height: 40)),
          const SliverToBoxAdapter(
            child: Navbar(
              username: "Jay Walker",
              title: "Lightning Ninja",
              profileImage: "assets/images/Jay.jpg",
              subtitle: "Vinyl Library",
            ),
          ),
          const SliverToBoxAdapter(child: SizedBox(height: 2)),

          // 🔎 Búsqueda
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            sliver: SliverToBoxAdapter(
              child: SearchBarCustom(onSearch: _searchSongs),
            ),
          ),
          const SliverToBoxAdapter(child: SizedBox(height: 5)),

          // 🎵 Resultados
          StreamBuilder<List<Track>>(
            stream: _searchStream.stream,
            builder: (context, snapshot) {
              if (_loading) {
                return const SliverToBoxAdapter(
                  child: Center(
                    child: Padding(
                      padding: EdgeInsets.all(20.0),
                      child: CircularProgressIndicator(color: Color(0XFFE9E8EE)),
                    ),
                  ),
                );
              }

              final songs = snapshot.data ?? [];
              if (songs.isEmpty) return const SliverToBoxAdapter(child: SizedBox());

              return SliverToBoxAdapter(
                child: SizedBox(
                  height: 180,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    physics: const BouncingScrollPhysics(),
                    cacheExtent: 500,
                    itemCount: songs.length,
                    itemBuilder: (_, i) => _SongResultCard(song: songs[i]),
                  ),
                ),
              );
            },
          ),

          // 💫 Smart Mixes de Ares
          if (_loadingAresMixes)
          const SliverToBoxAdapter(
            child: Center(
              child: Padding(
                padding: EdgeInsets.all(20),
                child: CircularProgressIndicator(color: Color(0xFFE9E8EE)),
              ),
            ),
          )
        else if (_aresPlaylists.isNotEmpty)
          _AresPlaylistSection(playlists: _aresPlaylists)
        else
          FutureBuilder<bool>(
            future: _hasInternetConnection(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const SliverToBoxAdapter(child: SizedBox());
              }
              if (snapshot.data == false) {
                return const CachedMixesSection(); // 👉 Sin internet, mostrar cache
              }
              return const SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.all(16.0),
                  child: Text(
                    "⚠️ No mixes available and failed to load new ones.",
                    style: TextStyle(color: Colors.white),
                  ),
                ),
              );
            },
          ),


          // 📀 Playlists manuales
          _PlaylistSection(title: "✨ Starlight Suggestions", playlists: _myPlaylists),
          _PlaylistSection(title: "🎧 DJ Nova’s Set", playlists: _recommendedPlaylists),
          _PlaylistSection(title: "💖 Eternal Hits", playlists: _djRecommendations),
          _PlaylistSection(title: "🎧 Orbit Crew Playlist", playlists: _friendsPlaylists),

          const SliverToBoxAdapter(child: SizedBox(height: 50)),
        ],
      ),
    );
  }
}

String _formatMsToDuration(dynamic ms) {
  if (ms == null) return "3:00";
  final d = Duration(milliseconds: ms is int ? ms : int.tryParse(ms.toString()) ?? 180000);
  final min = d.inMinutes.remainder(60).toString().padLeft(2, '0');
  final sec = d.inSeconds.remainder(60).toString().padLeft(2, '0');
  return "$min:$sec";
}


/// 💫 Sección Ares Smart Mixes
class _AresPlaylistSection extends StatelessWidget {
  final List<Map<String, dynamic>> playlists;
  const _AresPlaylistSection({required this.playlists});

  @override
  Widget build(BuildContext context) {
    final titleStyle = _LibraryScreenState._sectionTitleStyle;
    final playlistTitleStyle = _LibraryScreenState._playlistTitleStyle;

    return SliverToBoxAdapter(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            child: Text("💫 Ares Smart Mixes", style: titleStyle),
          ),
          SizedBox(
            height: 180,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              physics: const BouncingScrollPhysics(),
              itemCount: playlists.length,
              itemBuilder: (context, index) {
                final mix = playlists[index];
                final title = mix["title"] ?? "Untitled Mix";
                final desc = mix["description"] ?? "";
                final tracks = (mix["tracks"] as List<dynamic>? ?? []);
                final coverUrl = (tracks.isNotEmpty && tracks.first["albumArt"] != "")
                ? tracks.first["albumArt"]
                : _coverForMix(title);

                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8.0),
                  child: GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => AresPlaylistScreen(
                            title: title,
                            description: desc,
                            tracks: tracks,
                            coverUrl: coverUrl,
                          ),
                        ),
                      );
                    },
                    child: Column(
                      children: [
                        SafeCoverImage(imageUrl: coverUrl),
                        const SizedBox(height: 6),
                        SizedBox(
                          width: 120,
                          child: Text(
                            title,
                            style: playlistTitleStyle,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  static String _coverForMix(String title) {
    title = title.toLowerCase();
    if (title.contains("rebirth")) return "assets/images/Rebirth.jpg";
    if (title.contains("reflection")) return "assets/images/Reflection.jpg";
    if (title.contains("energy")) return "assets/images/Energy.jpg";
    return "assets/images/DefaultMix.jpg";
  }
}

/// 🎶 Card resultado
class _SongResultCard extends StatelessWidget {
  final Track song;
  const _SongResultCard({required this.song});

  @override
  Widget build(BuildContext context) {
    final textStyle = _LibraryScreenState._songTextStyle;
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Column(
        children: [
          RepaintBoundary(child: VinylWithCover(albumArt: song.albumArt)),
          const SizedBox(height: 6),
          SizedBox(
            width: 100,
            child: Text(
              "${song.title}\n${song.artist}",
              style: textStyle,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }
}

/// 📂 Playlists normales
class _PlaylistSection extends StatelessWidget {
  final String title;
  final List<Map<String, String>> playlists;
  const _PlaylistSection({required this.title, required this.playlists});

  @override
  Widget build(BuildContext context) {
    final titleStyle = _LibraryScreenState._sectionTitleStyle;
    final playlistTitleStyle = _LibraryScreenState._playlistTitleStyle;

    return SliverToBoxAdapter(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            child: Text(title, style: titleStyle),
          ),
          SizedBox(
            height: 160,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              cacheExtent: 500,
              itemCount: playlists.length,
              itemBuilder: (context, index) {
                final playlist = playlists[index];
                final cover = playlist["cover"]!;
                return Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Column(
                    children: [
                      cover.startsWith("http")
                          ? SizedBox(
                              width: 100,
                              height: 100,
                              child: CachedNetworkImage(
                                imageUrl: cover,
                                placeholder: (_, __) => const Center(
                                  child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Color(0XFFE9E8EE)),
                                ),
                                errorWidget: (_, __, ___) =>
                                    const Icon(Icons.error, color: Colors.red),
                                fit: BoxFit.cover,
                              ),
                            )
                          : RepaintBoundary(
                              child: VinylWithCover(albumArt: cover),
                            ),
                      const SizedBox(height: 5),
                      SizedBox(
                        width: 100,
                        child: Text(
                          playlist["title"]!,
                          style: playlistTitleStyle,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class CachedMixesSection extends StatelessWidget {
  const CachedMixesSection({super.key});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<Playlist>>(
      future: AresPlaylistCache.getAll(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const SliverToBoxAdapter(
            child: Center(child: CircularProgressIndicator()),
          );
        }

        final mixes = snapshot.data ?? [];
        if (mixes.isEmpty) {
          return const SliverToBoxAdapter(child: SizedBox());
        }

        return SliverToBoxAdapter(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                child: Text(
                  "🗂️ Offline Smart Mixes",
                  style: _LibraryScreenState._sectionTitleStyle,
                ),
              ),
              SizedBox(
                height: 180,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: mixes.length,
                  itemBuilder: (context, index) {
                    final mix = mixes[index];
                    final cover = mix.coverUrl.isNotEmpty
                        ? mix.coverUrl
                        : "assets/images/default_mix.jpg";

                    return Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8.0),
                      child: GestureDetector(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => AresPlaylistScreen(
                                title: mix.title,
                                description: mix.description,
                                coverUrl: cover,
                                tracks: mix.tracks.map((t) => t.toMap()).toList(),
                              ),
                            ),
                          );
                        },
                        child: Column(
                          children: [
                            SafeCoverImage(imageUrl: cover),
                            const SizedBox(height: 6),
                            SizedBox(
                              width: 120,
                              child: Text(
                                mix.title,
                                style: _LibraryScreenState._playlistTitleStyle,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                textAlign: TextAlign.center,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class SafeCoverImage extends StatelessWidget {
  final String imageUrl;
  final double size;

  const SafeCoverImage({
    required this.imageUrl,
    this.size = 120,
    super.key,
  });

  bool get _isNetwork => imageUrl.startsWith("http");

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: _isNetwork
          ? CachedNetworkImage(
              imageUrl: imageUrl,
              width: size,
              height: size,
              fit: BoxFit.cover,
              placeholder: (_, __) => const Center(
                child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFFE9E8EE)),
              ),
              errorWidget: (_, __, ___) => const Icon(Icons.music_note, color: Colors.white),
            )
          : Image.asset(
              imageUrl,
              width: size,
              height: size,
              fit: BoxFit.cover,
            ),
    );
  }
}



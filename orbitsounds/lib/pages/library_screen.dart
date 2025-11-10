import 'dart:async';
import 'package:flutter/material.dart';
import 'package:orbitsounds/components/vinyl_cover.dart';
import 'package:orbitsounds/pages/ares_recommendations_screen.dart';
import '../components/search_bar.dart';
import '../components/navbar.dart';
import '../models/track_model.dart';
import '../services/spotify_service.dart';
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

  /// 🔹 StreamController para resultados de búsqueda (permite actualizaciones reactivas)
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

  /// 🔍 Búsqueda de canciones (usa Future + handler + async/await + Stream)
  Future<void> _searchSongs(String query) async {
    if (query.isEmpty) return;
    _searchStream.add([]); // limpiar resultados previos
    setState(() => _loading = true);

    try {
      // 🔹 Future con async/await
      final results = await _spotifyService.searchTracks(query);
      // 🔹 Enviamos los resultados al Stream
      _searchStream.add(results);
    } catch (e) {
      // 🔹 Handler de error
      debugPrint("❌ Error buscando canciones: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Error buscando canciones")),
      );
    } finally {
      setState(() => _loading = false);
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

          // 🔎 Barra de búsqueda
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            sliver: SliverToBoxAdapter(
              child: SearchBarCustom(onSearch: _searchSongs),
            ),
          ),

          const SliverToBoxAdapter(child: SizedBox(height: 5)),

          // 🎶 Resultados de búsqueda usando StreamBuilder
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

          // 📂 Library Header
          SliverToBoxAdapter(
            child: Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text("Library", style: _sectionTitleStyle),
                  Row(
                    children: [
                      IconButton(
                        onPressed: () async {
                          final newPlaylist = await Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => AresRecommendationsScreen(),
                            ),
                          );
                          if (newPlaylist != null) {
                            debugPrint("Nueva playlist creada: ${newPlaylist.title}");
                          }
                        },
                        icon: const HeroIcon(
                          HeroIcons.plusCircle,
                          color: Color(0XFFE9E8EE),
                          size: 28,
                        ),
                      ),
                      const HeroIcon(
                        HeroIcons.ellipsisVertical,
                        color: Color(0XFFE9E8EE),
                        size: 28,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),

          // 📂 Secciones de playlists
          _PlaylistSection(
              title: "✨ Starlight Suggestions", playlists: _myPlaylists),
          _PlaylistSection(
              title: "🎧 DJ Nova’s Set", playlists: _recommendedPlaylists),
          _PlaylistSection(
              title: "💖 Eternal Hits", playlists: _djRecommendations),
          _PlaylistSection(
              title: "🎧 Orbit Crew Playlist", playlists: _friendsPlaylists),

          const SliverToBoxAdapter(child: SizedBox(height: 50)),
        ],
      ),
    );
  }
}

/// 🎶 Card de resultados
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

/// 📂 Sección de playlists
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
            padding:
                const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
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
                                      strokeWidth: 2, color: Color(0XFFE9E8EE)),
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

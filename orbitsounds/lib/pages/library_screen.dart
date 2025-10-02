import 'package:flutter/material.dart';
import 'package:melodymuse/components/vinyl_cover.dart';
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
  List<Track> _songs = [];
  bool _loading = false;

  // 🎨 Estilos centralizados (reusables)
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

  /// Simulación de playlists
  final _djRecommendations = const [
    {
      "title": "Hunting soul",
      "cover":
          "assets/images/Hunting.jpg"
    },
    {
      "title": "Ruined King",
      "cover":
          "assets/images/Ruined.jpg"
    },
  ];

  final _friendsPlaylists = const [
    {
      "title": "I Believe",
      "cover":
          "assets/images/UFO.jpg"
    },
    {
      "title": "Indie Dreams",
      "cover":
          "assets/images/Indie.jpg"
    },
  ];

  final _myPlaylists = const [
    {"title": "Roll a d20", "cover": "assets/images/Dungeons.jpg"},
    {
      "title": "Good Vibes",
      "cover":
          "assets/images/Good.jpg"
    },
    {
      "title": "Jazz Nights",
      "cover":
          "https://i.scdn.co/image/ab67616d0000b27333a4c2bd3a4a5edcabcdef123"
    },
  ];

  final _recommendedPlaylists = const [
    {"title": "Lofi", "cover": "assets/images/Lofi.jpg"},
    {
      "title": "Study",
      "cover":
          "assets/images/Study.jpg"
    },
    {
      "title": "Jazz Nights",
      "cover":
          "https://i.scdn.co/image/ab67616d0000b27333a4c2bd3a4a5edcabcdef123"
    },
  ];

  Future<void> _searchSongs(String query) async {
    if (query.isEmpty) return;
    setState(() => _loading = true);

    final results = await _spotifyService.searchTracks(query);

    setState(() {
      _songs = results;
      _loading = false;
    });
  }

  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context); // necesario por AutomaticKeepAliveClientMixin

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

          // 🎶 Resultados búsqueda
          if (_loading)
            const SliverToBoxAdapter(
              child: Center(
                child: Padding(
                  padding: EdgeInsets.all(20.0),
                  child: CircularProgressIndicator(color: Color(0XFFE9E8EE)),
                ),
              ),
            )
          else if (_songs.isNotEmpty)
            SliverToBoxAdapter(
              child: SizedBox(
                height: 180,
                child: ListView.builder(
                  physics: const BouncingScrollPhysics(),
                  scrollDirection: Axis.horizontal,
                  addRepaintBoundaries: true,
                  itemCount: _songs.length,
                  itemBuilder: (context, index) {
                    final song = _songs[index];
                    return _SongResultCard(song: song);
                  },
                ),
              ),
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
                        onPressed: () {},
                        icon: const HeroIcon(
                          HeroIcons.plusCircle,
                          color: Color(0XFFE9E8EE),
                          size: 28,
                        ),
                      ),
                      IconButton(
                        onPressed: () {},
                        icon: const HeroIcon(
                          HeroIcons.ellipsisVertical,
                          color: Color(0XFFE9E8EE),
                          size: 28,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),

          // 📂 Secciones
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

/// 🎶 Card para resultados de canciones
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
          VinylWithCover(albumArt: song.albumArt, isSpinning: false),
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

/// 📂 Sección de playlists (horizontal scroll)
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
              physics: const BouncingScrollPhysics(),
              scrollDirection: Axis.horizontal,
              addRepaintBoundaries: true,
              itemCount: playlists.length,
              itemBuilder: (context, index) {
                final playlist = playlists[index];
                final cover = playlist["cover"]!;

                return Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Column(
                    children: [
                      // ✅ Usa CachedNetworkImage solo si es URL
                      cover.startsWith("http")
                          ? SizedBox(
                              width: 100,
                              height: 100,
                              child: CachedNetworkImage(
                                imageUrl: cover,
                                placeholder: (_, __) => const Center(
                                    child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        color: Color(0XFFE9E8EE))),
                                errorWidget: (_, __, ___) =>
                                    const Icon(Icons.error, color: Colors.red),
                                fit: BoxFit.cover,
                              ),
                            )
                          : VinylWithCover(albumArt: cover, isSpinning: false),
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

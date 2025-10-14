import 'package:flutter/material.dart';
import 'package:melodymuse/pages/music_detail_screen.dart';
import '../models/track_model.dart';
import '../services/spotify_service.dart';
import '../services/openai_service.dart';
import '../components/track_tile.dart';
import 'package:heroicons/heroicons.dart';
import 'package:firebase_analytics/firebase_analytics.dart';


class PlaylistScreen extends StatefulWidget {
  final String genre;
  final List<Color> colors;
  final String fontFamily;
  final DateTime? startTime; // 👈 NUEVO

  const PlaylistScreen({
    super.key,
    required this.genre,
    required this.colors,
    required this.fontFamily,
    this.startTime, // 👈 OPCIONAL
  });

  @override
  State<PlaylistScreen> createState() => _PlaylistScreenState();
}

class _PlaylistScreenState extends State<PlaylistScreen>
    with SingleTickerProviderStateMixin {
  int? nowPlayingIndex;
  late AnimationController _waveController;
  final FirebaseAnalytics _analytics = FirebaseAnalytics.instance;

  final SpotifyService _spotifyService = SpotifyService();
  final OpenAIService _openAIService = OpenAIService();

  List<Track> tracks = [];
  bool isLoading = true;
  Duration totalDuration = Duration.zero;

  String? aiDescription;
  bool isLiked = false; // ❤️ estado del botón Like

  final Map<String, String> _playlistNames = {
    "Pop": "Pop Vibes",
    "Rock": "Rock Legends",
    "Jazz": "Smooth Jazz Nights",
    "Classical": "Timeless Classics",
    "EDM": "Electronic Beats",
    "Heavy Metal": "Metal Mayhem",
    "K-Pop": "K-Pop Fever",
    "J-Rock": "Japanese Rock Power",
    "Punk": "Rebel Riffs",
    "Medieval": "Ancient Echoes",
    "Anisong":"TO BE HERO X",
    "Rap":"Godzilla",
    "Musical":"Legendary"
  };

  final Map<String, String> _playlistCovers = {
    "Pop": "assets/images/pop.jpg",
    "Rock": "assets/images/rock.jpg",
    "Jazz": "assets/images/jazz.jpg",
    "Classical": "assets/images/classical.jpg",
    "EDM": "assets/images/edm.jpg",
    "Heavy Metal": "assets/images/metal.jpg",
    "K-Pop": "assets/images/kpop.jpg",
    "J-Rock": "assets/images/Kamui.jpg",
    "Punk": "assets/images/Hobbie.jpg",
    "Medieval": "assets/images/Dungeons.jpg",
    "Rap": "assets/images/Rap.jpg",
    "Anisong": "assets/images/Anisong.jpg",
    "Musical": "assets/images/Musical.jpg",
  };

  final Map<String, Color> _genreColors = {
    "Punk": Colors.red,
    "K-Pop": Colors.purple,
    "J-Rock": Colors.redAccent,
    "Pop": Colors.pinkAccent,
    "Jazz": Colors.green,
    "Rock": Colors.orange,
    "Classical": Colors.amber,
    "Heavy Metal": Colors.grey,
    "EDM": Colors.blueAccent,
    "Medieval": Colors.amber,
    "Rap":Colors.green,
    "Anisong":Colors.lightBlueAccent,
    "Musical":Colors.amber,
  };

  final Map<String, String> _fallbackDescriptions = {
    "Pop": "Bright, catchy beats that keep your mood high and your feet moving.",
    "Rock": "Raw energy, powerful riffs, and timeless anthems that never fade.",
    "Jazz": "Smooth improvisations and soulful melodies for late-night vibes.",
    "Classical": "Timeless masterpieces that bring elegance and serenity.",
    "EDM": "Pulsating rhythms and drops that electrify the dance floor.",
    "Heavy Metal": "Thundering drums and screaming guitars for headbanging chaos.",
    "K-Pop": "Colorful hooks, addictive choruses, and global pop magic.",
    "J-Rock": "Dynamic sounds from Japan’s rock scene with fiery intensity.",
    "Punk": "Fast, rebellious riffs with a raw and unapologetic spirit.",
    "Medieval": "Echoes of ancient halls, lutes, and chants from another era.",
    "Rap":"Hard-hitting beats, lyrical flow, and street-born stories with raw attitude.",
    "Anisong":"Epic melodies and emotional power, straight from anime worlds of heroes and dreams."
  };

  @override
  void initState() {
    super.initState();
    _waveController =
        AnimationController(vsync: this, duration: const Duration(seconds: 2))
          ..repeat();

    _loadTracks();
    _loadAIDescription();
  }

  Future<void> _loadTracks() async {
    final playlists = await _spotifyService.getGenrePlaylists(widget.genre);
    if (playlists.isEmpty) {
      setState(() => isLoading = false);
      return;
    }

    final playlistId = playlists.first['id'];
    final fetchedTracks = await _spotifyService.getPlaylistTracks(playlistId);

    final durationMs = fetchedTracks.fold<int>(
      0,
      (sum, track) => sum + track.durationMs,
    );

    setState(() {
      tracks = fetchedTracks;
      totalDuration = Duration(milliseconds: durationMs);
      isLoading = false;
    });

    // 👇👇👇 AGREGA ESTO AQUÍ 👇👇👇
    if (widget.startTime != null) {
      final endTime = DateTime.now();
      final loadTime = endTime.difference(widget.startTime!).inMilliseconds;
      final withinTarget = loadTime <= 8000;

      await _analytics.logEvent(
        name: 'playlist_loaded',
        parameters: {
          'genre': widget.genre,
          'load_time_ms': loadTime,
          'within_target': withinTarget ? 'true' : 'false', // ✅ string
          'timestamp': widget.startTime!.toIso8601String(),
        },
      );

      debugPrint("📊 Playlist loaded → genre=${widget.genre}, loadTime=${loadTime}ms, withinTarget=$withinTarget");
    }
  }


  Future<void> _loadAIDescription() async {
    try {
      final response =
          await _openAIService.generatePlaylistDescription(widget.genre);
      setState(() => aiDescription = response.content);
    } catch (e) {
      setState(() {
        aiDescription =
            _fallbackDescriptions[widget.genre] ?? "Enjoy the best of ${widget.genre} 🎶.";
      });
    }
  }

  String _formatDuration(Duration d) {
    final hours = d.inHours;
    final minutes = d.inMinutes.remainder(60);
    return hours > 0 ? "$hours h $minutes min" : "$minutes min";
  }

  Widget _buildCoverImage(String path) {
    if (path.startsWith("assets/")) {
      return Image.asset(path, fit: BoxFit.cover);
    } else {
      return Image.network(path, fit: BoxFit.cover);
    }
  }

  @override
  void dispose() {
    _waveController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final playlistName =
        _playlistNames[widget.genre] ?? "${widget.genre} Playlist";
    final coverImage = _playlistCovers[widget.genre] ?? "";
    final equalizerColor = _genreColors[widget.genre] ?? Colors.redAccent;

    return Scaffold(
      backgroundColor: const Color(0XFF010B19),
      body: Stack(
        children: [
          if (coverImage.isNotEmpty)
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              height: 381,
              child: Opacity(
                opacity: 0.35,
                child: _buildCoverImage(coverImage),
              ),
            ),

          Positioned(
            top: 40,
            left: 16,
            child: IconButton(
              icon: const HeroIcon(
                HeroIcons.arrowLeftCircle,
                style: HeroIconStyle.outline,
                color: Colors.white,
                size: 50,
              ),
              onPressed: () {
                if (Navigator.of(context).canPop()) {
                  Navigator.of(context).pop();
                }
              },
            ),
          ),

          if (isLoading)
            const Center(
              child: CircularProgressIndicator(color: Colors.greenAccent),
            ),

          if (!isLoading && tracks.isNotEmpty) ...[
            Positioned(
              top: 260,
              right: 24,
              child: _buildPlayButton(),
            ),

            Positioned.fill(
              top: 310,
              child: SingleChildScrollView(
                padding:
                    const EdgeInsets.symmetric(horizontal: 6, vertical: 24),
                child: Column(
                  children: [
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(10),
                        gradient: LinearGradient(
                          begin: Alignment.topRight,
                          end: Alignment.bottomLeft,
                          colors: widget.colors,
                        ),
                        border: Border.all(color: Colors.white70, width: 1),
                        color: Colors.black.withOpacity(0.8),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            playlistName,
                            style: TextStyle(
                              fontFamily: widget.fontFamily,
                              fontSize: widget.genre == "Pop" ? 44 : 34,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          SizedBox(height: widget.genre == "Pop" ? 2 : 12),
                          Text(
                            aiDescription ?? "Loading description...",
                            style: const TextStyle(
                              fontSize: 16,
                              color: Colors.white70,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            "Total Duration: ${_formatDuration(totalDuration)}",
                            style: const TextStyle(
                              fontSize: 14,
                              fontStyle: FontStyle.italic,
                              color: Colors.greenAccent,
                            ),
                          ),
                          const SizedBox(height: 12),

                          /// 🎛️ Action Buttons con HeroIcons
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              _actionButton(
                                const HeroIcon(
                                  HeroIcons.arrowsRightLeft,
                                  color: Colors.white,
                                  size: 40,
                                ),
                                "Shuffle",
                              ),
                              _likeButton(),
                              _actionButton(
                                const HeroIcon(
                                  HeroIcons.arrowDownTray,
                                  color: Colors.white,
                                  size: 40,
                                ),
                                "Download",
                              ),
                              _actionButton(
                                const HeroIcon(
                                  HeroIcons.ellipsisVertical,
                                  color: Colors.white,
                                  size: 40,
                                ),
                                "More",
                              ),
                            ],
                          ),
                          const SizedBox(height: 2),

                          /// 🎵 LISTA DE CANCIONES
                          ListView.builder(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: tracks.length,
                            itemBuilder: (context, index) {
                              final track = tracks[index];
                              final isPlaying = nowPlayingIndex == index;

                              return TrackTile(
                                track: track,
                                isPlaying: isPlaying,
                                waveController: _waveController,
                                equalizerColor: equalizerColor,
                                onTap: () {
                                  if (isPlaying) {
                                    // 🚀 Si ya está sonando, abrimos detalle
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) =>
                                            TrackDetailScreen(tracks: tracks,
                                            currentIndex: index,
                                            genre: widget.genre,),
                                      ),
                                    );
                                  } else {
                                    // 🎵 Si no, la marcamos como actual
                                    setState(() {
                                      nowPlayingIndex = index;
                                    });
                                  }
                                },
                              );
                            },
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  /// ▶️ Play Button (HeroIcon)
  Widget _buildPlayButton() {
    return GestureDetector(
      onTap: () {
        // TODO: Play all tracks
      },
      child: const HeroIcon(
        HeroIcons.playCircle,
        style: HeroIconStyle.outline,
        color: Colors.white,
        size: 60,
      ),
    );
  }

  /// 🎛️ Generic Action Button
  Widget _actionButton(Widget icon, String tooltip) {
    return Container(
      width: 50,
      height: 50,
      margin: const EdgeInsets.symmetric(horizontal: 10),
      child: InkWell(
        borderRadius: BorderRadius.circular(22),
        onTap: () {
          // TODO: acción del botón
        },
        child: Center(child: icon),
      ),
    );
  }

  /// ❤️ Like Button con toggle outline/solid
  Widget _likeButton() {
    return Container(
      width: 50,
      height: 50,
      margin: const EdgeInsets.symmetric(horizontal: 10),
      child: InkWell(
        borderRadius: BorderRadius.circular(22),
        onTap: () {
          setState(() => isLiked = !isLiked);
        },
        child: Center(
          child: HeroIcon(
            HeroIcons.heart,
            style: isLiked ? HeroIconStyle.solid : HeroIconStyle.outline,
            color: Colors.white,
            size: 40,
          ),
        ),
      ),
    );
  }
}

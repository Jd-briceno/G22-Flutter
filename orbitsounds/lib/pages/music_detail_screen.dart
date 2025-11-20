import 'package:flutter/material.dart';
import 'package:heroicons/heroicons.dart';
import 'package:feather_icons/feather_icons.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/track_model.dart';
import '../services/goal_tracker_service.dart';
import '../services/playback_manager_service.dart';
import '../services/session_logger_service.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:geolocator/geolocator.dart';

class TrackDetailScreen extends StatefulWidget {
  final List<Track> tracks;
  final int currentIndex;
  final String genre;

  const TrackDetailScreen({
    super.key,
    required this.tracks,
    required this.currentIndex,
    required this.genre,
  });

  @override
  State<TrackDetailScreen> createState() => _TrackDetailScreenState();
}

class _TrackDetailScreenState extends State<TrackDetailScreen>
    with WidgetsBindingObserver {
  final GoalTrackerService _goalTracker = GoalTrackerService();
  final SessionLoggerService _sessionLogger = SessionLoggerService();
  late PlaybackManagerService _player;
  final FirebaseAnalytics _analytics = FirebaseAnalytics.instance;

  String? _activeSessionId;
  bool _loadingSession = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _player = PlaybackManagerService();

    _loadLatestSessionFromFirestore(); // 🔥 busca la última sesión creada

    // Cargar playlist
    if (_player.playlist.isEmpty ||
        _player.genre != widget.genre ||
        _player.playlist != widget.tracks) {
      _player.loadPlaylist(
        widget.tracks,
        startIndex: widget.currentIndex,
        genre: widget.genre,
      );

      Future.microtask(() async {
        _player.play();
        _goalTracker.startTracking(widget.genre);
      });
    } else if (_player.isPlaying) {
      _goalTracker.startTracking(widget.genre);
    }
  }

  /// 🪐 Buscar la última sesión creada en Firestore
  Future<void> _loadLatestSessionFromFirestore() async {
    try {
      final uid = FirebaseAuth.instance.currentUser?.uid;
      if (uid == null) {
        debugPrint("⚠️ Usuario no autenticado, no se puede cargar sesión.");
        return;
      }

      final snapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .collection('sessions')
          .orderBy('timestamp', descending: true)
          .limit(1)
          .get();

      if (snapshot.docs.isNotEmpty) {
        final sessionId = snapshot.docs.first['sessionId'];
        setState(() {
          _activeSessionId = sessionId;
          _loadingSession = false;
        });
        debugPrint("🌌 Sesión activa detectada: $_activeSessionId");
      } else {
        setState(() => _loadingSession = false);
        debugPrint("⚠️ No se encontró ninguna sesión en Firestore.");
      }
    } catch (e) {
      debugPrint("❌ Error al obtener la sesión más reciente: $e");
      setState(() => _loadingSession = false);
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _goalTracker.stopTracking();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.inactive) {
      if (_player.isPlaying) _player.pause();
    } else if (state == AppLifecycleState.resumed) {
      if (!_player.isPlaying) _player.play();
    }
  }

  /// 📍 Evento geográfico de engagement
  Future<void> logEngagementEvent(String trackName, String genre) async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) return;

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied ||
            permission == LocationPermission.deniedForever) return;
      }

      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.low,
      );

      await _analytics.logEvent(
        name: 'user_engagement_geo',
        parameters: {
          'track_name': trackName,
          'genre': genre,
          'latitude': position.latitude,
          'longitude': position.longitude,
          'hour': DateTime.now().hour,
          'day_of_week': DateTime.now().weekday,
        },
      );

      debugPrint("📊 Evento geo registrado: $trackName / $genre");
    } catch (e) {
      debugPrint("⚠️ Error al registrar evento geo: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final screenWidth = MediaQuery.of(context).size.width;

    if (_loadingSession) {
      return const Scaffold(
        backgroundColor: Color(0XFF010B19),
        body: Center(
          child: CircularProgressIndicator(color: Colors.white),
        ),
      );
    }

    return ChangeNotifierProvider.value(
      value: _player,
      child: Consumer<PlaybackManagerService>(
        builder: (context, player, _) {
          final track = player.currentTrack;
          if (track == null) {
            return const Scaffold(
              backgroundColor: Color(0XFF010B19),
              body: Center(
                child: Text("No track loaded",
                    style: TextStyle(color: Colors.white)),
              ),
            );
          }

          final duration = Duration(
              milliseconds: track.durationMs > 0 ? track.durationMs : 30000);
          final position = player.position;
          final progress = duration.inMilliseconds > 0
              ? (position.inMilliseconds / duration.inMilliseconds)
              : 0.0;

          final prevIndex = (player.currentIndex - 1 + player.playlist.length) %
              player.playlist.length;
          final nextIndex =
              (player.currentIndex + 1) % player.playlist.length;

          final prevTrack = player.playlist[prevIndex];
          final nextTrack = player.playlist[nextIndex];

          return Scaffold(
            backgroundColor: const Color(0XFF010B19),
            body: Stack(
              children: [
                if (track.albumArt.isNotEmpty)
                  Positioned(
                    top: 0,
                    left: 0,
                    right: 0,
                    height: screenHeight * 0.8,
                    child: Opacity(
                      opacity: 0.3,
                      child: Image.network(track.albumArt, fit: BoxFit.cover),
                    ),
                  ),
                Positioned(
                  top: screenHeight * 0.50,
                  left: 0,
                  right: 0,
                  height: screenHeight * 0.65,
                  child: CustomPaint(
                    size: Size(screenWidth, screenHeight * 0.65),
                    painter: _BottomCurvePainter(),
                  ),
                ),
                SafeArea(
                  child: Column(
                    children: [
                      Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 8),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            IconButton(
                              icon: const HeroIcon(
                                HeroIcons.arrowLeftCircle,
                                style: HeroIconStyle.outline,
                                color: Colors.white,
                                size: 40,
                              ),
                              onPressed: () {
                                _goalTracker.stopTracking();
                                Navigator.of(context).pop();
                              },
                            ),
                            Expanded(
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    track.title,
                                    textAlign: TextAlign.center,
                                    style: const TextStyle(
                                      fontFamily: "EncodeSansExpanded",
                                      fontSize: 20,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    track.artist,
                                    textAlign: TextAlign.center,
                                    style: const TextStyle(
                                      fontFamily: "RobotoMono",
                                      fontSize: 13,
                                      color: Colors.white70,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                              ),
                            ),
                            IconButton(
                              icon: const HeroIcon(
                                HeroIcons.bars3,
                                style: HeroIconStyle.outline,
                                color: Colors.white,
                                size: 35,
                              ),
                              onPressed: () {},
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 60),
                      Expanded(
                        child: LayoutBuilder(
                          builder: (context, constraints) {
                            final curveStart = screenHeight * 0.20;
                            return Stack(
                              children: [
                                Positioned(
                                  top: curveStart - 30,
                                  left: constraints.maxWidth / 2 - 30,
                                  child: _buildTrackInfo(
                                    number: player.currentIndex + 1,
                                    track: track,
                                    isCenter: true,
                                    vertical: true,
                                  ),
                                ),
                                Positioned(
                                  top: curveStart - 5,
                                  left: 5,
                                  child: _buildTrackInfo(
                                    number: prevIndex + 1,
                                    track: prevTrack,
                                    isCenter: false,
                                    vertical: true,
                                  ),
                                ),
                                Positioned(
                                  top: curveStart - 5,
                                  right: 5,
                                  child: _buildTrackInfo(
                                    number: nextIndex + 1,
                                    track: nextTrack,
                                    isCenter: false,
                                    vertical: true,
                                  ),
                                ),
                              ],
                            );
                          },
                        ),
                      ),
                      _buildMusicControls(
                          player, track, duration, position, progress),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildMusicControls(
    PlaybackManagerService player,
    Track track,
    Duration duration,
    Duration position,
    double progress,
  ) {
    return SizedBox(
      height: 300,
      child: Stack(
        alignment: Alignment.topCenter,
        children: [
          Positioned(
            top: -30,
            child: CustomPaint(
              painter: _CurvedProgressPainter(
                progress: progress.clamp(0.0, 1.0),
                backgroundColor: const Color(0XFFB4B1B8),
                progressColor: const Color(0XFF0095FC),
                strokeWidth: 4,
              ),
              child: const SizedBox(height: 100, width: 280),
            ),
          ),
          Positioned.fill(
            top: 40,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: Icon(
                    track.isLiked
                        ? Icons.favorite
                        : Icons.favorite_border,
                    color: track.isLiked
                        ? const Color(0XFF0095FC)
                        : Colors.white,
                    size: 45,
                  ),
                  onPressed: () async {
                    setState(() => track.isLiked = !track.isLiked);
                    await _goalTracker.registerLike(
                      genre: widget.genre,
                      track: track,
                    );
                  },
                ),
                Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 40),
                  child: Row(
                    mainAxisAlignment:
                        MainAxisAlignment.spaceBetween,
                    children: [
                      Text(_formatDuration(position),
                          style: const TextStyle(
                              color: Colors.white70,
                              fontSize: 13,
                              fontFamily: "RobotoMono")),
                      Text(_formatDuration(duration),
                          style: const TextStyle(
                              color: Colors.white70,
                              fontSize: 13,
                              fontFamily: "RobotoMono")),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    IconButton(
                      onPressed: player.previous,
                      icon: const HeroIcon(
                        HeroIcons.backward,
                        style: HeroIconStyle.outline,
                        color: Colors.white,
                        size: 50,
                      ),
                    ),
                    const SizedBox(width: 40),
                    PlayPauseButton(
                      isPlaying: player.isPlaying,
                      onTap: () async {
                        if (track.previewUrl == null || track.previewUrl!.isEmpty) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text("Esta canción no tiene preview disponible."),
                              backgroundColor: Colors.redAccent,
                            ),
                          );
                          return;
                        }

                        player.isPlaying ? player.pause() : player.play();
                        await logEngagementEvent(track.title, widget.genre);

                        if (_activeSessionId != null) {
                          await _sessionLogger.addTrackToSession(
                            track: track,
                            sessionId: _activeSessionId!,
                          );
                        } else {
                          debugPrint("⚠️ No hay sesión activa registrada.");
                        }
                      },
                    ),
                    const SizedBox(width: 40),
                    IconButton(
                      onPressed: player.next,
                      icon: const HeroIcon(
                        HeroIcons.forward,
                        style: HeroIconStyle.outline,
                        color: Colors.white,
                        size: 50,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTrackInfo({
    required int number,
    required Track track,
    required bool isCenter,
    required bool vertical,
  }) {
    final content = SizedBox(
      height: 80,
      width: 120,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: isCenter
            ? CrossAxisAlignment.center
            : CrossAxisAlignment.start,
        children: [
          Text(
            number.toString().padLeft(2, "0"),
            style: TextStyle(
              fontFamily: "EncodeSansExpanded",
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: isCenter ? Colors.white : Colors.white70,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            track.title,
            textAlign: isCenter ? TextAlign.center : TextAlign.left,
            style: TextStyle(
              fontFamily: "EncodeSansExpanded",
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: isCenter ? Colors.white : Colors.white70,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 2),
          Text(
            track.artist,
            textAlign: isCenter ? TextAlign.center : TextAlign.left,
            style: TextStyle(
              fontFamily: "RobotoMono",
              fontSize: 10,
              color: isCenter ? Colors.white70 : Colors.white38,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
    return vertical ? RotatedBox(quarterTurns: 3, child: content) : content;
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, "0");
    final minutes = twoDigits(duration.inMinutes.remainder(60));
    final seconds = twoDigits(duration.inSeconds.remainder(60));
    return "$minutes:$seconds";
  }
}

class _BottomCurvePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final fillPaint = Paint()
      ..style = PaintingStyle.fill
      ..color = const Color(0XFF010B19);
    final strokePaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3
      ..color = Colors.white;
    final path = Path()
      ..moveTo(0, size.height)
      ..lineTo(0, size.height * 0.3)
      ..quadraticBezierTo(
        size.width * 0.5,
        0,
        size.width,
        size.height * 0.3,
      )
      ..lineTo(size.width, size.height)
      ..close();
    canvas.drawPath(path, fillPaint);
    canvas.drawPath(path, strokePaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _CurvedProgressPainter extends CustomPainter {
  final double progress;
  final Color backgroundColor;
  final Color progressColor;
  final double strokeWidth;

  _CurvedProgressPainter({
    required this.progress,
    required this.backgroundColor,
    required this.progressColor,
    this.strokeWidth = 4,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final bgPaint = Paint()
      ..color = backgroundColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;
    final fgPaint = Paint()
      ..color = progressColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;
    final path = Path()
      ..moveTo(0, size.height)
      ..quadraticBezierTo(size.width * 0.5, 0, size.width, size.height);
    canvas.drawPath(path, bgPaint);
    final metrics = path.computeMetrics().first;
    final extractPath = metrics.extractPath(0, metrics.length * progress);
    canvas.drawPath(extractPath, fgPaint);
  }

  @override
  bool shouldRepaint(covariant _CurvedProgressPainter oldDelegate) =>
      oldDelegate.progress != progress;
}

class PlayPauseButton extends StatelessWidget {
  final bool isPlaying;
  final VoidCallback onTap;

  const PlayPauseButton({
    super.key,
    required this.isPlaying,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    const double size = 100;
    const double innerRadius = (size / 2) - 15;
    return GestureDetector(
      onTap: onTap,
      child: CustomPaint(
        painter: _CirclePainter(),
        child: SizedBox(
          width: size,
          height: size,
          child: Center(
            child: Container(
              width: innerRadius * 1.4,
              height: innerRadius * 1.4,
              alignment: Alignment.center,
              child: Icon(
                isPlaying ? FeatherIcons.pause : FeatherIcons.play,
                size: innerRadius,
                color: Colors.white,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _CirclePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final outer = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;
    final inner = Paint()
      ..color = const Color(0XFFB4B1B8)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;
    final center = Offset(size.width / 2, size.height / 2);
    canvas.drawCircle(center, size.width / 2 - 5, outer);
    canvas.drawCircle(center, size.width / 2 - 15, inner);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

import 'package:flutter/material.dart';
import 'package:heroicons/heroicons.dart';
import 'package:feather_icons/feather_icons.dart';
import '../models/track_model.dart';
import '../services/goal_tracker_service.dart';

class TrackDetailScreen extends StatefulWidget {
  final List<Track> tracks;
  final int currentIndex;
  final String genre; // 🟢 Nuevo: para el tracking de logros

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
    with SingleTickerProviderStateMixin {
  late AnimationController _progressController;
  late int _currentIndex;
  bool isLiked = false;
  final GoalTrackerService _goalTracker = GoalTrackerService();

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.currentIndex;

    _progressController = AnimationController(vsync: this);
    _progressController.addStatusListener((status) async {
      if (status == AnimationStatus.completed) {
        // 🎵 Nuevo: registra canción escuchada
        await _goalTracker.registerSongPlayed(widget.genre);
        _playNextTrack();
      }
    });

    _loadCurrentTrack();
    _goalTracker.startTracking(widget.genre); // 🟢 Inicia conteo por género
  }

  void _loadCurrentTrack() {
    final durationMs = widget.tracks[_currentIndex].durationMs;
    final trackDuration =
        Duration(milliseconds: durationMs > 0 ? durationMs : 30000);

    _progressController.duration = trackDuration;
    _progressController.reset();
    _progressController.forward();
  }

  Future<void> _playNextTrack() async {
    setState(() {
      _currentIndex = (_currentIndex + 1) % widget.tracks.length;
      _loadCurrentTrack();
    });

    // 🎵 Nuevo: registra reproducción manual también
    await _goalTracker.registerSongPlayed(widget.genre);
  }

  void _playPrevTrack() {
    final currentProgress = _progressController.value;

    setState(() {
      if (currentProgress > 0.1) {
        _loadCurrentTrack();
      } else {
        _currentIndex =
            (_currentIndex - 1 + widget.tracks.length) % widget.tracks.length;
        _loadCurrentTrack();
      }
    });
  }

  @override
  void dispose() {
    _goalTracker.stopTracking(); // 🛑 Detiene el conteo al salir
    _progressController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final screenWidth = MediaQuery.of(context).size.width;

    final track = widget.tracks[_currentIndex];
    final prevIndex =
        (_currentIndex - 1 + widget.tracks.length) % widget.tracks.length;
    final nextIndex = (_currentIndex + 1) % widget.tracks.length;

    final prevTrack = widget.tracks[prevIndex];
    final nextTrack = widget.tracks[nextIndex];

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
                child: Image.network(
                  track.albumArt,
                  fit: BoxFit.cover,
                ),
              ),
            ),

          /// 🔴 Fondo curvo inferior
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
                /// 🔙 Barra superior
                Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
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
                          _goalTracker.stopTracking(); // 🛑 Detener al salir
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

                /// 🎵 Vista centrada de las canciones
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
                              number: _currentIndex + 1,
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

                /// 🎶 Controles de música
                AnimatedBuilder(
                  animation: _progressController,
                  builder: (context, child) {
                    final duration = Duration(
                        milliseconds:
                            track.durationMs > 0 ? track.durationMs : 30000);
                    final position = duration * _progressController.value;

                    return SizedBox(
                      height: 300,
                      child: Stack(
                        alignment: Alignment.topCenter,
                        children: [
                          Positioned(
                            top: -30,
                            child: CustomPaint(
                              painter: _CurvedProgressPainter(
                                progress: _progressController.value,
                                backgroundColor: const Color(0XFFB4B1B8),
                                progressColor: const Color(0XFF0095FC),
                                strokeWidth: 4,
                              ),
                              child: const SizedBox(
                                height: 100,
                                width: 280,
                              ),
                            ),
                          ),

                          Positioned.fill(
                            top: 40,
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                /// ❤️ Like
                                IconButton(
                                  icon: Icon(
                                    isLiked ? Icons.favorite : Icons.favorite_border,
                                    color: Colors.white,
                                    size: 45,
                                  ),
                                  onPressed: () async {
                                    setState(() => isLiked = !isLiked);
                                    if (isLiked) {
                                      // ❤️ Nuevo: registrar like
                                      await _goalTracker.registerLike(widget.genre);
                                    }
                                  },
                                ),

                                /// ⏱️ Tiempos
                                Padding(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 40),
                                  child: Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        _formatDuration(position),
                                        style: const TextStyle(
                                            color: Colors.white70,
                                            fontSize: 13,
                                            fontFamily: "RobotoMono"),
                                      ),
                                      Text(
                                        _formatDuration(duration),
                                        style: const TextStyle(
                                            color: Colors.white70,
                                            fontSize: 13,
                                            fontFamily: "RobotoMono"),
                                      ),
                                    ],
                                  ),
                                ),

                                /// 🔀 Shuffle y Repeat
                                Padding(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 80),
                                  child: Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: const [
                                      Icon(Icons.shuffle,
                                          color: Colors.white, size: 40),
                                      Icon(Icons.repeat,
                                          color: Colors.white, size: 40),
                                    ],
                                  ),
                                ),
                                const SizedBox(height: 20),

                                /// 🎧 Controles principales
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    IconButton(
                                      onPressed: _playPrevTrack,
                                      icon: const HeroIcon(
                                        HeroIcons.backward,
                                        style: HeroIconStyle.outline,
                                        color: Colors.white,
                                        size: 50,
                                      ),
                                    ),
                                    const SizedBox(width: 40),
                                    PlayPauseButton(
                                      isPlaying: _progressController.isAnimating,
                                      onTap: () {
                                        setState(() {
                                          if (_progressController.isAnimating) {
                                            _progressController.stop();
                                            _goalTracker.stopTracking(); // 🛑 pausa tracking
                                          } else {
                                            _progressController.forward();
                                            _goalTracker.startTracking(widget.genre); // ▶️ reanuda tracking
                                          }
                                        });
                                      },
                                    ),
                                    const SizedBox(width: 40),
                                    IconButton(
                                      onPressed: _playNextTrack,
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
                  },
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
        crossAxisAlignment:
            isCenter ? CrossAxisAlignment.center : CrossAxisAlignment.start,
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

/// 🔴 Fondo curvo inferior
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

/// 🎶 Barra curva de progreso
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
      ..quadraticBezierTo(
        size.width * 0.5,
        0,
        size.width,
        size.height,
      );

    canvas.drawPath(path, bgPaint);
    final metrics = path.computeMetrics().first;
    final extractPath = metrics.extractPath(0, metrics.length * progress);
    canvas.drawPath(extractPath, fgPaint);
  }

  @override
  bool shouldRepaint(covariant _CurvedProgressPainter oldDelegate) =>
      oldDelegate.progress != progress;
}

/// ⏯ Botón Play/Pause
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

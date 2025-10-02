import 'package:flutter/material.dart';
import 'package:heroicons/heroicons.dart';
import '../models/track_model.dart';

class TrackDetailScreen extends StatefulWidget {
  final List<Track> tracks;
  final int currentIndex;

  const TrackDetailScreen({
    super.key,
    required this.tracks,
    required this.currentIndex,
  });

  @override
  State<TrackDetailScreen> createState() => _TrackDetailScreenState();
}

class _TrackDetailScreenState extends State<TrackDetailScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _progressController;
  late int _currentIndex;
  bool isLiked = false;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.currentIndex;
    _initTrack();
  }

  void _initTrack() {
    final durationMs = widget.tracks[_currentIndex].durationMs;
    final trackDuration =
        Duration(milliseconds: durationMs > 0 ? durationMs : 30000);

    _progressController = AnimationController(
      vsync: this,
      duration: trackDuration,
    )
      ..forward()
      ..addStatusListener((status) {
        if (status == AnimationStatus.completed) {
          _playNextTrack();
        }
      });
  }

  void _playNextTrack() {
    setState(() {
      _currentIndex = (_currentIndex + 1) % widget.tracks.length;
      _progressController.dispose();
      _initTrack();
    });
  }

  @override
  void dispose() {
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
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          /// 📸 Fondo con portada
          if (track.albumArt.isNotEmpty)
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              height: screenHeight * 0.8,
              child: Opacity(
                opacity: 0.4,
                child: Image.network(
                  track.albumArt,
                  fit: BoxFit.cover,
                ),
              ),
            ),

          /// 🔴 Fondo curvado debajo
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

          /// 🔝 Overlay
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
                        onPressed: () => Navigator.of(context).pop(),
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

                /// 🎵 Canciones centradas
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

                /// 🎶 Controles dentro del bloque rojo
                AnimatedBuilder(
                  animation: _progressController,
                  builder: (context, child) {
                    final duration = Duration(
                        milliseconds:
                            track.durationMs > 0 ? track.durationMs : 30000);

                    final position = duration * _progressController.value;

                    return Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        /// 🎶 Barra curva
                        Center(
                          child: CustomPaint(
                            painter: _CurvedProgressPainter(
                              progress: _progressController.value,
                              backgroundColor: Colors.white24,
                              progressColor: Colors.blue,
                              strokeWidth: 4,
                            ),
                            child: const SizedBox(
                              height: 100,
                              width: 280,
                            ),
                          ),
                        ),
                        const SizedBox(height: 20),

                        /// ❤️ Like
                        IconButton(
                          icon: Icon(
                            isLiked ? Icons.favorite : Icons.favorite_border,
                            color: Colors.white,
                            size: 45,
                          ),
                          onPressed: () {
                            setState(() => isLiked = !isLiked);
                          },
                        ),

                        /// ⏱️ Tiempo actual / total (debajo del corazón)
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 40),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                _formatDuration(position),
                                style: const TextStyle(
                                    color: Colors.white70, fontSize: 13),
                              ),
                              Text(
                                _formatDuration(duration),
                                style: const TextStyle(
                                    color: Colors.white70, fontSize: 13),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 15),

                        /// 🔀 Shuffle y Repeat (más arriba)
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 80),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: const [
                              Icon(Icons.shuffle,
                                  color: Colors.white, size: 30),
                              Icon(Icons.repeat,
                                  color: Colors.white, size: 30),
                            ],
                          ),
                        ),
                        const SizedBox(height: 20),
                      ],
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

class _BottomCurvePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final fillPaint = Paint()
      ..style = PaintingStyle.fill
      ..color = Colors.red;

    final strokePaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3
      ..color = Colors.white;

    final path = Path();

    path.moveTo(0, size.height);
    path.lineTo(0, size.height * 0.3);
    path.quadraticBezierTo(
      size.width * 0.5,
      0,
      size.width,
      size.height * 0.3,
    );
    path.lineTo(size.width, size.height);
    path.close();

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

    /// 🌙 Curva
    final path = Path()
      ..moveTo(0, size.height * 0.7)
      ..quadraticBezierTo(
        size.width * 0.5,
        0,
        size.width,
        size.height * 0.7,
      );

    // 🎨 Fondo gris
    canvas.drawPath(path, bgPaint);

    // ✨ Progreso azul
    final metrics = path.computeMetrics().first;
    final extractPath = metrics.extractPath(0, metrics.length * progress);
    canvas.drawPath(extractPath, fgPaint);
  }

  @override
  bool shouldRepaint(covariant _CurvedProgressPainter oldDelegate) =>
      oldDelegate.progress != progress;
}

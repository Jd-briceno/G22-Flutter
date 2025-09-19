import 'dart:math';
import 'package:flutter/material.dart';
import 'package:marquee/marquee.dart';
import '../models/track_model.dart';

class TrackTile extends StatelessWidget {
  final Track track;
  final bool isPlaying;
  final AnimationController waveController;
  final Color equalizerColor;
  final VoidCallback onTap;

  const TrackTile({
    super.key,
    required this.track,
    required this.isPlaying,
    required this.waveController,
    required this.equalizerColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final title = track.title.isNotEmpty ? track.title : "Unknown title";
    final artist = track.artist.isNotEmpty ? track.artist : "Unknown artist";
    final albumArt = track.albumArt;

    return GestureDetector(
      onTap: onTap,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final height = 72.0;

          return Container(
            margin: const EdgeInsets.only(bottom: 24.0),
            height: height,
            child: Stack(
              children: [
                /// Rectangle + octagon stroke
                Positioned.fill(
                  child: IgnorePointer(
                    child: CustomPaint(
                      painter: TileWithOctagonPainter(),
                    ),
                  ),
                ),

                /// Album art in octagon (opacidad un poco más alta)
                Positioned(
                  left: 0,
                  top: 0,
                  bottom: 0,
                  width: 72.0,
                  child: ClipPath(
                    clipper: OctagonClipper(),
                    child: Opacity(
                      opacity: isPlaying ? 0.7 : 1.0,
                      child: _albumArtWidget(albumArt),
                    ),
                  ),
                ),

                /// Equalizer / waveform inside octagon
                if (isPlaying)
                  Positioned(
                    left: 0,
                    top: 0,
                    bottom: 0,
                    width: 72.0,
                    child: ClipPath(
                      clipper: OctagonClipper(),
                      child: AnimatedBuilder(
                        animation: waveController,
                        builder: (context, child) {
                          return CustomPaint(
                            painter: WaveformPainter(
                              animation: waveController,
                              color: equalizerColor,
                              waves: 5, // más ondas para efecto profesional
                              amplitude: 0.4,
                            ),
                          );
                        },
                      ),
                    ),
                  ),

                /// Song info
                Positioned(
                  left: 90.0,
                  right: 0,
                  top: 0,
                  bottom: 0,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _marqueeOrText(title, bold: true),
                        _marqueeOrText("$artist | ${track.duration}", bold: false),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _albumArtWidget(String path) {
    if (path.startsWith("http")) {
      return Image.network(path, fit: BoxFit.cover);
    } else {
      return Image.asset(path, fit: BoxFit.cover);
    }
  }

  Widget _marqueeOrText(String text, {required bool bold}) {
    return SizedBox(
      height: 22.0,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final tp = TextPainter(
            text: TextSpan(
              text: text,
              style: TextStyle(
                color: bold ? Colors.white : Colors.white70,
                fontSize: bold ? 16.0 : 14.0,
                fontWeight: bold ? FontWeight.bold : FontWeight.normal,
              ),
            ),
            maxLines: 1,
            textDirection: TextDirection.ltr,
          )..layout(maxWidth: constraints.maxWidth);

          if (tp.didExceedMaxLines) {
            return Marquee(
              text: text,
              style: TextStyle(
                color: bold ? Colors.white : Colors.white70,
                fontSize: bold ? 16.0 : 14.0,
                fontWeight: bold ? FontWeight.bold : FontWeight.normal,
              ),
              velocity: 25.0,
              blankSpace: 50.0,
            );
          } else {
            return Text(
              text,
              style: TextStyle(
                color: bold ? Colors.white : Colors.white70,
                fontSize: bold ? 16.0 : 14.0,
                fontWeight: bold ? FontWeight.bold : FontWeight.normal,
              ),
              overflow: TextOverflow.ellipsis,
            );
          }
        },
      ),
    );
  }
}

/// Octagon clipper
class OctagonClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    final w = size.width;
    final h = size.height;
    final path = Path();

    final centerX = w / 2;
    final centerY = h / 2;
    final radius = min(w, h) / 2;

    for (int i = 0; i < 8; i++) {
      final angle = pi / 4 * i - pi / 8;
      final x = centerX + radius * cos(angle);
      final y = centerY + radius * sin(angle);
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }
    path.close();
    return path;
  }

  @override
  bool shouldReclip(covariant CustomClipper<Path> oldClipper) => false;
}

/// Rectangle + Octagon painter
class TileWithOctagonPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;

    final scaleX = size.width / 387.0;
    final scaleY = size.height / 72.0;

    final rect = Path();
    rect.moveTo(55 * scaleX, 3 * scaleY);
    rect.lineTo(55 * scaleX, 69 * scaleY);
    rect.lineTo(370.305 * scaleX, 71 * scaleY);
    rect.lineTo(385.619 * scaleX, 52.764 * scaleY);
    rect.lineTo(386 * scaleX, 21.939 * scaleY);
    rect.lineTo(371.878 * scaleX, 1.82542 * scaleY);
    rect.lineTo(57 * scaleX, 1 * scaleY);
    rect.close();

    final octagon = OctagonClipper().getClip(Size(72.0, size.height));

    canvas.drawPath(rect, paint);
    canvas.drawPath(octagon, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// 🎶 Waveform/Synth Equalizer Profesional
class WaveformPainter extends CustomPainter {
  final Animation<double> animation;
  final Color color;
  final int waves;
  final double amplitude;

  WaveformPainter({
    required this.animation,
    required this.color,
    this.waves = 5,
    this.amplitude = 0.4,
  }) : super(repaint: animation);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0
      ..strokeCap = StrokeCap.round;

    final midY = size.height / 2;
    final width = size.width;
    final progress = animation.value;

    for (int w = 0; w < waves; w++) {
      final path = Path();
      final phase = progress * 2 * pi + (w * pi / 3); // fases distintas
      final waveAmp = amplitude * size.height * (0.4 + w * 0.15); // amplitudes diferentes

      for (double x = 0; x <= width; x += 1) {
        final normX = x / width;
        final y = sin(normX * 2 * pi * 2.0 + phase) * waveAmp + midY; // frecuencia un poco distinta
        if (x == 0) {
          path.moveTo(x, y);
        } else {
          path.lineTo(x, y);
        }
      }

      double layerOpacity = 1.0 - (w * 0.2); // opacidad decreciente suave
      if (layerOpacity < 0.2) layerOpacity = 0.2;

      paint.color = color.withOpacity(layerOpacity);
      canvas.drawPath(path, paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

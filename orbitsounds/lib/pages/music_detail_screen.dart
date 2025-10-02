import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:heroicons/heroicons.dart';
import 'package:flutter_svg/flutter_svg.dart';

class MusicDetailScreen extends StatefulWidget {
  final String albumImage;
  final String songTitle;
  final String artistName;

  const MusicDetailScreen({
    super.key,
    required this.albumImage,
    required this.songTitle,
    required this.artistName,
  });

  @override
  State<MusicDetailScreen> createState() => _MusicDetailScreenState();
}

class _MusicDetailScreenState extends State<MusicDetailScreen> {
  double progress = 30;
  final double total = 238;
  bool isPlaying = true;
  bool isFavorite = false;
  bool isShuffle = false;
  bool isRepeat = false;

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          Positioned.fill(
            child: Image.asset(widget.albumImage, fit: BoxFit.cover),
          ),
          Positioned.fill(
            child: Container(color: Colors.black.withOpacity(0.55)),
          ),

          Column(
            children: [
              const SizedBox(height: 40),

              // Barra superior
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const HeroIcon(
                        HeroIcons.arrowLeftCircle,
                        style: HeroIconStyle.outline,
                        size: 50,
                      ),
                    ),
                    const HeroIcon(
                      HeroIcons.bars3,
                      style: HeroIconStyle.outline,
                      color: Colors.white,
                      size: 50,
                    ),
                  ],
                ),
              ),

              Transform.translate(
                offset: const Offset(0, -40),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.songTitle,
                        style: GoogleFonts.encodeSansExpanded(
                          color: Colors.white,
                          fontSize: 26,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        widget.artistName,
                        style: GoogleFonts.robotoMono(
                          color: Colors.white70,
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              Expanded(
                child: Stack(
                  children: [
                    Align(
                      alignment: Alignment.topCenter,
                      child: _SongsOnArc(
                        configs: [
                          SongArcConfig(
                            title: "01. Ashes and Blood",
                            angle: math.pi * -0.1,
                            radiusOffset: -18,
                          ),
                          SongArcConfig(
                            title: "02. Neon Rain",
                            angle: math.pi * -0.01,
                            radiusOffset: -30,
                            verticalOffset: -60,
                          ),
                          SongArcConfig(
                            title: "03. Vengeance",
                            angle: math.pi * 1.1,
                            radiusOffset: -280,
                            verticalOffset: -170,
                            rotationOffset: math.pi,
                          ),
                          SongArcConfig(
                            title: "04. Jeopardy",
                            angle: math.pi * 1.22,
                            radiusOffset: -12,
                          ),
                          SongArcConfig(
                            title: "05. Night Drive",
                            angle: math.pi * 1.32,
                            radiusOffset: -10,
                          ),
                        ],
                        baseRadius: 160,
                      ),
                    ),
                  ],
                ),
              ),

              SizedBox(
                height: size.height * 0.45,
                width: double.infinity,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    CustomPaint(
                      size: Size(size.width, size.height * 0.45),
                      painter: _BottomPanelPainter(),
                    ),
                    _CurvedSlider(
                      progress: progress,
                      total: total,
                      flatten: 1.1,
                      onChanged: (v) => setState(() => progress = v),
                    ),
                    Positioned(
                      top: 85,
                      left: size.width * 0.13,
                      child: IconButton(
                        onPressed: () => setState(() => isShuffle = !isShuffle),
                        icon: SvgPicture.asset(
                          'assets/images/shuffle.svg',
                          width: 35,
                          height: 35,
                        ),
                      ),
                    ),
                    Positioned(
                      top: 25,
                      child: IconButton(
                        onPressed: () => setState(() => isFavorite = !isFavorite),
                        icon: Icon(
                          isFavorite ? Icons.favorite : Icons.favorite_border,
                          color: Colors.white,
                          size: 50,
                        ),
                      ),
                    ),
                    Positioned(
                      top: 85,
                      right: size.width * 0.13,
                      child: IconButton(
                        onPressed: () => setState(() => isRepeat = !isRepeat),
                        icon: SvgPicture.asset(
                          'assets/images/refresh.svg',
                          width: 35,
                          height: 35,
                        ),
                      ),
                    ),
                    Positioned(
                      bottom: 320,
                      left: 170,
                      child: Text(_format(progress),
                          style: const TextStyle(color: Colors.white70)),
                    ),
                    Positioned(
                      bottom: 320,
                      right: 170,
                      child: Text(_format(total),
                          style: const TextStyle(color: Colors.white70)),
                    ),
                    Positioned(
                      bottom: 320,
                      right: 210,
                      child: Text("/",
                          style: const TextStyle(color: Colors.white70)),
                    ),
                    Positioned(
                      bottom: 130,
                      child: Row(
                        children: [
                          IconButton(
                            iconSize: 70,
                            color: Colors.white,
                            icon: const HeroIcon(HeroIcons.backward),
                            onPressed: () {},
                          ),
                          const SizedBox(width: 20),
                          Container(
                            padding: const EdgeInsets.all(15),
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: Colors.black,
                              border: Border.all(color: Colors.white, width: 2),
                            ),
                            child: Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: Colors.black,
                                border: Border.all(color: Colors.white, width: 2),
                              ),
                              child: IconButton(
                                iconSize: 80,
                                color: Colors.white,
                                icon: HeroIcon(
                                  isPlaying ? HeroIcons.pause : HeroIcons.play,
                                  style: HeroIconStyle.outline,
                                ),
                                onPressed: () => setState(() => isPlaying = !isPlaying),
                              ),
                            ),
                          ),
                          const SizedBox(width: 20),
                          IconButton(
                            iconSize: 70,
                            color: Colors.white,
                            icon: const HeroIcon(HeroIcons.forward),
                            onPressed: () {},
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _format(double s) {
    final m = (s ~/ 60).toString().padLeft(2, '0');
    final sec = (s % 60).toInt().toString().padLeft(2, '0');
    return "$m:$sec";
  }
}

class _BottomPanelPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = const Color(0xFF010B19);
    final path = Path();
    path.moveTo(0, 60);
    path.quadraticBezierTo(size.width / 2, -120, size.width, 60);
    path.lineTo(size.width, size.height);
    path.lineTo(0, size.height);
    path.close();
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}

class _CurvedSlider extends StatelessWidget {
  final double progress;
  final double total;
  final double flatten;
  final ValueChanged<double> onChanged;

  const _CurvedSlider({
    required this.progress,
    required this.total,
    this.flatten = 1.0,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.translucent,
      onPanDown: (d) => _updateProgress(context, d.localPosition),
      onPanUpdate: (d) => _updateProgress(context, d.localPosition),
      child: CustomPaint(
        size: const Size(double.infinity, 70),
        painter: _ArcProgressPainter(progress / total, flatten: flatten),
      ),
    );
  }

  void _updateProgress(BuildContext context, Offset localPos) {
    final box = context.findRenderObject() as RenderBox;
    final size = box.size;

    final center = Offset(size.width / 2, 20);
    final dx = localPos.dx - center.dx;
    final dy = localPos.dy - center.dy;

    final angle = math.atan2(dy, dx);

    if (angle <= 0 && angle >= -math.pi) {
      final percent = 1 - (angle.abs() / math.pi);
      onChanged(total * percent.clamp(0, 1));
    }
  }
}

class _ArcProgressPainter extends CustomPainter {
  final double value;
  final double flatten;

  _ArcProgressPainter(this.value, {this.flatten = 1.0});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, 20);
    final radius = 140.0;

    final rect = Rect.fromCenter(
      center: center,
      width: radius * 3,
      height: radius * 2.5 * flatten,
    );

    final bg = Paint()
      ..color = Colors.white24
      ..strokeWidth = 4
      ..style = PaintingStyle.stroke;
    final fg = Paint()
      ..color = Colors.cyanAccent
      ..strokeWidth = 4
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    canvas.drawArc(rect, 3.6, 2.25, false, bg);
    canvas.drawArc(rect, 3.6, math.pi * value, false, fg);
  }

  @override
  bool shouldRepaint(_ArcProgressPainter old) =>
      old.value != value || old.flatten != flatten;
}

class SongArcConfig {
  final String title;
  final double angle;
  final double radiusOffset;
  final double rotationOffset;
  final double verticalOffset;

  const SongArcConfig({
    required this.title,
    this.angle = math.pi,
    this.radiusOffset = 0,
    this.rotationOffset = 0,
    this.verticalOffset = 0,
  });
}

class _SongsOnArc extends StatelessWidget {
  final List<SongArcConfig> configs;
  final double baseRadius;

  const _SongsOnArc({
    required this.configs,
    this.baseRadius = 160,
  });

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;

    return IgnorePointer(
      child: SizedBox(
        height: baseRadius + 190,
        child: ListView.builder(
          scrollDirection: Axis.horizontal,
          itemCount: configs.length,
          padding: const EdgeInsets.symmetric(horizontal: 15),
          itemBuilder: (context, index) {
            final c = configs[index];
            final r = baseRadius + c.radiusOffset;

            final offsetX = r * math.cos(c.angle);
            final offsetY = r * math.sin(c.angle) + c.verticalOffset;

            return SizedBox(
              width: screenWidth / 3,
              child: Transform.translate(
                offset: Offset(offsetX, -offsetY),
                child: Transform.rotate(
                  angle: c.angle - math.pi / 2 + c.rotationOffset,
                  child: Text(
                    c.title,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 20,
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

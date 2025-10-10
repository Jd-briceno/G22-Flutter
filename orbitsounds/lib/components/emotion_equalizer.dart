import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:path_drawing/path_drawing.dart';

class EmotionEqualizer extends StatefulWidget {
  final List<Color> colors;
  final bool showBars;

  const EmotionEqualizer({
    super.key,
    required this.colors,
    required this.showBars,
  });

  @override
  State<EmotionEqualizer> createState() => _EmotionEqualizerState();
}

class _EmotionEqualizerState extends State<EmotionEqualizer> {
  late Timer _timer;
  List<double> barHeights = [];
  static const int barCount = 32; // más barras

  @override
  void initState() {
    super.initState();

    barHeights = List.generate(barCount, (_) => Random().nextDouble());

    _timer = Timer.periodic(const Duration(milliseconds: 400), (_) {
      if (!widget.showBars) return;

      setState(() {
        barHeights = List.generate(barCount, (_) => Random().nextDouble());
      });
    });
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.center,
      children: [
        // SVG visible SIEMPRE
        SvgPicture.string(
          _svgShape,
          width: 194,
          height: 170,
          fit: BoxFit.contain,
        ),

        // Barras SOLO si están activadas
        if (widget.showBars)
          ClipPath(
            clipper: _SVGClipper(),
            child: SizedBox(
              width: 194,
              height: 170,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: List.generate(barHeights.length, (index) {
                  final color = widget.colors[index % widget.colors.length];
                  return Expanded(
                    child: _AnimatedBar(
                      value: barHeights[index],
                      color: color,
                    ),
                  );
                }),
              ),
            ),
          ),
      ],
    );
  }
}

class _AnimatedBar extends StatelessWidget {
  final double value;
  final Color color;

  const _AnimatedBar({required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: 0, end: value),
      duration: const Duration(milliseconds: 400),
      curve: Curves.easeInOut,
      builder: (context, animatedValue, child) {
        return Align(
          alignment: Alignment.bottomCenter,
          child: Container(
            width: 3.5, // más delgado
            height: animatedValue * 110, // altura máx ajustada
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
        );
      },
    );
  }
}

class _SVGClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    const originalSize = Size(192, 191);
    final path = parseSvgPathData(_svgPath);

    final double scaleX = size.width / originalSize.width;
    final double scaleY = size.height / originalSize.height;
    final double scale = min(scaleX, scaleY);

    final double dx = (size.width - originalSize.width * scale) / 2;
    final double dy = (size.height - originalSize.height * scale) / 2;

    final matrix = Matrix4.identity()
      ..translate(dx, dy)
      ..scale(scale, scale);

    return path.transform(matrix.storage);
  }

  @override
  bool shouldReclip(covariant CustomClipper<Path> oldClipper) => false;
}

// === SVG Path usado para recorte y fondo ===

const String _svgPath = '''
M34.067 1C32.614 1 31.2329 1.63203 30.2831 2.73159L20.87 13.6292C20.0855 14.5374 19.6538 15.6975 19.6538 16.8976V51.5078C19.6538 52.5671 19.3174 53.5991 18.6931 54.4548L1.96077 77.3887C1.33643 78.2445 1 79.2764 1 80.3357V110.096C1 111.197 1.36309 112.266 2.03298 113.14L59.499 188.043C60.4452 189.277 61.9114 190 63.466 190H148.36C150.102 190 151.717 189.094 152.626 187.608L190.348 125.919C192.385 122.587 189.987 118.31 186.082 118.31H82.9471C80.1857 118.31 77.9471 116.072 77.9471 113.31V91.3045C77.9471 89.9784 78.4739 88.7066 79.4116 87.769L96.5355 70.6448C97.4732 69.7072 98 68.4354 98 67.1093V32.997C98 31.7626 97.5433 30.5717 96.7179 29.6538L72.4417 2.65678C71.4935 1.60225 70.142 1 68.7238 1H34.067Z
''';

const String _svgShape = '''
<svg width="192" height="191" viewBox="0 0 192 191" fill="none" xmlns="http://www.w3.org/2000/svg">
  <path d="$_svgPath" stroke="#D9D9D9" stroke-width="1.2"/>
</svg>
''';
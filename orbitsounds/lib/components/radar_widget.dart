import 'dart:async';
import 'dart:math';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
// import 'package:flutter_blue_plus/flutter_blue_plus.dart'; // 🔹 Bluetooth (descomenta cuando quieras usarlo)

class RadarWidget extends StatefulWidget {
  const RadarWidget({super.key});

  @override
  State<RadarWidget> createState() => _RadarWidgetState();
}

class _RadarWidgetState extends State<RadarWidget> {
  List<RadarFriend> friends = [];
  final Map<String, ui.Image> _imageCache = {};

  @override
  void initState() {
    super.initState();

    // 🔹 Simulación inicial
    _generateFakeFriends();

    // 🔹 Si quieres usar Bluetooth real:
    // _startBluetoothScan();
  }

  void _generateFakeFriends() async {
    final random = Random();
    final images = [
      "assets/images/Jay.jpg",
      "assets/images/Kamui.jpg",
      "assets/images/joy.jpg",
      "assets/images/X.jpg",
      "assets/images/E-soul.jpg",
    ];

    final fakeFriends = images.map((img) {
      return RadarFriend(
        imagePath: img,
        angle: random.nextDouble() * 2 * pi,
        distance: random.nextDouble(),
      );
    }).toList();

    for (var f in fakeFriends) {
      if (!_imageCache.containsKey(f.imagePath)) {
        _imageCache[f.imagePath] = await _loadImage(f.imagePath);
      }
    }

    setState(() {
      friends = fakeFriends;
    });
  }

  Future<ui.Image> _loadImage(String assetPath) async {
    final completer = Completer<ui.Image>();
    final provider = AssetImage(assetPath);
    final stream = provider.resolve(const ImageConfiguration());
    late final ImageStreamListener listener;
    listener = ImageStreamListener((ImageInfo info, bool _) {
      completer.complete(info.image);
      stream.removeListener(listener);
    });
    stream.addListener(listener);
    return completer.future;
  }

  /*
  // 🚧 Bluetooth real (descomentar para probar en dispositivo físico)
  void _startBluetoothScan() {
    FlutterBluePlus.startScan(timeout: const Duration(seconds: 5));

    FlutterBluePlus.scanResults.listen((results) async {
      final random = Random();

      final newFriends = <RadarFriend>[];

      for (var r in results) {
        final imgPath = "assets/images/Jay.jpg"; // 🔹 Asigna según device.id
        if (!_imageCache.containsKey(imgPath)) {
          _imageCache[imgPath] = await _loadImage(imgPath);
        }

        newFriends.add(
          RadarFriend(
            imagePath: imgPath,
            angle: random.nextDouble() * 2 * pi,
            distance: random.nextDouble(),
          ),
        );
      }

      setState(() {
        friends = newFriends;
      });
    });
  }
  */

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: const Size(double.infinity, 300),
      painter: _RadarPainter(friends, _imageCache),
    );
  }
}

class RadarFriend {
  final String imagePath;
  final double angle;
  final double distance;

  RadarFriend({
    required this.imagePath,
    required this.angle,
    required this.distance,
  });
}

class _RadarPainter extends CustomPainter {
  final List<RadarFriend> friends;
  final Map<String, ui.Image> imageCache;

  _RadarPainter(this.friends, this.imageCache);

  @override
  void paint(Canvas canvas, Size size) {
    final Paint circlePaint = Paint()
      ..color = Color(0xFFB4B1B8).withOpacity(0.6)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;

    final Offset center = Offset(size.width / 2, size.height / 2);
    final double maxRadius = min(size.width, size.height) / 2;

    // 🔹 Dibujar círculos concéntricos
    for (int i = 1; i <= 5; i++) {
      canvas.drawCircle(center, maxRadius * (i / 5), circlePaint);
    }

    // 🔹 Dibujar amigos
    for (var f in friends) {
      final double r = maxRadius * f.distance;
      final double dx = center.dx + r * cos(f.angle);
      final double dy = center.dy + r * sin(f.angle);

      const double imgSize = 50;
      final Rect rect = Rect.fromCenter(
        center: Offset(dx, dy),
        width: imgSize,
        height: imgSize,
      );

      if (imageCache.containsKey(f.imagePath)) {
        final img = imageCache[f.imagePath]!;

        // Recorte circular
        final Path clipPath = Path()..addOval(rect);
        canvas.save();
        canvas.clipPath(clipPath);

        paintImage(
          canvas: canvas,
          rect: rect,
          image: img,
          fit: BoxFit.cover,
        );

        canvas.restore();

        // Borde blanco
        final Paint borderPaint = Paint()
          ..color = Colors.white
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1;
        canvas.drawOval(rect, borderPaint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant _RadarPainter oldDelegate) => true;
}

import 'package:flutter/material.dart';

class CurvedShapeButton extends StatelessWidget {
  final String imageAsset;
  final double width;
  final double height;
  final VoidCallback onTap;

  const CurvedShapeButton({
    super.key,
    required this.imageAsset,
    this.width = 40,
    this.height = 80,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: ClipPath(
        clipper: _CurvedClipper(),
        child: Image.asset(
          imageAsset,
          width: width,
          height: height,
          fit: BoxFit.cover,
        ),
      ),
    );
  }
}

class _CurvedClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    Path path = Path();
    path.moveTo(size.width, size.height / 2);
    path.cubicTo(
      size.width, size.height * 0.755,
      size.width * 0.618, size.height * 0.965,
      size.width * 0.12475, size.height * 0.996,
    );
    path.cubicTo(
      0.05625 * size.width, size.height,
      0, size.height * 0.972,
      0, size.height * 0.9375,
    );
    path.lineTo(0, size.height * 0.5);
    path.lineTo(0, size.height * 0.0625);
    path.cubicTo(
      0, size.height * 0.028,
      0.05625 * size.width, 0,
      size.width * 0.12475, size.height * 0.00385,
    );
    path.cubicTo(
      size.width * 0.618, size.height * 0.035,
      size.width, size.height * 0.248,
      size.width, size.height / 2,
    );
    path.close();
    return path;
  }

  @override
  bool shouldReclip(CustomClipper<Path> oldClipper) => false;
}
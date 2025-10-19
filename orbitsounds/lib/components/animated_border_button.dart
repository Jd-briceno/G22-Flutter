import 'dart:async';
import 'package:flutter/material.dart';

class AnimatedColorBorderButton extends StatefulWidget {
  final VoidCallback? onTap;
  final String text;
  final List<Color> colors;

  const AnimatedColorBorderButton({
    Key? key,
    required this.text,
    required this.colors,
    this.onTap,
  }) : super(key: key);

  @override
  State<AnimatedColorBorderButton> createState() => _AnimatedColorBorderButtonState();
}

class _AnimatedColorBorderButtonState extends State<AnimatedColorBorderButton> with SingleTickerProviderStateMixin {
  late Timer _colorTimer;
  int _currentColorIndex = 0;
  late Color _currentColor;
  late Color _nextColor;
  late AnimationController _scaleController;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();

    _currentColor = widget.colors[0];
    _nextColor = widget.colors.length > 1 ? widget.colors[1] : widget.colors[0];

    _scaleController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);

    _scaleAnimation = Tween(begin: 1.0, end: 1.05).animate(
      CurvedAnimation(parent: _scaleController, curve: Curves.easeInOut),
    );

    _colorTimer = Timer.periodic(const Duration(seconds: 3), (_) {
      setState(() {
        _currentColorIndex = (_currentColorIndex + 1) % widget.colors.length;
        _currentColor = widget.colors[_currentColorIndex];
        _nextColor = widget.colors[(_currentColorIndex + 1) % widget.colors.length];
      });
    });
  }

  @override
  void dispose() {
    _scaleController.dispose();
    _colorTimer.cancel();
    super.dispose();
  }

  Color _lerpColor(double t) {
    return Color.lerp(_currentColor, _nextColor, t) ?? _currentColor;
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _scaleController,
      builder: (context, child) {
        final borderColor = _lerpColor(_scaleController.value);
        return Transform.scale(
          scale: _scaleAnimation.value,
          child: GestureDetector(
            onTap: widget.onTap,
            child: Container(
              width: 296,
              height: 54,
              decoration: BoxDecoration(
                color: const Color(0xFF1E1E1E),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: borderColor, width: 3),
                boxShadow: [
                  BoxShadow(
                    color: borderColor.withOpacity(0.6),
                    blurRadius: 10,
                    spreadRadius: 1,
                  ),
                ],
              ),
              alignment: Alignment.center,
              child: Text(
                widget.text,
                style: TextStyle(
                  fontFamily: 'monospace',
                  fontWeight: FontWeight.w500,
                  fontSize: 12,
                  color: Colors.white,
                  shadows: [
                    Shadow(
                      blurRadius: 8,
                      color: borderColor.withOpacity(0.8),
                    )
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

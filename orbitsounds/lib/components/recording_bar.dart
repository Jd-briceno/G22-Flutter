import 'package:flutter/material.dart';

class RecordingBar extends StatefulWidget {
  final double width;
  final double height;

  const RecordingBar({
    super.key,
    this.width = 172,
    this.height = 17,
  });

  @override
  State<RecordingBar> createState() => _RecordingBarState();
}

class _RecordingBarState extends State<RecordingBar>
    with SingleTickerProviderStateMixin {
  late AnimationController _recordingController;

  @override
  void initState() {
    super.initState();
    _recordingController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _recordingController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: widget.width,
      height: widget.height,
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E1E),
        borderRadius: BorderRadius.circular(4),
      ),
      child: AnimatedBuilder(
        animation: _recordingController,
        builder: (context, child) {
          return Stack(
            children: [
              Positioned(
                left: _recordingController.value * (widget.width - 20),
                top: 0,
                child: Container(
                  width: 20,
                  height: widget.height,
                  decoration: BoxDecoration(
                    color: Colors.redAccent,
                    borderRadius: BorderRadius.circular(3),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
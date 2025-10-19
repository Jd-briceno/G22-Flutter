import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

class SvgButton extends StatelessWidget {
  final String text;
  final VoidCallback onPressed;
  final Color fillColor;
  final Color textColor;
  final double width;
  final double height;

  const SvgButton({
    super.key,
    required this.text,
    required this.onPressed,
    this.fillColor = Colors.blue,
    this.textColor = Colors.white,
    this.width = 150,
    this.height = 80,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onPressed,
      child: SizedBox(
        width: width,
        height: height,
        child: Stack(
          children: [
            SvgPicture.string(
              '''
<svg viewBox="0 0 171 80" xmlns="http://www.w3.org/2000/svg">
  <path d="M165.264 1H6C3.23858 1 1 3.23857 1 6V74.5C1 77.2614 3.23858 79.5 6 79.5H107.671C109.148 79.5 110.548 78.8476 111.499 77.7177L169.091 9.21768C171.826 5.9651 169.513 1 165.264 1Z" 
    fill="${_colorToHex(fillColor)}" 
    stroke="#D9D9D9"/>
</svg>
              ''',
              width: width,
              height: height,
            ),
            Align(
              alignment: Alignment.centerLeft, // center vertically
              child: Padding(
                padding: const EdgeInsets.only(left: 32), // keep same left margin
                child: SizedBox(
                  width: width * 0.7, // avoid hitting right curve
                  child: Text(
                    text,
                    style: TextStyle(
                      color: textColor,
                      fontSize: 13, // fixed smaller size
                      fontWeight: FontWeight.bold,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  static String _colorToHex(Color color) {
    return '#${color.value.toRadixString(16).padLeft(8, '0').substring(2)}';
  }
}
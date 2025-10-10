import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

class SvgActionButton extends StatelessWidget {
  final VoidCallback onPressed;
  final double width;
  final double height;

  const SvgActionButton({
    super.key,
    required this.onPressed,
    this.width = 65,
    this.height = 58,
  });

  @override
  Widget build(BuildContext context) {
    const String svgData = '''
<svg width="65" height="58" viewBox="0 0 65 58" fill="none" xmlns="http://www.w3.org/2000/svg">
<path d="M1 6C1 3.23858 3.23858 1 6 1H51.44C54.2014 1 56.44 3.23858 56.44 6V11.5114C56.44 12.8385 56.9676 14.1113 57.9067 15.0491L62.5333 19.67C63.4724 20.6078 64 21.8806 64 23.2077V49.2885C64 50.9613 63.1635 52.5233 61.7711 53.4504L57.6988 56.1618C56.878 56.7084 55.9138 57 54.9277 57H6C3.23858 57 1 54.7614 1 52V6Z" fill="#1E1E1E" stroke="#D9D9D9"/>
<rect x="16" y="31.5024" width="8" height="29.7532" rx="4" transform="rotate(-45 16 31.5024)" fill="#D9D9D9"/>
<rect x="24.7162" y="27.7202" width="8" height="22.4917" rx="4" transform="rotate(-135 24.7162 27.7202)" fill="#D9D9D9"/>
</svg>
    ''';

    return GestureDetector(
      onTap: onPressed,
      child: SvgPicture.string(
        svgData,
        width: width,
        height: height,
      ),
    );
  }
}
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:heroicons/heroicons.dart';

class SearchBarCustom extends StatelessWidget {
  final Function(String) onSearch;

  const SearchBarCustom({super.key, required this.onSearch});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 90,
      width: double.infinity,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          // 🎨 SVG de fondo
          Positioned.fill(
            child: SvgPicture.string(
              '''
<svg width="460" height="90" viewBox="0 0 460 90" fill="none" xmlns="http://www.w3.org/2000/svg">
  <!-- 🔹 Rectángulo más ancho -->
  <rect x="0.5" y="15" width="420" height="50" rx="25" fill="#010B19" stroke="#B4B1B8"/>
  
  <!-- 🔹 Círculos concéntricos -->
  <circle cx="420" cy="41" r="40" fill="#010B19" stroke="#E9E8EE"/>
  <circle cx="420" cy="41" r="34" stroke="#B4B1B8"/>
  <circle cx="420" cy="41" r="28" stroke="#B4B1B8"/>
  <circle cx="420" cy="41" r="22" fill="#B4B1B8" stroke="#B4B1B8"/>
</svg>
              ''',
              fit: BoxFit.contain,
              alignment: Alignment.centerLeft,
            ),
          ),

          // ✏️ Campo de texto
          Positioned(
            left: 8,
            right: 120,
            top: 28,
            child: SizedBox(
              height: 36,
              child: TextField(
                onChanged: onSearch,
                style: GoogleFonts.robotoMono(
                  color: Color(0XFFE9E8EE),
                  fontSize: 15,
                  fontStyle: FontStyle.italic
                ),
                decoration: const InputDecoration(
                  hintText: "Find your rhythm...",
                  hintStyle: TextStyle(color: Color(0XFFA1BBD1), fontSize: 15),
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.symmetric(horizontal: 8),
                  isCollapsed: true,
                ),
              ),
            ),
          ),

          // 🔍 Lupa — forzada absoluta y encima
          Positioned(
            left:  285, 
            top: 39 - 12, 
            child: IgnorePointer(
              child: HeroIcon(
                HeroIcons.magnifyingGlass,
                style: HeroIconStyle.outline,
                color: Color(0XFF010B19),
                size: 28,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

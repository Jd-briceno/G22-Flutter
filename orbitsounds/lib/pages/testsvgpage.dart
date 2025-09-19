import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

class TestSvgPage extends StatelessWidget {
  const TestSvgPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Align(
        alignment: Alignment.topCenter,
        child: SizedBox(
          width: 412,
          height: 474,
          child: Stack(
            children: [
              // === Fondo (solo el rectángulo verde + adornos) ===
              SvgPicture.string(
                '''
<svg width="412" height="474" viewBox="0 0 412 474" fill="none" xmlns="http://www.w3.org/2000/svg">
<path opacity="0.4" d="M0 10C0 4.47716 4.47715 0 10 0H402C407.523 0 412 4.47715 412 10V342H0V10Z" fill="#0BFB7B"/>
<rect x="81" y="401.071" width="10" height="10" transform="rotate(-45 81 401.071)" fill="#D9D9D9"/>
<path d="M88 349V389" stroke="#E9E8EE" stroke-width="2"/>
<path d="M88 414V448" stroke="#E9E8EE" stroke-width="2"/>
<rect x="206" y="459" width="10" height="10" transform="rotate(45 206 459)" fill="#D9D9D9"/>
<path d="M406 466H221" stroke="#E9E8EE" stroke-width="2"/>
<path d="M191 466H6.00001" stroke="#E9E8EE" stroke-width="2"/>
<rect x="3" y="6" width="50" height="50" fill="#D3A42E"/>
<rect x="356" y="6" width="50" height="50" fill="#D3A42E"/>
<rect x="356" y="349" width="50" height="50" fill="#D3A42E"/>
</svg>
                ''',
                allowDrawingOutsideViewBox: true,
              ),

              // === Hora (blanco, dividido en dos) ===
              Positioned(
                left: 6,
                top: 333,
                child: Container(
                  width: 58,
                  height: 98,
                  color: const Color(0xFFD9D9D9),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: const [
                      Text(
                        "12",
                        style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                      ),
                      Divider(color: Colors.black54, thickness: 1),
                      Text(
                        "45",
                        style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ),
              ),

              // === Día (naranja) ===
              Positioned(
                left: 85,
                top: 333,
                child: Container(
                  width: 137,
                  height: 42,
                  color: const Color(0xFFD43F00),
                  alignment: Alignment.center,
                  child: const Text(
                    "Monday",
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                    ),
                  ),
                ),
              ),

              // === Fecha (azul claro) ===
              Positioned(
                left: 85,
                top: 375,
                child: Container(
                  width: 130,
                  height: 16,
                  color: const Color(0xFF0BD3FB),
                  alignment: Alignment.center,
                  child: const Text(
                    "18 September 2025",
                    style: TextStyle(
                      color: Colors.black,
                      fontSize: 12,
                    ),
                  ),
                ),
              ),

              // === Temperatura (rosado con borde) ===
              Positioned(
                left: 100.5,
                top: 414.5,
                child: Container(
                  width: 129,
                  height: 33,
                  decoration: BoxDecoration(
                    color: const Color(0xFFF16DCA),
                    borderRadius: BorderRadius.circular(16.5),
                    border: Border.all(color: Color(0xFFB4B1B8)),
                  ),
                  alignment: Alignment.center,
                  child: const Text(
                    "24°C",
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),

              // === Icono dorado (ejemplo, puedes reemplazar por SVGs reales) ===
              const Positioned(
                left: 297,
                top: 349,
                child: Icon(Icons.star, color: Colors.amber, size: 40),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

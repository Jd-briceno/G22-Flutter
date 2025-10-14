import 'package:flutter/material.dart';
import 'vinyl_record.dart'; // Tu componente VinylRecord

/// ─────────────────────────────────────────────
/// VinylWithCover
/// • Muestra la funda (portada del álbum)
/// • El vinilo sobresaliendo SOLO horizontalmente
/// • Incluye la funda completa con borde + profundidad
/// • Línea superior alineada con la funda
/// ─────────────────────────────────────────────
class VinylWithCover extends StatelessWidget {
  final String albumArt;   // Imagen de la portada (local o URL)
  final String vinylArt;   // Imagen de la etiqueta del vinilo (opcional)

  const VinylWithCover({
    super.key,
    required this.albumArt,
    this.vinylArt = "",
  });

  /// Helper para soportar assets y URLs
  ImageProvider _getImageProvider(String path) {
    if (path.startsWith('http')) {
      return NetworkImage(path);
    } else {
      return AssetImage(path);
    }
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 165, // ancho total incluyendo el vinilo sobresalido
      height: 120, // funda + vinilo perfectamente alineados en altura
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          // 🎶 Vinilo detrás, sobresaliendo horizontalmente
          Positioned(
            left: 42, // cuánto sobresale hacia la derecha
            top: 0,   // alineado arriba
            bottom: 0, // alineado abajo
            child: VinylRecord(
              size: 120,
              image: _getImageProvider(
                vinylArt.isNotEmpty ? vinylArt : albumArt,
              ),
            ),
          ),

          // 📀 Funda con la portada del álbum
          Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              border: Border.all(color: Colors.white24, width: 1.5),
              image: DecorationImage(
                image: _getImageProvider(albumArt),
                fit: BoxFit.cover,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.5),
                  blurRadius: 6,
                  spreadRadius: 1,
                  offset: const Offset(2, 4),
                ),
              ],
            ),
          ),

          // 📏 Línea gris clarita superior del mismo ancho que la funda
          Positioned(
            top: 0,
            left: 0,
            child: Container(
              width: 120, // mismo ancho que la funda
              height: 1.5,
              color: Colors.white24,
            ),
          ),
        ],
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:heroicons/heroicons.dart';

class MiniSongReproductor extends StatelessWidget {
  final String albumImage;
  final String songTitle;
  final String artistName;
  final bool isPlaying;
  final VoidCallback onPlayPause;
  final VoidCallback onNext;
  final VoidCallback onPrevious;

  const MiniSongReproductor({
    super.key,
    required this.albumImage,
    required this.songTitle,
    required this.artistName,
    required this.isPlaying,
    required this.onPlayPause,
    required this.onNext,
    required this.onPrevious,
  });

  ImageProvider _imageProviderFor(String path) {
    if (path.startsWith("http")) return NetworkImage(path);
    return AssetImage(path);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 400,
      height: 62,
      decoration: BoxDecoration(
        color: const Color(0xFF010B19),
        borderRadius: BorderRadius.circular(30.5),
        border: Border.all(color: const Color(0xFFB4B1B8)),
      ),
      child: Row(
        children: [
          // ══════════ Imagen del álbum ══════════
          Container(
            margin: const EdgeInsets.all(2),
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(30),
              image: DecorationImage(
                image: _imageProviderFor(albumImage),
                fit: BoxFit.cover,
              ),
            ),
          ),

          // ══════════ Nombre y artista ══════════
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    songTitle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.encodeSansExpanded(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    artistName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.robotoMono(
                      fontSize: 10,
                      color: Colors.white70,
                    ),
                  ),
                ],
              ),
            ),
          ),

          // ══════════ Controles ══════════
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                onPressed: onPrevious,
                icon: const HeroIcon(
                  HeroIcons.backward,
                  style: HeroIconStyle.outline,
                  color: Color(0XFFE9E8EE),
                  size: 22,
                ),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
              IconButton(
                onPressed: onPlayPause,
                icon: HeroIcon(
                  isPlaying ? HeroIcons.pause : HeroIcons.play,
                  style: HeroIconStyle.outline,
                  color: Color(0XFFE9E8EE),
                  size: 26,
                ),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
              IconButton(
                onPressed: onNext,
                icon: const HeroIcon(
                  HeroIcons.forward,
                  style: HeroIconStyle.outline,
                  color: Color(0XFFE9E8EE),
                  size: 22,
                ),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
              const SizedBox(width: 6),
            ],
          ),
        ],
      ),
    );
  }
}

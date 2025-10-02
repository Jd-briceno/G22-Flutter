import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:heroicons/heroicons.dart';

class BackstageCard extends StatelessWidget {
  final bool isPremium;
  final String avatarUrl;
  final bool isAsset;
  final String username;
  final String title;
  final String description;
  final String qrData;
  final String backgroundAsset;

  const BackstageCard({
    super.key,
    required this.isPremium,
    required this.avatarUrl,
    required this.username,
    required this.title,
    required this.description,
    required this.qrData,
    this.isAsset = false,
    this.backgroundAsset = 'assets/images/Perfil.png',
  });

  @override
  Widget build(BuildContext context) {
    final avatarSize = 96.0;
    final qrSize = 100.0;

    return Stack(
      children: [
        // 📌 La tarjeta en sí
        Container(
          width: 320,
          height: 380,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            image: DecorationImage(
              image: AssetImage(
                isPremium ? 'assets/images/VIP.png' : backgroundAsset,
              ),
              fit: BoxFit.cover,
            ),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              child: Column(
                mainAxisSize: MainAxisSize.max,
                children: [
                  // Avatar
                  Center(
                    child: Container(
                      width: avatarSize,
                      height: avatarSize,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                            color: Colors.white.withOpacity(0.25), width: 2.5),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.5),
                            blurRadius: 8,
                            offset: const Offset(0, 4),
                          ),
                        ],
                        image: DecorationImage(
                          image: isAsset
                              ? AssetImage(avatarUrl) as ImageProvider
                              : NetworkImage(avatarUrl),
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 12),

                  // Nombre
                  Text(
                    username,
                    style: GoogleFonts.encodeSansExpanded(
                      textStyle: const TextStyle(
                        color: Color(0XFF010B19),
                        fontSize: 22,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 1.2,
                      ),
                    ),
                  ),

                  const SizedBox(height: 10),

                  // Badge con título
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 20, vertical: 8),
                    decoration: BoxDecoration(
                      color: const Color(0XFF010B19),
                      borderRadius: BorderRadius.circular(50),
                      border:
                          Border.all(color: Colors.white.withOpacity(0.15)),
                    ),
                    child: Text(
                      title,
                      style: GoogleFonts.encodeSansExpanded(
                        textStyle: const TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 5),

                  // Descripción
                  Text(
                    description,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.center,
                    style: GoogleFonts.robotoMono(
                      textStyle: const TextStyle(
                        color: Color(0XFF010B19),
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),

                  const Spacer(),

                  // QR
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: Color(0XFF010B19).withOpacity(0.4),
                          blurRadius: 10,
                          offset: const Offset(0, 6),
                        ),
                      ],
                    ),
                    child: QrImageView(
                      data: qrData,
                      version: QrVersions.auto,
                      size: qrSize,
                      gapless: true,
                      backgroundColor: Colors.white,
                      embeddedImage: isAsset
                          ? AssetImage(avatarUrl)
                          : NetworkImage(avatarUrl) as ImageProvider,
                      embeddedImageStyle: const QrEmbeddedImageStyle(
                        size: Size.square(30),
                      ),
                      eyeStyle: const QrEyeStyle(
                        eyeShape: QrEyeShape.square,
                        color: Color(0XFF010B19),
                      ),
                      dataModuleStyle: const QrDataModuleStyle(
                        dataModuleShape: QrDataModuleShape.square,
                        color: Color(0XFF010B19),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),

        // ✏️ Botón Pencil arriba a la izquierda
        Positioned(
          top: 8,
          right: 8,
          child: IconButton(
            onPressed: () {
              // 🚀 acción cuando toques el botón
              debugPrint("Editar perfil");
            },
            icon: const HeroIcon(
              HeroIcons.pencilSquare,
              style: HeroIconStyle.outline,
              color: Color(0XFF010B19),
              size: 32,
            ),
          ),
        ),
      ],
    );
  }
}

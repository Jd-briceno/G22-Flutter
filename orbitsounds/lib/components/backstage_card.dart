import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:qr_flutter/qr_flutter.dart';

class BackstageCard extends StatelessWidget {
  final bool isPremium;
  final String avatarUrl; // puede ser network o asset
  final bool isAsset; // 👈 para indicar si avatarUrl es asset o red
  final String username;
  final String title; // ej. "Ninja"
  final String description;
  final String qrData;
  final String backgroundAsset; // fondo cromado normal o gold

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
    final avatarSize = 96.0; // 🔥 más grande
    final qrSize = 100.0; // 🔥 más grande

    return Container(
      width: 320, // un poco más ancho
      height: 380, // un poco más alto
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
                    border: Border.all(color: Colors.white.withOpacity(0.25), width: 2.5),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.5),
                        blurRadius: 8,
                        offset: const Offset(0, 4),
                      ),
                    ],
                    image: DecorationImage(
                      image: isAsset ? AssetImage(avatarUrl) as ImageProvider : NetworkImage(avatarUrl),
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
                    fontSize: 22, // más grande
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.2,
                  ),
                ),
              ),

              const SizedBox(height: 10),

              // Badge con título
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                decoration: BoxDecoration(
                  color: Color(0XFF010B19),
                  borderRadius: BorderRadius.circular(50),
                  border: Border.all(color: Colors.white.withOpacity(0.15)),
                ),
                child: Text(
                  title,
                  style: GoogleFonts.encodeSansExpanded(
                    textStyle: const TextStyle(
                      color: Colors.white,
                      fontSize: 14, // más grande
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
                  textStyle: TextStyle(
                    color: Color(0XFF010B19),
                    fontSize: 12, // más grande
                    fontWeight:FontWeight.bold
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
                      color: Colors.black.withOpacity(0.4),
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
                  embeddedImage: isAsset ? AssetImage(avatarUrl) : NetworkImage(avatarUrl) as ImageProvider,
                  embeddedImageStyle: QrEmbeddedImageStyle(
                    size: Size.square(30), // también un poco más grande
                  ),
                  eyeStyle: const QrEyeStyle(
                    eyeShape: QrEyeShape.square,
                    color: Colors.black,
                  ),
                  dataModuleStyle: const QrDataModuleStyle(
                    dataModuleShape: QrDataModuleShape.square,
                    color: Colors.black,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
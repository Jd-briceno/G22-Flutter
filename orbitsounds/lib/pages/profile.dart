import 'package:flutter/material.dart';
import 'package:orbitsounds/components/backstage_card.dart';
import 'package:orbitsounds/components/mini_song_reproductor.dart';
import 'package:orbitsounds/components/navbar.dart';
import 'package:heroicons/heroicons.dart';

class ProfileBackstagePage extends StatelessWidget {
  const ProfileBackstagePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          child: Padding(
            padding: const EdgeInsets.only(bottom: 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const SizedBox(height: 20),

                const Navbar(
                  username: "Jay Walker",
                  title: "Lightning Ninja",
                  profileWidget: HeroIcon(
                    HeroIcons.cog,
                    style: HeroIconStyle.outline,
                    color: Color(0xFFE9E8EE),
                    size: 28),
                ),


                const SizedBox(height: 0),

                BackstageCard(
                  isPremium: false,
                  avatarUrl: "assets/images/Jay.jpg",
                  isAsset: true,
                  username: "Higan",
                  title: "Hero X",
                  description:
                      "From calm seas to wild storms — I have a track for it 🌊⚡",
                  qrData: "https://tuapp.com/user/higan",
                ),

                // Línea punteada
                CustomPaint(
                  size: const Size(320, 2),
                  painter: DottedLinePainter(),
                ),

                // Rectángulo inferior con secciones
                Container(
                  width: 320,
                  height:390,
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: const Color(0xFF010B19),
                    border: Border.all(color: Color(0xFFB4B1B8)),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Column(
                    children: [
                      // Sección Achievements
                      const SectionTitle(title: "Achievements"),
                      const SizedBox(height: 14),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: const [
                          AchievementCircle(image: "assets/images/medal.jpg"),
                          AchievementCircle(image: "assets/images/medal2.jpg"),
                          AchievementCircle(image: "assets/images/medal3.jpg"),
                          PlusIcon(),
                        ],
                      ),

                      const SizedBox(height: 28),

                      // Sección Friends
                      const SectionTitle(title: "Friends"),
                      const SizedBox(height: 14),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: const [
                          FriendCircle(
                            image: "assets/images/X.jpg",
                            status: FriendStatus.online,
                          ),
                          FriendCircle(
                            image: "assets/images/Lin ling.jpg",
                            status: FriendStatus.away,
                          ),
                          FriendCircle(
                            image: "assets/images/E-soul.jpg",
                            status: FriendStatus.offline,
                          ),
                          PlusIcon(),
                        ],
                      ),

                      const SizedBox(height: 28),

                      // Sección Now Listening
                      const SectionTitle(title: "Now Listening"),
                      const SizedBox(height: 14),
                      _buildPlayer(),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Player para Now Listening
  Widget _buildPlayer() {
    return MiniSongReproductor(
      albumImage: "assets/images/Coldrain.jpg",
      songTitle: "Vengeance",
      artistName: "Coldrain",
      isPlaying: true,
      onPlayPause: () {
        debugPrint("Play/Pause presionado");
      },
      onNext: () {
        debugPrint("Siguiente canción");
      },
      onPrevious: () {
        debugPrint("Canción anterior");
      },
    );
  }
}

/// Línea punteada horizontal
class DottedLinePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0XFFB4B1B8)
      ..strokeWidth = 2;

    const dashWidth = 6;
    const dashSpace = 4;
    double startX = 0;

    while (startX < size.width) {
      canvas.drawLine(
        Offset(startX, 0),
        Offset(startX + dashWidth, 0),
        paint,
      );
      startX += dashWidth + dashSpace;
    }
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}

/// Título centrado con líneas
class SectionTitle extends StatelessWidget {
  final String title;
  const SectionTitle({super.key, required this.title});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const Expanded(child: Divider(color: Colors.white54, thickness: 1)),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8),
          child: Text(
            title,
            style: const TextStyle(
              fontFamily: "RobotoMono",
              color: Colors.white,
              fontSize: 15,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        const Expanded(child: Divider(color: Colors.white54, thickness: 1)),
      ],
    );
  }
}

/// Círculo de medalla con borde blanco
class AchievementCircle extends StatelessWidget {
  final String image;
  const AchievementCircle({super.key, required this.image});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 52,
      height: 52,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white, width: 2), // 👈 borde blanco
        image: DecorationImage(
          image: AssetImage(image),
          fit: BoxFit.cover,
        ),
      ),
    );
  }
}


/// Ícono plus con mismo tamaño que los círculos
class PlusIcon extends StatelessWidget {
  const PlusIcon({super.key});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 60,
      height: 60,
      child: const HeroIcon(
        HeroIcons.plusCircle,
        color: Colors.white70,
        size: 60,
      ),
    );
  }
}

/// Estados posibles
enum FriendStatus { online, away, offline }

/// Avatar de amigo con borde de estado
class FriendCircle extends StatelessWidget {
  final String image;
  final FriendStatus status;
  const FriendCircle({super.key, required this.image, required this.status});

  Color get borderColor {
    switch (status) {
      case FriendStatus.online:
        return Colors.greenAccent;
      case FriendStatus.away:
        return Colors.amberAccent;
      case FriendStatus.offline:
        return Colors.red;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 52,
      height: 52,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: borderColor, width: 2),
        image: DecorationImage(image: AssetImage(image), fit: BoxFit.cover),
      ),
    );
  }
}
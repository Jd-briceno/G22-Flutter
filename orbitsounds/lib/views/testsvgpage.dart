import 'package:flutter/material.dart';
import 'package:melodymuse/components/navbar.dart';
import 'package:melodymuse/components/radar_widget.dart';
import 'package:heroicons/heroicons.dart';

// Ejecuta la app
void main() => runApp(const MyApp());

class MyApp extends StatelessWidget {
  const MyApp({super.key});
  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      debugShowCheckedModeBanner: false,
      home: SocialVinylDemo(),
    );
  }
}

class SocialVinylDemo extends StatefulWidget {
  const SocialVinylDemo({super.key});

  @override
  State<SocialVinylDemo> createState() => _SocialVinylDemoState();
}

class _SocialVinylDemoState extends State<SocialVinylDemo> {
  final List<_Friend> friends = [
    _Friend("Higan", "assets/images/Kamui.jpg", FriendStatus.online),
    _Friend("Jay", "assets/images/Jay.jpg", FriendStatus.offline),
    _Friend("Yang", "assets/images/E-soul.jpg", FriendStatus.away),
    _Friend("Ling Lin", "assets/images/joy.jpg", FriendStatus.online),
    _Friend("X", "assets/images/X.jpg", FriendStatus.offline),
    _Friend("Ghostblade", "assets/images/Ghostblade.jpg", FriendStatus.away),
  ];

  int selectedIndex = 0;
  double _dragDistance = 0.0;
  final List<int> slotOffsets = [-2, -1, 0, 1, 2];

  @override
  Widget build(BuildContext context) {
    final double screenW = MediaQuery.of(context).size.width;

    return Scaffold(
      backgroundColor: Color(0XFF010B19),
      body: Stack(
        children: [
          // 🎵 Fondo vinilo
          Positioned.fill(
            child: LayoutBuilder(
              builder: (context, constraints) => CustomPaint(
                size: Size(constraints.maxWidth, constraints.maxHeight),
                painter: VinylPainter(),
              ),
            ),
          ),

          // 🔹 Contenido principal con scroll
          SafeArea(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              child: Column(
                children: [
                  const SizedBox(height: 20),
                  const Navbar(
                    username: "Jay Walker",
                    title: "Lightning Ninja",
                    profileImage: "assets/images/Jay.jpg",
                  ),
                  const SizedBox(height: 12),

                  // Texto debajo de la Navbar
                  const Text(
                    "Your friends",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      fontFamily: 'RobotoMono',
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 10),

                  // Fila de iconos
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      IconButton(
                        icon: const HeroIcon(
                          HeroIcons.plusCircle,
                          color: Colors.white,
                          style: HeroIconStyle.outline,
                        ),
                        iconSize: 45,
                        onPressed: () => debugPrint("Agregar Amigos"),
                      ),
                      const SizedBox(width: 20),
                      IconButton(
                        icon: const HeroIcon(
                          HeroIcons.magnifyingGlassCircle,
                          color: Colors.white,
                          style: HeroIconStyle.outline,
                        ),
                        iconSize: 45,
                        onPressed: () => debugPrint("Buscar amigos"),
                      ),
                      const SizedBox(width: 20),

                      // 🎶 Nota musical dentro de un círculo con borde
                      Container(
                        width: 35,
                        height: 35,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 2),
                        ),
                        child: IconButton(
                          padding: EdgeInsets.zero,
                          icon: const HeroIcon(
                            HeroIcons.musicalNote,
                            color: Colors.white,
                            style: HeroIconStyle.outline,
                          ),
                          iconSize: 25,
                          onPressed: () => debugPrint("Música"),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // 🎡 Carrusel de amigos
                  SizedBox(
                    height: 150,
                    child: Center(
                      child: GestureDetector(
                        onHorizontalDragStart: (_) => _dragDistance = 0.0,
                        onHorizontalDragUpdate: (details) {
                          _dragDistance += details.delta.dx;
                        },
                        onHorizontalDragEnd: (_) {
                          if (_dragDistance < -30) {
                            _advance(1);
                          } else if (_dragDistance > 30) {
                            _advance(-1);
                          }
                          _dragDistance = 0.0;
                        },
                        child: SizedBox(
                          width: screenW,
                          height: 300,
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: slotOffsets.map((offset) {
                              final int friendIndex = _wrapIndex(
                                selectedIndex + offset,
                                friends.length,
                              );
                              final _Friend friend = friends[friendIndex];

                              // posiciones en "V"
                              final Map<int, double> fixedY = {
                                -2: -100,
                                -1: -50,
                                0: -5,
                                1: -50,
                                2: -100,
                              };
                              final double translateY = fixedY[offset] ?? 0.0;
                              final bool isCenter = offset == 0;

                              // tamaños
                              final double size = isCenter
                                  ? 110.0
                                  : (offset.abs() == 1 ? 80.0 : 64.0);

                              const double borderWidth = 3.0;

                              final Color borderColor = switch (friend.status) {
                                FriendStatus.online => Colors.greenAccent,
                                FriendStatus.away => Colors.yellowAccent,
                                FriendStatus.offline => Colors.redAccent,
                              };

                              // espacio horizontal → el centro ocupa más
                              final double slotWidth =
                                  isCenter ? screenW / 3 : screenW / 6;

                              return SizedBox(
                                width: slotWidth,
                                child: Center(
                                  child: Transform.translate(
                                    offset: Offset(0, translateY),
                                    child: Column(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        AnimatedContainer(
                                          duration: const Duration(milliseconds: 250),
                                          curve: Curves.easeOut,
                                          width: size,
                                          height: size,
                                          decoration: BoxDecoration(
                                            shape: BoxShape.circle,
                                            border: Border.all(
                                              color: borderColor,
                                              width: borderWidth,
                                            ),
                                            image: DecorationImage(
                                              image: AssetImage(friend.imagePath),
                                              fit: BoxFit.cover,
                                            ),
                                            boxShadow: isCenter
                                                ? [
                                                    BoxShadow(
                                                      color: borderColor
                                                          .withOpacity(0.6),
                                                      blurRadius: 25,
                                                      spreadRadius: 4,
                                                    ),
                                                  ]
                                                : null,
                                          ),
                                        ),
                                        if (isCenter) ...[
                                          const SizedBox(height: 4),
                                          Text(
                                            friend.name,
                                            style: const TextStyle(
                                              color: Color(0xFFB4B1B8),
                                              fontSize: 16,
                                              fontWeight: FontWeight.bold,
                                              fontFamily: 'RobotoMono',
                                            ),
                                          ),
                                        ]
                                      ],
                                    ),
                                  ),
                                ),
                              );
                            }).toList(),
                          ),
                        ),
                      ),
                      
                    ),
                    
                  ),
                  const SizedBox(height: 10),
                  // 🚀 Radar dentro del scroll (debajo del carrusel)
                  const Text(
                    "Nearby Friends",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      fontFamily: 'RobotoMono',
                    ),
                  ),
                  const SizedBox(height: 10),
                  SizedBox(
                    height: 350, // 👈 asegura que tenga espacio completo
                    child: RadarWidget(),
                  ),
                  const SizedBox(height: 15),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _advance(int step) {
    setState(() {
      selectedIndex = _wrapIndex(selectedIndex + step, friends.length);
    });
  }

  int _wrapIndex(int i, int length) {
    final int r = i % length;
    return r < 0 ? r + length : r;
  }
}

class _Friend {
  final String name;
  final String imagePath;
  final FriendStatus status;
  _Friend(this.name, this.imagePath, this.status);
}

enum FriendStatus { online, offline, away }

class VinylPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final Paint fillPaint = Paint()..color = const Color(0xFF010B19);
    final Paint strokePaint = Paint()
      ..color = const Color(0xFFB4B1B8)
      ..style = PaintingStyle.stroke;

    final Offset center = Offset(size.width / 2, size.height * 0.12);
    final double baseRadius = size.width / 2 + 150;
    const double spacing = 40;

    final radii = [
      baseRadius,
      baseRadius - spacing,
      baseRadius - (2 * spacing),
      baseRadius - (3 * spacing),
    ];

    for (int i = 0; i < radii.length; i++) {
      final r = radii[i];
      if (i == radii.length - 1) {
        final Path path = Path()
          ..addArc(
            Rect.fromCircle(center: center, radius: r),
            0.2,
            3.5,
          );
        canvas.drawPath(path, strokePaint);
      } else {
        canvas.drawCircle(center, r, fillPaint);
        canvas.drawCircle(center, r, strokePaint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

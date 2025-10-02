import 'dart:math';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:geolocator/geolocator.dart';
import 'package:melodymuse/components/navbar.dart';
import 'package:melodymuse/components/song_reproductor.dart';
import 'package:melodymuse/components/shortcuts_container.dart';
import 'package:melodymuse/pages/captain-longbook.dart';
import 'package:melodymuse/pages/genre_selector.dart';
import 'package:melodymuse/pages/library_screen.dart';
import 'package:melodymuse/pages/profile.dart';
import 'package:melodymuse/pages/social_vinyl.dart';
import 'package:melodymuse/pages/soul_sync_terminal.dart';
import '../services/weather_service.dart';
import '../models/weather_model.dart';
import 'package:heroicons/heroicons.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with TickerProviderStateMixin {
  final WeatherService _weatherService = WeatherService();
  Weather? _weather;
  bool _locationError = false;

  late AnimationController _timeController;
  late AnimationController _colorController;
  late AnimationController _lightningController;

  List<Color> _previousColors = [Colors.white];
  List<Color> _currentColors = [Colors.white];

  @override
  void initState() {
    super.initState();

    _timeController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 10),
    )..repeat();

    _colorController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    );

    _lightningController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );

    _loadWeather();
  }

  Future<void> _loadWeather() async {
    try {
      Position position = await _determinePosition();
      final weather = await _weatherService.fetchWeather(
        position.latitude,
        position.longitude,
      );

      setState(() {
        _weather = weather;
        _locationError = false;
      });

      _updateStarColors();

      if (_weather != null &&
          _weather!.condition.toLowerCase().contains("thunderstorm")) {
        _startLightning();
      }
    } catch (e) {
      setState(() {
        _locationError = true;
      });
      debugPrint("Error: $e");
    }
  }

  Future<Position> _determinePosition() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) throw Exception("Ubicación deshabilitada.");

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        throw Exception("Permisos de ubicación denegados.");
      }
    }
    if (permission == LocationPermission.deniedForever) {
      throw Exception("Permisos de ubicación denegados permanentemente.");
    }

    return await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.high,
    );
  }

  List<Color> _calculateStarColors() {
    if (_weather == null || _locationError) {
      return [Colors.white];
    }

    final hour = int.parse(DateFormat('HH').format(DateTime.now()));
    final condition = _weather!.condition.toLowerCase();
    final isDay = hour >= 6 && hour < 18;

    if (hour == 17) {
      return [Colors.deepOrange, Colors.orangeAccent, Colors.yellowAccent];
    }

    if (condition.contains("thunderstorm")) {
      return [Colors.blue.shade300, Colors.blueAccent];
    } else if (condition.contains("rain")) {
      return [Colors.lightBlueAccent, Colors.cyanAccent];
    } else if (condition.contains("cloud")) {
      return isDay
          ? [Colors.grey.shade400, Colors.yellowAccent]
          : [Colors.grey.shade300, Colors.white];
    } else {
      return isDay
          ? [Colors.yellow.shade700, Colors.orangeAccent]
          : [Colors.white, Colors.indigoAccent];
    }
  }

  void _updateStarColors() {
    _previousColors = _currentColors;
    _currentColors = _calculateStarColors();
    _colorController.forward(from: 0.0);
  }

  List<Color> _getInterpolatedColors() {
    return List.generate(_currentColors.length, (i) {
      final oldColor = _previousColors[i % _previousColors.length];
      final newColor = _currentColors[i % _currentColors.length];
      return Color.lerp(oldColor, newColor, _colorController.value) ?? newColor;
    });
  }

  void _startLightning() async {
    Future.doWhile(() async {
      await Future.delayed(
          Duration(milliseconds: 2000 + Random().nextInt(3000)));
      if (!mounted) return false;
      await _lightningController.forward(from: 0.0);
      return mounted &&
          _weather != null &&
          _weather!.condition.toLowerCase().contains("thunderstorm");
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFF010B19),
      body: Stack(
        children: [
          AnimatedBuilder(
            animation: Listenable.merge([_timeController, _colorController]),
            builder: (context, _) {
              return CustomPaint(
                size: MediaQuery.of(context).size,
                painter: StarPainter(
                  globalTime: _timeController.value * 2 * pi,
                  starColors: _getInterpolatedColors(),
                ),
              );
            },
          ),
          AnimatedBuilder(
            animation: _lightningController,
            builder: (context, _) {
              if (_lightningController.isAnimating) {
                return CustomPaint(
                  size: MediaQuery.of(context).size,
                  painter: LightningPainter(progress: _lightningController.value),
                );
              }
              return const SizedBox.shrink();
            },
          ),

          Column(
            children: [
              const SizedBox(height: 40),

              const Navbar(
                username: "Jay Walker",
                title: "Lightning Ninja",
                profileImage: "assets/images/Jay.jpg",
              ),

              const SizedBox(height: 20),
              Expanded(
                child: Center(
                  child: AnimatedBuilder(
                    animation: _timeController,
                    builder: (context, child) {
                      return Transform.translate(
                        offset:
                            Offset(0, sin(_timeController.value * 2 * pi) * 10),
                        child: Image.asset(
                          "assets/images/Astronaut_home.png",
                          height: MediaQuery.of(context).size.height * 1,
                        ),
                      );
                    },
                  ),
                ),
              ),
              _buildPlayer(),
              const SizedBox(height: 8),
              _buildShortcuts(context),
              const SizedBox(height: 20),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPlayer() {
    return SongReproductor(
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

    Widget _buildShortcuts(BuildContext context) {
      return ShortcutsContainer(
        shortcuts: [
          ShortcutItem(
            icon: HeroIcons.rocketLaunch,
            label: "Stellar Emotions",
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const GenreSelectorPage()),
              );
            },
          ),
          ShortcutItem(
            icon: HeroIcons.radio,
            label: "Star Archive",
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const LibraryScreen()),
              );
            },
          ),
          ShortcutItem(
            icon: HeroIcons.clipboardDocumentList,
            label: "Captain’s Log",
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const Longbook()),
              );
            },
          ),
          ShortcutItem(
            icon: HeroIcons.users,
            label: "Crew Members",
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const SocialVinylDemo()),
              );
            },
          ),
          ShortcutItem(
            icon: HeroIcons.userCircle,
            label: "Command Profile",
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const ProfileBackstagePage()),
              );
            },
          ),
        ],
      );
    }
  }

/// ───────────────────────────── Fondo: Estrellas + Rayos ─────────────────────────────

class _StarData {
  final Offset position;
  final double size;
  final double phase;
  final double speed;
  final double flickerChance;

  _StarData({
    required this.position,
    required this.size,
    required this.phase,
    required this.speed,
    required this.flickerChance,
  });
}

class StarPainter extends CustomPainter {
  final List<Color> starColors;
  final double globalTime;

  static final Random _random = Random();
  static List<_StarData>? _stars;

  StarPainter({required this.starColors, required this.globalTime}) {
    _stars ??= List.generate(
      120,
      (_) => _StarData(
        position: Offset(
          _random.nextDouble() * 500,
          _random.nextDouble() * 900,
        ),
        size: _random.nextDouble() * 3 + 3.0,
        phase: _random.nextDouble() * 2 * pi,
        speed: 0.5 + _random.nextDouble() * 1.5,
        flickerChance: _random.nextDouble(),
      ),
    );
  }

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint();

    for (var star in _stars!) {
      double flicker = star.flickerChance < 0.2
          ? 1.0
          : 0.5 + 0.5 * sin(globalTime * star.speed + star.phase);

      final color = starColors[(star.hashCode) % starColors.length];
      paint.color = color.withOpacity(0.28 + flicker * 0.6);
      canvas.drawCircle(star.position, star.size, paint);
    }
  }

  @override
  bool shouldRepaint(covariant StarPainter oldDelegate) {
    return oldDelegate.starColors != starColors ||
        oldDelegate.globalTime != globalTime;
  }
}

class LightningPainter extends CustomPainter {
  final double progress;
  final Random _random = Random();

  LightningPainter({required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    if (progress < 0.2 || progress > 0.8) return;

    final paint = Paint()
      ..color = Colors.blueAccent.withOpacity(1 - (progress - 0.2))
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;

    double startX = _random.nextDouble() * size.width;
    double y = 0;

    final path = Path()..moveTo(startX, y);

    while (y < size.height) {
      double xOffset = (_random.nextDouble() - 0.5) * 50;
      y += 30 + _random.nextDouble() * 20;
      path.lineTo(startX + xOffset, y);
      startX += xOffset;
    }

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant LightningPainter oldDelegate) {
    return oldDelegate.progress != progress;
  }
}

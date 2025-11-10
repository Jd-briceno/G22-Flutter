import 'dart:math';
import 'package:flutter/material.dart';
import 'package:orbitsounds/components/navbar.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:orbitsounds/pages/genre_selector.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:async';


// ───────────────────────────────────────────────
// MAIN
// ───────────────────────────────────────────────
void main() {
  runApp(const MaterialApp(
    home: CelestialSignalPage(sessionId: "test_session"),
    debugShowCheckedModeBanner: false,
  ));
}

// ───────────────────────────────────────────────
// MODELO DE CONSTELACIÓN
// ───────────────────────────────────────────────
class Constellation {
  final String name;
  final Color color;
  final List<Offset> points;
  final Offset relativePosition;
  bool isSelected = false;

  Constellation({
    required this.name,
    required this.color,
    required this.points,
    required this.relativePosition,
  });
}

// ───────────────────────────────────────────────
// NORMALIZAR ALTURA A 100 PX
// ───────────────────────────────────────────────
List<Offset> normalizeToHeight100(List<Offset> points) {
  double minY = points.map((p) => p.dy).reduce(min);
  double maxY = points.map((p) => p.dy).reduce(max);
  double minX = points.map((p) => p.dx).reduce(min);
  double maxX = points.map((p) => p.dx).reduce(max);

  double height = maxY - minY;
  double scale = 100 / height;

  double centerX = (minX + maxX) / 2;
  double centerY = (minY + maxY) / 2;

  return points
      .map((p) => Offset((p.dx - centerX) * scale, (p.dy - centerY) * scale))
      .toList();
}

// ───────────────────────────────────────────────
// LISTA DE CONSTELACIONES
// ───────────────────────────────────────────────
final List<Constellation> constellations = [
  Constellation(
    name: "Osa Mayor",
    color: const Color(0xFF9D2053),
    relativePosition: const Offset(0.70, 0.72),
    points: normalizeToHeight100([
      const Offset(-58.7, -27.0),
      const Offset(-30.3, -27.3),
      const Offset(-11.2, -14.8),
      const Offset(10.0, -1.9),
      const Offset(57.8, 3.1),
      const Offset(48.4, 27.7),
      const Offset(12.7, 18.7),
    ]),
  ),
  Constellation(
    name: "Cruz del Sur",
    color: const Color(0xFFF8CA00),
    relativePosition: const Offset(0.50, 0.86),
    points: normalizeToHeight100([
      const Offset(0, -25),
      const Offset(0, 25),
      const Offset(-25, 0),
      const Offset(25, 0),
    ]),
  ),
  Constellation(
    name: "Draco",
    color: const Color(0xFF23B8A9),
    relativePosition: const Offset(0.70, 0.17),
    points: normalizeToHeight100([
      const Offset(21.2, 117.3),
      const Offset(2.6, 108.3),
      const Offset(21.4, 89.5),
      const Offset(27.7, 105.3),
      const Offset(32.2, 21.4),
      const Offset(37.0, 1.7),
      const Offset(56.1, 6.5),
      const Offset(65.0, 23.8),
      const Offset(67.4, 69.2),
      const Offset(81.1, 98.5),
      const Offset(89.5, 116.4),
      const Offset(112.8, 118.2),
      const Offset(157.6, 90.1),
      const Offset(187.4, 48.9),
      const Offset(206.5, 34.0),
    ]),
  ),
  Constellation(
    name: "Pegaso",
    color: const Color(0xFF6664FF),
    relativePosition: const Offset(0.75, 0.34),
    points: normalizeToHeight100([
      const Offset(-93.2, 27.6),
      const Offset(-84.8, -41.2),
      const Offset(-12.0, -41.2),
      const Offset(12.4, -52.4),
      const Offset(47.6, -67.6),
      const Offset(-10.8, 27.6),
      const Offset(1.2, -23.6),
      const Offset(12.4, -14.8),
      const Offset(54.0, -30.0),
      const Offset(82.0, -38.8),
      const Offset(94.0, 43.6),
      const Offset(62.0, 67.6),
      const Offset(19.6, 49.2),
    ]),
  ),
  Constellation(
    name: "Fenix",
    color: const Color(0xFFD43F00),
    relativePosition: const Offset(0.25, 0.28),
    points: normalizeToHeight100([
      const Offset(3, 39),
      const Offset(43, 76),
      const Offset(64, 4),
      const Offset(90, 38),
      const Offset(107, 57),
      const Offset(213, 31),
      const Offset(209, 57),
      const Offset(230, 93),
      const Offset(324, 91),
      const Offset(286, 131),
      const Offset(249, 162),
      const Offset(73, 160),
      const Offset(110, 205),
    ]),
  ),
  Constellation(
    name: "Cisne",
    color: const Color(0xFFA1BBD1),
    relativePosition: const Offset(0.20, 0.70),
    points: normalizeToHeight100([
      const Offset(1.5, 103.5),
      const Offset(28.5, 102.5),
      const Offset(51.5, 88.5),
      const Offset(70, 62.5),
      const Offset(58, 40.5),
      const Offset(95, 40.5),
      const Offset(101.5, 10.5),
      const Offset(107.5, 1.5),
      const Offset(90.5, 85),
      const Offset(113, 113),
    ]),
  ),
];

// ───────────────────────────────────────────────
// MAPAS DE INFORMACIÓN / IMÁGENES
// ───────────────────────────────────────────────

// Imágenes individuales
final Map<int, String> individualImages = {
  0: 'assets/images/bear.png',
  1: 'assets/images/cross.png',
  2: 'assets/images/draco.png',
  3: 'assets/images/pegasus.png',
  4: 'assets/images/phoenix.png',
  5: 'assets/images/swan.png',
};

// Imágenes de pares
final Map<String, String> pairImages = {
  "0_1": 'assets/images/wolf.png',
  "3_5": 'assets/images/unicorn.png',
  "2_4": 'assets/images/snake.png',
  "1_5": 'assets/images/crane.png',
  "3_4": 'assets/images/chimera.png',
  "0_2": 'assets/images/eagle.png',
  "4_5": 'assets/images/koi.png',
  "1_2": 'assets/images/turtle.png',
  "0_3": 'assets/images/fox.png',
  "2_5": 'assets/images/heron.png',
  "1_4": 'assets/images/tiger.png',
  "2_3": 'assets/images/cerberus.png',
  "0_4": 'assets/images/dolphin.png',
  "0_5": 'assets/images/whale.png',
  "1_3": 'assets/images/chameleon.png',
};
// Colores
  final Map<String, Color> constellationColors = {
    "Great Bear": const Color(0xFF9D2053),
    "Southern Cross": const Color(0xFFF8CA00),
    "Draco": const Color(0xFF23B8A9),
    "Pegasus": const Color(0xFF6664FF),
    "Phoenix": const Color(0xFFD43F00),
    "Swan": const Color(0xFFA1BBD1),
    "Wolf": const Color(0xFFB44B3E),
    "Unicorn": const Color(0xFF757AF4),
    "Serpent": const Color(0xFF4F9A7F),
    "Crane": const Color(0xFFCDC369),
    "Chimera": const Color(0xFFB94840),
    "Aquila": const Color(0xFF429294),
    "Koi": const Color(0xFFC75E34),
    "Turtle": const Color(0xFF8EC155),
    "Fox": const Color(0xFF8242A9),
    "Heron": const Color(0xFF62BABD),
    "Tiger": const Color(0xFFE68500),
    "Cerberus": const Color(0xFF458ED4),
    "Dolphin": const Color(0xFFB9302A),
    "Whale": const Color(0xFF9F6E92),
    "Chameleon": const Color(0xFF8B7EBF),
  };


// Información (nombre, emoción, simbolismo...)
final Map<String, Map<String, dynamic>> constellationInfo = {
    // --- Singles ---
    "0": {
      "name": "Great Bear\n(北斗七星)",
      "emotion": "Protection",
      "meaning": "I roam the heavens, carrying ancient stories in my steps.",
      "symbolism": "Protection, legacy, and connection to tradition."
    },
    "1": {
      "name": "Southern Cross\n(南十字星)",
      "emotion": "Guidance",
      "meaning": "I align my heart to the stars, finding my way through the dark.",
      "symbolism": "Guidance, faith, and the search for one’s true path."
    },
    "2": {
      "name": "Draco\n(竜座)",
      "emotion": "Power",
      "meaning": "I guard the constellations, breathing storms into the night sky.",
      "symbolism": "Power, wisdom, and the will to protect what matters."
    },
    "3": {
      "name": "Pegasus\n(天馬座)",
      "emotion": "Ambition",
      "meaning": "I leap beyond the horizon, chasing the winds of impossible dreams.",
      "symbolism": "Boundless ambition, freedom of spirit, and the courage to explore beyond limits."
    },
    "4": {
      "name": "Phoenix\n(不死鳥座)",
      "emotion": "Renewal",
      "meaning": "From my own ashes, I carry the fire that will guide me home.",
      "symbolism": "Renewal, courage after loss, and embracing change."
    },
    "5": {
      "name": "Swan\n(白鳥座)",
      "emotion": "Serenity",
      "meaning": "I drift through quiet waters, carrying grace where silence blooms.",
      "symbolism": "Elegance, serenity, and the beauty of unspoken emotions."
    },

    // --- Pairs ---
    "0_1": {
      "name": "Wolf\n(狼座)",
      "emotion": "Loyalty",
      "meaning": "I roam beneath twin skies, loyal to the light that calls me home.",
      "symbolism": "Loyalty, courage, and guidance toward your true path."
    },
    "3_5": {
      "name": "Unicorn\n(一角獣座)",
      "emotion": "Wonder",
      "meaning": "I carry dreams upon my brow, untouched by the shadows that follow.",
      "symbolism": "Purity, idealism, and the pursuit of wonder."
    },
    "2_4": {
      "name": "Serpent\n(炎蛇座)",
      "emotion": "Passion",
      "meaning": "I weave through clouds of fire, each scale a spark of creation.",
      "symbolism": "Creativity, passion for making, and fearless expression."
    },
    "1_5": {
      "name": "Crane\n(鶴座)",
      "emotion": "Clarity",
      "meaning": "I stand still in mirrored waters, my mind unshaken by passing storms.",
      "symbolism": "Patience, clarity, and academic discipline."
    },
    "3_4": {
      "name": "Chimera\n(キメラ座)",
      "emotion": "Creativity",
      "meaning": "I weave fire into my thoughts, shaping impossible visions into reality.",
      "symbolism": "Creative intelligence and problem-solving."
    },
    "0_2": {
      "name": "Aquila\n(鷲座)",
      "emotion": "Insight",
      "meaning": "I soar on ancient winds, my gaze sharp upon hidden truths.",
      "symbolism": "Knowledge, insight, and deep focus."
    },
    "4_5": {
      "name": "Koi\n(鯉座)",
      "emotion": "Perseverance",
      "meaning": "I swim upstream toward the light, each scale catching the dawn.",
      "symbolism": "Perseverance, hope, and artistic refinement."
    },
    "1_2": {
      "name": "Turtle\n(玄武座)",
      "emotion": "Wisdom",
      "meaning": "I carry the weight of centuries, my steps slow but certain.",
      "symbolism": "Patience, wisdom, and deep life understanding."
    },
    "0_3": {
      "name": "Fox\n(天狐座)",
      "emotion": "Adaptability",
      "meaning": "I dance on the winds between worlds, clever and quick of mind.",
      "symbolism": "Adaptability, charm, and inspired problem-solving."
    },
    "2_5": {
      "name": "Heron\n(銀鷺座)",
      "emotion": "Reflection",
      "meaning": "I glide through the mists, seeking the still pond of truth.",
      "symbolism": "Calm clarity, inner reflection, and serenity."
    },
    "1_4": {
      "name": "Tiger\n(虎座)",
      "emotion": "Courage",
      "meaning": "I leap from the shadows with a roar, my heart fierce as flame.",
      "symbolism": "Boldness, leadership, and fearlessness in adversity."
    },
    "2_3": {
      "name": "Cerberus\n(ケルベロス座)",
      "emotion": "Guardianship",
      "meaning": "I watch three paths at once, unyielding at the gates of fate.",
      "symbolism": "Protection, loyalty, and vigilance against danger."
    },
    "0_4": {
      "name": "Dolphin\n(海豚)",
      "emotion": "Joy",
      "meaning": "I leap through starlit waves, carrying laughter in my wake.",
      "symbolism": "Joy in the present, playfulness, and emotional release."
    },
    "0_5": {
      "name": "Whale\n(鯨座)",
      "emotion": "Depth",
      "meaning": "I sing the ancient songs, carrying the ocean’s memory within me.",
      "symbolism": "Emotional depth, connection to nature, and timeless wisdom."
    },
    "1_3": {
      "name": "Chameleon\n(カメレオン座)",
      "emotion": "Flexibility",
      "meaning": "I change with the light, yet remain true to the shape of my soul.",
      "symbolism": "Adaptability, transformation, and self-discovery."
    },
  };


// ───────────────────────────────────────────────
// CONEXIONES ENTRE ESTRELLAS
// ───────────────────────────────────────────────
final Map<String, List<List<int>>> connections = {
  "Cruz del Sur": [
    [0, 1],
    [2, 3],
  ],
  "Osa Mayor": [
    [0, 1],
    [1, 2],
    [2, 3],
    [3, 4],
    [4, 5],
    [5, 6],
    [6, 3],
  ],
  "Draco": [
    [0, 1],
    [0,3],
    [1, 2],
    [2, 3],
    [2, 4],
    [4, 5],
    [5, 6],
    [6, 7],
    [7, 8],
    [8, 9],
    [9, 10],
    [10, 11],
    [11, 12],
    [12, 13],
    [13, 14],
  ],
  "Fenix": [
    [0, 1],
    [1, 2],
    [2, 3],
    [3, 4],
    [4, 5],
    [5, 6],
    [6, 7],
    [7, 8],
    [8, 9],
    [9, 10],
    [7, 12],
    [12, 11],
    [11, 4],
  ],
  "Pegaso": [
    [1, 0],
    [0, 5],
    [5, 12],
    [12, 11],
    [11, 10],
    [1, 2],
    [2, 5],
    [2, 6],
    [6, 7],
    [7, 8],
    [8, 9],
    [2, 3],
    [3, 4],
  ],
  "Cisne": [
    [0, 1],
    [1, 2],
    [2, 3],
    [3, 5],
    [5, 6],
    [6, 7],
    [4, 3],
    [3, 8],
    [8, 9],
  ],
};

// ───────────────────────────────────────────────
// FUNCION PARA BOUNDING BOX
// ───────────────────────────────────────────────
Rect getBoundingBox(List<Offset> points) {
  double minX = points.map((p) => p.dx).reduce(min);
  double maxX = points.map((p) => p.dx).reduce(max);
  double minY = points.map((p) => p.dy).reduce(min);
  double maxY = points.map((p) => p.dy).reduce(max);
  return Rect.fromLTRB(minX, minY, maxX, maxY);
}

// ───────────────────────────────────────────────
// PINTOR DE CONSTELACIONES
// ───────────────────────────────────────────────
class ConstellationPainter extends CustomPainter {
  final Constellation constellation;
  final Animation<double> animation;
  final String? emotion; // ✅ Ahora recibe emoción a pintar

  ConstellationPainter({
    required this.constellation,
    required this.animation,
    this.emotion,
  }) : super(repaint: animation);

  @override
  void paint(Canvas canvas, Size size) {
    final pos = Offset(
      size.width * constellation.relativePosition.dx,
      size.height * constellation.relativePosition.dy - 60,
    );

    final baseColor =
        constellation.isSelected ? constellation.color : Colors.white;

    final linePaint = Paint()
      ..color = baseColor.withOpacity(0.6)
      ..strokeWidth = 1.5;

    if (connections.containsKey(constellation.name)) {
      for (var pair in connections[constellation.name]!) {
        canvas.drawLine(
            pos + constellation.points[pair[0]],
            pos + constellation.points[pair[1]],
            linePaint);
      }
    }

    final starPaint = Paint()
      ..color = baseColor.withOpacity(0.9)
      ..style = PaintingStyle.fill;

    final glowPaint = Paint()
      ..color = baseColor.withOpacity(0.35)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8);

    for (final p in constellation.points) {
      final radius = 2.5 + sin(animation.value * pi) * 1.5;
      canvas.drawCircle(pos + p, radius + 6, glowPaint);
      canvas.drawCircle(pos + p, radius, starPaint);
    }

    // ✅ En vez del nombre, pintamos la emoción
    if (emotion != null && emotion!.isNotEmpty) {
      final textPainter = TextPainter(
        text: TextSpan(
          text: emotion,
          style: GoogleFonts.robotoMono(
            color: baseColor,
            fontSize: 12,
            fontWeight: FontWeight.bold,
          ),
        ),
        textDirection: TextDirection.ltr,
      );
      textPainter.layout();
      final textOffset =
          Offset(pos.dx - textPainter.width / 2, pos.dy + 60);
      textPainter.paint(canvas, textOffset);
    }
  }

  @override
  bool shouldRepaint(covariant ConstellationPainter oldDelegate) => true;
}

// ───────────────────────────────────────────────
// PINTOR GLOBAL
// ───────────────────────────────────────────────
class _AllConstellationsPainter extends CustomPainter {
  final Animation<double> animation;
  final List<Constellation> selected;

  _AllConstellationsPainter(this.animation, this.selected)
      : super(repaint: animation);

  @override
  void paint(Canvas canvas, Size size) {
    int? firstIndex;
    // ignore: unused_local_variable
    int? secondIndex;

    if (selected.isNotEmpty) {
      firstIndex = constellations.indexOf(selected.first);
      if (selected.length > 1) {
        secondIndex = constellations.indexOf(selected[1]);
      }
    }

    for (int i = 0; i < constellations.length; i++) {
      final c = constellations[i];
      String? emotion;

      if (selected.isEmpty) {
        // ✅ Caso 0 seleccionadas → emoción base
        emotion = constellationInfo["$i"]?["emotion"];

      } else if (selected.length == 1) {
        // ✅ Caso 1 seleccionada
        if (i == firstIndex) {
          // la primera mantiene su emoción base
          emotion = constellationInfo["$i"]?["emotion"];
        } else {
          // las demás muestran combinación con la primera
          final ordered = [firstIndex!, i]..sort();
          final key = "${ordered[0]}_${ordered[1]}";
          emotion = constellationInfo[key]?["emotion"] ?? "";
        }

      } else if (selected.length == 2) {
        // ✅ Caso 2 seleccionadas
        if (i == firstIndex) {
          // primera seleccionada mantiene emoción base
          emotion = constellationInfo["$i"]?["emotion"];
        } else {
          // todos (incluida la segunda) muestran combinación con la primera
          final ordered = [firstIndex!, i]..sort();
          final key = "${ordered[0]}_${ordered[1]}";
          emotion = constellationInfo[key]?["emotion"] ?? "";
        }
      }

      ConstellationPainter(
        constellation: c,
        animation: animation,
        emotion: emotion,
      ).paint(canvas, size);
    }
  }

  @override
  bool shouldRepaint(covariant _AllConstellationsPainter oldDelegate) => true;
}



// ───────────────────────────────────────────────
// UI PRINCIPAL
// ───────────────────────────────────────────────
class CelestialSignalPage extends StatefulWidget {
  final String sessionId;
  const CelestialSignalPage({super.key, required this.sessionId});

  @override
  State<CelestialSignalPage> createState() => _CelestialSignalPageState();
}

class _CelestialSignalPageState extends State<CelestialSignalPage>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  final List<Constellation> _selected = [];

  @override
  void initState() {
    super.initState();
    _controller =
        AnimationController(vsync: this, duration: const Duration(seconds: 2))
          ..repeat(reverse: true);

    // 🔄 Intentar sincronizar cache al abrir la pantalla
    _syncCachedSessions();
  }

  // ============================================================
  // 🔌 Función para verificar conexión a internet
  // ============================================================
  Future<bool> _isOnline() async {
    final result = await Connectivity().checkConnectivity();
    return result != ConnectivityResult.none;
  }

  // ============================================================
  // ☁️ Función para guardar emoción de constelación (online/offline)
  // ============================================================
  // ============================================================
// ☁️ Guardar emoción de constelación (online/offline)
// ============================================================
Future<void> _saveConstellationEmotion(String emotion) async {
  final user = FirebaseAuth.instance.currentUser;
  final uid = user?.uid ?? "guest";
  final sessionId = widget.sessionId;

  try {
    final online = await _isOnline();
    final prefs = await SharedPreferences.getInstance();

    // ✅ Usamos una clave separada para evitar mezclar emociones antiguas
    final key = 'cached_constellation_emotions_$sessionId';

    if (online) {
      // ☁️ Guardar en Firestore dentro de la sesión
      final docRef = FirebaseFirestore.instance
          .collection("users")
          .doc(uid)
          .collection("sessions")
          .doc(sessionId);

      await docRef.set({
        "userId": uid,
        "sessionId": sessionId,
        "timestamp": FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      await docRef.collection("constellation").add({
        "emotion": emotion,
        "source": "Constellation",
        "timestamp": FieldValue.serverTimestamp(),
      });

      print("☁️ Emoción de constelación guardada ONLINE: $emotion ($sessionId)");

      // ✅ Limpieza local si estaba cacheada
      await prefs.remove(key);
    } else {
      // 💾 Guardar localmente (offline)
      final existing = prefs.getStringList(key) ?? [];
      existing.add(emotion);
      await prefs.setStringList(key, existing);

      // Registrar sesión cacheada (si no existe)
      final cachedSessions = prefs.getStringList('cached_sessions') ?? [];
      if (!cachedSessions.contains(sessionId)) {
        cachedSessions.add(sessionId);
        await prefs.setStringList('cached_sessions', cachedSessions);
      }

      print("📴 Emoción de constelación guardada OFFLINE: $emotion ($sessionId)");
    }
  } catch (e) {
    print("❌ Error guardando emoción de constelación: $e");
  }
}


  // ============================================================
  // 🔄 Sincronizar sesiones cacheadas (cuando vuelve la conexión)
  // ============================================================
  // ============================================================
// 🔄 Sincronizar sesiones cacheadas (cuando vuelve la conexión)
// ============================================================
  Future<void> _syncCachedSessions() async {
    final prefs = await SharedPreferences.getInstance();
    final cachedSessions = prefs.getStringList('cached_sessions') ?? [];
    if (cachedSessions.isEmpty) return;

    if (await _isOnline()) {
      final uid = FirebaseAuth.instance.currentUser?.uid ?? "guest";

      for (final sessionId in cachedSessions) {
        // ✅ Usamos la clave correcta para constellation
        final emotions =
            prefs.getStringList('cached_constellation_emotions_$sessionId') ?? [];
        if (emotions.isEmpty) continue;

        try {
          final docRef = FirebaseFirestore.instance
              .collection("users")
              .doc(uid)
              .collection("sessions")
              .doc(sessionId);

          await docRef.set({
            "userId": uid,
            "sessionId": sessionId,
            "timestamp": FieldValue.serverTimestamp(),
          }, SetOptions(merge: true));

          for (final emotion in emotions) {
            await docRef.collection("constellation").add({
              "emotion": emotion,
              "source": "Constellation",
              "timestamp": FieldValue.serverTimestamp(),
            });
          }

          await prefs.remove('cached_constellation_emotions_$sessionId');
          print("✅ Sesión sincronizada correctamente: $sessionId (${emotions.length} emociones)");
        } catch (e) {
          print("⚠️ Error sincronizando sesión $sessionId: $e");
        }
      }

      await prefs.remove('cached_sessions');
    }
  }


  void _handleTap(TapDownDetails details, Size size) {
    for (final c in constellations) {
      final pos = Offset(
        size.width * c.relativePosition.dx,
        size.height * c.relativePosition.dy - 60,
      );
      final localBox = getBoundingBox(c.points);
      final screenBox = localBox.shift(pos).inflate(30);
      if (screenBox.contains(details.localPosition)) {
        setState(() {
          if (_selected.contains(c)) {
            _selected.remove(c);
            c.isSelected = false;
            if (_selected.isEmpty) {
              for (var cc in constellations) {
                cc.isSelected = false;
              }
            }
          } else {
            if (_selected.length < 2) {
              _selected.add(c);
              c.isSelected = true;
            }
          }
        });
        break;
      }
    }
  }


      @override
Widget build(BuildContext context) {
  return Scaffold(
    backgroundColor: const Color(0XFF010B19),
    body: Column(
      children: [
        const SizedBox(height: 40),
        Navbar(
          username: "Jay Walker",
          title: "Lightning Ninja",
          subtitle: "Stellar Emotions",
          profileImage: "assets/images/Jay.jpg",
        ),
        Expanded(
          child: SingleChildScrollView(
            child: SizedBox(
              height: MediaQuery.of(context).size.height * 1,
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final canvasSize =
                      Size(constraints.maxWidth, constraints.maxHeight);

                  // posiciones de Pegaso y Cruz del Sur
                  final pegaso =
                      constellations.firstWhere((c) => c.name == "Pegaso");
                  final pegasoPos = Offset(
                    canvasSize.width * pegaso.relativePosition.dx,
                    canvasSize.height * pegaso.relativePosition.dy - 60,
                  );
                  final cruzDelSur = constellations
                      .firstWhere((c) => c.name == "Cruz del Sur");
                  final cruzPos = Offset(
                    canvasSize.width * cruzDelSur.relativePosition.dx,
                    canvasSize.height * cruzDelSur.relativePosition.dy - 60,
                  );

                  // selección actual
                  String selectionKey = "";
                  Map<String, dynamic>? info;
                  String defaultImage = "assets/images/constellation.png";
                  String? centerImagePath;
                  Color displayColor = Colors.white;
                  String displayName = "";

                  if (_selected.isEmpty) {
                    selectionKey = "";
                    info = null;
                    centerImagePath = defaultImage;
                    displayColor = Colors.white;
                    displayName = "";
                  } else if (_selected.length == 1) {
                    final idx = constellations.indexOf(_selected.first);
                    selectionKey = "$idx";
                    info = constellationInfo[selectionKey];
                    centerImagePath = individualImages[idx] ?? defaultImage;
                    displayName =
                        info != null ? info["name"].toString().split("\n")[0] : "";
                    displayColor =
                        constellationColors[displayName] ?? Colors.white;
                  } else {
                    final i1 = constellations.indexOf(_selected[0]);
                    final i2 = constellations.indexOf(_selected[1]);
                    final ordered = [i1, i2]..sort();
                    selectionKey = "${ordered[0]}_${ordered[1]}";
                    info = constellationInfo[selectionKey];
                    centerImagePath = pairImages[selectionKey] ?? defaultImage;
                    displayName =
                        info != null ? info["name"].toString().split("\n")[0] : "";
                    displayColor =
                        constellationColors[displayName] ?? Colors.white;
                  }

                  return GestureDetector(
                    onTapDown: (details) => _handleTap(details, canvasSize),
                    child: Stack(
                      children: [
                        // 🎨 Canvas
                        CustomPaint(
                          size: canvasSize,
                          painter:
                              _AllConstellationsPainter(_controller, _selected),
                        ),

                        // ─────────── Círculo central con orejas + rectángulo ───────────
                        Positioned(
                          top: pegasoPos.dy + 50,
                          left: 0,
                          right: 0,
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Center(
                                child: Stack(
                                  clipBehavior: Clip.none,
                                  children: [
                                    SizedBox(
                                      width: 80,
                                      height: 80,
                                      child: Stack(
                                        alignment: Alignment.center,
                                        children: [
                                          Container(
                                            decoration: BoxDecoration(
                                              shape: BoxShape.circle,
                                              border: Border.all(
                                                color: Colors.white,
                                                width: 1.5,
                                              ),
                                            ),
                                          ),
                                          Image.asset(
                                            centerImagePath,
                                            width: 56,
                                            height: 56,
                                            fit: BoxFit.contain,
                                          ),
                                        ],
                                      ),
                                    ),
                                    Positioned(
                                      left: -7,
                                      top: 33,
                                      child: Container(
                                        width: 14,
                                        height: 14,
                                        decoration: const BoxDecoration(
                                          color: Colors.white,
                                          shape: BoxShape.circle,
                                        ),
                                      ),
                                    ),
                                    Positioned(
                                      right: -7,
                                      top: 33,
                                      child: Container(
                                        width: 14,
                                        height: 14,
                                        decoration: const BoxDecoration(
                                          color: Colors.white,
                                          shape: BoxShape.circle,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 5),
                              AnimatedSwitcher(
                                duration: const Duration(milliseconds: 250),
                                switchInCurve: Curves.easeOut,
                                switchOutCurve: Curves.easeIn,
                                transitionBuilder: (child, animation) {
                                  return FadeTransition(
                                    opacity: animation,
                                    child: SlideTransition(
                                      position: Tween<Offset>(
                                        begin: const Offset(0, 0.01),
                                        end: Offset.zero,
                                      ).animate(animation),
                                      child: child,
                                    ),
                                  );
                                },
                                child: Container(
                                  key: ValueKey(selectionKey),
                                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                                  margin: const EdgeInsets.symmetric(horizontal: 16),
                                  decoration: BoxDecoration(
                                    color: const Color(0XFF010B19),
                                    borderRadius: BorderRadius.circular(8),
                                    border: _selected.isEmpty
                                        ? null // 🚀 Sin stroke si no hay selección
                                        : Border.all(color: Colors.white, width: 1.5),
                                  ),
                                  child: _selected.isEmpty
                                      ? Text(
                                          "How do you want to feel today?",
                                          style: GoogleFonts.encodeSansExpanded(
                                            color: Colors.white,
                                            fontSize: 14,
                                            fontWeight: FontWeight.bold,
                                          ),
                                          textAlign: TextAlign.center,
                                        )
                                      : Column(
                                          crossAxisAlignment: CrossAxisAlignment.center,
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Text(
                                              displayName,
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                              textAlign: TextAlign.center,
                                              style: GoogleFonts.encodeSansExpanded(
                                                color: displayColor,
                                                fontSize: 12,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                            const SizedBox(height: 6),
                                            Text(
                                              info?["meaning"] ?? "",
                                              maxLines: 2,
                                              overflow: TextOverflow.ellipsis,
                                              textAlign: TextAlign.center,
                                              style: GoogleFonts.robotoMono(
                                                color: Colors.white,
                                                fontSize: 10,
                                              ),
                                            ),
                                            const SizedBox(height: 6),
                                            Text(
                                              info?["symbolism"] ?? "",
                                              maxLines: 2,
                                              overflow: TextOverflow.ellipsis,
                                              textAlign: TextAlign.center,
                                              style: GoogleFonts.robotoMono(
                                                color: displayColor,
                                                fontSize: 9,
                                              ),
                                            ),
                                          ],
                                        ),
                                ),
                              ),

                            ],
                          ),
                        ),

                        // ─────────── Botón debajo de Cruz del Sur ───────────
                        Positioned(
                          top: cruzPos.dy + 100,
                          left: cruzPos.dx - 150,
                          child: GestureDetector(
                            onTap: () async {
                              String? emotionToSave;
                              if (_selected.isEmpty) {
                                print("⚠️ Ninguna constelación seleccionada");
                                return;
                              }

                              if (_selected.length == 1) {
                                final idx = constellations.indexOf(_selected.first);
                                emotionToSave = constellationInfo["$idx"]?["emotion"] as String?;
                              } else {
                                final i1 = constellations.indexOf(_selected[0]);
                                final i2 = constellations.indexOf(_selected[1]);
                                final ordered = [i1, i2]..sort();
                                final key = "${ordered[0]}_${ordered[1]}";
                                emotionToSave = constellationInfo[key]?["emotion"] as String?;
                              }

                              if (emotionToSave == null || emotionToSave.isEmpty) {
                                print("⚠️ No se encontró emoción para la selección actual");
                                return;
                              }

                              print("🌟 Emoción de constelación detectada: $emotionToSave");
                              // Guardar en segundo plano (online/offline)
                              unawaited(_saveConstellationEmotion(emotionToSave));

                              // Limpiar selección visual
                              setState(() {
                                for (var c in constellations) c.isSelected = false;
                                _selected.clear();
                              });

                              // Avanzar de página inmediatamente
                              Navigator.push(
                                context,
                                MaterialPageRoute(builder: (_) => GenreSelectorPage()),
                              );
                            },
                            child: Container(
                              width: 300,
                              padding: const EdgeInsets.symmetric(
                                  vertical: 12, horizontal: 10),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(
                                    color: Colors.white, width: 1.5),
                                color: Colors.transparent,
                              ),
                              child: const Text(
                                "Choose the Colors of Your Sound",
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontFamily: "RobotoMono",
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ),
        ),
      ],
    ),
  );
}


  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
}
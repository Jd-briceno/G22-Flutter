import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:melodymuse/components/navbar.dart';
import 'package:melodymuse/components/one_minute_zen_modal.dart';
import 'package:melodymuse/pages/celestial_signal.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:firebase_analytics/observer.dart';
import 'package:melodymuse/services/sol_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:connectivity_plus/connectivity_plus.dart';

class SoulSyncTerminal extends StatefulWidget {
  const SoulSyncTerminal({Key? key}) : super(key: key);

  @override
  State<SoulSyncTerminal> createState() => _SoulSyncTerminal();
}

// 📍 Frases poéticas para cada emoción
const Map<String, String> emotionPhrases = {
  // Slider
  "JOY": "A spark that warms everything it touches",
  "FEAR": "Shadows stretch longer inside my chest",
  "SADNESS": "Raindrops echo in my veins",

  // Perilla 1
  "Anger": "A fire with nowhere to escape",
  "Disgust": "The bitter taste of rejection",
  "Anxiety": "Waves rising faster than I can breathe",
  "Envy": "A mirror cracked by longing",

  // Perilla 2
  "Love": "Two orbits colliding in harmony",
  "Embarrassment": "A blush louder than many words",
  "Boredom": "Time drips like thick honey",
};

// 📍 Colores exclusivos del slider
const Map<String, Color> sliderEmotionColors = {
  "JOY": Color(0xFFFECA39),
  "FEAR": Color(0xFF944FBC),
  "SADNESS": Color(0xFF2390D3),
};

// 📍 Colores exclusivos de la perilla 1
const Map<String, Color> knobEmotionColors = {
  "Anger": Color(0xFFFF595D),
  "Disgust": Color(0xFF91C836),
  "Anxiety": Color(0xFFFF924D),
  "Envy": Color(0xFF34C985),
};

// 📍 Colores exclusivos de la Perilla 2
const Map<String, Color> knob2EmotionColors = {
  "Love": Color(0xFFB53E8E),
  "Embarrassment": Color(0xFFB53F5F),
  "Boredom": Color(0xFFA08888),
};

class _SoulSyncTerminal extends State<SoulSyncTerminal>
    with SingleTickerProviderStateMixin {
  double _thumbY = (21.2913 + 571.797 - 68.4299) * 0.758;
  String? _selectedEmotion;
  List<String> _selectedEmotions = []; // 📍 Registro de emociones únicas
  final List<String> hardEmotions = [
    "ANGER", "FEAR", "ANXIETY", "ENVY", "SADNESS", "DISGUST"
  ];
  late AnimationController _controller;
  late Animation<double> _thumbAnimation;
  final FirebaseAnalytics _analytics = FirebaseAnalytics.instance;
  late DateTime _entryTime;

  static const railTop = 21.2913;
  static const railHeight = 571.797;
  static const railBottom = railTop + railHeight;

  final double scale = 0.758;

  bool _hasHardEmotions() {
    return _selectedEmotions.any((e) => hardEmotions.contains(e.toUpperCase()));
  }

  Future<bool> _shouldShowZen() async {
    final prefs = await SharedPreferences.getInstance();

    if (!_hasHardEmotions()) return false;

    final skipToday = prefs.getBool("skipZenToday") ?? false;
    if (skipToday) return false;

    final last = prefs.getInt("lastZenTime") ?? 0;
    final now = DateTime.now().millisecondsSinceEpoch;

    if (now - last < 4 * 60 * 60 * 1000) {
      return false;
    }

    return true;
  }

  Future<void> _markZenCompleted() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt("lastZenTime", DateTime.now().millisecondsSinceEpoch);
  }

  Future<void> _skipZenForToday() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool("skipZenToday", true);
  }

  Future<String?> _showOneMinuteZen(BuildContext context) async {
    String finalText;

    // Elegir emoción difícil principal
    final emotion = _selectedEmotions.firstWhere(
      (e) => hardEmotions.contains(e.toUpperCase()),
      orElse: () => "NEUTRAL",
    );

    try {
      final sol = SolService();
      finalText = await sol.generateZenMessage(_selectedEmotions);
    } catch (_) {
      finalText = "Let your thoughts settle like ink in water.\nBreathe softly.";
    }

    return await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => OneMinuteZenModal(
        zenText: finalText,
        emotion: emotion,
      ),
    );
  }

  // ============================================================
// 🔌 Estrategia de conectividad eventual (offline-first)
// ============================================================

// 🔍 Verificar si hay conexión activa
Future<bool> _isOnline() async {
  final result = await Connectivity().checkConnectivity();
  return result != ConnectivityResult.none;
}

// 💾 Guardar emoción localmente si no hay conexión
Future<void> _cacheEmotionLocally(String emotion) async {
  final prefs = await SharedPreferences.getInstance();
  final cached = prefs.getStringList('cached_emotions') ?? [];
  cached.add(emotion);
  await prefs.setStringList('cached_emotions', cached);
  print("📴 Emoción guardada offline: $emotion");
}

// ☁️ Guardar emoción en Firestore si hay conexión
Future<void> _saveEmotionOnline(String emotion) async {
  await FirebaseFirestore.instance.collection('emotions').add({
    "emotion": emotion,
    "timestamp": FieldValue.serverTimestamp(),
    "userId": _getCurrentUserId(),
  });
  print("☁️ Emoción guardada online: $emotion");
}

// 🔄 Sincronizar emociones guardadas localmente al recuperar conexión
Future<void> _syncCachedEmotions() async {
  final prefs = await SharedPreferences.getInstance();
  final cached = prefs.getStringList('cached_emotions') ?? [];
  if (cached.isEmpty) return;

  if (await _isOnline()) {
    for (final e in cached) {
      await _saveEmotionOnline(e);
    }
    await prefs.remove('cached_emotions');
    print("🔄 Emociones offline sincronizadas con Firestore (${cached.length})");
  }
}

  //Usuario actual
  String? _getCurrentUserId() {
    final user = FirebaseAuth.instance.currentUser;
    return user?.uid ?? "guest";
  }


  /// Guarda UNA emoción (documento por emoción)
  Future<void> _saveEmotionToFirestore(String emotion, String source) async {
    try {
      await FirebaseFirestore.instance.collection("emotions").add({
        "emotion": emotion,
        "source": source,
        "timestamp": FieldValue.serverTimestamp(),
        "userId": "guest", // aquí reemplaza si usas Firebase Auth
      });

      print("✅ Emoción guardada en Firestore: $emotion ($source)");
    } catch (e) {
      print("❌ Error al guardar emoción: $e");
    }
  }

  /// Guarda la lista de emociones seleccionadas (botón Ready to Ship?)
  Future<void> _saveEmotionsToFirestore() async {
    if (_selectedEmotions.isEmpty) {
      print("⚠️ No hay emociones para enviar.");
      return;
    }

    try {
      final online = await _isOnline();

      if (online) {
        // 🌐 Guardamos directamente en Firestore
        FirebaseFirestore.instance.collection("emotions_collections").add({
          "emotions": _selectedEmotions,
          "timestamp": FieldValue.serverTimestamp(),
          "userId": _getCurrentUserId(),
        }).then((_) {
          print("✅ Lista de emociones guardada ONLINE: $_selectedEmotions");
        }).catchError((e) {
          print("❌ Error guardando online: $e");
        });
      } else {
        // 💾 Guardamos localmente (modo offline)
        final prefs = await SharedPreferences.getInstance();
        final cachedCollections =
            prefs.getStringList('cached_emotion_collections') ?? [];
        cachedCollections.add(_selectedEmotions.join('|'));
        await prefs.setStringList('cached_emotion_collections', cachedCollections);
        print("📴 Lista de emociones guardada OFFLINE: $_selectedEmotions");
      }
    } catch (e) {
      print("❌ Error al guardar emociones: $e");
    }
  }

  // 🔄 Sincronizar colecciones de emociones guardadas offline
  Future<void> _syncCachedEmotionCollections() async {
    final prefs = await SharedPreferences.getInstance();
    final cached = prefs.getStringList('cached_emotion_collections') ?? [];
    if (cached.isEmpty) return;

    if (await _isOnline()) {
      for (final data in cached) {
        try {
          final emotions = data.split('|');
          await FirebaseFirestore.instance.collection("emotions_collections").add({
            "emotions": emotions,
            "timestamp": FieldValue.serverTimestamp(),
            "userId": _getCurrentUserId(),
          });
        } catch (e) {
          print("⚠️ Error subiendo colección cacheada: $e");
        }
      }
      await prefs.remove('cached_emotion_collections');
      print("🔄 Colecciones de emociones sincronizadas (${cached.length})");
    } else {
      print("⛔️ No hay conexión, no se sincronizan colecciones.");
    }
  }

  // 🔄 Sincronizar sesiones guardadas offline
  Future<void> _syncCachedSessions() async {
    final prefs = await SharedPreferences.getInstance();
    final cachedSessions = prefs.getStringList('cached_sessions') ?? [];
    if (cachedSessions.isEmpty) return;

    if (await _isOnline()) {
      for (final sessionId in cachedSessions) {
        final emotions = prefs.getStringList('cached_session_emotions_$sessionId') ?? [];
        if (emotions.isEmpty) continue;

        try {
          await FirebaseFirestore.instance
              .collection("users")
              .doc(_getCurrentUserId())
              .collection("sessions")
              .doc(sessionId)
              .set({
            "sessionId": sessionId,
            "userId": _getCurrentUserId(),
            "emotions": emotions,
            "timestamp": FieldValue.serverTimestamp(),
          });
          await prefs.remove('cached_session_emotions_$sessionId');
          print("✅ Sesión $sessionId sincronizada online.");
        } catch (e) {
          print("⚠️ Error al sincronizar sesión $sessionId: $e");
        }
      }

      await prefs.remove('cached_sessions');
    }
  }



  //Crear sesión
  Future<String?> _createSessionOnExit() async {
    if (_selectedEmotions.isEmpty) {
      print("⚠️ No hay emociones para guardar en sesión.");
      return null;
    }

    try {
      final uid = _getCurrentUserId();
      final sessionId = DateTime.now().millisecondsSinceEpoch.toString();

      // 💾 1️⃣ Guarda SIEMPRE localmente primero
      final prefs = await SharedPreferences.getInstance();

      final cachedSessions = prefs.getStringList('cached_sessions') ?? [];
      if (!cachedSessions.contains(sessionId)) {
        cachedSessions.add(sessionId);
        await prefs.setStringList('cached_sessions', cachedSessions);
      }

      await prefs.setStringList('cached_session_emotions_$sessionId', _selectedEmotions);

      print("📴 Sesión cacheada localmente: $sessionId");

      // 🌐 2️⃣ Si hay conexión real, sube en background (sin bloquear)
      if (await _isOnline()) {
        unawaited(_uploadSessionToFirestore(uid!, sessionId));
      }

      // 🔹 3️⃣ Analytics (también solo si hay red)
      try {
        if (await _isOnline()) {
          await FirebaseAnalytics.instance.logEvent(
            name: 'session_created',
            parameters: {
              'session_id': sessionId,
              'user_id': ?uid,
              'emotion_count': _selectedEmotions.length,
              'emotions': _selectedEmotions.join(', '),
            },
          );
          print("📊 Analytics: session_created -> $sessionId");
        }
      } catch (e) {
        print("⚠️ Error registrando evento en Analytics: $e");
      }

      return sessionId;
    } catch (e) {
      print("❌ Error al guardar sesión: $e");
      return null;
    }
  }

  /// 🔧 Función auxiliar: sube sesión si hay conexión
  Future<void> _uploadSessionToFirestore(String uid, String sessionId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final emotions = prefs.getStringList('cached_session_emotions_$sessionId') ?? [];

      await FirebaseFirestore.instance
          .collection("users")
          .doc(uid)
          .collection("sessions")
          .doc(sessionId)
          .set({
        "sessionId": sessionId,
        "userId": uid,
        "emotions": emotions,
        "timestamp": FieldValue.serverTimestamp(),
        "synced": true,
      });

      print("✅ Sesión sincronizada online: $sessionId");
    } catch (e) {
      print("⚠️ Error subiendo sesión online (queda en caché): $e");
    }
  }



/// 🔁 Intenta subir la sesión a Firestore si hay conexión (asincrónico)
Future<void> _trySyncSessionOnline(String uid, String sessionId, List<String> emotions) async {
  final online = await _isOnline();
  if (!online) {
    print("📡 Sin conexión, la sesión se sincronizará luego.");
    return;
  }

  try {
    await FirebaseFirestore.instance
        .collection("users")
        .doc(uid)
        .collection("sessions")
        .doc(sessionId)
        .set({
      "sessionId": sessionId,
      "userId": uid,
      "emotions": emotions,
      "timestamp": FieldValue.serverTimestamp(),
    });

    // Si subió bien, limpiamos el cache local
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('cached_session_emotions_$sessionId');
    print("✅ Sesión sincronizada online: $sessionId");

    // 🔹 Registrar evento en Analytics
    await FirebaseAnalytics.instance.logEvent(
      name: 'session_created',
      parameters: {
        'session_id': sessionId,
        'user_id': uid,
        'emotion_count': emotions.length,
        'emotions': emotions.join(', '),
      },
    );
    print("📊 Analytics: session_created -> $sessionId");

  } catch (e) {
    print("⚠️ Error al sincronizar sesión online: $e");
  }
}




  // Manejo centralizado: añade a historial y guarda en Firestore (padre)
  void _handleEmotionSelection(String emotion, String source) {
    if (emotion.isEmpty) return;

    final timeTaken = DateTime.now().difference(_entryTime).inMilliseconds;

    _setSelectedEmotion(emotion);
    _saveEmotionToFirestore(emotion, source);

    _analytics.logEvent(
      name: 'emotion_selected',
      parameters: {
        'emotion': emotion,
        'source': source,
        'user_id': ?_getCurrentUserId(),
        'time_taken_ms': timeTaken, // 💡 Tiempo hasta primera selección
      },
    );

    print("📊 Analytics: emotion_selected -> $emotion ($source) in ${timeTaken}ms");
  }

  // ========================================================
  // 📍 Al actualizar emoción → agregamos a la lista si no existe
  void _setSelectedEmotion(String? emotion) {
    if (emotion == null) return;

    setState(() {
      _selectedEmotion = emotion;
      if (!_selectedEmotions.contains(emotion)) {
        _selectedEmotions.add(emotion);
      }
    });

    print("✅ Emoción actual: $_selectedEmotion");
    print("📜 Historial: $_selectedEmotions");
  }

  @override
  void initState() {
    super.initState();
    _entryTime = DateTime.now();

    // 🎬 Inicialización de animación existente
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );

    // 🔁 Intentar sincronizar emociones pendientes al iniciar
    _syncCachedEmotions();
    _syncCachedEmotionCollections();
    _syncCachedSessions();

    // 🔔 Escuchar cambios de conectividad y sincronizar automáticamente
    Connectivity().onConnectivityChanged.listen((result) {
      if (result != ConnectivityResult.none) {
        _syncCachedEmotions();
        _syncCachedEmotionCollections();
        _syncCachedSessions();
      }
    });
  }

  void unawaited(Future<void> future) {} 
  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _updateThumb(double localY) {
    final clamped =
        localY.clamp(railTop * scale, (railBottom - 68.4299) * scale);

    // calculamos la emoción resultante
    final String? newEmotion;
    {
      final double savedThumbY = _thumbY;
      // temporalmente actualizamos para calcular
      final double tmpY = clamped;
      final sectionHeight = (railHeight * scale) / 24;
      final relativeIndex = ((railBottom * scale - tmpY - 68.4299 / 2) /
              sectionHeight)
          .clamp(0, 23)
          .floor();

      if (relativeIndex < 6) {
        newEmotion = null;
      } else if (relativeIndex < 12) {
        newEmotion = "FEAR";
      } else if (relativeIndex < 18) {
        newEmotion = "SADNESS";
      } else {
        newEmotion = "JOY";
      }
    }

    setState(() {
      _thumbY = clamped;
    });

    // Si la emoción cambió, la manejamos (padre guarda en Firestore)
    if (newEmotion != null && newEmotion != _selectedEmotion) {
      _handleEmotionSelection(newEmotion, "slider");
      print("🎚 Slider seleccionó: $newEmotion");
    }
  }

  void _jumpToEmotion(String emotion) {
    const thumbHeightBase = 68.4299;
    final thumbHeight = thumbHeightBase * scale;
    final sectionHeight = (railHeight * scale) / 24;

    double lineY;

    if (emotion == "FEAR") {
      lineY = railBottom * scale - (6 * sectionHeight);
    } else if (emotion == "SADNESS") {
      lineY = railBottom * scale - (12 * sectionHeight);
    } else if (emotion == "JOY") {
      lineY = railBottom * scale - (18 * sectionHeight);
    } else {
      return;
    }

    final targetY = lineY - thumbHeight / 2;

    _controller.stop();
    _thumbAnimation = Tween<double>(begin: _thumbY, end: targetY).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    )
      ..addListener(() {
        setState(() {
          _thumbY = _thumbAnimation.value;
        });
      });

    _controller.forward(from: 0);

    // Notificamos y guardamos
    _handleEmotionSelection(emotion, "slider");

    print("🎚 Jumped to emotion: $emotion");
  }

  String? _calculateEmotion() {
    final sectionHeight = (railHeight * scale) / 24;

    final relativeIndex = ((railBottom * scale - _thumbY - 68.4299 / 2) /
            sectionHeight)
        .clamp(0, 23)
        .floor();

    if (relativeIndex < 6) return null;
    if (relativeIndex < 12) return "FEAR";
    if (relativeIndex < 18) return "SADNESS";
    return "JOY";
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0XFF010B19),
      body: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 5),

            // 📍 Navbar arriba
            const Navbar(
              username: "Jay Walker",
              title: "Lightning Ninja",
              subtitle: "Stellar Emotions",
              profileImage: "assets/images/Jay.jpg",
            ),

            const SizedBox(height: 2),

            // 📍 Texto debajo del Navbar
            const Text(
              "How are you feeling today captain?",
              style: TextStyle(
                fontFamily: "RobotoMono",
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: Colors.white,
              ),
            ),

            const SizedBox(height: 15),

            // 📍 El resto ocupa el espacio restante
            Expanded(
              child: Center(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // =================== COLUMNA IZQUIERDA ===================
                    Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Rectángulo grande
                        SizedBox(
                          width: 190 * scale,
                          height: 206 * scale,
                          child: Stack(
                            alignment: Alignment.center,
                            children: [
                              CustomPaint(
                                size: Size(190 * scale, 206 * scale),
                                painter: RectPainter(radius: 39.5),
                              ),
                              Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  SizedBox(
                                    width: 120 * scale,
                                    height: 120 * scale,
                                    child: ClipRRect(
                                      borderRadius:
                                          BorderRadius.circular(12 * scale),
                                      child: _selectedEmotion == null
                                          ? Container(
                                              color: const Color(0xFF0A141F),
                                              child: Icon(Icons.mood,
                                                  color: Colors.white24,
                                                  size: 48 * scale),
                                            )
                                          : Image.asset(
                                              "assets/images/${_selectedEmotion!.toLowerCase()}.png",
                                              fit: BoxFit.cover,
                                              errorBuilder: (context, _, __) =>
                                                  Container(
                                                color: const Color(0xFF0A141F),
                                                alignment: Alignment.center,
                                                child: Icon(Icons.mood,
                                                    color: Colors.white24,
                                                    size: 48 * scale),
                                              ),
                                            ),
                                    ),
                                  ),
                                  if (_selectedEmotion != null) ...[
                                    Text(
                                      _selectedEmotion!,
                                      style: TextStyle(
                                        fontFamily: "RobotoMono",
                                        fontSize: 16 * scale,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.white,
                                      ),
                                    ),
                                    const SizedBox(height: 6),
                                    Text(
                                      emotionPhrases[_selectedEmotion!] ?? "",
                                      textAlign: TextAlign.center,
                                      style: TextStyle(
                                        fontFamily: "RobotoMono",
                                        fontSize: 12 * scale,
                                        fontStyle: FontStyle.italic,
                                        color: _getEmotionColor(_selectedEmotion!),
                                      ),
                                    ),
                                  ] else ...[
                                    Text(
                                      "Select an emotion",
                                      style: TextStyle(
                                        fontFamily: "RobotoMono",
                                        fontSize: 12 * scale,
                                        color: Colors.white54,
                                      ),
                                    ),
                                  ]
                                ],
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 5),

                        // Rectángulo chico con emociones seleccionadas
                        SizedBox(
                          width: 190 * scale,
                          height: 57 * scale,
                          child: Stack(
                            alignment: Alignment.center,
                            children: [
                              CustomPaint(
                                size: Size(190 * scale, 57 * scale),
                                painter: RectPainter(radius: 19.5),
                              ),
                              Padding(
                                padding: EdgeInsets.symmetric(horizontal: 6 * scale),
                                child: SingleChildScrollView(
                                  scrollDirection: Axis.horizontal,
                                  child: Row(
                                    children: _selectedEmotions.map((emotion) {
                                      return GestureDetector(
                                        onTap: () {
                                          setState(() {
                                            _selectedEmotions.remove(emotion);
                                          });
                                          print("🗑 Eliminada: $emotion");
                                        },
                                        child: Container(
                                          width: 50 * scale,
                                          height: 50 * scale, // 👈 cuadrado fijo
                                          margin: EdgeInsets.symmetric(horizontal: 3 * scale),
                                          decoration: BoxDecoration(
                                            borderRadius: BorderRadius.circular(6 * scale),
                                            image: DecorationImage(
                                              image: AssetImage("assets/images/${emotion.toLowerCase()}.png"),
                                              fit: BoxFit.cover,
                                            ),
                                          ),
                                        ),
                                      );
                                    }).toList(),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 10),

                        // Perilla 1 — el parent maneja guardado
                        EmotionKnob(
                          scale: scale,
                          onEmotionSelected: (e) => _handleEmotionSelection(e, "knob1"),
                        ),

                        const SizedBox(height: 10),

                        // Perilla 2 — el parent maneja guardado
                        EmotionKnob2(
                          scale: scale,
                          onEmotionSelected: (e) => _handleEmotionSelection(e, "knob2"),
                        ),
                      ],
                    ),

                    const SizedBox(width: 20),

                    // =================== COLUMNA DERECHA ===================
                    Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // 🎚 Slider
                        Transform.translate(
                          offset: const Offset(-2, -35),
                          child: GestureDetector(
                            onVerticalDragUpdate: (details) {
                              RenderBox box = context.findRenderObject() as RenderBox;
                              final local = box.globalToLocal(details.globalPosition);
                              _updateThumb(local.dy);
                            },
                            child: SizedBox(
                              width: 220 * scale,
                              height: 647 * scale,
                              child: Stack(
                                children: [
                                  CustomPaint(
                                    painter: SvgPainter(
                                      thumbY: _thumbY,
                                      scale: scale,
                                      selectedEmotion: _selectedEmotion,
                                    ),
                                    size: Size(220 * scale, 647 * scale),
                                  ),
                                  Positioned(
                                    left: 50 * scale,
                                    top: 437 * scale,
                                    child: GestureDetector(
                                      onTap: () => _jumpToEmotion("FEAR"),
                                      child: const Text(
                                        "FEAR",
                                        style: TextStyle(
                                          fontFamily: "RobotoMono",
                                          fontSize: 11,
                                          color: Colors.white,
                                        ),
                                      ),
                                    ),
                                  ),
                                  Positioned(
                                    left: 12 * scale,
                                    top: 289 * scale,
                                    child: GestureDetector(
                                      onTap: () => _jumpToEmotion("SADNESS"),
                                      child: const Text(
                                        "SADNESS",
                                        style: TextStyle(
                                          fontFamily: "RobotoMono",
                                          fontSize: 11,
                                          color: Colors.white,
                                        ),
                                      ),
                                    ),
                                  ),
                                  Positioned(
                                    left: 50 * scale,
                                    top: 142 * scale,
                                    child: GestureDetector(
                                      onTap: () => _jumpToEmotion("JOY"),
                                      child: const Text(
                                        "JOY",
                                        style: TextStyle(
                                          fontFamily: "RobotoMono",
                                          fontSize: 11,
                                          color: Colors.white,
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),

                        // 📍 Botón "Ready to Ship?"
                        Transform.translate(
                          offset: const Offset(-15, 0),
                          child: GestureDetector(
                            onTap: () async {
                              try {
                                // 1️⃣ Ver si toca mostrar el ritual zen
                                final showZen = await _shouldShowZen();

                                if (showZen) {
                                  final result = await _showOneMinuteZen(context);

                                  if (result == "skip") {
                                    await _skipZenForToday();
                                  } else if (result == "completed") {
                                    await _markZenCompleted();
                                  }
                                }

                                // 2️⃣ Flujo normal
                                final hasConnection = await _isOnline();

                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(
                                      hasConnection
                                          ? 'Conectado 🌐 — Guardando en la nube...'
                                          : 'Sin conexión 📴 — Guardando localmente...',
                                    ),
                                    backgroundColor: hasConnection ? Colors.green : Colors.orange,
                                    duration: const Duration(seconds: 2),
                                  ),
                                );

                                unawaited(_saveEmotionsToFirestore());

                                final sessionId = await _createSessionOnExit();
                                // === Nuevo evento: resumen de la sesión ===
                                try {
                                  final endTime = DateTime.now();
                                  final durationMs = endTime.difference(_entryTime).inMilliseconds;
                                  final sessionSummary = {
                                    "userId": _getCurrentUserId(),
                                    "sessionId": sessionId ?? 'offline_${DateTime.now().millisecondsSinceEpoch}',
                                    "emotionCount": _selectedEmotions.length,
                                    "durationMs": durationMs,
                                    "completedUnder5s": durationMs < 5000,
                                    "timestamp": FieldValue.serverTimestamp(),
                                  };

                                  await FirebaseFirestore.instance.collection("session_summaries").add(sessionSummary);

                                  print("📊 session_summary guardado: $sessionSummary");
                                } catch (e) {
                                  print("⚠️ Error al guardar session_summary: $e");
                                }

                                if (context.mounted) {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => CelestialSignalPage(
                                        sessionId: sessionId ??
                                            'offline_${DateTime.now().millisecondsSinceEpoch}',
                                      ),
                                    ),
                                  );
                                }
                              } catch (e) {
                                print("⚠️ Error ReadyToShip: $e");
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text('Error al guardar: $e'),
                                    backgroundColor: Colors.red,
                                  ),
                                );
                              }
                            },



                            child: SizedBox(
                              width: 191 * scale,
                              height: 40 * scale,
                              child: Stack(
                                alignment: Alignment.center,
                                children: [
                                  CustomPaint(
                                    size: Size(191 * scale, 40 * scale),
                                    painter: ButtonPainter(),
                                  ),
                                  Text(
                                    "Ready to Ship?",
                                    style: TextStyle(
                                      fontFamily: "RobotoMono",
                                      fontSize: 15,
                                      color: Colors.white,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// =================== RectPainter ===================
/// Pinta un rectángulo con fill #010B19 y stroke #B4B1B8, adaptándose al tamaño dado.
/// radius: radio (en unidades del SVG original; la clase la escala con el ancho real).
class RectPainter extends CustomPainter {
  final double radius; // radio en unidades originales (ej. 39.5 o 19.5)
  final Color fillColor;
  final Color strokeColor;

  RectPainter({
    required this.radius,
    this.fillColor = const Color(0xFF010B19),
    this.strokeColor = const Color(0xFFB4B1B8),
  });

  @override
  void paint(Canvas canvas, Size size) {
    // ajustamos radius en función del tamaño real (asumiendo ancho base 190)
    final double scaleFactor = size.width / 190.0;
    final double finalRadius = radius * scaleFactor;

    final Rect r = Rect.fromLTWH(0.5, 0.5, size.width - 1.0, size.height - 1.0);
    final RRect rr = RRect.fromRectAndRadius(r, Radius.circular(finalRadius));

    final Paint fill = Paint()..color = fillColor;
    final Paint stroke = Paint()
      ..color = strokeColor
      ..style = PaintingStyle.stroke;

    canvas.drawRRect(rr, fill);
    canvas.drawRRect(rr, stroke);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

//
// ========== SLIDER PAINTER ==========
class SvgPainter extends CustomPainter {
  final double thumbY;
  final double scale;
  final String? selectedEmotion;

  SvgPainter({required this.thumbY, required this.scale, this.selectedEmotion});

  @override
  void paint(Canvas canvas, Size size) {
    canvas.save();
    canvas.scale(scale);

    final Paint strokePaint = Paint()
      ..color = const Color(0xFFB4B1B8)
      ..style = PaintingStyle.stroke;

    final RRect outer = RRect.fromLTRBR(
      0.5,
      0.5,
      187,
      649,
      const Radius.circular(19.5),
    );
    canvas.drawRRect(outer, strokePaint);

    const double railX = 116.685;
    const double railWidth = 16.037;
    const double railTop = 21.2913;
    const double railHeight = 571.797;
    final double railBottom = railTop + railHeight;

    final Paint railInactive = Paint()..color = const Color(0xFF010B19);
    final Paint railActive = Paint()..color = const Color(0xFFE9E8EE);

    final RRect rail = RRect.fromLTRBR(
      railX,
      railTop,
      railX + railWidth,
      railBottom,
      const Radius.circular(8.01852),
    );
    canvas.drawRRect(rail, railInactive);
    canvas.drawRRect(rail, strokePaint);

    final RRect activeRail = RRect.fromLTRBR(
      railX,
      thumbY / scale + 34,
      railX + railWidth,
      railBottom,
      const Radius.circular(8.01852),
    );
    canvas.drawRRect(activeRail, railActive);

    final Paint circlePaint = Paint()..color = const Color(0xFFD9D9D9);
    for (final c in _circleOffsets()) {
      canvas.drawCircle(c, 3.40741, circlePaint);
    }

    final Paint linePaint = Paint()
      ..color = const Color(0xFFE9E8EE)
      ..strokeWidth = 2;
    for (final line in _lineOffsets()) {
      canvas.drawLine(line[0], line[1], linePaint);
    }

    // === VOLUME LABEL ===
    final textPainter = TextPainter(
      text: const TextSpan(
        text: "VOLUME",
        style: TextStyle(
          fontFamily: "RobotoMono",
          fontSize: 28,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();

    textPainter.paint(
      canvas,
      Offset(railX - (textPainter.width / 2) + railWidth / 2, railBottom + 10),
    );

    final Color thumbColor =
        sliderEmotionColors[selectedEmotion] ?? const Color(0xFFB4B1B8);
    final thumbPaint = Paint()..color = thumbColor;
    final thumbStroke = Paint()
      ..color = const Color(0xFF010B19)
      ..style = PaintingStyle.stroke;

    const double thumbHeight = 68.4299;
    const double thumbWidth = 43.2963;
    const double thumbLeft = 103.056;

    final RRect thumb = RRect.fromLTRBR(
      thumbLeft,
      thumbY / scale,
      thumbLeft + thumbWidth,
      thumbY / scale + thumbHeight,
      const Radius.circular(7.5),
    );
    canvas.drawRRect(thumb, thumbPaint);
    canvas.drawRRect(thumb, thumbStroke);

    canvas.restore();
  }

  List<List<Offset>> _lineOffsets() => [
        [const Offset(92.3335, 446.05), const Offset(107.667, 446.05)],
        [const Offset(143.444, 446.05), const Offset(158.778, 446.05)],
        [const Offset(77, 298.511), const Offset(102.556, 298.511)],
        [const Offset(143.444, 298.511), const Offset(169, 298.511)],
        [const Offset(92.3335, 151.84), const Offset(107.667, 151.84)],
        [const Offset(143.444, 151.84), const Offset(158.778, 151.84)],
      ];

  List<Offset> _circleOffsets() => [
        const Offset(102.555, 465.079),
        const Offset(102.555, 489.411),
        const Offset(102.555, 513.712),
        const Offset(102.555, 538.012),
        const Offset(102.555, 560.577),
        const Offset(102.555, 581.502),
        const Offset(102.555, 314.069),
        const Offset(102.555, 338.401),
        const Offset(102.555, 362.702),
        const Offset(102.555, 387.002),
        const Offset(102.555, 409.567),
        const Offset(102.555, 430.492),
        const Offset(102.555, 166.53),
        const Offset(102.555, 190.863),
        const Offset(102.555, 215.163),
        const Offset(102.555, 239.464),
        const Offset(102.555, 262.028),
        const Offset(102.555, 282.953),
        const Offset(102.555, 20.7272),
        const Offset(102.555, 45.0598),
        const Offset(102.555, 69.3603),
        const Offset(102.555, 93.6608),
        const Offset(102.555, 116.226),
        const Offset(102.555, 137.15),
        const Offset(146.852, 20.7272),
        const Offset(146.852, 45.0598),
        const Offset(146.852, 69.3603),
        const Offset(146.852, 93.6608),
        const Offset(146.852, 116.226),
        const Offset(146.852, 137.15),
        const Offset(146.852, 166.53),
        const Offset(146.852, 190.863),
        const Offset(146.852, 215.163),
        const Offset(146.852, 239.464),
        const Offset(146.852, 262.028),
        const Offset(146.852, 282.953),
        const Offset(146.852, 314.069),
        const Offset(146.852, 338.401),
        const Offset(146.852, 362.702),
        const Offset(146.852, 387.002),
        const Offset(146.852, 409.567),
        const Offset(146.852, 430.492),
        const Offset(146.852, 465.079),
        const Offset(146.852, 489.411),
        const Offset(146.852, 513.712),
        const Offset(146.852, 538.012),
        const Offset(146.852, 560.577),
        const Offset(146.852, 581.502),
      ];

  @override
  bool shouldRepaint(covariant SvgPainter oldDelegate) =>
      oldDelegate.thumbY != thumbY ||
      oldDelegate.scale != scale ||
      oldDelegate.selectedEmotion != selectedEmotion;
}

/// ========== PERILLA 1 (ANGER, ENVY, DISGUST, ANXIETY) ==========
class EmotionKnob extends StatefulWidget {
  final double scale;
  final Function(String) onEmotionSelected; // 📍 callback
  const EmotionKnob({
    Key? key,
    required this.scale,
    required this.onEmotionSelected,
  }) : super(key: key);

  @override
  State<EmotionKnob> createState() => _EmotionKnobState();
}

class _EmotionKnobState extends State<EmotionKnob>
    with SingleTickerProviderStateMixin {
  double _angle = pi / 2;
  String? _selectedEmotion;
  late AnimationController _controller;
  Animation<double>? _angleAnimation;

  final Map<String, double> emotionAngles = {
    "Anger": -pi / 4,
    "Anxiety": pi / 4,
    "Disgust": 3 * pi / 4,
    "Envy": -3 * pi / 4,
  };

  @override
  void initState() {
    super.initState();
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      FirebaseFirestore.instance.collection('mood_playlist_events').add({
        'user_id': user.uid,
        'mode': 'manual',
        'timestamp': DateTime.now().toIso8601String(),
      }).then((_) {
        print("📝 mood_playlist_event (manual) registrado");
      }).catchError((e) {
        print("❌ Error guardando evento manual: $e");
      });
    }
    _controller =
        AnimationController(vsync: this, duration: const Duration(milliseconds: 400));
  }
  

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _animateToAngle(double targetAngle) {
    double start = _angle;
    double end = targetAngle;
    double diff = (end - start).abs();
    if (diff > pi) {
      if (end > start) {
        start += 2 * pi;
      } else {
        end += 2 * pi;
      }
    }

    _controller.stop();
    _angleAnimation = Tween<double>(begin: start, end: end).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    )..addListener(() {
        setState(() {
          _angle = _angleAnimation!.value % (2 * pi);
        });
      });

    _controller.forward(from: 0);
  }

  void _updateEmotionFromAngle() {
    String? closest = _selectedEmotion;
    double minDiff = double.infinity;

    emotionAngles.forEach((emotion, targetAngle) {
      double diff = (targetAngle - _angle).abs();
      if (diff > pi) diff = 2 * pi - diff;
      if (diff < minDiff) {
        minDiff = diff;
        closest = emotion;
      }
    });

    if (closest != _selectedEmotion) {
      setState(() {
        _selectedEmotion = closest;
      });
      widget.onEmotionSelected(_selectedEmotion!);
      print("🎛 Perilla seleccionó: $_selectedEmotion");
    }
  }

  void _onPanUpdate(DragUpdateDetails details, Offset center) {
    final local = details.localPosition;
    final dx = local.dx - center.dx;
    final dy = local.dy - center.dy;
    final angle = atan2(dy, dx);

    setState(() {
      _angle = angle;
    });

    _updateEmotionFromAngle();
  }

  void _onPanEnd() {
    if (_selectedEmotion == null) return;
    String closest = _selectedEmotion!;
    double targetAngle = emotionAngles[closest]!;
    _animateToAngle(targetAngle);
    widget.onEmotionSelected(_selectedEmotion!);
    // NO llamamos a _saveEmotionToFirestore aquí: el padre lo hará
  }

  void _onTapEmotion(String emotion) {
    _animateToAngle(emotionAngles[emotion]!);
    setState(() {
      _selectedEmotion = emotion;
    });
    widget.onEmotionSelected(_selectedEmotion!);
    print("🎛 Perilla seleccionó: $_selectedEmotion");
  }

  @override
  Widget build(BuildContext context) {
    final double size = 130 * widget.scale;
    final Offset center = Offset(size / 2, size / 2);

    return SizedBox(
      width: size + 60,
      height: size + 60,
      child: Stack(
        alignment: Alignment.center,
        children: [
          GestureDetector(
            onPanUpdate: (details) => _onPanUpdate(details, center),
            onPanEnd: (_) => _onPanEnd(),
            child: CustomPaint(
              size: Size(size, size),
              painter: KnobPainter(
                angle: _angle,
                selectedEmotion: _selectedEmotion,
              ),
            ),
          ),
          // === Labels ===
          Positioned(
            top: 0,
            left: 10,
            child: GestureDetector(
              onTap: () => _onTapEmotion("Envy"),
              child: const Text("Envy",
                  style: TextStyle(
                      fontFamily: "RobotoMono",
                      fontSize: 12,
                      color: Colors.white)),
            ),
          ),
          Positioned(
            top: 0,
            right: 0,
            child: GestureDetector(
              onTap: () => _onTapEmotion("Anger"),
              child: const Text("Anger",
                  style: TextStyle(
                      fontFamily: "RobotoMono",
                      fontSize: 12,
                      color: Colors.white)),
            ),
          ),
          Positioned(
            bottom: 0,
            left: 10,
            child: GestureDetector(
              onTap: () => _onTapEmotion("Disgust"),
              child: const Text("Disgust",
                  style: TextStyle(
                      fontFamily: "RobotoMono",
                      fontSize: 12,
                      color: Colors.white)),
            ),
          ),
          Positioned(
            bottom: 0,
            right: 0,
            child: GestureDetector(
              onTap: () => _onTapEmotion("Anxiety"),
              child: const Text("Anxiety",
                  style: TextStyle(
                      fontFamily: "RobotoMono",
                      fontSize: 12,
                      color: Colors.white)),
            ),
          ),
        ],
      ),
    );
  }
}

// 🎨 Painter modificado
class KnobPainter extends CustomPainter {
  final double angle;
  final String? selectedEmotion;

  KnobPainter({required this.angle, required this.selectedEmotion});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);

    // Bordes
    final Paint borderPaint = Paint()
      ..color = const Color(0xFFB4B1B8)
      ..style = PaintingStyle.stroke;

    canvas.drawCircle(center, size.width / 2 - 0.5,
        Paint()..color = const Color(0xFF010B19));
    canvas.drawCircle(center, size.width / 2 - 0.5, borderPaint);

    // === Círculo dinámico ===
    final Color knobColor =
        knobEmotionColors[selectedEmotion] ?? const Color(0xFFB4B1B8);
    canvas.drawCircle(center, 55 * (size.width / 130),
        Paint()..color = knobColor);

    // === Pointer ===
    final pointerPaint = Paint()
      ..color = const Color(0xFF010B19)
      ..strokeWidth = 6
      ..strokeCap = StrokeCap.round;

    final dx = cos(angle) * (size.width / 2 - 10);
    final dy = sin(angle) * (size.width / 2 - 10);
    canvas.drawLine(center, center + Offset(dx, dy), pointerPaint);
  }

  @override
  bool shouldRepaint(covariant KnobPainter oldDelegate) =>
      oldDelegate.angle != angle ||
      oldDelegate.selectedEmotion != selectedEmotion;
}

/// ========== PERILLA 2 (LOVE, EMBARRASSMENT, BOREDOM) ==========
class EmotionKnob2 extends StatefulWidget {
  final double scale;
  final Function(String) onEmotionSelected; // 📍 callback
  const EmotionKnob2({Key? key, required this.scale, required this.onEmotionSelected}) : super(key: key);

  @override
  State<EmotionKnob2> createState() => _EmotionKnob2State();
}

class _EmotionKnob2State extends State<EmotionKnob2>
    with SingleTickerProviderStateMixin {
  double _angle = pi / 2; // empieza apuntando abajo
  String? _selectedEmotion;
  late AnimationController _controller;
  Animation<double>? _angleAnimation;

  /// Ángulos de cada emoción
  final Map<String, double> emotionAngles = {
    "Embarrassment": -pi / 2, // arriba
    "Love": 3 * pi / 4, // abajo izquierda
    "Boredom": pi / 4, // abajo derecha
  };

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _animateToAngle(double targetAngle) {
    double start = _angle;
    double end = targetAngle;
    double diff = (end - start).abs();
    if (diff > pi) {
      if (end > start) {
        start += 2 * pi;
      } else {
        end += 2 * pi;
      }
    }

    _controller.stop();
    _angleAnimation = Tween<double>(begin: start, end: end).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    )..addListener(() {
        setState(() {
          _angle = _angleAnimation!.value % (2 * pi);
        });
      });

    _controller.forward(from: 0);
  }

  void _updateEmotionFromAngle() {
    String? closest = _selectedEmotion;
    double minDiff = double.infinity;

    emotionAngles.forEach((emotion, targetAngle) {
      double diff = (targetAngle - _angle).abs();
      if (diff > pi) diff = 2 * pi - diff;
      if (diff < minDiff) {
        minDiff = diff;
        closest = emotion;
      }
    });

    if (closest != _selectedEmotion) {
      setState(() {
        _selectedEmotion = closest;
      });
      widget.onEmotionSelected(_selectedEmotion!); // ✅ se notifica al padre
      print("💖 Perilla 2 seleccionó: $_selectedEmotion");
    }
  }

  void _onPanUpdate(DragUpdateDetails details, Offset center) {
    final local = details.localPosition;
    final dx = local.dx - center.dx;
    final dy = local.dy - center.dy;
    final angle = atan2(dy, dx);

    setState(() {
      _angle = angle;
    });

    _updateEmotionFromAngle();
  }

  void _onPanEnd() {
    if (_selectedEmotion == null) return;
    String closest = _selectedEmotion!;
    double targetAngle = emotionAngles[closest]!;
    _animateToAngle(targetAngle);

    widget.onEmotionSelected(_selectedEmotion!); // el padre guardará
  }

  void _onTapEmotion(String emotion) {
    _animateToAngle(emotionAngles[emotion]!);
    setState(() {
      _selectedEmotion = emotion;
    });

    widget.onEmotionSelected(_selectedEmotion!); // el padre guardará
    print("💖 Perilla 2 seleccionó: $emotion");
  }

  @override
  Widget build(BuildContext context) {
    final double size = 149 * widget.scale;
    final Offset center = Offset(size / 2, size / 2);

    return SizedBox(
      width: size + 60,
      height: size + 60,
      child: Stack(
        alignment: Alignment.center,
        children: [
          GestureDetector(
            onPanUpdate: (details) => _onPanUpdate(details, center),
            onPanEnd: (_) => _onPanEnd(),
            child: CustomPaint(
              size: Size(size, size),
              painter: Knob2Painter(
                angle: _angle,
                scale: widget.scale,
                selectedEmotion: _selectedEmotion,
              ),
            ),
          ),
          // 📍 Texto arriba → Embarrassment
          Positioned(
            top: 0,
            child: GestureDetector(
              onTap: () => _onTapEmotion("Embarrassment"),
              child: const Text(
                "Embarrassment",
                style: TextStyle(
                  fontFamily: "RobotoMono",
                  fontSize: 12,
                  color: Colors.white,
                ),
              ),
            ),
          ),
          // 📍 Texto abajo izquierda → Love
          Positioned(
            bottom: 0,
            left: 8,
            child: GestureDetector(
              onTap: () => _onTapEmotion("Love"),
              child: const Text(
                "Love",
                style: TextStyle(
                  fontFamily: "RobotoMono",
                  fontSize: 12,
                  color: Colors.white,
                ),
              ),
            ),
          ),
          // 📍 Texto abajo derecha → Boredom
          Positioned(
            bottom: 0,
            right: 0,
            child: GestureDetector(
              onTap: () => _onTapEmotion("Boredom"),
              child: const Text(
                "Boredom",
                style: TextStyle(
                  fontFamily: "RobotoMono",
                  fontSize: 12,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class Knob2Painter extends CustomPainter {
  final double angle;
  final double scale;
  final String? selectedEmotion;

  Knob2Painter({
    required this.angle,
    required this.scale,
    this.selectedEmotion,
  });

  @override
  void paint(Canvas canvas, Size size) {
    canvas.save();
    canvas.scale(scale);

    final center = const Offset(72.3, 78.6);

    // ✅ círculo central con color según emoción
    final Color circleColor =
        knob2EmotionColors[selectedEmotion] ?? const Color(0xFFB4B1B8);

    final Paint innerCircle = Paint()..color = circleColor;
    canvas.drawCircle(center, 57.6, innerCircle);

    // === puntero dinámico ===
    final Paint pointer = Paint()
      ..color = const Color(0xFF010B19)
      ..strokeWidth = 6
      ..strokeCap = StrokeCap.round;

    final dx = cos(angle) * 60;
    final dy = sin(angle) * 60;
    canvas.drawLine(center, center + Offset(dx, dy), pointer);

    // === decoración original ===
    final decoPaint = Paint()..color = const Color(0xFFD9D9D9);

    final leftCircles = [
      const Offset(13.6, 116.3),
      const Offset(4.2, 98.5),
      const Offset(3.1, 78.6),
      const Offset(4.2, 60.8),
      const Offset(13.6, 41.9),
      const Offset(24.1, 27.2),
      const Offset(39.8, 14.7),
      const Offset(58.7, 7.3),
    ];
    for (final c in leftCircles) {
      canvas.drawCircle(c, 3.1, decoPaint);
    }

    final rightCircles = [
      const Offset(138.3, 115.2),
      const Offset(147.7, 97.4),
      const Offset(148.8, 77.5),
      const Offset(147.7, 59.7),
      const Offset(138.3, 40.9),
      const Offset(127.8, 26.2),
      const Offset(112.1, 13.6),
      const Offset(93.2, 6.3),
    ];
    for (final c in rightCircles) {
      canvas.drawCircle(c, 3.1, decoPaint);
    }

    // === líneas originales ===
    final linePaint = Paint()
      ..color = const Color(0xFFE9E8EE)
      ..strokeWidth = 6;
    canvas.drawLine(const Offset(24.1, 132), const Offset(11.5, 143), linePaint);
    canvas.drawLine(const Offset(126.8, 132), const Offset(139.3, 143), linePaint);
    canvas.drawLine(const Offset(73, 0), const Offset(73, 15.7), linePaint);

    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant Knob2Painter oldDelegate) =>
      oldDelegate.angle != angle ||
      oldDelegate.scale != scale ||
      oldDelegate.selectedEmotion != selectedEmotion;
}

//Boton
class ButtonPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final Rect r = Rect.fromLTWH(0.5, 0.5, size.width - 1, size.height - 1);
    final RRect rr = RRect.fromRectAndRadius(r, const Radius.circular(9.5));

    final Paint fill = Paint()..color = const Color(0xFF010B19);
    final Paint stroke = Paint()
      ..color = const Color(0xFFD9D9D9)
      ..style = PaintingStyle.stroke;

    canvas.drawRRect(rr, fill);
    canvas.drawRRect(rr, stroke);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

Color _getEmotionColor(String emotion) {
  if (sliderEmotionColors.containsKey(emotion)) {
    return sliderEmotionColors[emotion]!;
  }
  if (knobEmotionColors.containsKey(emotion)) {
    return knobEmotionColors[emotion]!;
  }
  if (knob2EmotionColors.containsKey(emotion)) {
    return knob2EmotionColors[emotion]!;
  }
  return Colors.white; // fallback
}

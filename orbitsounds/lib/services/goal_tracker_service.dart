import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:melodymuse/models/listening_goal_model.dart';
import '../services/notification_service.dart';

class GoalTrackerService {
  static final GoalTrackerService _instance = GoalTrackerService._internal();
  factory GoalTrackerService() => _instance;
  GoalTrackerService._internal();

  final _firestore = FirebaseFirestore.instance;
  final _auth = FirebaseAuth.instance;

  Timer? _timer;
  String? _currentGenre;
  int _secondsListened = 0;

  /// 🔹 Logros globales (acumulados entre todos los géneros)
  final Map<int, Map<String, String>> _globalLevels = {
    1: {'title': 'Warm Up Listener', 'icon': 'assets/icons/bronze_medal.png'},
    15: {'title': 'Groove Rider', 'icon': 'assets/icons/silver_medal.png'},
    30: {'title': 'Sonic Explorer', 'icon': 'assets/icons/gold_medal.png'},
  };

  /// 🔹 Logros específicos por género (60 minutos)
  final Map<String, Map<String, String>> _genreAchievements = {
    'Medieval': {'title': 'Knight of Ballads', 'icon': 'assets/medals/medieval_60.png'},
    'Rock': {'title': 'Riff Master', 'icon': 'assets/medals/rock_60.png'},
    'Pop': {'title': 'Smooth Criminal', 'icon': 'assets/medals/pop_60.png'},
    'Jazz': {'title': 'Soul Improviser', 'icon': 'assets/medals/jazz_60.png'},
    'J-Rock': {'title': 'Shonen Virtuoso', 'icon': 'assets/medals/jrock_60.png'},
    'Punk': {'title': 'Rebel Anthemist', 'icon': 'assets/medals/punk_60.png'},
    'K-Pop': {'title': 'Stage Icon', 'icon': 'assets/medals/kpop_60.png'},
    'Classical': {'title': 'Maestro of Harmony', 'icon': 'assets/medals/classical_60.png'},
    'Heavy Metal': {'title': 'Thunder Virtuoso', 'icon': 'assets/medals/metal_60.png'},
    'EDM': {'title': 'Beat Architect', 'icon': 'assets/medals/edm_60.png'},
    'Rap': {'title': 'Flow Commander', 'icon': 'assets/medals/rap_60.png'},
    'Anisong': {'title': 'Main Character', 'icon': 'assets/medals/anisong_60.png'},
    'Musical': {'title': 'Thunder Bringer', 'icon': 'assets/medals/musical_60.png'},
  };

  /// 🎵 Inicia el conteo por género
  void startTracking(String genre) {
    _currentGenre = genre;
    _secondsListened = 0;

    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      _secondsListened++;
      if (_secondsListened % 60 == 0) {
        _updateProgress(1);
      }
    });
  }

  /// ⏸️ Pausa el seguimiento
  void stopTracking() {
    _timer?.cancel();
    _timer = null;
  }

  /// 🧠 Actualiza progreso en Firestore y verifica logros
  Future<void> _updateProgress(int minutes) async {
    final user = _auth.currentUser;
    if (user == null || _currentGenre == null) return;

    final ref = _firestore
        .collection('users')
        .doc(user.uid)
        .collection('listening_goals')
        .doc(_currentGenre);

    final snap = await ref.get();

    ListeningGoal goal = snap.exists
        ? ListeningGoal.fromMap(snap.data()!)
        : ListeningGoal(genre: _currentGenre!, targetMinutes: 60);

    goal.listenedMinutes += minutes;
    goal.lastSession = DateTime.now().toIso8601String();

    // Logros especiales (día/noche)
    await _checkSpecialAchievements(goal.genre);

    // Meta completada (60 minutos)
    if (!goal.achieved && goal.listenedMinutes >= goal.targetMinutes) {
      goal.achieved = true;
      await NotificationService().showAchievementNotification(
        title: "🏁 Meta completada",
        body: "Has escuchado ${goal.genre} por ${goal.targetMinutes} minutos 🎶",
      );
    }

    await ref.set(goal.toMap(), SetOptions(merge: true));

    // Calcular minutos totales escuchados (global)
    final allGoalsSnap = await _firestore
        .collection('users')
        .doc(user.uid)
        .collection('listening_goals')
        .get();

    int totalMinutes = allGoalsSnap.docs.fold<int>(
      0,
      (sum, doc) => sum + ((doc.data()['listenedMinutes'] ?? 0) as int),
    );

    await _checkGlobalAchievements(totalMinutes);
    await _checkGenreAchievement(goal.genre, goal.listenedMinutes);
  }

  /// 🎶 Registrar una canción escuchada (por género + global)
  Future<void> registerSongPlayed(String genre) async {
    final user = _auth.currentUser;
    if (user == null) return;

    final ref = _firestore
        .collection('users')
        .doc(user.uid)
        .collection('listening_goals')
        .doc(genre);

    final snap = await ref.get();
    if (!snap.exists) return;

    final goal = ListeningGoal.fromMap(snap.data()!);
    goal.songsPlayed += 1;

    await ref.set(goal.toMap(), SetOptions(merge: true));

    // 🎧 Logros por canciones escuchadas (por género)
    if (goal.songsPlayed == 10) {
      await _unlockAchievement(
        user.uid,
        type: 'genre_song10_$genre',
        title: "🎵 Explorador del género $genre",
        icon: _getDynamicIconPath(genre: genre, type: 'song10'),
        body: "Has escuchado 10 canciones de $genre 🎶",
      );
    } else if (goal.songsPlayed == 50) {
      await _unlockAchievement(
        user.uid,
        type: 'genre_song50_$genre',
        title: "🔥 Devoto del $genre",
        icon: _getDynamicIconPath(genre: genre, type: 'song50'),
        body: "¡Has escuchado 50 canciones de $genre! 💥",
      );
    }

    // 🔸 Logros globales de canciones
    await _checkGlobalSongAchievements(user.uid);
  }

  /// ❤️ Registrar una canción marcada como favorita (por género + global)
  Future<void> registerLike(String genre) async {
    final user = _auth.currentUser;
    if (user == null) return;

    final ref = _firestore
        .collection('users')
        .doc(user.uid)
        .collection('listening_goals')
        .doc(genre);

    final snap = await ref.get();
    if (!snap.exists) return;

    final goal = ListeningGoal.fromMap(snap.data()!);
    goal.likesGiven += 1;

    await ref.set(goal.toMap(), SetOptions(merge: true));

    // 💖 Logros por likes (por género)
    if (goal.likesGiven == 5) {
      await _unlockAchievement(
        user.uid,
        type: 'genre_like5_$genre',
        title: "❤️ Fan del género $genre",
        icon: _getDynamicIconPath(genre: genre, type: 'like5'),
        body: "Has marcado 5 canciones de $genre como favoritas 💫",
      );
    } else if (goal.likesGiven == 20) {
      await _unlockAchievement(
        user.uid,
        type: 'genre_like20_$genre',
        title: "💞 Melómano de $genre",
        icon: _getDynamicIconPath(genre: genre, type: 'like20'),
        body: "¡Has marcado 20 canciones de $genre como favoritas! 🌟",
      );
    }

    // 🔸 Logros globales de likes
    await _checkGlobalLikeAchievements(user.uid);
  }

  /// 🌙 Logros especiales (día/noche)
  Future<void> _checkSpecialAchievements(String genre) async {
    final hour = DateTime.now().hour;
    final user = _auth.currentUser;
    if (user == null) return;

    if (hour >= 22 || hour < 5) {
      await _unlockAchievement(
        user.uid,
        type: 'night_session',
        title: 'Moonlight Listener 🌙',
        icon: 'assets/icons/night_listen.png',
        body: "Has disfrutado de $genre bajo la luna ✨",
      );
    } else if (hour >= 7 && hour <= 18) {
      await _unlockAchievement(
        user.uid,
        type: 'day_session',
        title: 'Sunlight Listener ☀️',
        icon: 'assets/icons/day_listen.png',
        body: "Has disfrutado de $genre durante el día 🌼",
      );
    }
  }

  /// 🌍 Logros globales (tiempo total)
  Future<void> _checkGlobalAchievements(int totalMinutes) async {
    final user = _auth.currentUser;
    if (user == null) return;

    for (final entry in _globalLevels.entries) {
      if (totalMinutes >= entry.key) {
        await _unlockAchievement(
          user.uid,
          type: 'global_${entry.key}',
          title: entry.value['title']!,
          icon: entry.value['icon']!,
          body: "Has acumulado $totalMinutes minutos de música en total 🎧",
        );
      }
    }
  }

  /// 🎸 Logros de género (60 min)
  Future<void> _checkGenreAchievement(String genre, int minutes) async {
    if (!_genreAchievements.containsKey(genre)) return;
    final user = _auth.currentUser;
    if (user == null) return;

    if (minutes >= 60) {
      final achievement = _genreAchievements[genre]!;
      await _unlockAchievement(
        user.uid,
        type: 'genre_$genre',
        title: achievement['title']!,
        icon: achievement['icon']!,
        body: "Has dominado el género $genre escuchándolo por 60 minutos 🎶",
      );
    }
  }

  /// 🎧 Logros globales de canciones escuchadas
  Future<void> _checkGlobalSongAchievements(String userId) async {
    final goalsSnap = await _firestore
        .collection('users')
        .doc(userId)
        .collection('listening_goals')
        .get();

    int totalSongs = goalsSnap.docs.fold<int>(
      0,
      (sum, doc) => sum + ((doc.data()['songsPlayed'] ?? 0) as int),
    );

    if (totalSongs >= 100) {
      await _unlockAchievement(
        userId,
        type: 'global_songs100',
        title: "🎶 Music Wanderer",
        icon: 'assets/icons/songs_100.png',
        body: "Has escuchado 100 canciones en total 🌍",
      );
    } else if (totalSongs >= 500) {
      await _unlockAchievement(
        userId,
        type: 'global_songs500',
        title: "🌟 Infinite Listener",
        icon: 'assets/icons/songs_500.png',
        body: "¡Has escuchado 500 canciones en toda tu travesía musical! 💫",
      );
    }
  }

  /// 💞 Logros globales de likes dados
  Future<void> _checkGlobalLikeAchievements(String userId) async {
    final goalsSnap = await _firestore
        .collection('users')
        .doc(userId)
        .collection('listening_goals')
        .get();

    int totalLikes = goalsSnap.docs.fold<int>(
      0,
      (sum, doc) => sum + ((doc.data()['likesGiven'] ?? 0) as int),
    );

    if (totalLikes >= 50) {
      await _unlockAchievement(
        userId,
        type: 'global_like50',
        title: "💗 Passionate Listener",
        icon: 'assets/icons/like_50.png',
        body: "Has marcado 50 canciones como favoritas 💕",
      );
    } else if (totalLikes >= 200) {
      await _unlockAchievement(
        userId,
        type: 'global_like200',
        title: "💖 True Music Lover",
        icon: 'assets/icons/like_200.png',
        body: "¡Has marcado 200 canciones como favoritas en total! 🌸",
      );
    }
  }

  /// 🏆 Método auxiliar para evitar duplicados
  Future<void> _unlockAchievement(
    String userId, {
    required String type,
    required String title,
    required String icon,
    required String body,
  }) async {
    final achievementsRef = _firestore
        .collection('users')
        .doc(userId)
        .collection('achievements');

    final exists =
        await achievementsRef.where('type', isEqualTo: type).limit(1).get();

    if (exists.docs.isEmpty) {
      await achievementsRef.add({
        'type': type,
        'title': title,
        'icon': icon,
        'unlockedAt': FieldValue.serverTimestamp(),
      });

      await NotificationService().showAchievementNotification(
        title: title,
        body: body,
      );
    }
  }

  /// 🔹 Alias para nombres de archivos de medallas
  final Map<String, String> _genreAliases = {
    'J-Rock': 'jrock',
    'K-Pop': 'kpop',
    'Heavy Metal': 'metal',
    'Rap': 'rap',
    'EDM': 'edm',
    'Pop': 'pop',
    'Rock': 'rock',
    'Jazz': 'jazz',
    'Classical': 'classical',
    'Medieval': 'medieval',
    'Anisong': 'anisong',
    'Musical': 'musical',
    'Punk': 'punk',
  };

  /// 🖼️ Método para generar la ruta del ícono dinámico según el tipo
  String _getDynamicIconPath({required String genre, required String type}) {
    final safeGenre = _genreAliases[genre] ?? genre.toLowerCase().replaceAll(' ', '_');
    return 'assets/medals/${safeGenre}_$type.png';
  }
}

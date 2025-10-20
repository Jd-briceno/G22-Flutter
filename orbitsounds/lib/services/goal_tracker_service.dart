import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:melodymuse/models/listening_goal_model.dart';
import 'package:melodymuse/models/track_model.dart';
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
    1: {'title': 'Observer', 'icon': 'assets/medals/bronze_medal.png'},
    15: {'title': 'To the Stars', 'icon': 'assets/medals/silver_medal.png'},
    30: {'title': 'Just Visiting… Forever', 'icon': 'assets/medals/gold_medal.png'},
  };

  /// 🔹 Logros específicos por género (60 minutos)
  final Map<String, Map<String, String>> _genreAchievements = {
    'Medieval': {'title': 'The Grand Ballad of Eternity', 'icon': 'assets/medals/medieval_60.png'},
    'Rock': {'title': 'Hour of the Titan', 'icon': 'assets/medals/rock_60.png'},
    'Pop': {'title': 'Smooth Criminal', 'icon': 'assets/medals/pop_60.png'},
    'Jazz': {'title': 'Soul Improviser', 'icon': 'assets/medals/jazz_60.png'},
    'J-Rock': {'title': 'The Eternal Shōnen', 'icon': 'assets/medals/jrock_60.png'},
    'Punk': {'title': 'The Riot Session', 'icon': 'assets/medals/punk_60.png'},
    'K-Pop': {'title': 'Your Idol', 'icon': 'assets/medals/kpop_60.png'},
    'Classical': {'title': 'Maestro of Harmony', 'icon': 'assets/medals/classical_60.png'},
    'Heavy Metal': {'title': 'Hour of the Inquisition', 'icon': 'assets/medals/metal_60.png'},
    'EDM': {'title': 'Tron', 'icon': 'assets/medals/edm_60.png'},
    'Rap': {'title': 'Rap God', 'icon': 'assets/medals/rap_60.png'},
    'Anisong': {'title': 'Main Character', 'icon': 'assets/medals/anisong_60.png'},
    'Musical': {'title': 'Thunder Bringer', 'icon': 'assets/medals/musical_60.png'},
  };

  /// 🎵 Inicia el conteo por género (acumula segundos entre canciones)
  void startTracking(String genre) {
    // Si el usuario cambió de género, guarda el progreso previo antes de reiniciar
    if (_currentGenre != genre && _secondsListened > 0) {
      final minutes = (_secondsListened / 60).floor();
      if (minutes > 0) {
        _updateProgress(minutes);
      }
      // Mantiene los segundos sobrantes para no perderlos
      _secondsListened = _secondsListened % 60;
    }

    _currentGenre = genre;
    _timer?.cancel();

    // 🔁 Empieza a contar segundos
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      _secondsListened++;

      // ✅ Cada 60 segundos (1 minuto completo)
      if (_secondsListened >= 60) {
        _updateProgress(1);
        _secondsListened -= 60; // conserva los segundos sobrantes
      }
    });
  }

  /// ⏸️ Pausa o detiene el seguimiento (guarda segundos pendientes)
  void stopTracking() {
    _timer?.cancel();
    _timer = null;

    // ✅ Si quedan segundos sin guardar, acumularlos como minutos parciales
    if (_secondsListened > 0) {
      final minutes = (_secondsListened / 60).floor();
      if (minutes > 0) {
        _updateProgress(minutes);
      }
      _secondsListened = 0;
    }
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

  // 🎵 Logros por canciones escuchadas (por género)
  final titlesByGenre10 = {
    'Rock': 'First Chord',
    'Pop': 'The Spark Inside',
    'Jazz': 'Midnight Melody',
    'Rap': 'Origin Flow',
    'EDM': 'Circuit Starter',
    'Classical': 'Prelude of Light',
    'Heavy Metal': 'Acolyte of Noise',
    'J-Rock': 'Way of the Ninja',
    'K-Pop': 'Debut Dreamer',
    'Punk': 'Anarchy Initiate',
    'Anisong': 'The King of Curses',
    'Musical': 'Prologue of the Hero',
    'Medieval': 'Wanderer of Taverns',
  };

  final titlesByGenre50 = {
    'Rock': 'Stage Inferno',
    'Pop': 'Dancefloor Destiny',
    'Jazz': 'King of the Midnight Table',
    'Rap': 'Master of the Verse',
    'EDM': 'Pulse Architect',
    'Classical': 'Eclipsed Symphony',
    'Heavy Metal': 'Iron Primarch',
    'J-Rock': 'Sword of Sound',
    'K-Pop': 'Stage Commander',
    'Punk': 'The Rebel’s Anthem',
    'Anisong': 'The Honored One',
    'Musical': 'Maestro of Fate',
    'Medieval': 'Knight of Harmony',
  };

  if (goal.songsPlayed == 10) {
    await _unlockAchievement(
      user.uid,
      type: 'genre_song10_$genre',
      title: titlesByGenre10[genre] ?? '🎵 Explorador del género $genre',
      icon: _getDynamicIconPath(genre: genre, type: 'song10'),
      body: "Has escuchado 10 canciones de $genre 🎶",
    );
  } else if (goal.songsPlayed == 50) {
    await _unlockAchievement(
      user.uid,
      type: 'genre_song50_$genre',
      title: titlesByGenre50[genre] ?? '🔥 Devoto del $genre',
      icon: _getDynamicIconPath(genre: genre, type: 'song50'),
      body: "¡Has escuchado 50 canciones de $genre! 💥",
    );
  }

  // 🔸 Logros globales de canciones
  await _checkGlobalSongAchievements(user.uid);
}


  /// ❤️ Registrar o quitar like (toggle seguro)
  Future<void> registerLike({
    required String genre,
    required Track track,
  }) async {
    final user = _auth.currentUser;
    if (user == null) return;

    // 🔹 Referencia al registro del like individual
    final likeRef = _firestore
        .collection('users')
        .doc(user.uid)
        .collection('liked_songs')
        .doc('${genre}_${track.title}'); // Usa track.id si existe

    // 🔹 Referencia al progreso general del género
    final goalRef = _firestore
        .collection('users')
        .doc(user.uid)
        .collection('listening_goals')
        .doc(genre);

    final likeSnap = await likeRef.get();
    final goalSnap = await goalRef.get();

    if (!goalSnap.exists) return;
    final goal = ListeningGoal.fromMap(goalSnap.data()!);

    // 🔍 Comprobar si ya está marcada como like
    bool isLiked = likeSnap.exists && (likeSnap.data()?['liked'] == true);

    if (isLiked) {
      // 💔 Quitar like → restar 1
      goal.likesGiven = (goal.likesGiven - 1).clamp(0, goal.likesGiven);
      await likeRef.delete();
    } else {
      // ❤️ Nuevo like → sumar 1
      goal.likesGiven += 1;
      await likeRef.set({
        'genre': genre,
        'songId': track.title,
        'title': track.title,
        'artist': track.artist,
        'albumArt': track.albumArt,
        'liked': true,
        'timestamp': FieldValue.serverTimestamp(),
      });
    }

    // 🔹 Actualizar progreso del género
    await goalRef.set(goal.toMap(), SetOptions(merge: true));

    // 🎯 Solo verificar logros si se dio un nuevo like
    if (!isLiked) {
      await _checkGenreLikeAchievements(user.uid, genre, goal.likesGiven);
      await _checkGlobalLikeAchievements(user.uid);
    }
  }

  /// 💖 Submétodo auxiliar para logros de likes por género
  Future<void> _checkGenreLikeAchievements(String userId, String genre, int likesGiven) async {
    final likeTitles5 = {
      'Rock': 'Amped Soul',
      'Pop': 'Mirror Heart',
      'Jazz': 'Velvet Charisma',
      'Rap': 'Street Poet',
      'EDM': 'Synthwave Soul',
      'Classical': 'Virtue in Vibrato',
      'Heavy Metal': 'Inquisitor of Sound',
      'J-Rock': 'Wolf Clan Drifter',
      'K-Pop': 'Heartlight',
      'Punk': 'Patch Collector',
      'Anisong': 'Kaiju No. 8',
      'Musical': 'Voice of Olympus',
      'Medieval': 'Silver Tongue',
    };

    final likeTitles20 = {
      'Rock': 'Crown of the Encore',
      'Pop': 'Rhythm Royalty',
      'Jazz': 'The Heart Gambler',
      'Rap': 'Rhythm Messiah',
      'EDM': 'Glitch Monarch',
      'Classical': 'The Fallen Maestro',
      'Heavy Metal': 'God Emperor of Mankind',
      'J-Rock': 'Kamui’s Oath',
      'K-Pop': 'Crown of the Comeback',
      'Punk': 'Antihero Icon',
      'Anisong': 'Hero X',
      'Musical': 'The Golden Performer',
      'Medieval': 'Paladin of Passion',
    };

    if (likesGiven == 5) {
      await _unlockAchievement(
        userId,
        type: 'genre_like5_$genre',
        title: likeTitles5[genre] ?? "❤️ Fan del género $genre",
        icon: _getDynamicIconPath(genre: genre, type: 'like5'),
        body: "Has marcado 5 canciones de $genre como favoritas 💫",
      );
    } else if (likesGiven == 20) {
      await _unlockAchievement(
        userId,
        type: 'genre_like20_$genre',
        title: likeTitles20[genre] ?? "💞 Melómano de $genre",
        icon: _getDynamicIconPath(genre: genre, type: 'like20'),
        body: "¡Has marcado 20 canciones de $genre como favoritas! 🌟",
      );
    }
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
        icon: 'assets/medals/night_listen.png',
        body: "Has disfrutado de $genre bajo la luna ✨",
      );
    } else if (hour >= 7 && hour <= 18) {
      await _unlockAchievement(
        user.uid,
        type: 'day_session',
        title: 'Sunside Session',
        icon: 'assets/medals/day_listen.png',
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
        title: "I Believe",
        icon: 'assets/medals/songs_100.png',
        body: "Has escuchado 100 canciones en total 🌍",
      );
    } else if (totalSongs >= 500) {
      await _unlockAchievement(
        userId,
        type: 'global_songs500',
        title: "STARMAN",
        icon: 'assets/medals/songs_500.png',
        body: "¡Has escuchado 500 canciones en toda tu travesía musical! 💫",
      );
    }
  }

    /// 💞 Logros globales de likes dados (corregido)
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

    print("💗 Total likes acumulados globalmente: $totalLikes");

    // ✅ Primero verifica el de 200 (más alto)
    if (totalLikes >= 200) {
      await _unlockAchievement(
        userId,
        type: 'global_like200',
        title: "Interstellar",
        icon: 'assets/medals/like_200.png',
        body: "¡Has marcado 200 canciones como favoritas en total! 🌸",
      );
    }

    // ✅ Luego el de 50
    if (totalLikes >= 50) {
      await _unlockAchievement(
        userId,
        type: 'global_like50',
        title: "Ask for a Wish",
        icon: 'assets/medals/like_50.png',
        body: "Has marcado 50 canciones como favoritas 💕",
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

  /// 🔁 Registrar cuántas veces se ha escuchado una canción específica (con modelo Track)
  bool _processingSong = false;

  Future<void> registerSongRepeat({
    required String genre,
    required String songId,
    required Track track,
  }) async {
    if (_processingSong) return; // 🔒 evita duplicados
    _processingSong = true;

    try {
      final user = _auth.currentUser;
      if (user == null) {
        _processingSong = false;
        return;
      }

      final repeatsRef = _firestore
          .collection('users')
          .doc(user.uid)
          .collection('song_repeats')
          .doc('${genre}_$songId');

      final snap = await repeatsRef.get();
      int currentCount = (snap.data()?['count'] ?? 0) as int;
      currentCount++;

      await repeatsRef.set({
        'genre': genre,
        'songId': songId,
        'songTitle': track.title,
        'artist': track.artist,
        'albumArt': track.albumArt,
        'count': currentCount,
        'lastPlayed': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      // 🎯 Verificar logros progresivos
      final List<int> milestones = [25, 50];
      for (final milestone in milestones) {
        if (currentCount == milestone) {
          await _unlockAchievement(
            user.uid,
            type: 'song_repeat_${genre}_$milestone',
            title: _getRepeatTitle(genre, milestone),
            icon: _getDynamicIconPath(genre: genre, type: 'repeat$milestone'),
            body:
                "Has escuchado **'${track.title}'** de *${track.artist}* ($genre) $milestone veces 🔁",
          );
          break;
        }
      }
    } catch (e) {
      print("⚠️ Error en registerSongRepeat: $e");
    } finally {
      _processingSong = false; // ✅ Siempre se libera el bloqueo
    }
  }



  /// 🏷️ Títulos personalizados por género y progresión
  String _getRepeatTitle(String genre, int milestone) {
    final Map<String, Map<int, String>> titlesByGenre = {
      'Medieval': {
        25: 'Druid of the Echo Woods',
        50: 'Warlord of the Chorus',
      },
      'Rock': {
        25: 'Riff Rewind',
        50: 'Guitar God',
      },
      'Pop': {
        25: 'Dancing Shadow',
        50: 'Forever the Showman',
      },
      'Jazz': {
        25: 'Shadow Shuffle',
        50: 'Gambit',
      },
      'J-Rock': {
        25: 'Echo of the Shuriken',
        50: 'Ronin of Rhythm',
      },
      'Punk': {
        25: 'Vinyl Scars',
        50: 'Legend of the Broken Strings',
      },
      'K-Pop': {
        25: 'Echo of Stardust',
        50: 'Golden',
      },
      'Classical': {
        25: 'Eternal Aria',
        50: 'The Dissonant One',
      },
      'Heavy Metal': {
        25: 'Battle Brother Reborn',
        50: 'Primarch of Resonance',
      },
      'EDM': {
        25: 'Echo Protocol',
        50: 'System Overdrive',
      },
      'Rap': {
        25: 'Echo of the Streets',
        50: 'Shadow Spitter',
      },
      'Anisong': {
        25: 'Greatest King',
        50: 'Shadow Monarch',
      },
      'Musical': {
        25: 'The Immortal Overture',
        50: 'The Odyssey in Sound',
      },
    };

    String? title = titlesByGenre[genre]?[milestone];
    if (title != null) return title;

    // Título por defecto si el género o hito no está en el mapa
    return "🎵 Repetición de $genre: $milestone veces";
  }

}

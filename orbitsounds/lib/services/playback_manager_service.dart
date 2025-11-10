import 'dart:async';
import 'package:flutter/foundation.dart';
import '../models/track_model.dart';
import 'goal_tracker_service.dart';
import 'package:firebase_analytics/firebase_analytics.dart';

class PlaybackManagerViewModel extends ChangeNotifier {
  static final PlaybackManagerViewModel _instance = PlaybackManagerViewModel._internal();
  factory PlaybackManagerViewModel() => _instance;
  PlaybackManagerViewModel._internal();

  final GoalTrackerService _goalTracker = GoalTrackerService();
  final FirebaseAnalytics analytics = FirebaseAnalytics.instance;

  List<Track> _playlist = [];
  int _currentIndex = 0;
  Duration _position = Duration.zero;
  bool _isPlaying = false;
  String _genre = "";
  Timer? _timer;
  bool _processingCompletion = false;

  // 🕒 NUEVO: inicio de sesión de escucha
  DateTime? _sessionStartTime;

  // 🆕 NUEVO: registro de última canción reproducida
  String? _lastSongId;
  DateTime? _lastSongStartTime;

  // ✅ Getters públicos
  List<Track> get playlist => _playlist;
  Track? get currentTrack => _playlist.isNotEmpty ? _playlist[_currentIndex] : null;
  int get currentIndex => _currentIndex;
  Duration get position => _position;
  bool get isPlaying => _isPlaying;
  String get genre => _genre;

  // 🔹 Cargar playlist y género actual
  void loadPlaylist(List<Track> tracks, {int startIndex = 0, required String genre}) {
    if (tracks.isEmpty) return;
    _playlist = List.from(tracks);
    _currentIndex = startIndex.clamp(0, _playlist.length - 1);
    _position = Duration.zero;
    _genre = genre;
    notifyListeners();
  }

  // ▶️ Reproducir
  void play() async {
    if (_playlist.isEmpty) return;

    if (!_isPlaying) {
      _sessionStartTime = DateTime.now();
    }

    _isPlaying = true;
    _goalTracker.startTracking(_genre);

    final track = _playlist[_currentIndex];
    final now = DateTime.now();

    // 🆕 Si esta canción ya fue escuchada antes en esta sesión (aunque sea hace rato),
    // cuenta como repetición. Pero con un pequeño cooldown para evitar rebotes.
    if (_lastSongId == track.title) {
      final diff = now.difference(_lastSongStartTime ?? now).inSeconds;
      if (diff > 5) {
        await _goalTracker.registerSongRepeat(
          genre: _genre,
          songId: track.title,
          track: track,
        );
      }
    } else {
      // Es una canción nueva → marca como "ya escuchada una vez"
      await _goalTracker.registerSongRepeat(
        genre: _genre,
        songId: track.title,
        track: track,
      );
    }

    _lastSongId = track.title;
    _lastSongStartTime = now;

    // ⏱ Timer para simular progreso
    _timer?.cancel();
    _processingCompletion = false;

    _timer = Timer.periodic(const Duration(seconds: 1), (timer) async {
    final total = Duration(
      milliseconds: track.durationMs > 0 ? track.durationMs : 30000,
    );

    if (_position < total) {
      _position += const Duration(seconds: 1);
      notifyListeners();
    } else if (!_processingCompletion) {
      _processingCompletion = true;
      _timer?.cancel();
      _position = Duration.zero;

      try {
        // ✅ Registrar la canción completada (una sola vez)
        await _goalTracker.registerSongRepeat(
          genre: _genre,
          songId: track.title,
          track: track,
        );

        // ✅ Registrar el conteo global (una vez por canción completa)
        await _goalTracker.registerSongPlayed(_genre);
      } catch (e) {
        print("⚠️ Error registrando canción completada: $e");
      } finally {
        _processingCompletion = false;
      }

      // 🔁 Avanzar a la siguiente canción
      Future.microtask(() => next());
    }
  });



    notifyListeners();
  }

  // ⏸️ Pausar
  void pause() {
    _isPlaying = false;
    _timer?.cancel();
    _goalTracker.stopTracking();

    // 📊 Registrar sesión
    if (_sessionStartTime != null) {
      final endTime = DateTime.now();
      final sessionDuration = endTime.difference(_sessionStartTime!).inSeconds;

      analytics.logEvent(
        name: 'listening_session',
        parameters: {
          'genre': _genre,
          'duration_seconds': sessionDuration,
          'timestamp': endTime.toIso8601String(),
        },
      );

      _sessionStartTime = null;
    }

    notifyListeners();
  }

  // ⏭️ Siguiente canción
  void next() {
    if (_playlist.isEmpty) return;

    _timer?.cancel();
    _currentIndex = (_currentIndex + 1) % _playlist.length;
    _position = Duration.zero;
    notifyListeners();

    if (_isPlaying) play();
  }

  // ⏮️ Anterior canción
  void previous() {
    if (_playlist.isEmpty) return;
    _timer?.cancel();

    if (_position.inSeconds > 2) {
      _position = Duration.zero;
    } else {
      _currentIndex = (_currentIndex - 1 + _playlist.length) % _playlist.length;
      _position = Duration.zero;
    }

    notifyListeners();
    if (_isPlaying) play();
  }

  // ⏩ Buscar en posición específica
  void seekTo(Duration newPosition) {
    final track = currentTrack;
    if (track == null) return;

    final duration = Duration(milliseconds: track.durationMs > 0 ? track.durationMs : 30000);
    if (newPosition < Duration.zero) {
      _position = Duration.zero;
    } else if (newPosition > duration) {
      _position = duration;
    } else {
      _position = newPosition;
    }

    notifyListeners();
  }

  // 🛑 Detener todo
  void stop() {
    _timer?.cancel();
    _isPlaying = false;
    _position = Duration.zero;
    _goalTracker.stopTracking();

    if (_sessionStartTime != null) {
      final endTime = DateTime.now();
      final sessionDuration = endTime.difference(_sessionStartTime!).inSeconds;
      analytics.logEvent(
        name: 'listening_session',
        parameters: {
          'genre': _genre,
          'duration_seconds': sessionDuration,
          'timestamp': endTime.toIso8601String(),
        },
      );
      _sessionStartTime = null;
    }

    notifyListeners();
  }
}

typedef PlaybackManagerService = PlaybackManagerViewModel;

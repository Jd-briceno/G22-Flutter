import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:just_audio/just_audio.dart';
import '../models/track_model.dart';
import 'goal_tracker_service.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class PlaybackManagerService with ChangeNotifier {
  static final PlaybackManagerService _instance = PlaybackManagerService._internal();
  factory PlaybackManagerService() => _instance;
  PlaybackManagerService._internal();

  final GoalTrackerService _goalTracker = GoalTrackerService();
  final FirebaseAnalytics analytics = FirebaseAnalytics.instance;

  final AudioPlayer _audioPlayer = AudioPlayer();

  List<Track> _playlist = [];
  int _currentIndex = 0;
  Duration _position = Duration.zero;
  bool _isPlaying = false;
  String _genre = "";
  bool _isSimulated = false;
  Timer? _simulatedTimer;

  StreamSubscription<Duration>? _positionSub;
  StreamSubscription<PlayerState>? _playerStateSub;

  DateTime? _sessionStartTime;
  String? _lastSongId;
  DateTime? _lastSongStartTime;

  List<Track> get playlist => _playlist;
  Track? get currentTrack => _playlist.isNotEmpty ? _playlist[_currentIndex] : null;
  int get currentIndex => _currentIndex;
  Duration get position => _position;
  bool get isPlaying => _isPlaying;
  String get genre => _genre;

  void loadPlaylist(List<Track> tracks, {int startIndex = 0, required String genre}) {
    if (tracks.isEmpty) return;
    _playlist = List.from(tracks);
    _currentIndex = startIndex.clamp(0, _playlist.length - 1);
    _position = Duration.zero;
    _genre = genre;
    notifyListeners();
  }

  Future<void> play() async {
    final track = currentTrack;
    if (track == null) return;

    if (!_isPlaying) {
      _sessionStartTime = DateTime.now();
    }
    _isPlaying = true;
    notifyListeners();

    _goalTracker.startTracking(_genre);

    final now = DateTime.now();
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
      await _goalTracker.registerSongRepeat(
        genre: _genre,
        songId: track.title,
        track: track,
      );
    }
    _lastSongId = track.title;
    _lastSongStartTime = now;

    _isSimulated = false;
    _simulatedTimer?.cancel();

    if (track.previewUrl != null && track.previewUrl!.isNotEmpty) {
      try {
        await _audioPlayer.setUrl(track.previewUrl!);
        await _audioPlayer.play();
      } catch (e) {
        print("⚠️ Error al cargar la preview URL: $e");
      }

      _positionSub?.cancel();
      _positionSub = _audioPlayer.positionStream.listen((pos) {
        _position = pos;
        notifyListeners();
      });

      _playerStateSub?.cancel();
      _playerStateSub = _audioPlayer.playerStateStream.listen((state) {
        if (state.processingState == ProcessingState.completed) {
          _onTrackComplete();
        }
      });
    } else {
      _isSimulated = true;
      final duration = Duration(milliseconds: track.durationMs > 0 ? track.durationMs : 30000);
      _simulatedTimer = Timer(duration, _onTrackComplete);
    }
  }

  Future<void> pause() async {
    if (_isPlaying) {
      _isPlaying = false;

      if (_isSimulated) {
        _simulatedTimer?.cancel();
      } else {
        await _audioPlayer.pause();
      }

      _positionSub?.cancel();
      _playerStateSub?.cancel();
      _goalTracker.stopTracking();

      if (_sessionStartTime != null) {
        final endTime = DateTime.now();
        final sessionDuration = endTime.difference(_sessionStartTime!).inSeconds;
        await analytics.logEvent(
          name: 'listening_session',
          parameters: {
            'genre': _genre,
            'duration_seconds': sessionDuration,
            'timestamp': endTime.toIso8601String(),
          },
        );
        await _registerSessionInFirestore(sessionDuration);
        _sessionStartTime = null;
      }
      notifyListeners();
    }
  }

  Future<void> stop() async {
    _isPlaying = false;
    _position = Duration.zero;
    _isSimulated = false;
    _simulatedTimer?.cancel();
    await _audioPlayer.stop();
    _positionSub?.cancel();
    _playerStateSub?.cancel();
    _goalTracker.stopTracking();

    if (_sessionStartTime != null) {
      final endTime = DateTime.now();
      final sessionDuration = endTime.difference(_sessionStartTime!).inSeconds;
      await analytics.logEvent(
        name: 'listening_session',
        parameters: {
          'genre': _genre,
          'duration_seconds': sessionDuration,
          'timestamp': endTime.toIso8601String(),
        },
      );
      await _registerSessionInFirestore(sessionDuration);
      _sessionStartTime = null;
    }
    notifyListeners();
  }

  void next() {
    if (_playlist.isEmpty) return;
    _currentIndex = (_currentIndex + 1) % _playlist.length;
    _position = Duration.zero;
    notifyListeners();
    if (_isPlaying) play();
  }

  void previous() {
    if (_playlist.isEmpty) return;
    if (_position.inSeconds > 2) {
      _position = Duration.zero;
    } else {
      _currentIndex = (_currentIndex - 1 + _playlist.length) % _playlist.length;
      _position = Duration.zero;
    }
    notifyListeners();
    if (_isPlaying) play();
  }

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
      _audioPlayer.seek(newPosition);
    }
    notifyListeners();
  }

  Future<void> _onTrackComplete() async {
    final track = currentTrack;
    if (track == null) return;

    await _goalTracker.registerSongPlayed(_genre);
    _position = Duration.zero;
    notifyListeners();

    next();
  }

  Future<void> _registerSessionInFirestore(int durationSeconds) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      final durationMinutes = (durationSeconds / 60).clamp(0.0, double.infinity);
      final ref = FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('listening_goals')
          .doc(_genre);

      await FirebaseFirestore.instance.runTransaction((tx) async {
        final snapshot = await tx.get(ref);

        if (snapshot.exists) {
          final data = snapshot.data()!;
          final listenedMinutes = (data['listenedMinutes'] ?? 0).toDouble();
          final sessionsCount = (data['sessionsCount'] ?? 0).toInt();
          final newMinutes = listenedMinutes + durationMinutes;
          final newSessions = sessionsCount + 1;
          tx.update(ref, {
            'listenedMinutes': newMinutes,
            'sessionsCount': newSessions,
            'lastSession': DateTime.now().toIso8601String(),
          });
        } else {
          tx.set(ref, {
            'genre': _genre,
            'targetMinutes': 60,
            'listenedMinutes': durationMinutes,
            'sessionsCount': 1,
            'achieved': false,
            'songsPlayed': 0,
            'likesGiven': 0,
            'lastSession': DateTime.now().toIso8601String(),
          });
        }
      });
    } catch (e) {
      print("❌ Error al registrar sesión en Firestore: $e");
    }
  }

  @override
  void dispose() {
    _positionSub?.cancel();
    _playerStateSub?.cancel();
    _simulatedTimer?.cancel();
    _audioPlayer.dispose();
    super.dispose();
  }
}

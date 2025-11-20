import 'package:just_audio/just_audio.dart';
import 'package:audio_session/audio_session.dart';
import '../models/track_model.dart';

enum PlaybackMode {
  preview,
  spotify,
}

class AudioPlaybackService {
  final AudioPlayer _player = AudioPlayer();
  PlaybackMode? _mode;

  Future<void> init() async {
    final session = await AudioSession.instance;
    await session.configure(const AudioSessionConfiguration.music());
  }

  Future<void> playTrack(Track track) async {
    if (track.previewUrl != null && track.previewUrl!.isNotEmpty) {
      _mode = PlaybackMode.preview;
      await _player.setUrl(track.previewUrl!);
      await _player.play();
    } else {
      _mode = PlaybackMode.spotify;
    }
  }

  Future<void> pause() async {
    if (_mode == PlaybackMode.preview) {
      await _player.pause();
    }
  }

  Future<void> stop() async {
    if (_mode == PlaybackMode.preview) {
      await _player.stop();
    }
  }

  Future<void> seek(Duration position) async {
    if (_mode == PlaybackMode.preview) {
      await _player.seek(position);
    }
  }

  Stream<Duration> get positionStream => _player.positionStream;
  Stream<Duration?> get durationStream => _player.durationStream;

  void dispose() {
    _player.dispose();
  }
}

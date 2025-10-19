class Track {
  final String title;
  final String artist;
  final String duration; // formatted string "3:45"
  final int durationMs;  // raw milliseconds
  final String albumArt;
  final String? previewUrl; // optional, for 30s preview playback
  bool isLiked; // ✅ Nuevo campo para controlar el "like"

  Track({
    required this.title,
    required this.artist,
    required this.duration,
    required this.durationMs,
    required this.albumArt,
    this.previewUrl,
    this.isLiked = false,
  });

  factory Track.fromSpotify(Map<String, dynamic> json) {
    final durationMs = json['duration_ms'] ?? 0;
    final minutes = (durationMs / 60000).floor();
    final seconds = ((durationMs % 60000) / 1000).floor();

    final artists = (json['artists'] as List<dynamic>? ?? [])
        .map((a) => a['name'] as String? ?? '')
        .where((name) => name.isNotEmpty)
        .toList();

    final images = json['album']?['images'] as List<dynamic>? ?? [];
    final albumArtUrl = images.isNotEmpty ? images[0]['url'] ?? '' : '';

    return Track(
      title: json['name'] ?? '',
      artist: artists.join(", "),
      duration: "$minutes:${seconds.toString().padLeft(2, '0')}",
      durationMs: durationMs,
      albumArt: albumArtUrl,
      previewUrl: json['preview_url'],
      isLiked: false,
    );
  }

  // ✅ Método para convertir el objeto en un Map (para enviar a Isolate o guardar)
  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'artist': artist,
      'duration': duration,
      'durationMs': durationMs,
      'albumArt': albumArt,
      'previewUrl': previewUrl,
      'isLiked': isLiked,
    };
  }

  // ✅ Método inverso para reconstruir el objeto desde un Map
  factory Track.fromMap(Map<String, dynamic> map) {
    return Track(
      title: map['title'] ?? '',
      artist: map['artist'] ?? '',
      duration: map['duration'] ?? '',
      durationMs: map['durationMs'] ?? 0,
      albumArt: map['albumArt'] ?? '',
      previewUrl: map['previewUrl'],
      isLiked: map['isLiked'] ?? false,
    );
  }

  // ✅ copyWith: útil para clonar o actualizar propiedades
  Track copyWith({
    String? title,
    String? artist,
    String? duration,
    int? durationMs,
    String? albumArt,
    String? previewUrl,
    bool? isLiked,
  }) {
    return Track(
      title: title ?? this.title,
      artist: artist ?? this.artist,
      duration: duration ?? this.duration,
      durationMs: durationMs ?? this.durationMs,
      albumArt: albumArt ?? this.albumArt,
      previewUrl: previewUrl ?? this.previewUrl,
      isLiked: isLiked ?? this.isLiked,
    );
  }
}

class Track {
  final String title;
  final String artist;
  final String duration;   // formatted string "3:45"
  final int durationMs;    // raw milliseconds
  final String albumArt;
  final String? previewUrl; // optional, for 30s preview playback

  Track({
    required this.title,
    required this.artist,
    required this.duration,
    required this.durationMs,
    required this.albumArt,
    this.previewUrl,
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
      previewUrl: json['preview_url'], // can be null
    );
  }
}
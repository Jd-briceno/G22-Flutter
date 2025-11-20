import 'track_model.dart'; // 👈 importa el modelo Track

class Playlist {
  final String id;
  final String title;
  final String description;
  final String coverUrl;
  final List<Track> tracks;

  Playlist({
    required this.id,
    required this.title,
    required this.description,
    required this.coverUrl,
    required this.tracks,
  });

  Map<String, dynamic> toJson() => {
        "title": title,
        "description": description,
        "coverUrl": coverUrl,
        "tracks": tracks.map((t) => {
              "title": t.title,
              "artist": t.artist,
              "duration": t.duration,
              "durationMs": t.durationMs,
              "albumArt": t.albumArt,
              "previewUrl": t.previewUrl,
              "isLiked": t.isLiked,       
            }).toList(),
      };

  factory Playlist.fromJson(String id, Map<String, dynamic> json) {
    return Playlist(
      id: id,
      title: json["title"] ?? "",
      description: json["description"] ?? "",
      coverUrl: json["coverUrl"] ?? "",
      tracks: (json["tracks"] as List<dynamic>? ?? [])
          .map((t) => Track(
                title: t["title"] ?? "",
                artist: t["artist"] ?? "",
                duration: t["duration"] ?? "0:00",
                durationMs: t["durationMs"] ?? 0,
                albumArt: t["albumArt"] ?? "",
                previewUrl: t["previewUrl"],
                isLiked: t["isLiked"] ?? false,
              ))
          .toList(),
    );
  }
}

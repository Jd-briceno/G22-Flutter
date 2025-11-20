import 'dart:convert';
import 'dart:math';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import '../models/track_model.dart';
import '../services/hive_service.dart';
import '../cache/lru_cache.dart';
import 'deezer_service.dart';

/// 🔥 Agregado: función para enriquecer un track con preview de Deezer
Future<Track> enrichTrackWithDeezerPreview(Track track) async {
  try {
    final deezerService = DeezerPreviewService();
    final previewUrl = await deezerService.fetchPreviewUrl(track.title, track.artist);
    print("🎧 Deezer Preview for ${track.title}: $previewUrl");
    return track.copyWith(previewUrl: previewUrl);
  } catch (e) {
    print("❌ Error fetching preview for ${track.title}: $e");
    return track;
  }
}

class SpotifyService {
  final String _clientId = dotenv.env['SPOTIFY_CLIENT_ID'] ?? '';
  final String _clientSecret = dotenv.env['SPOTIFY_CLIENT_SECRET'] ?? '';

  final LRUCache<String, List<Track>> _memoryCache = LRUCache(10);

  final List<String> _markets = [
    "US","GB","DE","JP","KR","MX","BR","FR","ES","IT",
    "CA","AR","AU","CL","CO","NL","SE","NO","FI","DK",
    "PL","PT","IE","NZ","TR","IL","IN","ID","TH","SG","RU"
  ];

  final Map<String, List<String>> _specialQueries = {
    "j-rock": ["J-Rock", "Japanese Rock", "邦楽ロック"],
    "k-pop": ["K-Pop", "케이팝", "Korean Pop"],
    "medieval": ["Medieval", "Celtic", "Dungeons and dragons"],
    "anisong": ["Anisong", "Anime", "Demon Slayer"],
    "musical": ["Hamilton", "Epic", "Musical"],
  };

  Future<String?> getAccessToken() async {
    final credentials = base64Encode(utf8.encode("$_clientId:$_clientSecret"));

    final response = await http.post(
      Uri.parse("https://accounts.spotify.com/api/token"),
      headers: {
        "Authorization": "Basic $credentials",
        "Content-Type": "application/x-www-form-urlencoded",
      },
      body: {"grant_type": "client_credentials"},
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body)["access_token"];
    } else {
      print("❌ Error getting token: ${response.body}");
      return null;
    }
  }

  Future<List<dynamic>> getGenrePlaylists(String genre) async {
    final token = await getAccessToken();
    if (token == null) return [];

    final playlists = <dynamic>[];
    final random = Random();
    String market = _markets[random.nextInt(_markets.length)];

    List<String> queries = _specialQueries[genre.toLowerCase()] ?? [genre];

    for (final query in queries) {
      final response = await http.get(
        Uri.parse(
          "https://api.spotify.com/v1/search?q=$query&type=playlist&limit=10&market=$market",
        ),
        headers: {"Authorization": "Bearer $token"},
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final items = (data["playlists"]?["items"] ?? []) as List<dynamic>;

        playlists.addAll(
          items.where((item) => item != null && item["id"] != null),
        );
      } else {
        print("❌ Error searching playlists for $query: ${response.body}");
      }
    }

    playlists.shuffle(Random());
    print("🔎 Found ${playlists.length} playlists for $genre in $market");

    return playlists;
  }

  /// 🎶 Obtener canciones + añadir preview desde Deezer
  Future<List<Track>> getPlaylistTracks(String playlistId, {String market = "US"}) async {
    if (_memoryCache.contains(playlistId)) {
      print("⚡ Cargado desde LRU cache: $playlistId");
      return _memoryCache.get(playlistId)!;
    }

    final diskData = HiveService.getTracks(playlistId);
    if (diskData != null) {
      final cachedTracks = diskData.map((e) => Track.fromJson(e)).toList();
      _memoryCache.put(playlistId, cachedTracks);
      print("💾 Cargado desde Hive cache: $playlistId");
      return cachedTracks;
    }

    final token = await getAccessToken();
    if (token == null) return [];

    final response = await http.get(
      Uri.parse("https://api.spotify.com/v1/playlists/$playlistId/tracks?market=$market&limit=100"),
      headers: {"Authorization": "Bearer $token"},
    );

    if (response.statusCode != 200) {
      print("❌ Error fetching tracks: ${response.body}");
      return [];
    }

    final data = jsonDecode(response.body);
    final items = data["items"] as List<dynamic>? ?? [];

    final tracks = items
        .map((item) => item["track"])
        .where((track) =>
            track != null &&
            track["id"] != null &&
            track["name"] != null &&
            track["uri"] != null)
        .map((track) => Track.fromSpotify(track))
        .where((track) => track.title.isNotEmpty)
        .toList();

    tracks.shuffle(Random());

    /// ⬇️ **AQUÍ ES DONDE SE AGREGA EL PREVIEW DE DEEZER**
    final enrichedTracks = await Future.wait(
      tracks.map((t) => enrichTrackWithDeezerPreview(t)),
    );

    final limited = enrichedTracks.take(15).toList();

    _memoryCache.put(playlistId, limited);
    await HiveService.saveTracks(playlistId, limited.map((t) => t.toJson()).toList());

    print("🌐 Descargado de Spotify + previews de Deezer: $playlistId");

    return limited;
  }

  Future<List<Track>> searchTracks(String query, {String market = "US"}) async {
    final token = await getAccessToken();
    if (token == null) return [];

    final response = await http.get(
      Uri.parse("https://api.spotify.com/v1/search?q=$query&type=track&limit=15&market=$market"),
      headers: {"Authorization": "Bearer $token"},
    );

    if (response.statusCode != 200) {
      print("❌ Error searching tracks: ${response.body}");
      return [];
    }

    final data = jsonDecode(response.body);
    final items = (data["tracks"]?["items"] ?? []) as List<dynamic>;

    final results = items
        .map((track) => Track.fromSpotify(track))
        .toList();

    /// ⬇️ También enriquecemos resultados de búsqueda
    return await Future.wait(
      results.map((t) => enrichTrackWithDeezerPreview(t)),
    );
  }

  void clearCache() {
    _memoryCache.clear();
    HiveService.clearTrackCache();
    print("🧹 Caché limpiada completamente (LRU + Hive)");
  }
}

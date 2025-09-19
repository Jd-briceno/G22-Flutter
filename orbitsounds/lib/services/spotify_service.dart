import 'dart:convert';
import 'dart:math';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import '../models/track_model.dart';

class SpotifyService {
  final String _clientId = dotenv.env['SPOTIFY_CLIENT_ID'] ?? '';
  final String _clientSecret = dotenv.env['SPOTIFY_CLIENT_SECRET'] ?? '';

  Future<String?> getAccessToken() async {
    final String credentials =
        base64Encode(utf8.encode("$_clientId:$_clientSecret"));

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

  /// 🌎 Lista de mercados (random para variar resultados)
  final List<String> _markets = [
    "US","GB","DE","JP","KR","MX","BR","FR","ES","IT",
    "CA","AR","AU","CL","CO","NL","SE","NO","FI","DK",
    "PL","PT","IE","NZ","TR","IL","IN","ID","TH","SG",
    "RU"
  ];

  /// 🎯 Queries especiales por género
  final Map<String, List<String>> _specialQueries = {
    "j-rock": ["J-Rock", "Japanese Rock", "邦楽ロック"],
    "k-pop": ["K-Pop", "케이팝", "Korean Pop"],
    "medieval":["Medieval","Celtic","Dungeons and dragons"],
    "anisong":["Anisong","Anime","Demon Slayer"]
  };

  /// 🔍 Obtener playlists de un género (directo con search)
  Future<List<dynamic>> getGenrePlaylists(String genre) async {
    final token = await getAccessToken();
    if (token == null) return [];

    final playlists = <dynamic>[];
    final random = Random();

    // 🎲 Elegir mercado aleatorio
    String market = _markets[random.nextInt(_markets.length)];

    // ✅ Obtener queries especiales si existen, sino usamos el género literal
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
          items.where((item) => item != null && item["id"] != null).toList(),
        );
      } else {
        print("❌ Error searching playlists for $query in $market: ${response.body}");
      }
    }

    // 🔀 Mezclar resultados
    playlists.shuffle(Random());

    print("🔎 Found ${playlists.length} playlists for $genre in $market");

    return playlists;
  }

  /// 🎶 Obtener canciones dentro de una playlist (máximo 15 aleatorias)
  Future<List<Track>> getPlaylistTracks(String playlistId, {String market = "US"}) async {
    final token = await getAccessToken();
    if (token == null) return [];

    final response = await http.get(
      Uri.parse(
        "https://api.spotify.com/v1/playlists/$playlistId/tracks?market=$market&limit=100",
      ),
      headers: {"Authorization": "Bearer $token"},
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final items = data["items"] as List<dynamic>? ?? [];

      final tracks = items
          .map((item) => item["track"])
          .where((track) => track != null && track["id"] != null)
          .map((track) => Track.fromSpotify(track))
          .where((track) => track.title.isNotEmpty)
          .toList();

      // 🔀 Mezclar y limitar a 15
      tracks.shuffle(Random());
      return tracks.take(15).toList();
    } else {
      print("❌ Error fetching tracks: ${response.body}");
      return [];
    }
  }
  /// 🔍 Buscar canciones directamente
Future<List<Track>> searchTracks(String query, {String market = "US"}) async {
  final token = await getAccessToken();
  if (token == null) return [];

  final response = await http.get(
    Uri.parse(
      "https://api.spotify.com/v1/search?q=$query&type=track&limit=15&market=$market",
    ),
    headers: {"Authorization": "Bearer $token"},
  );

  if (response.statusCode == 200) {
    final data = jsonDecode(response.body);
    final items = (data["tracks"]?["items"] ?? []) as List<dynamic>;

    return items
        .where((track) => track != null && track["id"] != null)
        .map((track) => Track.fromSpotify(track))
        .toList();
  } else {
    print("❌ Error searching tracks: ${response.body}");
    return [];
  }
}

}

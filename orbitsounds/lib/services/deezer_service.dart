import 'dart:convert';
import 'package:http/http.dart' as http;

class DeezerPreviewService {
  Future<String?> fetchPreviewUrl(String title, String artist) async {
    final query = "$title $artist";
    final url = Uri.parse("https://api.deezer.com/search?q=${Uri.encodeComponent(query)}&limit=1");
    final response = await http.get(url);

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final results = (data["data"] as List<dynamic>?) ?? [];
      if (results.isNotEmpty) {
        return results[0]["preview"];
      }
    }
    return null;
  }
}

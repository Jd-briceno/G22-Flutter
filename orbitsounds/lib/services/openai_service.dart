import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:orbitsounds/models/openai_model.dart';


class OpenAIService {
  final String _baseUrl = "https://api.openai.com/v1/chat/completions";
  final String _apiKey = dotenv.env['OPENAI_API_KEY']!;

  Future<OpenAIResponse> generatePlaylistDescription(String genre) async {
    final response = await http.post(
      Uri.parse(_baseUrl),
      headers: {
        "Content-Type": "application/json",
        "Authorization": "Bearer $_apiKey",
      },
      body: jsonEncode({
        "model": "gpt-4o-mini",
        "messages": [
          {
            "role": "system",
            "content":
                "You are a creative assistant that writes catchy and engaging playlist descriptions."
          },
          {
            "role": "user",
            "content":
                "Write a short playlist description for the music genre: $genre. Be creative, maximum 5 sentences."
          }
        ],
        "max_tokens": 60,
      }),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return OpenAIResponse.fromJson(data);
    } else {
      throw Exception("Failed to fetch description: ${response.body}");
    }
  }
}

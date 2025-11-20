import 'dart:convert';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import '../models/weather_model.dart';

class WeatherService {
  final String _baseUrl = "https://api.openweathermap.org/data/2.5/weather";
  final String _apiKey = dotenv.env['OPENWEATHER_API_KEY'] ?? '';

  Future<Weather> fetchWeather(double lat, double lon) async {
    final url = Uri.parse("$_baseUrl?lat=$lat&lon=$lon&appid=$_apiKey&units=metric&lang=es");

    final response = await http.get(url);

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return Weather.fromJson(data);
    } else {
      throw Exception("Error al obtener el clima: ${response.statusCode}");
    }
  }
}

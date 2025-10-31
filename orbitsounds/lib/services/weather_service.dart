import 'dart:convert';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import '../models/weather_model.dart';
import 'package:heroicons/heroicons.dart';
import 'package:flutter/material.dart';

class WeatherService {
  final String _baseUrl = "https://api.openweathermap.org/data/2.5/weather";
  final String _apiKey = dotenv.env['OPENWEATHER_API_KEY'] ?? '';

  // Devuelve el ícono adecuado según la condición del clima
  HeroIcons getIconForCondition(String condition) {
    condition = condition.toLowerCase();

    if (condition.contains("thunder")) {
      return HeroIcons.bolt;
    }
    if (condition.contains("rain")) {
      return HeroIcons.cloud;
    }
    if (condition.contains("snow")) {
      return HeroIcons.sparkles;
    }
    if (condition.contains("cloud")) {
      return HeroIcons.cloud;
    }
    if (condition.contains("clear")) {
      return HeroIcons.sun;
    }
    if (condition.contains("mist") || condition.contains("fog")) {
      return HeroIcons.cloud;
    }

    return HeroIcons.moon;
  }

  // Devuelve un color de acento según la condición
  Color getColorForCondition(String condition) {
    condition = condition.toLowerCase();
    if (condition.contains("thunder")) return const Color(0xFF9EA7FF);
    if (condition.contains("rain")) return const Color(0xFF5AC8FA);
    if (condition.contains("cloud")) return const Color(0xFFE9E8EE);
    if (condition.contains("clear")) return const Color(0xFFFFD60A);
    if (condition.contains("snow")) return const Color(0xFFBBDEFB);
    if (condition.contains("mist") || condition.contains("fog")) return const Color(0xFFB0BEC5);
    return const Color(0xFFE9E8EE);
  }

  // Consulta la API y devuelve un WeatherModel
  Future<WeatherModel> fetchWeather(double lat, double lon) async {
    final url = Uri.parse("$_baseUrl?lat=$lat&lon=$lon&appid=$_apiKey&units=metric&lang=es");
    final response = await http.get(url);

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final condition = data['weather'][0]['main'] ?? 'Desconocido';
      final description = data['weather'][0]['description'] ?? 'Desconocido';
      final temperature = data['main']['temp']?.toDouble() ?? 0.0;
      final icon = getIconForCondition(condition);
      final color = getColorForCondition(condition);

      return WeatherModel(
        condition: condition, // ✅ agregado correctamente
        description: description,
        temperature: temperature,
        iconData: icon,
        iconColor: color,
      );
    } else {
      throw Exception("Error al obtener el clima: ${response.statusCode}");
    }
  }
}

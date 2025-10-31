// lib/models/weather_model.dart
import 'package:flutter/material.dart';
import 'package:heroicons/heroicons.dart';

class WeatherModel {
  final String condition;     // p.ej. "Clouds", "Clear"
  final double temperature;   // en °C (metric)
  final String description;   // p.ej. "nubes dispersas"
  final HeroIcons iconData;   // ícono heroicons para renderizar en UI
  final Color iconColor;      // color de acento para UI

  WeatherModel({
    required this.condition,
    required this.temperature,
    required this.description,
    required this.iconData,
    required this.iconColor,
  });

  factory WeatherModel.fromJson(Map<String, dynamic> json) {
    return WeatherModel(
      condition: (json['weather']?[0]?['main'] as String?) ?? 'Unknown',
      description: (json['weather']?[0]?['description'] as String?) ?? 'Desconocido',
      temperature: (json['main']?['temp'] as num?)?.toDouble() ?? 0.0,
      // Por defecto, usamos el ícono de sol; el servicio lo ajustará según condición.
      iconData: HeroIcons.sun,
      iconColor: Colors.white,
    );
  }
}

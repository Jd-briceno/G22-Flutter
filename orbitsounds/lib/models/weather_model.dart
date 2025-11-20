class Weather {
  final String condition; // clear, clouds, rain, thunderstorm, etc
  final double temperature;
  final String description;

  Weather({
    required this.condition,
    required this.temperature,
    required this.description,
  });

  factory Weather.fromJson(Map<String, dynamic> json) {
    return Weather(
      condition: json['weather'][0]['main'].toLowerCase(),
      description: json['weather'][0]['description'],
      temperature: (json['main']['temp']).toDouble(),
    );
  }
}

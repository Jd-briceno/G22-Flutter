class ListeningGoal {
  final String genre;
  final int targetMinutes;
  int listenedMinutes;
  bool achieved;

  /// 🔹 Nuevos campos
  int songsPlayed;     // Número de canciones escuchadas del género
  int likesGiven;      // Cuántas canciones del género fueron marcadas como favoritas
  String? lastSession; // Fecha de última sesión (para estadísticas o streaks)
  int sessionsCount; // Sesiones para promedio

  ListeningGoal({
    required this.genre,
    required this.targetMinutes,
    this.listenedMinutes = 0,
    this.achieved = false,
    this.songsPlayed = 0,
    this.likesGiven = 0,
    this.lastSession,
    this.sessionsCount = 0, // 👈 Valor inicial

  });

  factory ListeningGoal.fromMap(Map<String, dynamic> map) {
    return ListeningGoal(
      genre: map['genre'] ?? '',
      targetMinutes: (map['targetMinutes'] is num)
          ? (map['targetMinutes'] as num).toInt()
          : 60,
      listenedMinutes: (map['listenedMinutes'] is num)
          ? (map['listenedMinutes'] as num).toInt()
          : 0,
      achieved: map['achieved'] ?? false,
      songsPlayed: (map['songsPlayed'] is num)
          ? (map['songsPlayed'] as num).toInt()
          : 0,
      likesGiven: (map['likesGiven'] is num)
          ? (map['likesGiven'] as num).toInt()
          : 0,
      lastSession: map['lastSession'],
      sessionsCount: (map['sessionsCount'] ?? 0).toInt(), // 👈
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'genre': genre,
      'targetMinutes': targetMinutes,
      'listenedMinutes': listenedMinutes,
      'achieved': achieved,
      'songsPlayed': songsPlayed,
      'likesGiven': likesGiven,
      'lastSession': lastSession,
      'sessionsCount': sessionsCount, // 👈
    };
  }
}

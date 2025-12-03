// session_data.dart

class SessionData {
  final List<String> selectedEmotions;
  final String notes;
  final List<String> voiceNotePaths; // rutas locales de archivos de audio
  final List<String> albumArts;       // URLs o paths de carátulas

  SessionData({
    required this.selectedEmotions,
    required this.notes,
    required this.voiceNotePaths,
    required this.albumArts,
  });

  Map<String, dynamic> toMap() {
    return {
      'selectedEmotions': selectedEmotions,
      'notes': notes,
      'voiceNotePaths': voiceNotePaths,
      'albumArts': albumArts,
    };
  }

  factory SessionData.fromMap(Map<String, dynamic> map) {
    return SessionData(
      selectedEmotions: List<String>.from(map['selectedEmotions'] ?? <String>[]),
      notes: map['notes'] ?? '',
      voiceNotePaths: List<String>.from(map['voiceNotePaths'] ?? <String>[]),
      albumArts: List<String>.from(map['albumArts'] ?? <String>[]),
    );
  }
}

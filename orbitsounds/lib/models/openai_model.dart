class OpenAIResponse {
  final String content;

  OpenAIResponse({required this.content});

  factory OpenAIResponse.fromJson(Map<String, dynamic> json) {
    final choices = json['choices'] as List<dynamic>;
    final message = choices.first['message'];
    return OpenAIResponse(content: message['content'].toString().trim());
  }
}

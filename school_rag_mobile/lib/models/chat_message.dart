class ChatMessage {
  final String text;
  final bool isUser;

  ChatMessage({required this.text, required this.isUser});

  Map<String, dynamic> toJson() => {
    'role': isUser ? 'user' : 'model',
    'content': text
  };

  factory ChatMessage.fromJson(Map<String, dynamic> json) {
    return ChatMessage(
      text: json['content'],
      isUser: json['role'] == 'user',
    );
  }
}

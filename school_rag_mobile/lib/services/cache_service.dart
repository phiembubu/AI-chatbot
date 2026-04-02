import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/chat_message.dart';

class CacheService {
  static const String chatKey = 'cached_chat_history';

  static Future<void> saveHistory(List<ChatMessage> messages) async {
    final prefs = await SharedPreferences.getInstance();
    // Cache last 20 messages as requested for offline viewing
    final toSave = messages.length > 20 
        ? messages.sublist(messages.length - 20) 
        : messages;
    final String encodedData = jsonEncode(toSave.map((e) => e.toJson()).toList());
    await prefs.setString(chatKey, encodedData);
  }

  static Future<List<ChatMessage>> loadHistory() async {
    final prefs = await SharedPreferences.getInstance();
    final String? encodedData = prefs.getString(chatKey);
    if (encodedData == null) return [];
    
    final List<dynamic> decodedData = jsonDecode(encodedData);
    return decodedData.map((e) => ChatMessage.fromJson(e)).toList();
  }
}

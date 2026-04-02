import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/chat_message.dart';

class ApiService {
  // Use 10.0.2.2 for Android Emulator connecting to localhost
  // Use actual IPv4 address (e.g., 192.168.x.x) for physical mobile devices
  static const String baseUrl = "http://192.168.68.133:8000"; 

  static Future<String> askQuestion(String question, List<ChatMessage> history) async {
    final url = Uri.parse('$baseUrl/ask');
    try {
      final response = await http.post(
        url,
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "question": question,
          "chat_history": history.map((e) => e.toJson()).toList(),
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['answer'];
      } else {
        throw Exception("Server error: ${response.statusCode}");
      }
    } catch (e) {
      throw Exception("Network error. Make sure FastAPI is running on 0.0.0.0.");
    }
  }

  static Future<bool> submitFeedback(String question, String answer, String rating) async {
    final url = Uri.parse('$baseUrl/feedback');
    try {
      final response = await http.post(
        url,
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "question": question,
          "answer": answer,
          "rating": rating,
          "username": "MobileAppUser"
        }),
      );
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  static Future<bool> uploadDocument(String filePath) async {
    final url = Uri.parse('$baseUrl/admin/upload');
    try {
      var request = http.MultipartRequest('POST', url);
      request.files.add(await http.MultipartFile.fromPath('file', filePath));
      var response = await request.send();
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }
}

import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:file_picker/file_picker.dart';

class UploadService {
  // Đảm bảo IP này giống với ApiService hoặc sử dụng biến môi trường chung
  static const String baseUrl = "http://192.168.68.133:8000"; 

  // Hàm được di chuyển và sửa đổi từ api_service.dart (nếu cần dùng lại)
  static Future<void> uploadPDF() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf'],
    );

    if (result != null && result.files.single.path != null) {
      var request = http.MultipartRequest(
        'POST', 
        Uri.parse('$baseUrl/admin/upload')
      );
      
      request.files.add(await http.MultipartFile.fromPath('file', result.files.single.path!));

      var response = await request.send();
      if (response.statusCode == 200) {
        print("Upload thành công!");
      } else {
        print("Lỗi upload: ${response.statusCode}");
      }
    }
  }

  // Lấy danh sách file từ máy chủ
  static Future<List<String>> getFiles() async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/admin/files'));
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        
        // Hỗ trợ cả 2 dạng JSON trả về: List hoặc Map chứa List
        if (data is List) {
          return data.map((e) => e.toString()).toList();
        } else if (data is Map && data.containsKey('files')) {
          return List<String>.from(data['files']);
        } else if (data is Map && data.containsKey('documents')) {
          return List<String>.from(data['documents']);
        } else if (data is Map && data.containsKey('file_names')) {
           return List<String>.from(data['file_names']);
        }
        return [];
      } else {
        throw Exception("Server trả về mã lỗi: ${response.statusCode}");
      }
    } catch (e) {
      throw Exception("Lỗi kết nối: $e");
    }
  }

  // Xóa tài liệu
  static Future<bool> deleteFile(String fileName) async {
    try {
      final response = await http.delete(Uri.parse('$baseUrl/admin/delete/$fileName'));
      return response.statusCode == 200;
    } catch (e) {
      print("Lỗi khi xóa file: $e");
      return false;
    }
  }
}

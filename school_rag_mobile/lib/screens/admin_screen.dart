import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import '../services/api_service.dart';
import 'admin_document_manager.dart';

class AdminScreen extends StatefulWidget {
  const AdminScreen({Key? key}) : super(key: key);

  @override
  State<AdminScreen> createState() => _AdminScreenState();
}

class _AdminScreenState extends State<AdminScreen> {
  bool _isUploading = false;
  String? _statusMessage;

  Future<void> _pickAndUpload() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['txt'],
    );

    if (result != null && result.files.single.path != null) {
      setState(() {
        _isUploading = true;
        _statusMessage = 'Uploading ${result.files.single.name}...';
      });

      bool success = await ApiService.uploadDocument(result.files.single.path!);

      setState(() {
        _isUploading = false;
        _statusMessage = success 
            ? 'Success: Document ingested into Vector DB.' 
            : 'Error: Failed to upload to backend.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Card(
            child: Padding(
              padding: EdgeInsets.all(16.0),
              child: Row(
                children: [
                  Icon(Icons.dns, size: 40, color: Colors.indigo),
                  SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Backend Status', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                        Text('Connected (0.0.0.0:8000)', style: TextStyle(color: Colors.green)),
                      ],
                    ),
                  )
                ],
              ),
            ),
          ),
          const SizedBox(height: 32),
          const Text('Quản lý cơ sở dữ liệu', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          const Text('Chọn file .txt chứa các quy định, chính sách của trường để nạp vào cơ sở dữ liệu RAG một cách động.'),
          const SizedBox(height: 24),
          
          ElevatedButton.icon(
            onPressed: _isUploading ? null : _pickAndUpload,
            icon: _isUploading 
                ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                : const Icon(Icons.upload_file),
            label: Text(_isUploading ? 'Processing...' : 'Chọn dữ liệu mới'),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.all(16),
              backgroundColor: Colors.indigo,
              foregroundColor: Colors.white,
            ),
          ),
          const SizedBox(height: 16),
          OutlinedButton.icon(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const AdminDocumentManager(),
                ),
              );
            },
            icon: const Icon(Icons.folder_shared),
            label: const Text('Quản lý & Xóa file trên Server'),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.all(16),
              foregroundColor: Colors.indigo,
              side: const BorderSide(color: Colors.indigo, width: 1.5),
            ),
          ),
          const SizedBox(height: 24),
          
          if (_statusMessage != null)
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: _statusMessage!.startsWith('Success') ? Colors.green.shade50 : Colors.red.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: _statusMessage!.startsWith('Success') ? Colors.green : Colors.red),
              ),
              child: Text(
                _statusMessage!,
                style: TextStyle(
                  color: _statusMessage!.startsWith('Success') ? Colors.green.shade800 : Colors.red.shade800,
                  fontWeight: FontWeight.bold
                ),
                textAlign: TextAlign.center,
              ),
            ),
        ],
      ),
    );
  }
}

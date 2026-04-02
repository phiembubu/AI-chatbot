import 'package:flutter/material.dart';
import '../services/upload_service.dart';

class AdminDocumentManager extends StatefulWidget {
  const AdminDocumentManager({Key? key}) : super(key: key);

  @override
  State<AdminDocumentManager> createState() => _AdminDocumentManagerState();
}

class _AdminDocumentManagerState extends State<AdminDocumentManager> {
  List<String> _files = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _fetchFiles();
  }

  Future<void> _fetchFiles() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final files = await UploadService.getFiles();
      setState(() {
        _files = files;
      });
    } catch (e) {
      // Hiển thị thông báo nếu có lỗi
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Lỗi khi tải danh sách file: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _deleteFile(String fileName) async {
    bool confirm = await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Xác nhận xóa'),
        content: Text('Bạn có chắc chắn muốn xóa file "$fileName" không? Hành động này sẽ không thể hoàn tác.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Hủy', style: TextStyle(color: Colors.blueGrey)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Xóa', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    ) ?? false;

    if (!confirm) return;

    setState(() {
      _isLoading = true; // Hiện loading trong lúc xóa
    });

    bool success = await UploadService.deleteFile(fileName);

    if (!mounted) return;

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Đã xóa $fileName thành công'), 
          backgroundColor: Colors.green,
        ),
      );
      // Tự động tải lại danh sách sau khi xóa thành công
      _fetchFiles(); 
    } else {
      setState(() {
        _isLoading = false; // Tắt loading nếu lỗi để người dùng thấy
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Lỗi khi xóa file! Vui lòng thử lại.'), 
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Quản lý Tài liệu PDF', style: TextStyle(color: Colors.white)),
        backgroundColor: Colors.blueGrey,
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _fetchFiles,
            tooltip: 'Làm mới danh sách',
          ),
        ],
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(color: Colors.blueGrey),
            SizedBox(height: 16),
            Text('Đang xử lý...', style: TextStyle(color: Colors.blueGrey)),
          ],
        ),
      );
    }

    if (_files.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.folder_open, size: 64, color: Colors.blueGrey),
            SizedBox(height: 16),
            Text(
              'Không có file nào trên Server', 
              style: TextStyle(color: Colors.blueGrey, fontSize: 16, fontWeight: FontWeight.w500),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _fetchFiles, // Cho phép vuốt chóp xuống để làm mới
      color: Colors.blueGrey,
      child: ListView.builder(
        padding: const EdgeInsets.all(12),
        itemCount: _files.length,
        itemBuilder: (context, index) {
          final fileName = _files[index];
          return Card(
            margin: const EdgeInsets.symmetric(vertical: 6),
            elevation: 2,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            child: ListTile(
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              leading: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.picture_as_pdf, color: Colors.blue, size: 28),
              ),
              title: Text(
                fileName,
                style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.blueGrey, fontSize: 16),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              trailing: IconButton(
                icon: const Icon(Icons.delete, color: Colors.red),
                tooltip: 'Xóa tài liệu này',
                onPressed: () => _deleteFile(fileName),
              ),
            ),
          );
        },
      ),
    );
  }
}

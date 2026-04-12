import 'package:flutter/material.dart';

import 'package:image_picker/image_picker.dart';
import 'dart:io';

class PackagingScreen extends StatefulWidget {
  final String batchId; // Nhận mã lô hàng từ Nông dân
  final String farmerName;
  const PackagingScreen({
    super.key,
    required this.batchId,
    required this.farmerName,
  });

  @override
  State<PackagingScreen> createState() => _PackagingScreenState();
}

class _PackagingScreenState extends State<PackagingScreen> {
  // MockData: Lô hàng nguyên liệu nhận từ Nông dân
  final String rawBatchId = "BATCH-1766898237504-853";
  final String farmerName = "Hai ông Farm";

  File? _selectedImage;

  Future<void> _pickImage(ImageSource source) async {
    final ImagePicker picker = ImagePicker();
    // Chọn ảnh từ source được truyền vào (Camera hoặc Gallery)
    final XFile? image = await picker.pickImage(
      source: source,
      imageQuality: 50,
      maxWidth: 800,
    );

    if (image != null) {
      setState(() {
        _selectedImage = File(image.path);
      });
    }
  }

  void _showImageSourceActionSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min, // Chỉ chiếm chiều cao vừa đủ
          children: [
            const Text(
              "Chọn hình ảnh",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                // Nút CHỤP ẢNH
                InkWell(
                  onTap: () {
                    Navigator.pop(context); // Đóng menu
                    _pickImage(ImageSource.camera); // Gọi Camera
                  },
                  child: Column(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(15),
                        decoration: BoxDecoration(
                          color: Colors.blue.withOpacity(0.1),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.camera_alt,
                          color: Colors.blue,
                          size: 30,
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text("Chụp ảnh"),
                    ],
                  ),
                ),

                // Nút THƯ VIỆN
                InkWell(
                  onTap: () {
                    Navigator.pop(context); // Đóng menu
                    _pickImage(ImageSource.gallery); // Gọi Gallery
                  },
                  child: Column(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(15),
                        decoration: BoxDecoration(
                          color: Colors.green.withOpacity(0.1),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.photo_library,
                          color: Colors.green,
                          size: 30,
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text("Thư viện"),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          "Sản xuất & Đóng gói",
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: Colors.green[700], // Màu chủ đạo AgriTrace [cite: 148]
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1. Thông tin nguồn gốc nguyên liệu
            _buildSectionTitle("Nguồn gốc nguyên liệu"),
            Card(
              elevation: 2,
              color: Colors.green[50],
              child: ListTile(
                leading: Icon(Icons.agriculture, color: Colors.green),
                title: Text("Mã lô: $rawBatchId"),
                subtitle: Text("Nguồn: $farmerName"),
                trailing: Icon(
                  Icons.verified,
                  color: Colors.blue,
                ), // Icon xác thực Blockchain
              ),
            ),
            SizedBox(height: 20),

            // 2. Form nhập thông tin đóng gói
            _buildSectionTitle("Thông tin thành phẩm"),
            _buildTextField("Tên thành phẩm", "VD: Nước ép dưa lưới đóng chai"),
            _buildTextField("Quy cách đóng gói", "VD: Thùng 24 chai / 500ml"),
            _buildTextField("Số lượng thành phẩm", "VD: 500"),
            _buildTextField("Hạn sử dụng", "VD: 12 tháng kể từ ngày đóng gói"),

            SizedBox(height: 20),

            // 3. Khu vực hình ảnh thực tế (Mock)
            _buildSectionTitle("Hình ảnh đóng gói"),
            InkWell(
              onTap: () => _showImageSourceActionSheet(context),
              child: Container(
                width: double.infinity,
                height: 200,
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey),
                  borderRadius: BorderRadius.circular(10),
                  color: Colors.grey[100],
                ),
                child: _selectedImage != null
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: Image.file(_selectedImage!, fit: BoxFit.cover),
                      )
                    : Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: const [
                          Icon(Icons.camera_alt, size: 50, color: Colors.grey),
                          Text(
                            "Chạm để chụp/chọn ảnh",
                            style: TextStyle(color: Colors.grey),
                          ),
                        ],
                      ),
              ),
            ),

            SizedBox(height: 30),

            // 4. Nút bấm xác nhận Blockchain
            SizedBox(
              width: double.infinity,
              height: 55,
              child: ElevatedButton.icon(
                onPressed: () => _showSuccessDialog(context),
                icon: Icon(Icons.cloud_upload),
                label: Text(
                  "XÁC NHẬN & GHI LÊN BLOCKCHAIN",
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green[700],
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
            ),
            Center(
              child: Padding(
                padding: const EdgeInsets.only(top: 8.0),
                child: Text(
                  "Cơ chế Gasless: Phí giao dịch được tài trợ 100%",
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                    fontStyle: FontStyle.italic,
                  ),
                ), // Nhấn mạnh Relayer
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: Colors.green[800],
        ),
      ),
    );
  }

  Widget _buildTextField(String label, String hint) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 15.0),
      child: TextFormField(
        decoration: InputDecoration(
          labelText: label,
          hintText: hint,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
          focusedBorder: OutlineInputBorder(
            borderSide: BorderSide(color: Colors.green),
          ),
        ),
      ),
    );
  }

  void _showSuccessDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.check_circle, color: Colors.green),
            SizedBox(width: 10),
            Text("Thành công!"),
          ],
        ),
        content: Text(
          "Dữ liệu đóng gói đã được xử lý qua Relayer và lưu trữ bất biến trên mạng Polygon.",
        ), // Giải thích cơ chế [cite: 58, 126]
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text("ĐÓNG"),
          ),
        ],
      ),
    );
  }
}

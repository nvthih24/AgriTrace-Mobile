import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:qr_flutter/qr_flutter.dart';

import 'dart:convert';

import 'add_crop_screen.dart';
import 'profile_screen.dart';
import 'harvest_product_screen.dart';
import 'care_diary_screen.dart';
import 'notification_screen.dart';
import 'qr_scanner_screen.dart';
import 'packaging_screen.dart'; // Đảm bảo đã import trang này

import '../configs/constants.dart';
import '../widgets/statistics_chart.dart';

const Color kManufacturerPrimaryColor = Color(
  0xFF1A237E,
); // Màu xanh Indigo cho Nhà máy

class ManufacturerMainScreen extends StatefulWidget {
  const ManufacturerMainScreen({super.key});
  @override
  State<ManufacturerMainScreen> createState() => _ManufacturerMainScreenState();
}

class _ManufacturerMainScreenState extends State<ManufacturerMainScreen> {
  int _selectedIndex = 0;

  // SỬA LỖI: Không gọi chính ManufacturerMainScreen ở đây để tránh đệ quy
  static final List<Widget> _pages = [
    const ManufacturerDashboardTab(),
    const NotificationScreen(),
    const ProfileScreen(),
  ];

  void _onItemTapped(int index) {
    setState(() => _selectedIndex = index);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _pages[_selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(
            icon: Icon(Icons.dashboard),
            label: 'Hệ quản trị',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.notifications),
            label: 'Thông báo',
          ),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Cá nhân'),
        ],
        currentIndex: _selectedIndex,
        selectedItemColor: kManufacturerPrimaryColor,
        onTap: _onItemTapped,
      ),
    );
  }
}

class ManufacturerDashboardTab extends StatefulWidget {
  const ManufacturerDashboardTab({super.key});
  @override
  State<ManufacturerDashboardTab> createState() =>
      _ManufacturerDashboardTabState();
}

class _ManufacturerDashboardTabState extends State<ManufacturerDashboardTab> {
  List<dynamic> _products = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchProducts();
  }

  Future<void> _fetchProducts() async {
    // 1. Tạo hiệu ứng load nhẹ (0.5 giây) để demo trông giống như đang tải dữ liệu thật
    setState(() => _isLoading = true);
    await Future.delayed(const Duration(milliseconds: 500));

    // 2. Dữ liệu giả (Mock Data) chuẩn cấu trúc backend của ông
    final List<Map<String, dynamic>> mockData = [
      {
        "_id": "BATCH-1766888-863",
        "name": "Dưa lưới Gallia",
        "status":
            "harvested", // Trạng thái: Đã thu hoạch (chờ nhà máy đóng gói)
        "farmId": {"name": "Hai Ông Farm"},
      },
      {
        "_id": "BATCH-2026-041",
        "name": "Khổ qua rừng",
        "status": "at_factory", // Trạng thái: Đã nhập kho nhà máy
        "farmId": {"name": "Hợp tác xã Hmong Farm"},
      },
      {
        "_id": "BATCH-COFFEE-007",
        "name": "Cà phê Robusta",
        "status": "harvested",
        "farmId": {"name": "Lâm Đồng Green Farm"},
      },
      {
        "_id": "BATCH-FRUIT-99",
        "name": "Thanh long ruột đỏ",
        "status": "at_factory",
        "farmId": {"name": "Farm Bình Thuận"},
      },
    ];

    // 3. Cập nhật giao diện
    setState(() {
      _products = mockData;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "Hệ quản trị Nhà máy",
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        backgroundColor: kManufacturerPrimaryColor,
        actions: [
          IconButton(
            icon: const Icon(Icons.qr_code_scanner, color: Colors.white),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const QrScannerScreen()),
            ),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _fetchProducts,
              child: ListView.builder(
                padding: const EdgeInsets.all(12),
                itemCount: _products.length,
                itemBuilder: (context, index) =>
                    _ProductCard(product: _products[index]),
              ),
            ),
    );
  }
}

class _ProductCard extends StatelessWidget {
  final dynamic product;
  const _ProductCard({required this.product});

  @override
  Widget build(BuildContext context) {
    // SỬA LỖI: Khai báo các biến bị undefined ở đây
    final id = product['_id'] ?? '';
    final name = product['name'] ?? 'Không tên';
    final farmName = product['farmId']?['name'] ?? 'Nông trại chưa xác định';
    final status = product['status'] ?? '';

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 3,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    name,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.indigo,
                    ),
                  ),
                ),
                _buildStatusChip(status),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              "Nguồn gốc: $farmName",
              style: TextStyle(color: Colors.grey[600]),
            ),
            const SizedBox(height: 4),
            Text(
              "Mã lô: $id",
              style: const TextStyle(fontSize: 12, color: Colors.grey),
            ),
            const Divider(height: 24),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                // Nút xem lịch sử gốc gác từ nông dân
                SizedBox(
                  width: (MediaQuery.of(context).size.width - 60) / 2,
                  child: OutlinedButton.icon(
                    onPressed: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) =>
                            CareDiaryScreen(productId: id, productName: name),
                      ), // Dùng id đã khai báo
                    ),
                    icon: const Icon(Icons.history_edu, size: 18),
                    label: const Text(
                      "Gốc gác",
                      style: TextStyle(fontSize: 12),
                    ),
                  ),
                ),

                // SỬA LỖI: Truyền đúng productId và productName cho PackagingScreen
                SizedBox(
                  width: (MediaQuery.of(context).size.width - 60) / 2,
                  child: ElevatedButton.icon(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => PackagingScreen(
                            batchId: id, // Truyền id vào batchId
                            farmerName:
                                farmName, // Truyền farmName vào farmerName
                          ),
                        ),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.indigo[700],
                      padding: const EdgeInsets.symmetric(vertical: 10),
                    ),
                    icon: const Icon(
                      Icons.inventory_2,
                      color: Colors.white,
                      size: 18,
                    ),
                    label: const Text(
                      "Đóng gói",
                      style: TextStyle(color: Colors.white, fontSize: 13),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusChip(String status) {
    Color color = Colors.grey;
    String text = status;
    switch (status) {
      case 'harvested':
        color = Colors.orange;
        text = "Đã thu hoạch";
        break;
      case 'at_factory':
        color = Colors.blue;
        text = "Tại nhà máy";
        break;
      case 'packaged':
        color = Colors.green;
        text = "Đã đóng gói";
        break;
    }
    return Chip(
      label: Text(
        text,
        style: const TextStyle(color: Colors.white, fontSize: 10),
      ),
      backgroundColor: color,
      padding: EdgeInsets.zero,
      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
    );
  }
}

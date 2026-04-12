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
import 'packaging_screen.dart';

import '../configs/constants.dart';
import '../widgets/statistics_chart.dart';

const Color kFarmerPrimaryColor = Color(0xFF2E7D32);

class FarmerMainScreen extends StatefulWidget {
  const FarmerMainScreen({super.key});
  @override
  State<FarmerMainScreen> createState() => _FarmerMainScreenState();
}

class _FarmerMainScreenState extends State<FarmerMainScreen> {
  int _selectedIndex = 0;

  static final List<Widget> _pages = [
    const FarmerDashboardTab(),
    const NotificationScreen(),
    const ProfileScreen(),
  ];

  // void _onItemTapped(int index) {
  //   setState(() => _selectedIndex = index);
  // }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _pages[_selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.dashboard),
            label: 'Trang chủ',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.notifications),
            label: 'Thông báo',
          ),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Tài khoản'),
        ],
        currentIndex: _selectedIndex,
        selectedItemColor: kFarmerPrimaryColor,
        unselectedItemColor: Colors.grey,
        onTap: (index) => setState(() => _selectedIndex = index),
        type: BottomNavigationBarType.fixed,
      ),
    );
  }
}

// ===============================================
// DASHBOARD VỚI DỮ LIỆU THẬT & LOGIC CHUẨN
// ===============================================
class FarmerDashboardTab extends StatefulWidget {
  const FarmerDashboardTab({super.key});
  @override
  State<FarmerDashboardTab> createState() => _FarmerDashboardTabState();
}

class _FarmerDashboardTabState extends State<FarmerDashboardTab> {
  // bool _isSearching = false;
  // final TextEditingController _searchController = TextEditingController();
  // String _searchKeyword = "";
  // String _selectedStatus = "Tất cả";

  List<Map<String, dynamic>> myCrops = [];
  List<Map<String, dynamic>> _foundProducts = [];
  bool isLoading = true;
  String errorMessage = "";
  List<int> _statsData = [0, 0, 0, 0];

  @override
  void initState() {
    super.initState();
    _loadMyProducts();
  }

  // GỌI API LẤY DANH SÁCH SẢN PHẨM THẬT
  Future<void> _loadMyProducts() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');

    if (token == null) {
      setState(() {
        errorMessage = "Chưa đăng nhập";
        isLoading = false;
      });
      return;
    }

    try {
      final response = await http.get(
        Uri.parse('${Constants.baseUrl}/products/my-products'),
        headers: {'Authorization': 'Bearer $token'},
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        List<dynamic> rawList = data['products'];
        List<Map<String, dynamic>> parsedList = rawList
            .map((e) => Map<String, dynamic>.from(e))
            .toList();

        setState(() {
          myCrops = parsedList;
          _foundProducts = List.from(myCrops);
          isLoading = false;
        });
        _calculateRealStats(parsedList);
      } else {
        throw Exception("Lỗi server");
      }
    } catch (e) {
      setState(() {
        errorMessage = "Lỗi kết nối: $e";
        isLoading = false;
      });
    }
  }

  // 🔥 HÀM TÍNH TOÁN DỮ LIỆU THẬT
  void _calculateRealStats(List<Map<String, dynamic>> products) {
    int pendingPlant = 0; // Chờ duyệt gieo trồng
    int farming = 0; // Đang trồng
    int pendingHarvest = 0; // Chờ duyệt thu hoạch
    int done = 0; // Hoàn tất

    for (var crop in products) {
      // Logic phân loại GIỐNG HỆT _buildCropCard
      int pStatus = crop['plantingStatus'] ?? 0;
      int hStatus = crop['harvestStatus'] ?? 0;
      int hDate = (crop['harvestDate'] is int) ? crop['harvestDate'] : 0;

      if (pStatus == 0) {
        pendingPlant++;
      } else if (pStatus == 1) {
        if (hDate > 0) {
          if (hStatus == 0)
            pendingHarvest++; // Đã bấm thu hoạch, chờ duyệt
          else if (hStatus == 1)
            done++; // Đã duyệt xong
        } else {
          farming++; // Chưa bấm thu hoạch -> Đang trồng
        }
      }
    }

    // Cập nhật vào biểu đồ
    setState(() {
      _statsData = [pendingPlant, farming, pendingHarvest, done];
    });
  }

  // Hàm hiển thị Mã QR
  void _showQrDialog(BuildContext context, String data, String name) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text("Mã QR: $name", style: const TextStyle(fontSize: 16)),
        content: SizedBox(
          width: 250,
          height: 250,
          child: Center(
            child: QrImageView(
              data: data,
              version: QrVersions.auto,
              size: 200.0,
              backgroundColor: Colors.white,
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Đóng"),
          ),
        ],
      ),
    );
  }

  // --- HÀM XUẤT BÁN (MỚI THÊM LẠI CHO ÔNG) ---
  void _showDistributeDialog(BuildContext context, String productId) {
    final retailerController = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Xuất kho / Bàn giao"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text("Nhập tên đơn vị vận chuyển để bàn giao:"),
            const SizedBox(height: 10),
            TextField(
              controller: retailerController,
              decoration: const InputDecoration(
                labelText: "Đơn vị vận chuyển",
                hintText: "VD: 3TML Logistics",
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Hủy"),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text("Đã sẵn sàng vận chuyển!")),
              );
            },
            child: const Text("Xác nhận"),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      appBar: AppBar(
        backgroundColor: kFarmerPrimaryColor,
        elevation: 0,
        title: const Text(
          "Quản Lý Nông Trại",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadMyProducts,
          ),
        ],
      ),

      // Floating Button để thêm nhanh
      floatingActionButton: FloatingActionButton(
        backgroundColor: kFarmerPrimaryColor,
        onPressed: () async {
          await Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const AddCropScreen()),
          );
          _loadMyProducts();
        },
        child: const Icon(Icons.add, color: Colors.white),
      ),

      body: isLoading
          ? const Center(
              child: CircularProgressIndicator(color: kFarmerPrimaryColor),
            )
          : RefreshIndicator(
              onRefresh: _loadMyProducts,
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 1. BIỂU ĐỒ THỐNG KÊ (MỚI)
                    const Text(
                      "Tổng quan năng suất",
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 10),
                    StatisticsChart(data: _statsData),

                    const SizedBox(height: 25),

                    // 2. MENU CHỨC NĂNG NHANH (MỚI)
                    const Text(
                      "Tiện ích nhanh",
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 10),
                    GridView.count(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      crossAxisCount: 2, // 2 cột
                      childAspectRatio: 1.5, // Hình chữ nhật ngang
                      crossAxisSpacing: 10,
                      mainAxisSpacing: 10,
                      children: [
                        _buildQuickAction(
                          Icons.add_circle,
                          "Tạo Mùa Vụ",
                          Colors.orange,
                          () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const AddCropScreen(),
                              ),
                            );
                          },
                        ),
                        _buildQuickAction(
                          Icons.history_edu,
                          "Nhật Ký",
                          Colors.blue,
                          () {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text(
                                  "Tính năng xem toàn bộ nhật ký đang phát triển",
                                ),
                              ),
                            );
                          },
                        ),
                        _buildQuickAction(
                          Icons.qr_code,
                          "Quét Mã",
                          Colors.purple,
                          () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const QrScannerScreen(),
                              ),
                            );
                          },
                        ),
                        _buildQuickAction(
                          Icons.analytics,
                          "Báo Cáo",
                          Colors.teal,
                          () {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text("Đang tải báo cáo chi tiết..."),
                              ),
                            );
                          },
                        ),
                      ],
                    ),

                    const SizedBox(height: 25),

                    // 3. DANH SÁCH SẢN PHẨM (GIỮ NGUYÊN)
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          "Mùa vụ của tôi",
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        TextButton.icon(
                          onPressed: () {
                            // Logic mở bộ lọc cũ của ông
                            // _showFilterModal();
                          },
                          icon: const Icon(Icons.filter_list, size: 18),
                          label: const Text("Bộ lọc"),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),

                    _foundProducts.isEmpty
                        ? const Center(
                            child: Padding(
                              padding: EdgeInsets.all(20),
                              child: Text("Chưa có dữ liệu"),
                            ),
                          )
                        : ListView.builder(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: _foundProducts.length,
                            itemBuilder: (_, i) =>
                                _buildCropCard(_foundProducts[i]),
                          ),
                    const SizedBox(height: 60), // Khoảng trống dưới cùng
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildQuickAction(
    IconData icon,
    String label,
    Color color,
    VoidCallback onTap,
  ) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(color: Colors.grey.withOpacity(0.1), blurRadius: 4),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color, size: 32),
            const SizedBox(height: 8),
            Text(
              label,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
            ),
          ],
        ),
      ),
    );
  }

  // Widget _buildStatCard(String title, String count, Color color) {
  //   return Expanded(
  //     child: Container(
  //       padding: const EdgeInsets.symmetric(vertical: 15),
  //       decoration: BoxDecoration(
  //         color: Colors.white,
  //         borderRadius: BorderRadius.circular(10),
  //         border: Border(left: BorderSide(color: color, width: 4)),
  //         boxShadow: [
  //           BoxShadow(color: Colors.grey.withOpacity(0.1), blurRadius: 5),
  //         ],
  //       ),
  //       child: Column(
  //         children: [
  //           Text(
  //             count,
  //             style: TextStyle(
  //               fontSize: 20,
  //               fontWeight: FontWeight.bold,
  //               color: color,
  //             ),
  //           ),
  //           const SizedBox(height: 5),
  //           Text(
  //             title,
  //             style: const TextStyle(fontSize: 11, color: Colors.grey),
  //           ),
  //         ],
  //       ),
  //     ),
  //   );
  // }

  // --- WIDGET CARD SẢN PHẨM (LOGIC MỚI NHẤT) ---
  Widget _buildCropCard(Map<String, dynamic> crop) {
    final String id = crop['id'] ?? '';
    final String name = crop['name'] ?? 'Không tên';
    final String imageUrl = crop['image'] ?? '';

    // 1. LẤY DỮ LIỆU TỪ API (Backend đã trả về đủ rồi)
    final int plantingStatus = crop['plantingStatus'] ?? 0;

    // Lưu ý: Backend trả về harvestDate là số (timestamp)
    final int harvestDate = (crop['harvestDate'] is int)
        ? crop['harvestDate']
        : 0;

    // Lưu ý: Backend trả về harvestStatus (0: Pending, 1: Approved, 2: Rejected)
    final int harvestStatus = crop['harvestStatus'] ?? 0;

    // 2. TÍNH TOÁN TRẠNG THÁI HIỂN THỊ (Logic 4 bước)
    int displayStatus = 0;

    if (plantingStatus == 0) {
      displayStatus = 0; // Chờ duyệt gieo trồng
    } else if (plantingStatus == 1) {
      // Đã duyệt gieo trồng -> Kiểm tra tiếp thu hoạch
      if (harvestDate > 0) {
        // Nông dân ĐÃ bấm nút thu hoạch
        if (harvestStatus == 0) {
          displayStatus = 2; // CHỜ DUYỆT THU HOẠCH (Cái ông đang cần)
        } else if (harvestStatus == 1) {
          displayStatus = 3; // ĐÃ DUYỆT THU HOẠCH (Xong)
        } else {
          displayStatus = -1; // Bị từ chối
        }
      } else {
        // Chưa bấm nút thu hoạch
        displayStatus = 1; // ĐANG TRỒNG
      }
    } else {
      displayStatus = -1; // Bị từ chối gieo trồng
    }

    // 3. CẤU HÌNH GIAO DIỆN (Màu sắc & Nút bấm)
    String statusText = "Không xác định";
    Color statusColor = Colors.grey;
    bool showHarvestBtn = false;
    bool showCareBtn = false;
    bool showDistributeBtn = false;
    bool showQrBtn = (plantingStatus == 1);

    if (displayStatus == 0) {
      statusText = "Chờ duyệt gieo trồng";
      statusColor = Colors.orange;
    } else if (displayStatus == 1) {
      statusText = "Đang canh tác";
      statusColor = Colors.blue;
      showCareBtn = true;
      showHarvestBtn = true;
    } else if (displayStatus == 2) {
      statusText = "Chờ duyệt thu hoạch"; // <--- NÓ SẼ HIỆN CÁI NÀY
      statusColor = Colors.purple;
      // Không hiện nút gì cả (Đúng logic)
    } else if (displayStatus == 3) {
      statusText = "Hoàn tất / Sẵn sàng bán";
      statusColor = Colors.green;
      showDistributeBtn = true;
    } else if (displayStatus == -1) {
      statusText = "Bị từ chối";
      statusColor = Colors.red;
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 15),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            // --- PHẦN 1: ẢNH & THÔNG TIN ---
            Row(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.network(
                    imageUrl,
                    width: 80,
                    height: 80,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => Container(
                      width: 80,
                      height: 80,
                      color: Colors.grey[300],
                      child: const Icon(Icons.local_florist),
                    ),
                  ),
                ),
                const SizedBox(width: 15),
                Expanded(
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
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          if (showQrBtn)
                            IconButton(
                              icon: const Icon(
                                Icons.qr_code_2,
                                color: Colors.black87,
                              ),
                              onPressed: () => _showQrDialog(context, id, name),
                            )
                          else if (statusText.contains("Chờ"))
                            Tooltip(
                              message: "Đang chờ...",
                              child: Icon(
                                Icons.hourglass_bottom,
                                size: 20,
                                color: statusColor,
                              ),
                            ),
                        ],
                      ),
                      Text(
                        "ID: $id",
                        style: const TextStyle(
                          fontSize: 12,
                          color: Colors.grey,
                        ),
                      ),
                      const SizedBox(height: 5),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: statusColor.withOpacity(0.1),
                          border: Border.all(color: statusColor),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          statusText,
                          style: TextStyle(
                            color: statusColor,
                            fontWeight: FontWeight.bold,
                            fontSize: 11,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            // --- PHẦN 2: NÚT BẤM ---
            if (showCareBtn || showHarvestBtn) ...[
              const SizedBox(height: 12),
              const Divider(),
              Row(
                children: [
                  if (showCareBtn)
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => CareDiaryScreen(
                              productId: id,
                              productName: name,
                            ),
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.teal,
                          padding: const EdgeInsets.symmetric(vertical: 10),
                        ),
                        icon: const Icon(
                          Icons.edit_note,
                          color: Colors.white,
                          size: 18,
                        ),
                        label: const Text(
                          "Chăm Sóc",
                          style: TextStyle(color: Colors.white, fontSize: 13),
                        ),
                      ),
                    ),
                  if (showCareBtn && showHarvestBtn) const SizedBox(width: 10),
                  if (showHarvestBtn)
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () async {
                          await Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => HarvestProductScreen(
                                productId: id,
                                productName: name,
                              ),
                            ),
                          );
                          _loadMyProducts(); // Reload khi quay về
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.orange[800],
                          padding: const EdgeInsets.symmetric(vertical: 10),
                        ),
                        icon: const Icon(
                          Icons.agriculture,
                          color: Colors.white,
                          size: 18,
                        ),
                        label: const Text(
                          "Thu Hoạch",
                          style: TextStyle(color: Colors.white, fontSize: 13),
                        ),
                      ),
                    ),
                ],
              ),
            ],

            if (showDistributeBtn) ...[
              const SizedBox(height: 12),
              const Divider(),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () => _showDistributeDialog(context, id),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue[800],
                  ),
                  icon: const Icon(Icons.local_shipping, color: Colors.white),
                  label: const Text(
                    "Xuất Bán / Bàn Giao",
                    style: TextStyle(color: Colors.white),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

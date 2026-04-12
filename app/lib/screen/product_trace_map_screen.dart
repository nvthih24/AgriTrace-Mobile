import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart'; // Lib mới
import 'package:latlong2/latlong.dart'; // Lib xử lý tọa độ

class ProductTraceMapScreen extends StatefulWidget {
  // Vì latlong2 dùng class LatLng riêng, nên ta nhận double cho dễ truyền
  final double farmLat, farmLng;
  final double? transportLat, transportLng; // Có thể null nếu chưa vận chuyển
  final double? retailerLat, retailerLng; // Có thể null nếu chưa đến cửa hàng

  const ProductTraceMapScreen({
    Key? key,
    required this.farmLat,
    required this.farmLng,
    this.transportLat,
    this.transportLng,
    this.retailerLat,
    this.retailerLng,
  }) : super(key: key);

  @override
  State<ProductTraceMapScreen> createState() => _ProductTraceMapScreenState();
}

class _ProductTraceMapScreenState extends State<ProductTraceMapScreen> {
  // 🔑 KEY VIETMAP CỦA ÔNG
  final String _vietMapKey = "506862bb03a3d71632bdeb7674a3625328cb7e5a9b011841";

  @override
  Widget build(BuildContext context) {
    // Tạo danh sách các điểm có dữ liệu
    List<Marker> markers = [];
    List<LatLng> routePoints = [];

    // 1. Điểm Nông trại (Luôn có)
    LatLng farmPos = LatLng(widget.farmLat, widget.farmLng);
    markers.add(_buildMarker(farmPos, Icons.agriculture, Colors.green));
    routePoints.add(farmPos);

    // 2. Điểm Vận chuyển (Nếu có)
    if (widget.transportLat != null && widget.transportLng != null) {
      LatLng transPos = LatLng(widget.transportLat!, widget.transportLng!);
      markers.add(_buildMarker(transPos, Icons.local_shipping, Colors.orange));
      routePoints.add(transPos);
    }

    // 3. Điểm Cửa hàng (Nếu có)
    if (widget.retailerLat != null && widget.retailerLng != null) {
      LatLng retailPos = LatLng(widget.retailerLat!, widget.retailerLng!);
      markers.add(_buildMarker(retailPos, Icons.storefront, Colors.red));
      routePoints.add(retailPos);
    }

    return Scaffold(
      appBar: AppBar(title: const Text("Hành trình sản phẩm")),
      body: Stack(
        children: [
          FlutterMap(
            options: MapOptions(
              initialCenter: farmPos, // Mở map là thấy nông trại ngay
              initialZoom: 13.0,
            ),
            children: [
              // Lớp hiển thị bản đồ VietMap (Dạng Raster Tile)
              TileLayer(
                urlTemplate:
                    "https://maps.vietmap.vn/tm/{z}/{x}/{y}@2x.png?apikey=$_vietMapKey",
                userAgentPackageName:
                    'com.agritrace.app', // Tên package app của ông
              ),

              // Lớp vẽ đường nối
              PolylineLayer(
                polylines: [
                  Polyline(
                    points: routePoints,
                    strokeWidth: 4.0,
                    color: Colors.blueAccent,
                    isDotted: true, // Đường đứt đoạn nhìn cho nghệ
                  ),
                ],
              ),

              // Lớp hiển thị Marker
              MarkerLayer(markers: markers),
            ],
          ),

          // Card thông tin (Giữ nguyên UI cũ)
          Positioned(
            bottom: 20,
            left: 20,
            right: 20,
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [BoxShadow(blurRadius: 10, color: Colors.black12)],
              ),
              child: const Text(
                "📍 Lộ trình được xác thực bởi Blockchain & Google Maps API",
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.blue,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Marker _buildMarker(LatLng pos, IconData icon, Color color) {
    return Marker(
      point: pos,
      width: 40,
      height: 40,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          shape: BoxShape.circle,
          border: Border.all(color: color, width: 2),
          boxShadow: const [BoxShadow(blurRadius: 5, color: Colors.black26)],
        ),
        child: Icon(icon, color: color, size: 24),
      ),
    );
  }
}

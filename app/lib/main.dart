import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';
import 'package:hive_flutter/hive_flutter.dart';

// Import các màn hình
import 'screen/home_screen.dart';
import 'screen/farmer_main_screen.dart';
import 'screen/transporter_main_screen.dart';
import 'screen/retailer_main_screen.dart';
import 'screen/inspector_main_screen.dart';
import 'screen/manufacturer_main_screen.dart';

void main() async {
  WidgetsBinding widgetsBinding = WidgetsFlutterBinding.ensureInitialized();
  FlutterNativeSplash.preserve(widgetsBinding: widgetsBinding);

  await Firebase.initializeApp();
  await Hive.initFlutter();
  await Hive.openBox('scan_history');

  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  // 🔥 MẶC ĐỊNH LÀ HOME (Cho khách quét mã ngay)
  Widget _destinationScreen = const HomeScreen();

  @override
  void initState() {
    super.initState();
    _checkLoginAndNavigate();
  }

  Future<void> _checkLoginAndNavigate() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');
    final role = prefs.getString('role');
    // final bool isStaff = prefs.getBool('is_staff') ?? false;

    Widget nextScreen;

    if (token != null && token.isNotEmpty) {
      // 🟢 1. CÒN HẠN ĐĂNG NHẬP -> Vào thẳng Dashboard
      switch (role) {
        case 'farmer':
          nextScreen = const FarmerMainScreen();
          break;
        case 'transporter':
          nextScreen = const TransporterMainScreen();
          break;
        case 'manager':
        case 'retailer':
          nextScreen = const RetailerMainScreen();
          break;
        case 'moderator':
          nextScreen = const InspectorMainScreen();
          break;
        case 'manufacturer':
          nextScreen = const ManufacturerMainScreen();
          break;
        default:
          nextScreen = const HomeScreen();
      }
    }
    // else if (isStaff) {
    //   // 🟠 2. HẾT HẠN/ĐÃ ĐĂNG XUẤT NHƯNG LÀ MÁY NHÂN VIÊN -> Về Login để quét vân tay
    //   print("🔓 Máy nhân viên cũ -> Về Login");
    //   nextScreen = const LoginScreen();
    // }
    else {
      // 🔵 3. KHÁCH VÃNG LAI -> Vào Home quét mã
      print("🌍 Khách mới / Chưa đăng nhập -> Vào Home");
      nextScreen = const HomeScreen();
    }

    if (!mounted) return;

    setState(() {
      _destinationScreen = nextScreen;
    });

    // Gỡ màn hình chờ Native
    FlutterNativeSplash.remove();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'AgriTrace',
      theme: ThemeData(
        primarySwatch: Colors.green,
        useMaterial3: true,
        scaffoldBackgroundColor: Colors.white,
      ),
      home: _destinationScreen,
    );
  }
}

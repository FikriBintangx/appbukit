import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:tiara_fin/firebase_options.dart';
import 'package:tiara_fin/notification_service.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:tiara_fin/screens/splash_screen.dart';

/// Handle background messages (must be top-level)
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  print("📱 Background Message: ${message.notification?.title}");
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Enable High Refresh Rate (60-120Hz)
  await _enableHighRefreshRate();

  // Jaga-jaga kalo pas nyala malah meledak
  try {
    // Nyalain Firebase
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );

    // Siapin satpam background (FCM)
    FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);

    // Panggil Supabase
    await Supabase.initialize(
      url: 'https://sofrnepvtfwexcthmgwh.supabase.co',
      anonKey: 'sb_publishable_Xp2rAPiwf_ZgwzlSQvdlww_IqaCTxF5',
    );

    // Siapin Service Notifikasi
    await NotificationService().initialize();

    runApp(const MyApp());
  } catch (e) {
    // Aplikasi cadangan kalo yang utama tewas
    runApp(ErrorApp(error: e.toString()));
  }
}

/// Helper to enable High Refresh Rate
Future<void> _enableHighRefreshRate() async {
  try {
    // Set FPS mentok kanan buat device sultan
    await SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]);

    // Layar full sampe mentok
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);

    // Transparent Status Bar
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        systemNavigationBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.dark,
        systemNavigationBarIconBrightness: Brightness.dark,
      ),
    );
  } catch (e) {
    debugPrint('Gagal aktifin high refresh rate: $e');
  }
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Tiara Finance',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0x0000d09c), // Hijau terang
          primary: const Color(0xFF00D09C),
          secondary: const Color(0xFF00B882),
          brightness: Brightness.light,
        ),
        useMaterial3: true,
        scaffoldBackgroundColor: const Color(0xFFF5F5F5),
        appBarTheme: const AppBarTheme(
          elevation: 0,
          centerTitle: true,
          backgroundColor: Colors.white,
          foregroundColor: Colors.black,
        ),
        cardTheme: const CardThemeData(
          elevation: 1,
          color: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.all(Radius.circular(16)),
          ),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            elevation: 0,
            backgroundColor: const Color(0xFF00D09C),
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
        pageTransitionsTheme: const PageTransitionsTheme(
          builders: {
            TargetPlatform.android: ZoomPageTransitionsBuilder(),
            TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
          },
        ),
      ),
      home: const ConnectivityWrapper(child: SplashScreen()),
    );
  }
}

/// Bungkus buat ngecek nyambung gak nih internetnya
class ConnectivityWrapper extends StatefulWidget {
  final Widget child;
  const ConnectivityWrapper({super.key, required this.child});

  @override
  State<ConnectivityWrapper> createState() => _ConnectivityWrapperState();
}

class _ConnectivityWrapperState extends State<ConnectivityWrapper> {
  bool _isConnected = true;

  @override
  void initState() {
    super.initState();
    _checkConnectivity();

    // Dengerin kabar dari sinyal
    Connectivity().onConnectivityChanged.listen((result) {
      if (mounted) {
        setState(() {
          _isConnected =
              result.contains(ConnectivityResult.mobile) ||
              result.contains(ConnectivityResult.wifi);
        });
      }
    });
  }

  Future<void> _checkConnectivity() async {
    final result = await Connectivity().checkConnectivity();
    if (mounted) {
      setState(() {
        _isConnected =
            result.contains(ConnectivityResult.mobile) ||
            result.contains(ConnectivityResult.wifi);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        widget.child,
        if (!_isConnected)
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: Material(
              color: Colors.red,
              child: SafeArea(
                bottom: false,
                child: Container(
                  padding: const EdgeInsets.all(12),
                  child: Row(
                    children: [
                      const Icon(Icons.wifi_off, color: Colors.white, size: 20),
                      const SizedBox(width: 8),
                      const Expanded(
                        child: Text(
                          'Yah, internetnya putus bos',
                          style: TextStyle(color: Colors.white, fontSize: 14),
                        ),
                      ),
                      TextButton(
                        onPressed: _checkConnectivity,
                        child: const Text(
                          'Coba Lagi',
                          style: TextStyle(color: Colors.white),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}

/// Screen Error Darurat
class ErrorApp extends StatelessWidget {
  final String error;
  const ErrorApp({super.key, required this.error});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline, size: 64, color: Colors.red),
                const SizedBox(height: 20),
                const Text(
                  'Waduh, Gagal Start Nih',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 10),
                Text(
                  error,
                  style: const TextStyle(fontSize: 14, color: Colors.grey),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 30),
                ElevatedButton(
                  onPressed: () {
                    // Keluar aja deh
                    SystemNavigator.pop();
                  },
                  child: const Text('Tutup Aplikasi'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:camera/camera.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'dart:io';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:purchases_flutter/purchases_flutter.dart';
import 'firebase_options.dart';

import 'core/themes.dart';
import 'core/app_config.dart';
import 'models/document_model.dart';
import 'providers/document_provider.dart';
import 'views/home_screen.dart';
import 'views/recent_downloads_screen.dart';
import 'views/dashboard_screen.dart';
import 'views/review_filter_screen.dart';
import 'views/document_management_screen.dart';
import 'views/export_settings_screen.dart';
import 'views/export_success_screen.dart';
import 'views/subscription_screen.dart';
import 'providers/subscription_provider.dart';
import 'views/auth/login_screen.dart';
import 'views/paywall.dart';
import 'views/profile_screen.dart';

List<CameraDescription> cameras = [];
bool _isCameraResetNeeded = false;

final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
    FlutterLocalNotificationsPlugin();

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize Firebase
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    print('Firebase initialized');
  } catch (e) {
    print('Error initializing Firebase: $e');
  }
  // Set up error handling
  FlutterError.onError = (FlutterErrorDetails details) {
    FlutterError.presentError(details);
    print('Flutter Error: ${details.exception}');
    print('Stack Trace: ${details.stack}');
  };

  // Get and print device ID for AdMob test ads
  String? testDeviceId;
  try {
    final deviceInfo = DeviceInfoPlugin();
    if (Platform.isAndroid) {
      final androidInfo = await deviceInfo.androidInfo;
      testDeviceId = androidInfo.id;
    } else if (Platform.isIOS) {
      final iosInfo = await deviceInfo.iosInfo;
      testDeviceId = iosInfo.identifierForVendor;
    }
    if (testDeviceId != null) {
      print('AdMob Test Device ID: $testDeviceId');
      await MobileAds.instance.updateRequestConfiguration(
        RequestConfiguration(testDeviceIds: [testDeviceId]),
      );
    }
  } catch (e) {
    print('Could not get device ID for AdMob test ads: $e');
  }

  print('Initializing MobileAds...');
  try {
    final InitializationStatus status = await MobileAds.instance.initialize();
    // Fix string interpolation for readable logs
    print('MobileAds initialized: ${status.adapterStatuses}');
  } catch (e) {
    print('Error initializing MobileAds: $e');
  }

  // Initialize Hive
  await Hive.initFlutter();

  // Register Hive adapters
  if (!Hive.isAdapterRegistered(0)) {
    Hive.registerAdapter(DocumentModelAdapter());
  }
  if (!Hive.isAdapterRegistered(1)) {
    Hive.registerAdapter(DocumentTypeAdapter());
  }

  // Initialize cameras
  try {
    cameras = await availableCameras();
    if (cameras.isEmpty) {
      print('No cameras available');
    }
  } catch (e) {
    print('Error initializing cameras: $e');
    cameras = [];
  }

  // Initialize flutter_local_notifications
  const AndroidInitializationSettings initializationSettingsAndroid =
      AndroidInitializationSettings('@mipmap/ic_launcher');
  final InitializationSettings initializationSettings = InitializationSettings(
    android: initializationSettingsAndroid,
    // iOS and other platforms can be added here
  );
  // await flutterLocalNotificationsPlugin.initialize(initializationSettings);
  await requestNotificationPermissionIfNeeded();

  // Initialize RevenueCat (Purchases) BEFORE loading subscription state
  try {
    // RevenueCat public API key for SleekScan app
    const revenueCatApiKey = 'test_QWBBmtPOyBQyCYASJqiQFFFMYgh';
    
    // Configure RevenueCat with platform-specific settings
    final config = PurchasesConfiguration(revenueCatApiKey)
      ..diagnosticsEnabled = true;  // Enable diagnostics in development
    
    await Purchases.configure(config);
    
    // Enable debug logs in development
    await Purchases.setLogLevel(LogLevel.debug);
    
    // Optional: Set user ID for tracking (if user is logged in at startup)
    // await Purchases.logIn('user_id');
    
    print('✅ RevenueCat Purchases configured successfully');
  } catch (e) {
    print('❌ Error initializing RevenueCat Purchases: $e');
  }

  final subscriptionProvider = SubscriptionProvider();
  await subscriptionProvider.load();
  runApp(DocumentScannerApp(subscriptionProvider: subscriptionProvider));
}

// Helper function to ensure cameras are available
Future<List<CameraDescription>> getAvailableCameras() async {
  if (cameras.isEmpty) {
    try {
      cameras = await availableCameras();
    } catch (e) {
      print('Error getting cameras: $e');
      cameras = [];
    }
  }
  return cameras;
}

// Refresh camera list
Future<List<CameraDescription>> refreshCameras() async {
  try {
    print('Refreshing camera list...');
    cameras = await availableCameras();
    print('Found ${cameras.length} cameras');
    return cameras;
  } catch (e) {
    print('Error refreshing cameras: $e');
    cameras = [];
    return cameras;
  }
}

// Mark that camera reset is needed after PDF export
void markCameraResetNeeded() {
  print('Marking camera reset as needed');
  _isCameraResetNeeded = true;
}

// Check if camera reset is needed
bool isCameraResetNeeded() {
  return _isCameraResetNeeded;
}

// Reset camera flag
void resetCameraFlag() {
  print('Resetting camera flag');
  _isCameraResetNeeded = false;
}

Future<void> requestNotificationPermissionIfNeeded() async {
  if (Platform.isAndroid) {
    final androidImplementation =
        flutterLocalNotificationsPlugin.resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();
    final granted =
        await androidImplementation?.requestNotificationsPermission();
    print('Notification permission granted: $granted');
  }
}

class DocumentScannerApp extends StatelessWidget {
  final SubscriptionProvider subscriptionProvider;

  const DocumentScannerApp({Key? key, required this.subscriptionProvider}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ScreenUtilInit(
      designSize: const Size(390, 844), // iPhone 12 Pro size, adjust as needed
      minTextAdapt: true,
      splitScreenMode: true,
      builder: (context, child) {
        return MultiProvider(
          providers: [
            ChangeNotifierProvider(create: (_) => DocumentProvider()),
            ChangeNotifierProvider.value(value: subscriptionProvider),
          ],
          child: MaterialApp(
            title: AppConfig.appName,
            debugShowCheckedModeBanner: false,
            theme: AppThemes.lightTheme,
            darkTheme: ThemeData.dark(),
            themeMode: ThemeMode.light, // Always light mode per spec
            home: const SplashScreen(),
            routes: {
              '/dashboard': (context) => const DashboardScreen(),
              '/recent_downloads': (context) => const RecentDownloadsScreen(),
              '/document-manage': (context) => const DocumentManagementScreen(),
              '/export-settings': (context) => const ExportSettingsScreen(),
              '/export-success': (context) => const ExportSuccessScreen(),
              '/auth': (context) => const AuthLoginScreen(),
              '/profile': (context) => const ProfileScreen(),
              '/subscription': (context) => const SubscriptionScreen(),
              '/subscription-paywall': (context) => const PaywallScreen(),
              '/paywall': (context) => const PaywallScreen(),
            },
            onGenerateRoute: (settings) {
              if (settings.name == '/review') {
                final imagePath = settings.arguments as String;
                return MaterialPageRoute(
                  builder: (context) =>
                      ReviewFilterScreen(imagePath: imagePath),
                );
              }
              return null;
            },
          ),
        );
      },
    );
  }
}

class SplashScreen extends StatefulWidget {
  const SplashScreen({Key? key}) : super(key: key);

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();

    _animationController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: const Interval(0.0, 0.6, curve: Curves.easeIn),
    ));

    _scaleAnimation = Tween<double>(
      begin: 0.9,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: const Interval(0.2, 0.9, curve: Curves.easeOutBack),
    ));

    _startAnimation();
  }

  void _startAnimation() async {
    await _animationController.forward();

    // Initialize app data
    if (mounted) {
      await Provider.of<DocumentProvider>(context, listen: false).initialize();

      // Navigate to home screen
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const HomeScreen()),
      );
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [
              AppColors.primaryBlue,
              AppColors.primaryBlueLight,
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Stack(
          children: [
            // Decorative soft light blobs
            Positioned(
              top: -80,
              right: -60,
              child: _softBlob(const Color(0x66FFFFFF), 220),
            ),
            Positioned(
              bottom: -100,
              left: -60,
              child: _softBlob(const Color(0x55FFFFFF), 260),
            ),
            Center(
              child: AnimatedBuilder(
                animation: _animationController,
                builder: (context, child) {
                  return FadeTransition(
                    opacity: _fadeAnimation,
                    child: ScaleTransition(
                      scale: _scaleAnimation,
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            width: 120,
                            height: 120,
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(28),
                              border: Border.all(
                                color: Colors.white.withOpacity(0.35),
                                width: 1.5,
                              ),
                              boxShadow: const [
                                BoxShadow(
                                  color: Color(0x33000000),
                                  blurRadius: 30,
                                  offset: Offset(0, 12),
                                ),
                              ],
                            ),
                            child: Padding(
                              padding: const EdgeInsets.all(16.0),
                              child: Image.asset(
                                'assets/icons/sleekscan_icon_without_text.png',
                                fit: BoxFit.contain,
                              ),
                            ),
                          ),
                          const SizedBox(height: 24),
                          const Text(
                            'SleekScan',
                            style: TextStyle(
                              fontSize: 30,
                              fontWeight: FontWeight.w800,
                              color: Colors.white,
                              letterSpacing: 0.2,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Scan • Enhance • Organize',
                            style: AppTextStyles.bodyMedium.copyWith(
                              color: Colors.white.withOpacity(0.9),
                            ),
                          ),
                          const SizedBox(height: 28),
                          SizedBox(
                            width: 140,
                            child: LinearProgressIndicator(
                              minHeight: 4,
                              borderRadius:
                                  const BorderRadius.all(Radius.circular(8)),
                              color: Colors.white,
                              backgroundColor: Colors.white.withOpacity(0.25),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _softBlob(Color color, double size) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(
          colors: [color, Colors.transparent],
          stops: const [0.0, 1.0],
        ),
      ),
    );
  }
}

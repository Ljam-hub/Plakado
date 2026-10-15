import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'app_theme.dart';
import 'models/user_profile.dart';
import 'services/storage_service.dart';
import 'services/firestore_service.dart';
import 'services/ocr_recognition_service.dart';
import 'controllers/auth_controller.dart';
import 'controllers/scanner_controller.dart';
import 'controllers/vehicle_controller.dart';
import 'controllers/gate_log_controller.dart';
import 'controllers/theme_controller.dart';
import 'views/auth/login_view.dart';
import 'views/security/security_dashboard_view.dart';
import 'views/portal/student_faculty_dashboard_view.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Firebase for Web & Android
  FirestoreService? firestoreService;
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    firestoreService = FirestoreService();
  } catch (e) {
    debugPrint('Firebase initialization note: $e');
  }

  // Initialize Core Services & Local Persistence with Cloud Sync
  final prefs = await SharedPreferences.getInstance();
  final storageService = await StorageService.init(firestoreService);
  final ocrService = OcrRecognitionService();

  runApp(PlakadoApp(
    storageService: storageService,
    ocrService: ocrService,
    prefs: prefs,
  ));
}

class PlakadoApp extends StatelessWidget {
  final StorageService storageService;
  final OcrRecognitionService ocrService;
  final SharedPreferences prefs;

  const PlakadoApp({
    super.key,
    required this.storageService,
    required this.ocrService,
    required this.prefs,
  });

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(
          create: (_) => ThemeController(prefs),
        ),
        ChangeNotifierProvider(
          create: (_) => AuthController(storageService),
        ),
        ChangeNotifierProvider(
          create: (_) => ScannerController(storageService, ocrService),
        ),
        ChangeNotifierProvider(
          create: (_) => VehicleController(storageService),
        ),
        ChangeNotifierProvider(
          create: (_) => GateLogController(storageService),
        ),
      ],
      child: Consumer<ThemeController>(
        builder: (context, themeCtrl, _) {
          return MaterialApp(
            title: 'Plakado - Campus Plate Identifier & Gate Security',
            debugShowCheckedModeBanner: false,
            theme: AppTheme.lightTheme,
            darkTheme: AppTheme.darkTheme,
            themeMode: themeCtrl.themeMode, // Follows phone system Light/Dark mode automatically!
            home: const RootGatekeeperView(),
          );
        },
      ),
    );
  }
}

/// Dynamic Role-Based View Router (MVC View)
class RootGatekeeperView extends StatelessWidget {
  const RootGatekeeperView({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthController>();

    if (!auth.isAuthenticated) {
      return const LoginView();
    }

    switch (auth.currentRole) {
      case UserRole.security:
      case UserRole.admin:
        return const SecurityDashboardView();
      case UserRole.student:
      case UserRole.faculty:
        return const StudentFacultyDashboardView();
    }
  }
}

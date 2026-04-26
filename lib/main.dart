import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:provider/provider.dart';
import 'package:todo_with_resfulapi/models/task.dart';
import 'package:todo_with_resfulapi/providers/task_provider.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'auth/main_page.dart';
import 'routes/app_routes.dart';
import 'services/api_service.dart';
import 'services/settings_service.dart';
import 'constants/app_color_path.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Firebase (avoid duplicate initialization if already configured)
  try {
    if (Firebase.apps.isEmpty) {
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );
    }
  } catch (e) {
    // If Firebase was already initialized on the native side, ignore duplicate-app errors.
    final msg = e.toString();
    if (msg.contains('duplicate-app') || msg.contains('already exists')) {
      // expected when Firebase auto-initializes on Android; safe to continue
      debugPrint('Firebase already initialized natively; skipping explicit init.');
    } else {
      rethrow;
    }
  }

  // Initialize Hive
  await Hive.initFlutter();

  // Register Hive adapter for Task model
  Hive.registerAdapter(TaskAdapter());

  // Initialize settings and apply saved API configuration (mock toggle + api key)
  final settings = SettingsService();
  await settings.init();

  // Load saved mock toggle (default: true for offline/demo). You can change
  // this in-app via the settings UI we'll add.
  ApiService.useMock = settings.getUseMock();

  // If an API key was stored, apply it to ApiService
  final savedKey = settings.getApiKey();
  if (savedKey != null && savedKey.isNotEmpty) {
    ApiService.setApiKey(savedKey);
  }

  runApp(
    ChangeNotifierProvider(
      create: (context) => TaskProvider(),
      child: const TodoRestfulApi(),
    ),
  );
}

class TodoRestfulApi extends StatelessWidget {
  const TodoRestfulApi({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Todo with RESTful API.',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepOrange),
        scaffoldBackgroundColor: AppColorsPath.backgroundLight,
        appBarTheme: AppBarTheme(
          backgroundColor: AppColorsPath.primaryRed,
          foregroundColor: AppColorsPath.white,
        ),
        floatingActionButtonTheme: FloatingActionButtonThemeData(
          backgroundColor: AppColorsPath.primaryOrange,
        ),
      ),
      darkTheme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: AppColorsPath.backgroundDark,
        appBarTheme: AppBarTheme(
          backgroundColor: AppColorsPath.primaryRed,
          foregroundColor: AppColorsPath.white,
        ),
      ),
      themeMode: ThemeMode.system,
      home: const MainPage(),
      // Register named routes used across the app so Navigator.pushNamed works
      routes: AppRoutes.routes,
    );
  }
}

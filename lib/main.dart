import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'screens/splash_screen.dart';
import 'screens/home_page.dart';
import 'screens/settings_page.dart';
import 'screens/documents_list_page.dart';
import 'screens/quiz_generator_page.dart';
import 'screens/summary_page.dart';
import 'screens/auth/login_page.dart';
import 'screens/auth/signup_page.dart';
import 'utils/app_theme.dart';
import 'utils/theme_controller.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Load environment variables from .env file
  // When .env is in assets (pubspec.yaml), dotenv.load() should find it automatically
  try {
    await dotenv.load(fileName: '.env');
    debugPrint('✓ Environment variables loaded successfully');

    // Verify the key is loaded
    if (dotenv.isInitialized) {
      final key = dotenv.env['OPENROUTER_API_KEY']?.trim();
      final model =
          dotenv.env['OPENROUTER_MODEL']?.trim() ?? 'openai/gpt-oss-120b:free';
      if (key != null && key.isNotEmpty) {
        debugPrint('✓ OPENROUTER_API_KEY found: ${key.substring(0, 10)}...');
        debugPrint('✓ Key length: ${key.length}');
        debugPrint('✓ Using model: $model');
        debugPrint('✓ API is ready to use!');
      } else {
        debugPrint('✗ OPENROUTER_API_KEY is null or empty');
        debugPrint('✗ Available keys: ${dotenv.env.keys.toList()}');
        debugPrint(
          '⚠ Please check your .env file contains: OPENROUTER_API_KEY=your_key',
        );
        debugPrint('⚠ Get your free API key from: https://openrouter.ai/keys');
      }
    } else {
      debugPrint('✗ dotenv is not initialized');
    }
  } catch (e) {
    debugPrint('✗ Failed to load .env file: $e');
    debugPrint('⚠ Make sure:');
    debugPrint('  1. .env file exists in project root');
    debugPrint('  2. .env is listed in pubspec.yaml assets');
    debugPrint('  3. File contains: OPENROUTER_API_KEY=your_key');
    debugPrint('  4. Get your free API key from: https://openrouter.ai/keys');
    debugPrint('  5. You did a FULL RESTART (not hot reload)');
  }

  runApp(const MainApp());
}

class MainApp extends StatelessWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<ThemeMode>(
      valueListenable: ThemeController.instance.themeMode,
      builder: (context, mode, _) {
        return MaterialApp(
          title: 'EduScript',
          debugShowCheckedModeBanner: false,
          theme: AppTheme.light(),
          darkTheme: AppTheme.dark(),
          themeMode: mode,
          initialRoute: '/',
          routes: {
            '/': (context) => const SplashScreen(),
            '/login': (context) => const LoginPage(),
            '/signup': (context) => const SignUpPage(),
            '/home': (context) => const HomePage(),
            '/settings': (context) => const SettingsPage(),
            '/documents': (context) => const DocumentsListPage(),
            '/quiz': (context) => const QuizGeneratorPage(),
            '/summary': (context) {
              final args = ModalRoute.of(context)?.settings.arguments;
              if (args is Document) {
                return SummaryPage(document: args);
              }
              return const SummaryPage();
            },
          },
        );
      },
    );
  }
}

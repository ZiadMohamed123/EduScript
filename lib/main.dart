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
import 'package:flutter_dotenv/flutter_dotenv.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    await dotenv.load(fileName: ".env");
    // Verify API key was loaded
    final apiKey = dotenv.env['GEMINI_API_KEY'];
    if (apiKey == null || apiKey.isEmpty) {
      debugPrint("Warning: GEMINI_API_KEY is not set in .env file");
    } else {
      debugPrint("Gemini API key loaded successfully (${apiKey.substring(0, apiKey.length > 7 ? 7 : apiKey.length)}...)");
    }
  } catch (e) {
    // .env file not found, but app can still run
    // API calls will fail if API key is needed
    debugPrint("Warning: .env file not found or could not be loaded: $e");
    debugPrint("Please create a .env file in the project root with GEMINI_API_KEY=your_key");
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

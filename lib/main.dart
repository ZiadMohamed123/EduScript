import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:provider/provider.dart';

import 'screens/scanner_page.dart';
import 'package:quiz_generator/screens/SavedQuizzesListPage.dart';
import 'screens/splash_screen.dart';
import 'screens/home_page.dart';
import 'screens/settings_page.dart';
import 'screens/edit_profile_page.dart';
import 'screens/documents_list_page.dart' show Document, DocumentsListPage;
import 'screens/quiz_generator_page.dart';
import 'screens/summary_page.dart';

import 'utils/app_theme.dart';
import 'utils/theme_controller.dart';

import 'screens/auth/login_page.dart';
import 'screens/auth/signup_page.dart';

import 'providers/document_provider.dart';

import 'screens/document_summary_view.dart';
import 'utils/auth_guard.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    await dotenv.load(fileName: "assets/.env");
    // Verify API key was loaded
    final apiKey = dotenv.env['GEMINI_API_KEY'];
    if (apiKey == null || apiKey.isEmpty) {
      debugPrint("Warning: GEMINI_API_KEY is not set in .env file");
    } else {
      debugPrint(
        "Gemini API key loaded successfully (${apiKey.substring(0, apiKey.length > 7 ? 7 : apiKey.length)}...)",
      );
    }
  } catch (e) {
    // .env file not found, but app can still run
    // API calls will fail if API key is needed
    debugPrint("Warning: .env file not found or could not be loaded: $e");
    debugPrint(
      "Please create a .env file in the project root with GEMINI_API_KEY=your_key",
    );
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
            '/scanner': (context) => ChangeNotifierProvider(
                  create: (_) => DocumentProvider(),
                  child: const ScannerPage(),
                ),
            '/saved-quizzes': (context) => const SavedQuizzesListPage(),
            '/signup': (context) => const SignUpPage(),
            '/home': (context) => const AuthGuard(child: HomePage()),
            '/settings': (context) => const AuthGuard(child: SettingsPage()),
            '/edit-profile': (context) =>
                const AuthGuard(child: EditProfilePage()),
            '/documents': (context) =>
                const AuthGuard(child: DocumentsListPage()),
            '/quiz': (context) => const AuthGuard(child: QuizGeneratorPage()),
            '/summary': (context) {
              final args = ModalRoute.of(context)?.settings.arguments;
              if (args is Document) {
                return AuthGuard(child: SummaryPage(document: args));
              }
              return const AuthGuard(child: SummaryPage());
            },
            '/document-summary': (context) {
              final args = ModalRoute.of(context)?.settings.arguments;
              if (args is Document) {
                return AuthGuard(child: DocumentSummaryView(document: args));
              }
              return const AuthGuard(
                child: Scaffold(
                  body: Center(child: Text('No document provided')),
                ),
              );
            },
          },
        );
      },
    );
  }
}

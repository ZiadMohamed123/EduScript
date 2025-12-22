import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:provider/provider.dart';

import 'screens/splash_screen.dart';
import 'screens/home_page.dart';
import 'screens/settings_page.dart';
import 'screens/documents_list_page.dart';
import 'screens/quiz_generator_page.dart';
import 'screens/summary_page.dart';
import 'screens/auth/login_page.dart';
import 'screens/auth/signup_page.dart';
import 'screens/extraction_result_page.dart';

import 'utils/app_theme.dart';
import 'utils/theme_controller.dart';
import 'providers/document_provider.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // ⚠️ Keep startup VERY light
  await dotenv.load(fileName: 'assets/.env');

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
            '/extracted': (context) => ChangeNotifierProvider(
                  create: (_) => DocumentProvider(),
                  child: const ExtractionResultPage(),
                ),
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

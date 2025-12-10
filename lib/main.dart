import 'package:flutter/material.dart';
import 'screens/splash_screen.dart';
import 'screens/home_page.dart';
import 'screens/settings_page.dart';
  import 'screens/documents_list_page.dart';
  import 'screens/quiz_generator_page.dart';
import 'utils/app_theme.dart';
import 'utils/theme_controller.dart';

void main() {
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
            '/home': (context) => const HomePage(),
            '/settings': (context) => const SettingsPage(),
            '/documents': (context) => const DocumentsListPage(),
            '/quiz': (context) => const QuizGeneratorPage(),
          },
        );
      },
    );
  }
}

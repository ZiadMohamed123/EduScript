import 'package:flutter/material.dart';

class ThemeController {
  ThemeController._();
  static final ThemeController instance = ThemeController._();

  final ValueNotifier<ThemeMode> themeMode = ValueNotifier(ThemeMode.system);

  bool get isDark => themeMode.value == ThemeMode.dark;

  void setTheme(ThemeMode mode) {
    themeMode.value = mode;
  }

  void toggleDark(bool enabled) {
    themeMode.value = enabled ? ThemeMode.dark : ThemeMode.light;
  }
}

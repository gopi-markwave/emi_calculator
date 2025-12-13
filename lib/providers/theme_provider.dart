import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final themeProvider = ChangeNotifierProvider<ThemeNotifier>(
  (ref) => ThemeNotifier(),
);

class ThemeNotifier extends ChangeNotifier {
  ThemeData _themeData;
  bool _isDarkMode;

  ThemeNotifier()
    : _themeData = ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF6366F1),
          brightness: Brightness.light,
        ),
        useMaterial3: true,
      ),
      _isDarkMode = false;

  ThemeData get themeData => _themeData;
  bool get isDarkMode => _isDarkMode;

  void toggleTheme() {
    _isDarkMode = !_isDarkMode;
    _themeData = ThemeData(
      colorScheme: ColorScheme.fromSeed(
        seedColor: const Color(0xFF6366F1),
        brightness: _isDarkMode ? Brightness.dark : Brightness.light,
      ),
      useMaterial3: true,
    );
    notifyListeners();
  }

  void setTheme(bool isDark) {
    if (_isDarkMode != isDark) {
      _isDarkMode = isDark;
      _themeData = ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF6366F1),
          brightness: _isDarkMode ? Brightness.dark : Brightness.light,
        ),
        useMaterial3: true,
      );
      notifyListeners();
    }
  }
}

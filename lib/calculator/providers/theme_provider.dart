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
          seedColor: const Color(0xFF000080), // Navy Blue
          brightness: Brightness.light,
          surface: const Color(0xFFFAFAFA),
        ),
        scaffoldBackgroundColor: Colors.white,
        cardTheme: CardThemeData(
          color: const Color(0xFFF5F5F7), // Greyish card
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(color: Colors.black.withOpacity(0.05)),
          ),
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
        seedColor: const Color(0xFF000080), // Navy Blue
        brightness: _isDarkMode ? Brightness.dark : Brightness.light,
        surface: _isDarkMode
            ? const Color(0xFF121212)
            : const Color(0xFFFAFAFA),
      ),
      scaffoldBackgroundColor: _isDarkMode ? Colors.black : Colors.white,
      cardTheme: CardThemeData(
        color: _isDarkMode ? const Color(0xFF1E1E1E) : const Color(0xFFF5F5F7),
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(
            color: _isDarkMode
                ? Colors.white10
                : Colors.black.withOpacity(0.05),
          ),
        ),
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
          seedColor: const Color(0xFF000080), // Navy Blue
          brightness: _isDarkMode ? Brightness.dark : Brightness.light,
          surface: _isDarkMode
              ? const Color(0xFF121212)
              : const Color(0xFFFAFAFA),
        ),
        scaffoldBackgroundColor: _isDarkMode ? Colors.black : Colors.white,
        cardTheme: CardThemeData(
          color: _isDarkMode
              ? const Color(0xFF1E1E1E)
              : const Color(0xFFF5F5F7),
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(
              color: _isDarkMode
                  ? Colors.white10
                  : Colors.black.withOpacity(0.05),
            ),
          ),
        ),
        useMaterial3: true,
      );
      notifyListeners();
    }
  }
}

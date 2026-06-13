import 'package:flutter/material.dart';

class AppTheme {
  static final ThemeData winterTheme = ThemeData(
    brightness: Brightness.dark,
    primaryColor: Colors.blueAccent,
    scaffoldBackgroundColor: const Color(0xFF000000),
    appBarTheme: const AppBarTheme(
      backgroundColor: Colors.transparent,
      elevation: 0,
      centerTitle: true,
      titleTextStyle: TextStyle(
        fontFamily: 'Inter',
        fontSize: 20,
        fontWeight: FontWeight.bold,
        color: Colors.white,
      ),
    ),
    bottomNavigationBarTheme: const BottomNavigationBarThemeData(
      backgroundColor: Color(0xFF101010),
      selectedItemColor: Colors.blueAccent,
      unselectedItemColor: Colors.grey,
    ),
    colorScheme: const ColorScheme.dark(
      primary: Colors.blueAccent,
      secondary: Colors.cyanAccent,
      surface: Color(0xFF121212),
    ),
    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: const Color(0xFF101010),
      indicatorColor: Colors.blueAccent.withValues(alpha: 0.2),
      labelTextStyle: WidgetStateProperty.all(
        const TextStyle(color: Colors.white70, fontSize: 12),
      ),
      iconTheme: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) {
          return const IconThemeData(color: Colors.blueAccent);
        }
        return const IconThemeData(color: Colors.grey);
      }),
    ),
  );
}


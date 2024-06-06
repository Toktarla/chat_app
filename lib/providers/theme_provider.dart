import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../core/animations/fade_in_transition.dart';
import '../core/constants/app_colors.dart';

class ThemeProvider extends ChangeNotifier {
  final SharedPreferences _prefs;
  ThemeProvider(this._prefs) {
    _loadTheme();
  }

  ThemeData _currentTheme = _lightTheme;
  ThemeData get currentTheme => _currentTheme;

  static final ThemeData _lightTheme = ThemeData(
    dialogBackgroundColor: AppColors.blueColor,
    pageTransitionsTheme: const PageTransitionsTheme(
      builders: {
        TargetPlatform.android: FadePageTransitionsBuilder(),
        TargetPlatform.iOS: FadePageTransitionsBuilder(),
      },
    ),
    floatingActionButtonTheme: FloatingActionButtonThemeData(
      backgroundColor: AppColors.primaryColor,
    ),
    brightness: Brightness.light,
    primaryColor: AppColors.primaryColor,
    fontFamily: 'Roboto',
    iconTheme: IconThemeData(
      color: AppColors.blueColor,
    ),
    textTheme: TextTheme(
      displayLarge: TextStyle(
        color: Colors.white,
        fontWeight: FontWeight.bold,
        fontSize: 20,
      ),
      displayMedium: TextStyle(
        color: Colors.white,
        fontWeight: FontWeight.bold,
        fontSize: 14,
      ),
      displaySmall: TextStyle(
        color: Colors.white,
        fontWeight: FontWeight.bold,
        fontSize: 12,
      ),
      titleLarge: TextStyle(
        color: Colors.black,
        fontWeight: FontWeight.bold,
        fontSize: 20,
      ),
      titleMedium: TextStyle(
        color: Colors.black87,
        fontWeight: FontWeight.bold,
        fontSize: 14,
      ),
      titleSmall: TextStyle(
        color: Colors.black87,
        fontWeight: FontWeight.bold,
        fontSize: 12,
      ),
      bodyLarge: TextStyle(
        color: Colors.blueGrey,
        fontSize: 20,
        fontWeight: FontWeight.bold,
      ),
      bodyMedium: TextStyle(
        color: Colors.blueGrey,
        fontSize: 14,
        fontWeight: FontWeight.bold,
      ),
      bodySmall: TextStyle(
        color: Colors.blueGrey,
        fontSize: 12,
        fontWeight: FontWeight.bold,
      ),
      labelLarge: TextStyle(color: Colors.white),
      labelSmall: TextStyle(
        color: Colors.black87,
        fontSize: 12,
        fontWeight: FontWeight.w500,
      ),
    ),
    appBarTheme: AppBarTheme(
      color: AppColors.primaryColor,
      elevation: 5,
    ),
    bottomNavigationBarTheme: BottomNavigationBarThemeData(
      backgroundColor: AppColors.whiteColor,
      unselectedItemColor: AppColors.unSelectedBottomBarColorLight,
      selectedItemColor: AppColors.primaryColor,
    ),
    datePickerTheme: DatePickerThemeData(
      elevation: 0,
      backgroundColor: AppColors.whiteColor,
      dividerColor: Colors.greenAccent,
      headerBackgroundColor: AppColors.primaryColor,
    ),
    expansionTileTheme: ExpansionTileThemeData(
      iconColor: AppColors.primaryColor,
    ),
    primaryIconTheme: IconThemeData(
      color: AppColors.blueColor,
    ),
    scaffoldBackgroundColor: AppColors.whiteColor,
    cardColor: AppColors.whiteColor,
    dividerColor: Colors.grey,
  );

  static final ThemeData _darkTheme = ThemeData(
    dialogBackgroundColor: AppColors.blueColor,
    floatingActionButtonTheme: FloatingActionButtonThemeData(
      backgroundColor: Colors.pinkAccent,
    ),
    pageTransitionsTheme: const PageTransitionsTheme(
      builders: {
        TargetPlatform.android: FadePageTransitionsBuilder(),
        TargetPlatform.iOS: FadePageTransitionsBuilder(),
      },
    ),
    brightness: Brightness.dark,
    primaryColor: AppColors.backgroundColor,

    fontFamily: 'Roboto',
    primaryIconTheme: IconThemeData(
      color: AppColors.whiteColor,
    ),
    expansionTileTheme: ExpansionTileThemeData(
      iconColor: AppColors.whiteColor,
    ),
    bottomNavigationBarTheme: BottomNavigationBarThemeData(
      backgroundColor: AppColors.darkBlueColor,
      unselectedItemColor: AppColors.unSelectedBottomBarColorDark,
      selectedItemColor: AppColors.pinkColor,
    ),
    iconTheme: IconThemeData(
      color: AppColors.whiteColor,
    ),
    appBarTheme: AppBarTheme(
      color: AppColors.blueColor,
      elevation: 5,
    ),
    textTheme: TextTheme(
      displayLarge: TextStyle(
        color: Colors.white,
        fontWeight: FontWeight.bold,
        fontSize: 20,
      ),
      displayMedium: TextStyle(
        color: Colors.white,
        fontWeight: FontWeight.bold,
        fontSize: 14,
      ),
      displaySmall: TextStyle(
        color: Colors.white,
        fontWeight: FontWeight.bold,
        fontSize: 12,
      ),
      titleLarge: TextStyle(
        color: Colors.white,
        fontWeight: FontWeight.bold,
        fontSize: 20,
      ),
      titleMedium: TextStyle(
        color: Colors.white,
        fontWeight: FontWeight.bold,
        fontSize: 14,
      ),
      titleSmall: TextStyle(
        color: Colors.white,
        fontWeight: FontWeight.bold,
        fontSize: 12,
      ),
      bodyLarge: TextStyle(
        color: AppColors.pinkColor,
        fontSize: 20,
        fontWeight: FontWeight.bold,
      ),
      bodyMedium: TextStyle(
        color: AppColors.pinkColor,
        fontSize: 14,
        fontWeight: FontWeight.bold,
      ),
      bodySmall: TextStyle(
        color: AppColors.pinkColor,
        fontSize: 12,
        fontWeight: FontWeight.bold,
      ),
      labelLarge: TextStyle(color: Colors.white),
      labelSmall: TextStyle(
        color: AppColors.pinkColor,
        fontSize: 12,
        fontWeight: FontWeight.w500,
      ),
    ),
    cardColor: AppColors.blueColor,
    scaffoldBackgroundColor: AppColors.blueColor,
  );

  void _loadTheme() {
    final isDarkMode = _prefs.getBool('isDarkMode') ?? false;
    _currentTheme = isDarkMode ? _darkTheme : _lightTheme;
    notifyListeners();
  }

  void toggleTheme() {
    final isDarkMode = _currentTheme.brightness == Brightness.dark;
    _prefs.setBool('isDarkMode', !isDarkMode);
    _currentTheme = !isDarkMode ? _darkTheme : _lightTheme;
    notifyListeners();
  }
}
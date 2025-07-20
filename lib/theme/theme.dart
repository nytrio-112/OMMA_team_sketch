import 'package:flutter/material.dart';
import '../constants/colors.dart';

final ThemeData appTheme = ThemeData(
  brightness: Brightness.light,
  scaffoldBackgroundColor: Colors.white,
  colorScheme: ColorScheme.fromSeed(
    seedColor: OmmaColors.green,
    brightness: Brightness.light,
    primary: OmmaColors.green,
    secondary: OmmaColors.pink,
    surface: Colors.white,
    error: OmmaColors.redAlert,
  ),
  textTheme: const TextTheme(
    bodyLarge: TextStyle(fontSize: 18, color: OmmaColors.green),
    bodyMedium: TextStyle(fontSize: 16, color: OmmaColors.green),
    titleLarge: TextStyle(
      fontSize: 20,
      fontWeight: FontWeight.bold,
      color: OmmaColors.green,
    ),
  ),
  elevatedButtonTheme: ElevatedButtonThemeData(
    style: ElevatedButton.styleFrom(
      backgroundColor: OmmaColors.green,
      foregroundColor: Colors.white,
    ),
  ),
  appBarTheme: const AppBarTheme(
    backgroundColor: Colors.white,
    elevation: 0,
    titleTextStyle: TextStyle(
      color: OmmaColors.green,
      fontSize: 20,
      fontWeight: FontWeight.bold,
    ),
    iconTheme: IconThemeData(color: OmmaColors.green),
  ),
);

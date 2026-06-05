// lib/core/styles.dart

import 'package:flutter/material.dart';
import 'package:securia/core/app_colors.dart';

/// AppStyles contient les définitions de style et de thème pour l'ensemble de l'application.
class AppStyles {
  // Définition du thème principal de l'application
  static ThemeData get mainTheme {
    return ThemeData(
      primarySwatch: AppColors.primarySwatch,
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.appBarBackground,
        foregroundColor: AppColors.appBarForeground,
        elevation: 0,
        titleTextStyle: TextStyle(
          color: AppColors.appBarForeground,
          fontSize: 20,
          fontWeight: FontWeight.bold,
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.buttonBackground,
          foregroundColor: AppColors.buttonForeground,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
          textStyle: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: AppColors.inputBorder, width: 2),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(
            color: AppColors.inputFocusedBorder,
            width: 2,
          ),
        ),
        labelStyle: const TextStyle(color: AppColors.inputLabel),
        hintStyle: const TextStyle(color: AppColors.hintText),
      ),
      textTheme: const TextTheme(
        bodyLarge: TextStyle(color: AppColors.primaryText),
        bodyMedium: TextStyle(color: AppColors.secondaryText),
      ),
      scaffoldBackgroundColor: AppColors.backgroundColor,
      cardTheme: CardThemeData(
        color: AppColors.cardColor,
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
      // Style pour les titres de cartes sur la page d'accueil
    );
  }

  // Style pour les titres de cartes sur la page d'accueil
  static const TextStyle cardTitleStyle = TextStyle(
    fontSize: 18,
    fontWeight: FontWeight.bold,
    color: AppColors.textColorPrimary,
  );
}

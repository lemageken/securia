// lib/core/app_colors.dart

import 'package:flutter/material.dart';

/// Palette de couleurs harmonisée et premium pour SECUR.IA (Sûreté Nationale Camerounaise)
class AppColors {
  // Couleur primaire Bleu Marine Institutionnel (Confiance, Sécurité, Autorité)
  static const Color primaryDark = Color(0xFF152A56);
  
  // Couleur secondaire de texte
  static const Color secondaryText = Color(0xFF475569); // Slate 600
  
  // Couleur de fond générale des champs de texte
  static const Color inputBackground = Color(0xFFF1F5F9); // Slate 100
  
  // Couleur des bordures de champ de texte
  static const Color inputBorder = Color(0xFFCBD5E1); // Slate 300
  
  // Couleur du texte des hints dans les champs
  static const Color hintText = Color(0xFF94A3B8); // Slate 400
  
  // Couleur du texte des liens
  static const Color linkText = Color(0xFF1D4ED8); // Blue 700
  
  // Couleur du texte principal
  static const Color primaryText = Color(0xFF0F172A); // Slate 900
  
  // Couleur du texte blanc pour les boutons
  static const Color buttonText = Colors.white;
  
  // Couleur de l'arrière-plan de la barre de navigation inférieure
  static const Color bottomBarColor = Colors.white;
  
  // Couleur de l'encoche de la barre de navigation inférieure (Bleu Marine)
  static const Color notchColor = Color(0xFF152A56);
  
  // Couleur des icônes inactives dans la barre de navigation
  static const Color inActiveIconColor = Color(0xFF94A3B8); // Slate 400
  
  // Couleurs des icônes actives dans la barre de navigation (Bleu Marine & Or Camerounais)
  static const Color activeIconColorRed = Color(0xFF152A56); // Bleu Marine
  static const Color activeIconColorPink = Color(0xFFD97706); // Or Camerounais
  
  // Couleur de fond des boutons
  static const Color buttonBackground = Color(0xFF152A56);
  
  // Couleur de premier plan (texte/icône) des boutons
  static const Color buttonForeground = Colors.white;
  
  // Couleur de fond de l'AppBar
  static const Color appBarBackground = Color(0xFF152A56);
  
  // Couleur de premier plan (texte/icône) de l'AppBar
  static const Color appBarForeground = Colors.white;
  
  // Couleur des messages IA (Pocam237) - Gris ardoise très clair ultra-lisible
  static const Color iaMessageColor = Color(0xFFF1F5F9); // Slate 100
  static const Color iaMessageText = Color(0xFF1E293B);  // Slate 800
  
  // Couleur des messages Utilisateur - Bleu ciel doux et sophistiqué
  static const Color userMessageColor = Color(0xFFE0F2FE); // Blue 100
  static const Color userMessageText = Color(0xFF0369A1);  // Blue 700
  
  static const Color errorColor = Color(0xFFEF4444); // Red 500
  static const Color cardColor = Colors.white;
  
  // Couleur d'arrière-plan globale (Slate 50) pour un aspect hautement professionnel
  static const Color backgroundColor = Color(0xFFF8FAFC); // Slate 50

  // Couleurs des cartes de la page d'accueil (Blanc épuré sur ombre grise discrète)
  static const Color homeCardBackground = Colors.white;
  static const Color homeCardShadow = Color(0x0C000000); // 5% d'opacité noire

  // Couleurs pour les boutons de sélection de région/ville
  static const Color regionButtonBackground = Colors.white;
  static const Color regionButtonShadow = Color(0x0C000000);

  // Couleurs du texte général
  static const Color textColorPrimary = Color(0xFF0F172A);
  static const Color textColorSecondary = Color(0xFF64748B);

  // Couleurs spécifiques pour la barre de navigation et authentification
  static const Color inputFocusedBorder = Color(0xFF152A56);
  static const Color inputLabel = Color(0xFF1E293B);
  
  static const Color authButtonPrimary = Color(0xFF152A56);
  static const Color authButtonSecondary = Color(0xFF475569);
  static const Color authPromptColor = Color(0xFF475569);
  static const Color authLinkColor = Color(0xFF1D4ED8);
  static const MaterialColor primarySwatch = Colors.blue;
}

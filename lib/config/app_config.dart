// lib/config/app_config.dart

import 'package:flutter/material.dart';
import 'package:securia/core/app_colors.dart';

/// AppConfig est une classe qui gère les paramètres de configuration de l'application.
/// Elle hérite de ChangeNotifier pour notifier les widgets en cas de modification.
class AppConfig extends ChangeNotifier {
  // --- Paramètres pour ItemShow (qui sera ContactListItem) ---
  double _itemCardElevation = 10.0;
  double _itemCardBorderRadius = 10.0;
  Color _itemCardBackgroundColor = AppColors.cardColor;
  double _itemTitleFontSize = 16.0;
  FontWeight _itemTitleFontWeight = FontWeight.bold;
  Color _itemTitleColor = AppColors.textColorPrimary;
  double _itemSubtitleFontSize = 14.0;
  FontStyle _itemSubtitleFontStyle = FontStyle.italic;
  Color _itemSubtitleColor = AppColors.textColorSecondary;

  // --- Paramètres pour UnitTitle ---
  double _unitTitleFontSize = 18.0;
  FontWeight _unitTitleFontWeight = FontWeight.bold;
  Color _unitTitleColor = AppColors.primaryDark;
  EdgeInsetsGeometry _unitTitlePadding = const EdgeInsets.symmetric(
    vertical: 8.0,
    horizontal: 16.0,
  );

  // --- Paramètres pour le dialogue (qui sera géré par ContactListItem) ---
  String _callButtonText = "APPELER";
  String _messageButtonText = "MESSAGE";
  bool _showDialogImage = true;
  Color _dialogImageBackgroundColor = Colors.white;

  // Getters pour accéder aux paramètres
  double get itemCardElevation => _itemCardElevation;
  double get itemCardBorderRadius => _itemCardBorderRadius;
  Color get itemCardBackgroundColor => _itemCardBackgroundColor;
  double get itemTitleFontSize => _itemTitleFontSize;
  FontWeight get itemTitleFontWeight => _itemTitleFontWeight;
  Color get itemTitleColor => _itemTitleColor;
  double get itemSubtitleFontSize => _itemSubtitleFontSize;
  FontStyle get itemSubtitleFontStyle => _itemSubtitleFontStyle;
  Color get itemSubtitleColor => _itemSubtitleColor;

  double get unitTitleFontSize => _unitTitleFontSize;
  FontWeight get unitTitleFontWeight => _unitTitleFontWeight;
  Color get unitTitleColor => _unitTitleColor;
  EdgeInsetsGeometry get unitTitlePadding => _unitTitlePadding;

  String get callButtonText => _callButtonText;
  String get messageButtonText => _messageButtonText;
  bool get showDialogImage => _showDialogImage;
  Color get dialogImageBackgroundColor => _dialogImageBackgroundColor;

  // Setters pour modifier les paramètres et notifier les listeners
  set itemCardElevation(double value) {
    if (_itemCardElevation != value) {
      _itemCardElevation = value;
      notifyListeners();
    }
  }

  set itemCardBorderRadius(double value) {
    if (_itemCardBorderRadius != value) {
      _itemCardBorderRadius = value;
      notifyListeners();
    }
  }

  set itemCardBackgroundColor(Color value) {
    if (_itemCardBackgroundColor != value) {
      _itemCardBackgroundColor = value;
      notifyListeners();
    }
  }

  set itemTitleFontSize(double value) {
    if (_itemTitleFontSize != value) {
      _itemTitleFontSize = value;
      notifyListeners();
    }
  }

  set itemTitleFontWeight(FontWeight value) {
    if (_itemTitleFontWeight != value) {
      _itemTitleFontWeight = value;
      notifyListeners();
    }
  }

  set itemTitleColor(Color value) {
    if (_itemTitleColor != value) {
      _itemTitleColor = value;
      notifyListeners();
    }
  }

  set itemSubtitleFontSize(double value) {
    if (_itemSubtitleFontSize != value) {
      _itemSubtitleFontSize = value;
      notifyListeners();
    }
  }

  set itemSubtitleFontStyle(FontStyle value) {
    if (_itemSubtitleFontStyle != value) {
      _itemSubtitleFontStyle = value;
      notifyListeners();
    }
  }

  set itemSubtitleColor(Color value) {
    if (_itemSubtitleColor != value) {
      _itemSubtitleColor = value;
      notifyListeners();
    }
  }

  set unitTitleFontSize(double value) {
    if (_unitTitleFontSize != value) {
      _unitTitleFontSize = value;
      notifyListeners();
    }
  }

  set unitTitleFontWeight(FontWeight value) {
    if (_unitTitleFontWeight != value) {
      _unitTitleFontWeight = value;
      notifyListeners();
    }
  }

  set unitTitleColor(Color value) {
    if (_unitTitleColor != value) {
      _unitTitleColor = value;
      notifyListeners();
    }
  }

  set unitTitlePadding(EdgeInsetsGeometry value) {
    if (_unitTitlePadding != value) {
      _unitTitlePadding = value;
      notifyListeners();
    }
  }

  set callButtonText(String value) {
    if (_callButtonText != value) {
      _callButtonText = value;
      notifyListeners();
    }
  }

  set messageButtonText(String value) {
    if (_messageButtonText != value) {
      _messageButtonText = value;
      notifyListeners();
    }
  }

  set showDialogImage(bool value) {
    if (_showDialogImage != value) {
      _showDialogImage = value;
      notifyListeners();
    }
  }

  set dialogImageBackgroundColor(Color value) {
    if (_dialogImageBackgroundColor != value) {
      _dialogImageBackgroundColor = value;
      notifyListeners();
    }
  }
}

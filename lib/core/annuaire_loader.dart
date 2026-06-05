// lib/core/annuaire_loader.dart

import 'dart:convert';
import 'package:flutter/services.dart' show rootBundle;
import 'package:securia/models/category_model.dart';
import 'package:securia/models/item_model.dart';

class AnnuaireLoader {
  /// Charge le fichier JSON depuis les assets et le décode en List
  static Future<List<Category>> loadAnnuaireData() async {
    final String response = await rootBundle.loadString(
      'assets/data/annuaire.json',
    );
    final data = json.decode(response) as List<dynamic>;
    return data
        .map((json) => Category.fromJson(json as Map<String, dynamic>))
        .toList();
  }

  /// Aplati la hiérarchie en une simple liste d'Item (utile pour la recherche).
  static List<Item> flattenToItems(List<Category> categories) {
    final List<Item> items = [];

    void extractItems(Category category) {
      items.addAll(category.items.cast<Item>());
      for (var sub in category.subcategories) {
        extractItems(sub);
      }
    }

    for (var cat in categories) {
      extractItems(cat);
    }
    return items;
  }
}

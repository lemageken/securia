// lib/models/category_model.dart

import 'package:securia/models/item_model.dart'; // Importer Item depuis item_model.dart

class Category {
  final String name;
  final List<Item> items;
  final List<Category> subcategories;

  Category({
    required this.name,
    List<Item>? items,
    List<Category>? subcategories,
  }) : items = items ?? [],
       subcategories = subcategories ?? [];

  factory Category.fromJson(Map<String, dynamic> json) {
    final name = json['name'] as String?;
    if (name == null) {
      throw FormatException(
        'Category JSON missing required "name" field: $json',
      );
    }
    return Category(
      name: name,
      items: (json['items'] as List<dynamic>?)
          ?.map((e) => Item.fromJson(e as Map<String, dynamic>))
          .toList(),
      subcategories: (json['subcategories'] as List<dynamic>?)
          ?.map((e) => Category.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }

  Map<String, dynamic> toJson() => {
    'name': name,
    'items': items.map((e) => e.toJson()).toList(),
    'subcategories': subcategories.map((e) => e.toJson()).toList(),
  };
}

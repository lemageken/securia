// lib/models/item_model.dart

class Item {
  String name;
  String? tph;

  Item({required this.name, this.tph});

  factory Item.fromJson(Map<String, dynamic> json) {
    return Item(
      name:
          json['name'] as String? ??
          json['nom'] as String, // Gérer 'nom' et 'name'
      tph:
          json['tph'] as String? ??
          json['telephone'] as String?, // Gérer 'tph' et 'telephone'
    );
  }

  Map<String, dynamic> toJson() {
    return {'name': name, 'tph': tph};
  }
}

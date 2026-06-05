// lib/screens/annuaire/region_detail_page.dart

import 'package:flutter/material.dart';
import 'package:securia/core/app_colors.dart';
import 'package:securia/models/category_model.dart';
import 'package:securia/widgets/unit_title.dart';
import 'package:securia/widgets/contact_list_item.dart';

class RegionDetailPage extends StatelessWidget {
  final Category region;

  const RegionDetailPage({super.key, required this.region});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(region.name),
        backgroundColor: AppColors.appBarBackground,
        foregroundColor: AppColors.appBarForeground,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          // Afficher les contacts directs de la région, s'il y en a
          if (region.items.isNotEmpty) ...[
            UnitTitle(title: 'Contacts directs'),
            ...region.items.map(
              (item) => ContactListItem(item: item), // Utiliser ContactListItem
            ),
            const SizedBox(height: 16.0),
          ],
          // Afficher les sous-catégories (villes ou autres)
          if (region.subcategories.isNotEmpty)
            ...region.subcategories.map(
              (sub) => ExpansionTile(
                title: UnitTitle(title: sub.name),
                children: [
                  // Afficher les contacts de la sous-catégorie
                  if (sub.items.isNotEmpty)
                    ...sub.items.map((item) => ContactListItem(item: item)),
                  // Ajouter une option pour naviguer vers une sous-catégorie plus profonde
                  if (sub.subcategories.isNotEmpty)
                    ListTile(
                      title: const Text('Voir plus'),
                      trailing: const Icon(Icons.arrow_forward),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => RegionDetailPage(region: sub),
                          ),
                        );
                      },
                    ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

// lib/screens/annuaire/category_page.dart

import 'package:flutter/material.dart';
import 'package:securia/models/category_model.dart';
import 'package:securia/widgets/unit_title.dart';
import 'package:securia/widgets/contact_list_item.dart';

class CategoryPage extends StatelessWidget {
  final Category category;

  const CategoryPage({super.key, required this.category});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(category.name)),
      body: ListView(
        children: [
          ...category.subcategories.map(
            (sub) => ExpansionTile(
              title: UnitTitle(title: sub.name),
              children: [
                ...sub.items.map((item) => ContactListItem(item: item)),
                if (sub.subcategories.isNotEmpty)
                  ListTile(
                    title: const Text('Voir plus'),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => CategoryPage(category: sub),
                        ),
                      );
                    },
                  ),
              ],
            ),
          ),
          ...category.items.map((item) => ContactListItem(item: item)),
        ],
      ),
    );
  }
}

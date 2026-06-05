// lib/screens/search/search_contacts_page.dart

import 'package:flutter/material.dart';
import 'package:securia/core/annuaire_loader.dart';
import 'package:securia/models/category_model.dart';
import 'package:securia/models/item_model.dart';
import 'package:securia/widgets/contact_list_item.dart';
import 'package:securia/core/app_colors.dart';

class SearchContactsPage extends StatefulWidget {
  const SearchContactsPage({super.key});

  @override
  State<SearchContactsPage> createState() => _SearchContactsPageState();
}

class _SearchContactsPageState extends State<SearchContactsPage> {
  List<Category> _allCategories = [];
  List<Item> _allContacts = [];
  List<Item> _searchResults = [];
  final TextEditingController _searchController = TextEditingController();
  List<String> _cities = [];
  String? _selectedCity;

  @override
  void initState() {
    super.initState();
    _loadData();
    _searchController.addListener(_onSearchChanged);
  }

  Future<void> _loadData() async {
    final categories = await AnnuaireLoader.loadAnnuaireData();
    setState(() {
      _allCategories = categories;
      _allContacts = AnnuaireLoader.flattenToItems(categories);
      _cities = _extractCities(categories);
      _selectedCity = 'Toutes les villes';
      _searchResults = _allContacts;
    });
  }

  List<String> _extractCities(List<Category> categories) {
    Set<String> citiesSet = {};
    void extract(Category category) {
      for (var sub in category.subcategories) {
        citiesSet.add(sub.name);
        extract(sub);
      }
    }

    for (var cat in categories) {
      extract(cat);
    }
    return citiesSet
        .where(
          (name) =>
              name.startsWith('VILLE') ||
              name.startsWith('COMMIS') ||
              name.startsWith('POSTE'),
        )
        .toList()
      ..sort();
  }

  List<Item> _flattenCategory(Category category) {
    List<Item> items = List.from(category.items);
    for (var sub in category.subcategories) {
      items.addAll(_flattenCategory(sub));
    }
    return items;
  }

  Category? _findCategoryByName(String cityName) {
    Category? findInList(List<Category> cats) {
      for (var cat in cats) {
        if (cat.name.toLowerCase().contains(cityName.toLowerCase())) return cat;
        var found = findInList(cat.subcategories);
        if (found != null) return found;
      }
      return null;
    }

    return findInList(_allCategories);
  }

  List<Item> _getItemsForCity(String cityName) {
    final cityCategory = _findCategoryByName(cityName);
    if (cityCategory != null) {
      return _flattenCategory(cityCategory);
    }
    return [];
  }

  @override
  void dispose() {
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    _filterContacts(_searchController.text);
  }

  void _filterContacts(String query) {
    List<Item> results = [];
    final lowerQuery = query.toLowerCase();

    if (_selectedCity != null && _selectedCity != 'Toutes les villes') {
      // Filtrage sur ville sélectionnée
      final cityCategory = _findCategoryByName(_selectedCity!);
      if (cityCategory != null) {
        final allItemsInCity = _flattenCategory(cityCategory);
        results = allItemsInCity.where((item) {
          return item.name.toLowerCase().contains(lowerQuery) ||
              (item.tph?.toLowerCase().contains(lowerQuery) ?? false);
        }).toList();
      }
    } else {
      // Recherche globale
      if (lowerQuery.isEmpty) {
        // Query vide : tous les contacts
        results = _allContacts;
      } else if (lowerQuery.length < 3) {
        // Query trop courte : filtrage normal
        results = _allContacts.where((item) {
          return item.name.toLowerCase().contains(lowerQuery) ||
              (item.tph?.toLowerCase().contains(lowerQuery) ?? false);
        }).toList();
      } else {
        // Vérifier si la query correspond à une ville
        final matchingCity = _cities.firstWhere(
          (city) => city.toLowerCase().contains(lowerQuery),
          orElse: () => '',
        );
        if (matchingCity.isNotEmpty) {
          // Vérifier si la query est le dernier mot du nom de ville (ex. "kribi" pour "VILLE DE KRIBI")
          final words = matchingCity.toLowerCase().split(' ');
          final lastWord = words.isNotEmpty ? words.last : '';
          if (lastWord == lowerQuery) {
            // Afficher tous les contacts de cette ville
            results = _getItemsForCity(matchingCity);
          } else {
            // Filtrage normal sur tous les items
            results = _allContacts.where((item) {
              return item.name.toLowerCase().contains(lowerQuery) ||
                  (item.tph?.toLowerCase().contains(lowerQuery) ?? false);
            }).toList();
          }
        } else {
          // Filtrage normal sur tous les items
          results = _allContacts.where((item) {
            return item.name.toLowerCase().contains(lowerQuery) ||
                (item.tph?.toLowerCase().contains(lowerQuery) ?? false);
          }).toList();
        }
      }
    }

    setState(() {
      _searchResults = results;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Rechercher un contact'),
        backgroundColor: AppColors.appBarBackground,
        foregroundColor: AppColors.appBarForeground,
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Column(
              children: [
                // Dropdown pour sélectionner la ville
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: DropdownButtonFormField<String>(
                    initialValue: _selectedCity ?? 'Toutes les villes',
                    decoration: InputDecoration(
                      labelText: 'Sélectionner une ville',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10.0),
                      ),
                      filled: true,
                      fillColor: AppColors.inputBackground,
                    ),
                    items: [
                      const DropdownMenuItem<String>(
                        value: 'Toutes les villes',
                        child: Text('Toutes les villes'),
                      ),
                      ..._cities.map(
                        (city) => DropdownMenuItem<String>(
                          value: city,
                          child: Text(city),
                        ),
                      ),
                    ],
                    onChanged: (value) {
                      setState(() {
                        _selectedCity = value;
                      });
                      _filterContacts(_searchController.text);
                    },
                  ),
                ),
                const SizedBox(height: 8.0),
                // Champ de recherche
                TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: 'Rechercher par nom ou numéro...',
                    prefixIcon: const Icon(Icons.search),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10.0),
                      borderSide: BorderSide.none,
                    ),
                    filled: true,
                    fillColor: AppColors.inputBackground,
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: _allCategories.isEmpty
                ? const Center(child: CircularProgressIndicator())
                : _searchResults.isEmpty && _searchController.text.isNotEmpty
                ? const Center(
                    child: Text(
                      'Aucun contact trouvé.',
                      style: TextStyle(fontSize: 16),
                    ),
                  )
                : ListView.builder(
                    itemCount: _searchResults.length,
                    itemBuilder: (context, index) {
                      final item = _searchResults[index];
                      return ContactListItem(item: item);
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

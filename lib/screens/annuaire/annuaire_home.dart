// Dans lib/screens/annuaire/annuaire_home.dart

import 'package:flutter/material.dart';
import 'package:securia/core/annuaire_loader.dart';
import 'package:securia/models/category_model.dart';
import 'package:securia/screens/annuaire/region_detail_page.dart'; // Importer RegionDetailPage
import 'package:securia/widgets/region_city_button.dart';

class AnnuaireHomePage extends StatefulWidget {
  const AnnuaireHomePage({super.key});

  @override
  State<AnnuaireHomePage> createState() => _AnnuaireHomePageState();
}

class _AnnuaireHomePageState extends State<AnnuaireHomePage> {
  List<Category> _annuaireData = [];

  @override
  void initState() {
    super.initState();
    _loadAnnuaire();
  }

  Future<void> _loadAnnuaire() async {
    final data = await AnnuaireLoader.loadAnnuaireData();
    if (!mounted) return;
    setState(() {
      _annuaireData = data;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_annuaireData.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    // Le premier est Services Centraux, les suivants sont régions
    final centraux = _annuaireData.firstWhere(
      (cat) => cat.name == 'Services Centraux',
      orElse: () => Category(name: 'Services Centraux'),
    );
    final regions = _annuaireData
        .where((cat) => cat.name.startsWith('REGION') == true)
        .toList();

    return Scaffold(
      appBar: AppBar(title: const Text('Annuaire')),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Padding(
              padding: EdgeInsets.all(16.0),
              child: Text(
                'Services Centraux',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
            ),
            RegionCityButton(
              title: 'Services Centraux',
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => RegionDetailPage(
                      region: centraux,
                    ), // Utiliser RegionDetailPage
                  ),
                );
              },
            ),
            const Padding(
              padding: EdgeInsets.all(16.0),
              child: Text(
                'Régions',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
            ),
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                childAspectRatio: 2,
              ),
              itemCount: regions.length,
              itemBuilder: (context, index) {
                final region = regions[index];
                return RegionCityButton(
                  title: region.name,
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => RegionDetailPage(
                          region: region,
                        ), // Utiliser RegionDetailPage
                      ),
                    );
                  },
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

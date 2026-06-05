// lib/config/config_page.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:securia/config/app_config.dart';
import 'package:securia/core/app_colors.dart';

/// Page de configuration où l'utilisateur peut ajuster les paramètres
/// de l'interface utilisateur pour les listes de contacts.
class ConfigPage extends StatelessWidget {
  const ConfigPage({super.key});

  @override
  Widget build(BuildContext context) {
    final appConfig = Provider.of<AppConfig>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Paramètres de l\'Application'),
        backgroundColor: AppColors.appBarBackground,
        foregroundColor: AppColors.appBarForeground,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Configuration des Éléments de Contact',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: AppColors.textColorPrimary,
              ),
            ),
            const SizedBox(height: 10),
            ListTile(
              title: Text(
                'Élévation de la carte: ${appConfig.itemCardElevation.toStringAsFixed(1)}',
              ),
              subtitle: Slider(
                value: appConfig.itemCardElevation,
                min: 0,
                max: 20,
                divisions: 20,
                label: appConfig.itemCardElevation.toStringAsFixed(1),
                onChanged: (value) {
                  appConfig.itemCardElevation = value;
                },
              ),
            ),
            ListTile(
              title: Text(
                'Rayon des bords de la carte: ${appConfig.itemCardBorderRadius.toStringAsFixed(1)}',
              ),
              subtitle: Slider(
                value: appConfig.itemCardBorderRadius,
                min: 0,
                max: 30,
                divisions: 30,
                label: appConfig.itemCardBorderRadius.toStringAsFixed(1),
                onChanged: (value) {
                  appConfig.itemCardBorderRadius = value;
                },
              ),
            ),
            ListTile(
              title: const Text('Couleur de fond de la carte'),
              trailing: GestureDetector(
                onTap: () {
                  showDialog(
                    context: context,
                    builder: (context) => AlertDialog(
                      title: const Text('Choisir une couleur'),
                      content: BlockPicker(
                        pickerColor: appConfig.itemCardBackgroundColor,
                        onColorChanged: (color) {
                          appConfig.itemCardBackgroundColor = color;
                        },
                      ),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.of(context).pop(),
                          child: const Text('OK'),
                        ),
                      ],
                    ),
                  );
                },
                child: Container(
                  width: 24,
                  height: 24,
                  color: appConfig.itemCardBackgroundColor,
                ),
              ),
            ),
            ListTile(
              title: Text(
                'Taille de police du titre: ${appConfig.itemTitleFontSize.toStringAsFixed(1)}',
              ),
              subtitle: Slider(
                value: appConfig.itemTitleFontSize,
                min: 10,
                max: 30,
                divisions: 20,
                label: appConfig.itemTitleFontSize.toStringAsFixed(1),
                onChanged: (value) {
                  appConfig.itemTitleFontSize = value;
                },
              ),
            ),
            ListTile(
              title: const Text('Poids de la police du titre'),
              trailing: DropdownButton<FontWeight>(
                value: appConfig.itemTitleFontWeight,
                items: FontWeight.values
                    .map(
                      (weight) => DropdownMenuItem(
                        value: weight,
                        child: Text(weight.toString().split('.').last),
                      ),
                    )
                    .toList(),
                onChanged: (value) {
                  if (value != null) appConfig.itemTitleFontWeight = value;
                },
              ),
            ),

            ListTile(
              title: const Text('Couleur du titre de l\'unité'),
              trailing: GestureDetector(
                onTap: () {
                  showDialog(
                    context: context,
                    builder: (context) => AlertDialog(
                      title: const Text('Choisir une couleur'),
                      content: BlockPicker(
                        pickerColor: appConfig.unitTitleColor,
                        onColorChanged: (color) {
                          appConfig.unitTitleColor = color;
                        },
                      ),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.of(context).pop(),
                          child: const Text('OK'),
                        ),
                      ],
                    ),
                  );
                },
                child: Container(
                  width: 24,
                  height: 24,
                  color: appConfig.unitTitleColor,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class BlockPicker extends StatelessWidget {
  final Color pickerColor;
  final ValueChanged<Color> onColorChanged;

  const BlockPicker({
    super.key,
    required this.pickerColor,
    required this.onColorChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Wrap(
          spacing: 8.0,
          runSpacing: 8.0,
          children: [
            _buildColorBlock(AppColors.primaryDark), // Bleu Marine Impérial
            _buildColorBlock(AppColors.activeIconColorPink), // Or Camerounais
            _buildColorBlock(AppColors.backgroundColor), // Gris Ardoise Clair
            _buildColorBlock(AppColors.textColorPrimary), // Ardoise Foncé
            _buildColorBlock(Colors.red),
            _buildColorBlock(Colors.pink),
            _buildColorBlock(Colors.purple),
            _buildColorBlock(Colors.deepPurple),
            _buildColorBlock(Colors.indigo),
            _buildColorBlock(Colors.blue),
            _buildColorBlock(Colors.lightBlue),
            _buildColorBlock(Colors.cyan),
            _buildColorBlock(Colors.teal),
            _buildColorBlock(Colors.green),
            _buildColorBlock(Colors.lightGreen),
            _buildColorBlock(Colors.lime),
            _buildColorBlock(Colors.yellow),
            _buildColorBlock(Colors.amber),
            _buildColorBlock(Colors.orange),
            _buildColorBlock(Colors.deepOrange),
            _buildColorBlock(Colors.brown),
            _buildColorBlock(Colors.grey),
            _buildColorBlock(Colors.blueGrey),
            _buildColorBlock(Colors.black),
            _buildColorBlock(Colors.white),
            _buildColorBlock(Colors.orangeAccent),
            _buildColorBlock(Colors.lightBlueAccent),
            _buildColorBlock(Colors.deepPurpleAccent),

            _buildColorBlock(const Color.fromARGB(255, 175, 233, 247)),
          ],
        ),
      ],
    );
  }

  Widget _buildColorBlock(Color color) {
    return GestureDetector(
      onTap: () => onColorChanged(color),
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: pickerColor == color ? Colors.black : Colors.transparent,
            width: 2,
          ),
        ),
      ),
    );
  }
}

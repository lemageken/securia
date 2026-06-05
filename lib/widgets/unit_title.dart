// lib/widgets/unit_title.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:securia/config/app_config.dart';

class UnitTitle extends StatelessWidget {
  final String title;

  const UnitTitle({super.key, required this.title});

  @override
  Widget build(BuildContext context) {
    final appConfig = Provider.of<AppConfig>(context);

    return Padding(
      padding: appConfig.unitTitlePadding,
      child: Text(
        title,
        style: TextStyle(
          fontWeight: appConfig.unitTitleFontWeight,
          fontSize: appConfig.unitTitleFontSize,
          color: appConfig.unitTitleColor,
        ),
      ),
    );
  }
}

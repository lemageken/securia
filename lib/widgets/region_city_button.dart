// lib/widgets/region_city_button.dart

import 'package:flutter/material.dart';
import 'package:securia/core/app_colors.dart';

class RegionCityButton extends StatelessWidget {
  final String title;
  final VoidCallback onPressed;

  const RegionCityButton({
    super.key,
    required this.title,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onPressed,
      child: Container(
        width: 150,
        height: 70,
        decoration: BoxDecoration(
          color: AppColors.regionButtonBackground,
          borderRadius: BorderRadius.circular(10),
          boxShadow: [
            BoxShadow(
              color: AppColors.regionButtonShadow,
              spreadRadius: 2,
              blurRadius: 5,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Center(
          child: Text(
            title,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16,
              color: AppColors.textColorPrimary,
            ),
          ),
        ),
      ),
    );
  }
}

// lib/widgets/home_action_card.dart

import 'package:flutter/material.dart';
import 'package:securia/core/app_colors.dart';

class HomeActionCard extends StatelessWidget {
  final String title;
  final VoidCallback onPressed;

  const HomeActionCard({
    super.key,
    required this.title,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onPressed,
      child: Container(
        width: 175,
        height: 225,
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: AppColors.homeCardBackground,
          borderRadius: BorderRadius.circular(10),
          boxShadow: [
            BoxShadow(
              color: AppColors.homeCardShadow,
              spreadRadius: 5,
              blurRadius: 7,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Center(
          child: Text(
            title,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppColors.textColorPrimary,
            ),
          ),
        ),
      ),
    );
  }
}

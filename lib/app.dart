// lib/app.dart

import 'package:flutter/material.dart';
import 'package:securia/core/styles.dart';

class MyApp extends StatelessWidget {
  final Widget homePage;

  const MyApp({super.key, required this.homePage});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: "SECUR.IA",
      theme: AppStyles.mainTheme,
      home: homePage,
    );
  }
}

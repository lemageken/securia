// lib/wrappers/auth_wrapper.dart

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:securia/screens/auth/email_auth_page.dart'; // Ton écran login/inscription
import 'package:securia/screens/home/home_page.dart'; // Écran annuaire/home

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance
          .authStateChanges(), // Persistence token local
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        // Connecté ? Direct à annuaire (sans Internet pour check token)
        if (snapshot.hasData) {
          return const MainHomePage(); // Ton annuaire/home
        }

        // Pas connecté : Login (seulement première fois)
        return const EmailAuthPage();
      },
    );
  }
}

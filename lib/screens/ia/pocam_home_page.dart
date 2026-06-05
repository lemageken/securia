import 'package:flutter/material.dart';
import 'package:securia/core/app_colors.dart';
import 'package:securia/screens/ia/pocam_chat_page.dart';
import 'package:securia/screens/home/home_page.dart';
import 'package:securia/screens/infos/infos_page.dart';

class PocamHomePage extends StatelessWidget {
  const PocamHomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "Accueil Pocam237, l'IA de la POCAM",
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: AppColors.appBarForeground,
          ),
        ),
        backgroundColor: AppColors.appBarBackground,
        actions: [
          PopupMenuButton<int>(
            icon: const Icon(Icons.menu, color: AppColors.appBarForeground),
            onSelected: (item) {
              switch (item) {
                case 0:
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const MainHomePage(),
                    ),
                  );
                  break;
                case 1:
                  break; // IA Chatbot (actuel)
                case 2:
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(builder: (context) => const InfoPage()),
                  );
                  break;
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem<int>(
                value: 0,
                child: Text('Accueil principal'),
              ),
              const PopupMenuItem<int>(value: 1, child: Text('IA Chatbot')),
              const PopupMenuItem<int>(value: 2, child: Text('Informations')),
            ],
          ),
        ],
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.only(
            left: 16.0,
            right: 16.0,
            top: 1.0,
            bottom: 16.0,
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: <Widget>[
              CircleAvatar(
                radius: 60,
                backgroundColor: AppColors.primaryDark,
                backgroundImage: const AssetImage('assets/images/Pocam.jpg'),
                onBackgroundImageError: (_, __) {
                  debugPrint("Erreur : Impossible de charger l'image Pocam.jpg");
                },
              ),
              const SizedBox(height: 10),
              Text(
                'Bonjour, je suis Pocam237, votre assistant IA de la Police Nationale !',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: AppColors.primaryText,
                ),
              ),
              const SizedBox(height: 8),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24.0),
                child: Text(
                  "Je suis un assistant virtuel conçu pour vous aider avec "
                  "des informations relatives aux cas pratiques de service, "
                  "au code pénal, procédure pénale et aux procédures professionnelles de la police camerounaise. "
                  "Posez-moi vos questions et j'essaierai de vous fournir des "
                  "réponses claires, précises et structurées.",
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 16, color: AppColors.primaryText),
                ),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const PocamChatPage(),
                    ),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryDark,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30.0),
                  ),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 40,
                    vertical: 12,
                  ),
                  elevation: 5,
                ),
                child: const Text(
                  "Discuter avec Pocam237",
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppColors.buttonText,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

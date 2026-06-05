// lib/screens/infos/infos_page.dart

import 'package:flutter/material.dart';
import 'package:securia/core/app_colors.dart';
import 'package:url_launcher/url_launcher.dart';

class InfoPage extends StatelessWidget {
  const InfoPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundColor,
      appBar: AppBar(
        title: const Text('Informations Utiles'),
        backgroundColor: AppColors.appBarBackground,
        foregroundColor: AppColors.appBarForeground,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // En-tête de marque élégante avec dégradé institutionnel
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20.0),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [AppColors.primaryDark, Color(0xFF1E3A8A)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withAlpha((0.08 * 255).round()),
                    blurRadius: 15,
                    offset: const Offset(0, 5),
                  )
                ],
              ),
              child: Column(
                children: [
                  CircleAvatar(
                    radius: 36,
                    backgroundColor: Colors.white,
                    child: Padding(
                      padding: const EdgeInsets.all(4.0),
                      child: Image.asset('assets/images/logo_police.jpg'),
                    ),
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'SECUR.IA',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      letterSpacing: 1.5,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Plateforme Numérique Intelligente',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.white.withAlpha((0.8 * 255).round()),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Card: Présentation de SECUR.IA
            _buildSectionCard(
              title: 'Présentation de SECUR.IA',
              icon: Icons.info_outline_rounded,
              child: const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'SECUR.IA est une plateforme numérique intelligente conçue pour moderniser l’accès à l’information, renforcer la communication professionnelle et accompagner les fonctionnaires de Police dans leurs missions quotidiennes grâce aux technologies de l’Intelligence Artificielle.',
                    style: TextStyle(
                      fontSize: 15,
                      height: 1.5,
                      color: AppColors.textColorPrimary,
                    ),
                  ),
                  SizedBox(height: 12),
                  Text(
                    'L’application facilite l’accès rapide et sécurisé à l’annuaire téléphonique professionnel de la DGSN, tout en offrant un assistant intelligent capable de fournir des informations utiles, un accompagnement opérationnel, ainsi qu’un support de formation continue adapté aux réalités du terrain.',
                    style: TextStyle(
                      fontSize: 15,
                      height: 1.5,
                      color: AppColors.textColorPrimary,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Card: Notre Mission
            _buildSectionCard(
              title: 'Notre Mission',
              icon: Icons.track_changes_rounded,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'La mission de SECUR.IA est de contribuer à la transformation numérique des services de sécurité en mettant à la disposition des personnels de Police un outil moderne, pratique et performant.',
                    style: TextStyle(
                      fontSize: 15,
                      height: 1.5,
                      color: AppColors.textColorPrimary,
                    ),
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'À travers l’Intelligence Artificielle, SECUR.IA vise à :',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: AppColors.primaryDark,
                    ),
                  ),
                  const SizedBox(height: 10),
                  _buildBulletItem('simplifier la communication professionnelle ;'),
                  _buildBulletItem('accélérer l’accès aux informations essentielles ;'),
                  _buildBulletItem('améliorer l’efficacité opérationnelle ;'),
                  _buildBulletItem('renforcer les capacités professionnelles des agents ;'),
                  _buildBulletItem('faciliter l’apprentissage continu et l’assistance dans les procédures administratives et opérationnelles.'),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Card: Notre Vision
            _buildSectionCard(
              title: 'Notre Vision',
              icon: Icons.visibility_outlined,
              child: const Text(
                'Faire de SECUR.IA une référence technologique au service des forces de sécurité en Afrique, en intégrant l’innovation, l’accessibilité et l’intelligence artificielle au cœur des missions de protection et de service public.',
                style: TextStyle(
                  fontSize: 15,
                  height: 1.5,
                  color: AppColors.textColorPrimary,
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Card: Contactez-nous
            _buildSectionCard(
              title: 'Contactez-nous',
              icon: Icons.chat_bubble_outline_rounded,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Pour toute question ou suggestion, veuillez nous contacter :',
                    style: TextStyle(
                      fontSize: 15,
                      color: AppColors.textColorPrimary,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Material(
                    color: Colors.transparent,
                    child: InkWell(
                      borderRadius: BorderRadius.circular(14),
                      onTap: () async {
                        final Uri whatsappUri = Uri.parse("https://wa.me/237683911717");
                        try {
                          if (await canLaunchUrl(whatsappUri)) {
                            await launchUrl(whatsappUri, mode: LaunchMode.externalApplication);
                          } else {
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text("Impossible de lancer WhatsApp directement. Veuillez enregistrer le numéro 683911717."),
                                ),
                              );
                            }
                          }
                        } catch (e) {
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text("Erreur lors de l'ouverture de WhatsApp : $e"),
                              ),
                            );
                          }
                        }
                      },
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                        decoration: BoxDecoration(
                          color: const Color(0xFF25D366).withAlpha((0.08 * 255).round()),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: const Color(0xFF25D366).withAlpha((0.25 * 255).round()),
                            width: 1.5,
                          ),
                        ),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: const BoxDecoration(
                                color: Color(0xFF25D366),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.chat_bubble_rounded,
                                color: Colors.white,
                                size: 20,
                              ),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: const [
                                  Text(
                                    '(WhatsApp 683911717)',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      color: Color(0xFF0F5132),
                                      letterSpacing: 0.5,
                                    ),
                                  ),
                                  SizedBox(height: 2),
                                  Text(
                                    'Cliquez pour ouvrir l\'application',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Color(0xFF198754),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Icon(
                              Icons.open_in_new_rounded,
                              color: const Color(0xFF0F5132).withAlpha((0.6 * 255).round()),
                              size: 18,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Footer de version harmonisé
            Center(
              child: Column(
                children: [
                  const Text(
                    'SECUR.IA',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textColorSecondary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Version: 1.0.0 - Août 2025',
                    style: TextStyle(
                      fontSize: 13,
                      color: AppColors.textColorSecondary.withAlpha((0.8 * 255).round()),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionCard({
    required String title,
    required IconData icon,
    required Widget child,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: AppColors.homeCardBackground,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha((0.03 * 255).round()),
            blurRadius: 10,
            offset: const Offset(0, 4),
          )
        ],
        border: Border.all(
          color: Colors.black.withAlpha((0.03 * 255).round()),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                icon,
                color: AppColors.activeIconColorPink, // Or Camerounais pour marquer l'identité
                size: 22,
              ),
              const SizedBox(width: 10),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.bold,
                  color: AppColors.primaryDark,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          const Divider(height: 1, color: Color(0xFFF1F5F9)),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }

  Widget _buildBulletItem(String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.only(top: 4.0),
            child: Icon(
              Icons.check_circle_outline_rounded,
              color: AppColors.activeIconColorPink, // Or Camerounais
              size: 16,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                fontSize: 15,
                height: 1.4,
                color: AppColors.textColorPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

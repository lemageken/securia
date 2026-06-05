import 'package:animated_notch_bottom_bar/animated_notch_bottom_bar/animated_notch_bottom_bar.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:securia/core/app_colors.dart';
import 'package:securia/screens/annuaire/annuaire_home.dart';
import 'package:securia/screens/ia/pocam_home_page.dart';
import 'package:securia/screens/infos/infos_page.dart';
import 'package:securia/config/config_page.dart';
import 'package:securia/screens/search/search_contacts_page.dart';
import 'package:securia/screens/auth/email_auth_page.dart';
import 'package:securia/core/version_helper.dart';

class MainHomePage extends StatefulWidget {
  const MainHomePage({super.key});

  @override
  State<MainHomePage> createState() => _MainHomePageState();
}

class _MainHomePageState extends State<MainHomePage> {
  final _pageController = PageController(initialPage: 0);
  final _notchController = NotchBottomBarController(index: 0);

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      VersionHelper.checkVersion(context);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('SECUR.IA'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              // Capturer NavigatorState et ScaffoldMessengerState avant l'opération asynchrone
              final navigator = Navigator.of(context);
              final scaffoldMessenger = ScaffoldMessenger.of(context);
              final route = MaterialPageRoute(
                builder: (_) => const EmailAuthPage(),
              );
              try {
                await FirebaseAuth.instance.signOut();
                if (mounted) {
                  navigator.pushReplacement(route);
                }
              } catch (e) {
                if (mounted) {
                  scaffoldMessenger.showSnackBar(
                    SnackBar(
                      content: Text('Erreur lors de la déconnexion : $e'),
                    ),
                  );
                }
              }
            },
          ),
        ],
      ),
      body: PageView(
        controller: _pageController,
        physics: const NeverScrollableScrollPhysics(),
        children: [
          AnnuaireHomePage(),
          PocamHomePage(),
          InfoPage(),
          ConfigPage(),
          SearchContactsPage(),
        ],
      ),
      bottomNavigationBar: AnimatedNotchBottomBar(
        notchBottomBarController: _notchController,
        color: AppColors.bottomBarColor,
        showLabel: true,
        notchColor: AppColors.notchColor,
        kIconSize: 24.0,
        kBottomRadius: 16.0,
        bottomBarItems: [
          BottomBarItem(
            itemLabel: 'Annuaire',
            inActiveItem: Icon(
              Icons.contacts,
              color: AppColors.inActiveIconColor,
            ),
            activeItem: Icon(
              Icons.contacts,
              color: AppColors.activeIconColorRed,
            ),
          ),
          BottomBarItem(
            itemLabel: 'IA',
            inActiveItem: Icon(
              Icons.smart_toy,
              color: AppColors.inActiveIconColor,
            ),
            activeItem: Icon(
              Icons.smart_toy,
              color: AppColors.activeIconColorPink,
            ),
          ),
          BottomBarItem(
            itemLabel: 'Infos',
            inActiveItem: Icon(Icons.info, color: AppColors.inActiveIconColor),
            activeItem: Icon(Icons.info, color: AppColors.activeIconColorRed),
          ),
          BottomBarItem(
            itemLabel: 'Config',
            inActiveItem: Icon(
              Icons.settings,
              color: AppColors.inActiveIconColor,
            ),
            activeItem: Icon(
              Icons.settings,
              color: AppColors.activeIconColorPink,
            ),
          ),
          BottomBarItem(
            itemLabel: 'Recherche',
            inActiveItem: Icon(
              Icons.search,
              color: AppColors.inActiveIconColor,
            ),
            activeItem: Icon(Icons.search, color: AppColors.activeIconColorRed),
          ),
        ],
        onTap: (index) {
          _pageController.jumpToPage(index);
        },
      ),
    );
  }
}

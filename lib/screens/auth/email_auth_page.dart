// lib/screens/auth/email_auth_page.dart

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:securia/core/app_colors.dart';
import 'package:securia/core/constants.dart';
import 'package:securia/screens/home/home_page.dart';
import 'package:securia/widgets/message_box.dart';

class EmailAuthPage extends StatefulWidget {
  const EmailAuthPage({super.key});

  @override
  State<EmailAuthPage> createState() => _EmailAuthPageState();
}

class _EmailAuthPageState extends State<EmailAuthPage> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _firstNameController = TextEditingController();
  final TextEditingController _matriculeController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  bool _isLoading = false;
  bool _isLoginMode = true;
  bool _isPasswordVisible = false;

  @override
  void dispose() {
    _nameController.dispose();
    _firstNameController.dispose();
    _matriculeController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  // Fonction d'authentification
  Future<void> _handleAuth() async {
    final name = _nameController.text.trim();
    final firstName = _firstNameController.text.trim();
    final matricule = _matriculeController.text.trim();
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();

    if (email.isEmpty || password.isEmpty) {
      if (mounted) {
        MessageBox.show(
          context,
          'Erreur',
          'Veuillez saisir votre e-mail et votre mot de passe.',
        );
      }
      return;
    }

    // --- NOUVELLE VÉRIFICATION DE LA LONGUEUR DU MOT DE PASSE ---
    if (password.length < 6) {
      if (mounted) {
        MessageBox.show(
          context,
          'Mot de passe trop court',
          'Le mot de passe doit contenir au moins 6 caractères.',
        );
      }
      return;
    }
    // -----------------------------------------------------------

    if (!_isLoginMode &&
        (name.isEmpty || firstName.isEmpty || matricule.isEmpty)) {
      if (mounted) {
        MessageBox.show(
          context,
          'Erreur',
          'Veuillez remplir tous les champs (Nom, Prénom, Matricule) pour l\'inscription.',
        );
      }
      return;
    }

    if (mounted) {
      setState(() {
        _isLoading = true;
      });
    }

    try {
      if (_isLoginMode) {
        // Mode Connexion
        UserCredential userCredential = await _auth.signInWithEmailAndPassword(
          email: email,
          password: password,
        );
        User? user = userCredential.user;

        if (user != null) {
          if (user.emailVerified) {
            // Si l'e-mail est vérifié, rediriger vers la page d'accueil
            if (mounted) {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (context) => const MainHomePage()),
              );
            }
          } else {
            // E-mail non vérifié, déconnecter et informer l'utilisateur
            await _auth.signOut();
            if (mounted) {
              MessageBox.show(
                context,
                'Vérification requise',
                'Veuillez vérifier votre adresse e-mail pour vous connecter.',
              );
            }
          }
        }
      } else {
        // Mode Inscription
        UserCredential userCredential = await _auth
            .createUserWithEmailAndPassword(email: email, password: password);
        User? user = userCredential.user;

        if (user != null) {
          // Enregistrer les informations de l'utilisateur dans Firestore
          await _firestore.collection('users').doc(user.uid).set({
            'uid': user.uid,
            'nom': name,
            'prenom': firstName,
            'matricule': matricule,
            'email': email,
            'createdAt': FieldValue.serverTimestamp(),
          });

          // Envoyer l'e-mail de vérification
          await user.sendEmailVerification();

          if (mounted) {
            MessageBox.show(
              context,
              'Vérification requise',
              'Un e-mail de vérification a été envoyé à $email. Veuillez vérifier votre boîte de réception pour continuer.',
            );
            // Passer en mode connexion après l'inscription réussie
            if (mounted) {
              setState(() {
                _isLoginMode = true;
              });
            }
          }
        }
      }
    } on FirebaseAuthException catch (e) {
      String errorMessage = 'Une erreur est survenue.';
      if (e.code == 'weak-password') {
        errorMessage = 'Le mot de passe fourni est trop faible.';
      } else if (e.code == 'email-already-in-use') {
        errorMessage = 'Un compte existe déjà pour cet e-mail.';
      } else if (e.code == 'user-not-found' || e.code == 'wrong-password') {
        errorMessage = 'E-mail ou mot de passe incorrect.';
      }
      if (mounted) {
        MessageBox.show(context, 'Erreur d\'authentification', errorMessage);
      }
    } catch (e) {
      if (mounted) {
        MessageBox.show(
          context,
          'Erreur',
          'Une erreur inattendue est survenue: $e',
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  // Fonction pour lancer l'application de messagerie

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          Image.asset(
            AppConstants.firstPageBgPath,
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) {
              return Container(
                color: Colors.white,
                child: const Center(child: Text("Image first.png introuvable")),
              );
            },
          ),
          Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: <Widget>[
                  const SizedBox(height: 25),
                  Align(
                    alignment: Alignment.center,
                    child: Image.asset(
                      AppConstants.logoPolicePath,
                      height: 150,
                      errorBuilder: (context, error, stackTrace) {
                        return const Icon(
                          Icons.security,
                          size: 80,
                          color: AppColors.primaryDark,
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    _isLoginMode ? 'CONNEXION' : 'INSCRIPTION',
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 38,
                      fontWeight: FontWeight.bold,
                      color: AppColors.primaryDark,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Authentification de la Police Camerounaise',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 16,
                      color: AppColors.secondaryText,
                    ),
                  ),
                  const SizedBox(height: 80),

                  if (!_isLoginMode) ...[
                    _buildTextField(_nameController, 'Nom'),
                    const SizedBox(height: 20),
                    _buildTextField(_firstNameController, 'Prénom'),
                    const SizedBox(height: 20),
                    _buildTextField(_matriculeController, 'Matricule'),
                    const SizedBox(height: 20),
                  ],

                  _buildTextField(
                    _emailController,
                    'Adresse e-mail',
                    type: TextInputType.emailAddress,
                  ),
                  const SizedBox(height: 20),

                  // Champ mot de passe avec visibilité
                  TextField(
                    controller: _passwordController,
                    obscureText: !_isPasswordVisible,
                    decoration: InputDecoration(
                      hintText: 'Mot de passe',
                      filled: true,
                      fillColor: AppColors.inputBackground,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12.0),
                        borderSide: BorderSide.none,
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        vertical: 16.0,
                        horizontal: 20.0,
                      ),
                      suffixIcon: IconButton(
                        icon: Icon(
                          _isPasswordVisible
                              ? Icons.visibility
                              : Icons.visibility_off,
                          color: AppColors.primaryDark,
                        ),
                        onPressed: () {
                          setState(() {
                            _isPasswordVisible = !_isPasswordVisible;
                          });
                        },
                      ),
                    ),
                  ),
                  const SizedBox(height: 40),

                  _isLoading
                      ? const Center(child: CircularProgressIndicator())
                      : ElevatedButton(
                          onPressed: _handleAuth,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primaryDark,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12.0),
                            ),
                            padding: const EdgeInsets.symmetric(vertical: 16.0),
                          ),
                          child: Text(
                            _isLoginMode ? 'Se connecter' : 'S\'inscrire',
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: AppColors.buttonText,
                            ),
                          ),
                        ),
                  const SizedBox(height: 20),

                  TextButton(
                    onPressed: () {
                      setState(() {
                        _isLoginMode = !_isLoginMode;
                      });
                    },
                    child: Text(
                      _isLoginMode
                          ? 'Vous n\'avez pas de compte ? S\'inscrire'
                          : 'Vous avez déjà un compte ? Se connecter',
                      style: const TextStyle(
                        color: AppColors.primaryDark,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),

                  const SizedBox(height: 50),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTextField(
    TextEditingController controller,
    String hint, {
    TextInputType type = TextInputType.text,
  }) {
    return TextField(
      controller: controller,
      keyboardType: type,
      decoration: InputDecoration(
        hintText: hint,
        filled: true,
        fillColor: AppColors.inputBackground,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12.0),
          borderSide: BorderSide.none,
        ),
        contentPadding: const EdgeInsets.symmetric(
          vertical: 16.0,
          horizontal: 20.0,
        ),
      ),
    );
  }
}

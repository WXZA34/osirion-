import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/providers/repository_providers.dart';
import '../../core/navigation/main_navigation_shell.dart';
import 'onboarding/setup_flow/sanctuary_setup_screen.dart';

class RegisterScreen extends ConsumerStatefulWidget {
  const RegisterScreen({super.key});

  @override
  ConsumerState<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends ConsumerState<RegisterScreen> {
  final _pseudoController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;
  String _errorMessage = '';

  Future<void> _register() async {
    if (_pseudoController.text.trim().isEmpty) {
      setState(() => _errorMessage = "Veuillez entrer un pseudonyme");
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      final valerionRepo = ref.read(valerionRepositoryProvider);
      final authRepository = ref.read(authRepositoryProvider);

      // 1. Vérification de l'unicité du pseudo
      final pseudo = _pseudoController.text.trim();
      final isAvailable = await valerionRepo.isUsernameAvailable(pseudo);

      if (!isAvailable) {
        setState(
          () =>
              _errorMessage =
                  "Ce pseudonyme est déjà utilisé par une autre recrue",
        );
        return;
      }

      // 2. La création de compte via la couche d'interface
      final user = await authRepository.signUpWithEmail(
        _emailController.text.trim(),
        _passwordController.text.trim(),
        pseudo,
      );

      // Sécurité : On s'assure d'avoir l'Entity remplie parfaitement (Le createdAt pourrait être farfelu depuis certains Mocks Auth)
      final userToSave =
          user.createdAt.year < 2000
              ? user.copyWith(createdAt: DateTime.now(), level: 1, xp: 0)
              : user;

      // Enregistre le profil initial dans Firestore (Level 1, 0 XP)
      if (kDebugMode) {
        debugPrint(
          "🚀 [RegisterScreen] Lancement de la sauvegarde du UserProfile...",
        );
      }
      await valerionRepo.saveUserProfile(userToSave);

      if (mounted) {
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (context) => const SanctuarySetupScreen()),
          (route) => false, // Nettoie la pile entière
        );
      }
    } catch (e) {
      if (mounted) {
        setState(
          () => _errorMessage = e.toString().replaceAll("Exception: ", ""),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        fit: StackFit.expand,
        children: [
          // Background Image
          Positioned.fill(
            child: Image.asset('assets/branding/1234.jpeg', fit: BoxFit.cover),
          ),
          // Dark overlay
          Positioned.fill(
            child: Container(color: Colors.black.withOpacity(0.2)),
          ),
          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Align(
                    alignment: Alignment.centerLeft,
                    child: GestureDetector(
                      onTap: () => Navigator.pop(context),
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(
                          Icons.arrow_back,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  const Text(
                    "NOUVELLE RECRUE",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 28,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 2,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    "L'ère d'OSIRION t'attend. Crée ton profil.",
                    style: TextStyle(color: Colors.white54, fontSize: 16),
                  ),
                  const SizedBox(height: 32),

                  // Glassmorphism Form Container
                  Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(24),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(24),
                      child: BackdropFilter(
                        filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
                        child: Container(
                          padding: const EdgeInsets.all(24),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [
                                Colors.white.withValues(alpha: 0.15),
                                Colors.white.withValues(alpha: 0.05),
                              ],
                            ),
                            borderRadius: BorderRadius.circular(24),
                            border: Border.all(
                              color: Colors.white.withValues(alpha: 0.2),
                              width: 1.5,
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              // Champ Pseudo
                              _buildTextField(
                                controller: _pseudoController,
                                hintText: "Nom de code (Pseudo)",
                                icon: Icons.person,
                              ),
                              const SizedBox(height: 16),

                              // Champ Email
                              _buildTextField(
                                controller: _emailController,
                                hintText: "Email",
                                icon: Icons.email,
                              ),
                              const SizedBox(height: 16),

                              // Champ Password
                              _buildTextField(
                                controller: _passwordController,
                                hintText: "Mot de passe d'accès",
                                icon: Icons.lock,
                                isPassword: true,
                              ),
                              const SizedBox(height: 24),

                              // Error Message
                              if (_errorMessage.isNotEmpty)
                                Padding(
                                  padding: const EdgeInsets.only(bottom: 16),
                                  child: Text(
                                    _errorMessage,
                                    style: const TextStyle(
                                      color: Colors.redAccent,
                                      fontSize: 14,
                                    ),
                                  ),
                                ),

                              // Bouton
                              ElevatedButton(
                                onPressed: _isLoading ? null : _register,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.greenAccent[700],
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 16,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                                child:
                                    _isLoading
                                        ? const SizedBox(
                                          height: 20,
                                          width: 20,
                                          child: CircularProgressIndicator(
                                            color: Colors.black,
                                            strokeWidth: 2,
                                          ),
                                        )
                                        : const Text(
                                          "S'ENRÔLER DANS OSIRION",
                                          style: TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.bold,
                                            color: Colors.black,
                                          ),
                                        ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String hintText,
    required IconData icon,
    bool isPassword = false,
  }) {
    return TextField(
      controller: controller,
      obscureText: isPassword,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        hintText: hintText,
        hintStyle: const TextStyle(color: Colors.white24),
        filled: true,
        fillColor: Colors.grey[900],
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        prefixIcon: Icon(icon, color: Colors.blueGrey),
      ),
    );
  }

  @override
  void dispose() {
    _pseudoController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }
}

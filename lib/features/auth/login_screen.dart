import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/providers/repository_providers.dart';
import 'register_screen.dart';
import '../../core/navigation/main_navigation_shell.dart';
import '../../l10n/app_localizations.dart';
import 'onboarding/setup_flow/sanctuary_setup_screen.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;
  String _errorMessage = '';

  Future<void> _login() async {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      final authRepository = ref.read(authRepositoryProvider);
      await authRepository.signInWithEmail(
        _emailController.text.trim(),
        _passwordController.text.trim(),
      );

      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const MainNavigationShell()),
        );
      }
    } catch (e) {
      setState(
        () => _errorMessage = e.toString().replaceAll("Exception: ", ""),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _loginWithGoogle() async {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      final authRepo = ref.read(authRepositoryProvider);
      final valerionRepo = ref.read(valerionRepositoryProvider);

      final user = await authRepo.signInWithGoogle();
      final profile = await valerionRepo.getUserProfile(user.id);

      if (profile == null) {
        // Nouveau profil, on demande le pseudo via une modale
        if (mounted) {
          final pseudo = await _showPseudoDialog(context, valerionRepo);
          if (pseudo != null && pseudo.isNotEmpty) {
            final userToSave = user.copyWith(
              username: pseudo,
              createdAt: DateTime.now(),
              level: 1,
              xp: 0,
            );
            await valerionRepo.saveUserProfile(userToSave);
            
            if (mounted) {
              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(builder: (context) => const SanctuarySetupScreen()),
                (route) => false,
              );
            }
          } else {
            // L'utilisateur a annulé, on le déconnecte
            await authRepo.signOut();
            setState(() => _isLoading = false);
            return;
          }
        }
      } else {
        // Profil existant
        if (mounted) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => const MainNavigationShell()),
          );
        }
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

  Future<String?> _showPseudoDialog(BuildContext context, valerionRepo) async {
    final controller = TextEditingController();
    String? errorText;

    return showDialog<String>(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setStateDialog) {
            return AlertDialog(
              backgroundColor: const Color(0xFF161A22),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              title: Text(
                AppLocalizations.of(context)!.googlePseudoTitle,
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    AppLocalizations.of(context)!.googlePseudoDesc,
                    style: const TextStyle(color: Colors.white70),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: controller,
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      hintText: "Pseudo",
                      hintStyle: const TextStyle(color: Colors.white54),
                      errorText: errorText,
                      filled: true,
                      fillColor: Colors.black26,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: Text(
                    AppLocalizations.of(context)!.googlePseudoCancel,
                    style: const TextStyle(color: Colors.white54),
                  ),
                ),
                ElevatedButton(
                  onPressed: () async {
                    final text = controller.text.trim();
                    if (text.isEmpty) {
                      setStateDialog(() => errorText = AppLocalizations.of(context)!.googlePseudoEmptyError);
                      return;
                    }
                    final isAvailable = await valerionRepo.isUsernameAvailable(text);
                    if (!isAvailable) {
                      setStateDialog(() => errorText = AppLocalizations.of(context)!.googlePseudoTakenError);
                      return;
                    }
                    if (context.mounted) {
                      Navigator.of(context).pop(text);
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFFFD700),
                    foregroundColor: Colors.black,
                  ),
                  child: Text(AppLocalizations.of(context)!.googlePseudoValidate),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> _resetPassword() async {
    final email = _emailController.text.trim();
    if (email.isEmpty) {
      setState(
        () =>
            _errorMessage =
                "Veuillez entrer votre Identifiant (Email) d'abord.",
      );
      return;
    }
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });
    try {
      final authRepository = ref.read(authRepositoryProvider);
      await authRepository.sendPasswordResetEmail(email);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              "Un email contenant un lien de réinitialisation a été envoyé à cette adresse.",
            ),
            backgroundColor: Colors.greenAccent,
          ),
        );
      }
    } catch (e) {
      setState(
        () => _errorMessage = e.toString().replaceAll("Exception: ", ""),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black, // Dark Theme
      body: Stack(
        fit: StackFit.expand,
        children: [
          // Background Image
          Positioned.fill(
            child: Image.asset('assets/branding/1234.jpeg', fit: BoxFit.cover),
          ),
          // Dark overlay to ensure text remains readable
          Positioned.fill(
            child: Container(color: Colors.black.withOpacity(0.2)),
          ),
          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SizedBox(height: 40),
                  const Text(
                    "OSIRION",
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 32,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 4,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    "Initie ta connexion au système",
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.white54, fontSize: 16),
                  ),
                  const SizedBox(height: 48),

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
                              // Champ Email
                              TextField(
                                controller: _emailController,
                                style: const TextStyle(color: Colors.white),
                                decoration: InputDecoration(
                                  hintText: "Identifiant Alpha (Email)",
                                  hintStyle: const TextStyle(
                                    color: Colors.white24,
                                  ),
                                  filled: true,
                                  fillColor: Colors.grey[900]?.withValues(alpha: 0.5),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: BorderSide.none,
                                  ),
                                  prefixIcon: const Icon(
                                    Icons.email,
                                    color: Colors.blueAccent,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 16),

                              // Champ Password
                              TextField(
                                controller: _passwordController,
                                obscureText: true,
                                style: const TextStyle(color: Colors.white),
                                decoration: InputDecoration(
                                  hintText: "Code de sécurité",
                                  hintStyle: const TextStyle(
                                    color: Colors.white24,
                                  ),
                                  filled: true,
                                  fillColor: Colors.grey[900]?.withValues(alpha: 0.5),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: BorderSide.none,
                                  ),
                                  prefixIcon: const Icon(
                                    Icons.lock,
                                    color: Colors.blueAccent,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 24),

                              // Error Message
                              if (_errorMessage.isNotEmpty)
                                Padding(
                                  padding: const EdgeInsets.only(bottom: 16),
                                  child: Text(
                                    _errorMessage,
                                    textAlign: TextAlign.center,
                                    style: const TextStyle(
                                      color: Colors.redAccent,
                                      fontSize: 14,
                                    ),
                                  ),
                                ),

                              // Bouton Démarrer
                              ElevatedButton(
                                onPressed: _isLoading ? null : _login,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.blueAccent,
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
                                            color: Colors.white,
                                            strokeWidth: 2,
                                          ),
                                        )
                                        : const Text(
                                          "CONNEXION",
                                          style: TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.bold,
                                            color: Colors.white,
                                          ),
                                        ),
                              ),

                              const SizedBox(height: 16),
                              Row(
                                children: [
                                  const Expanded(child: Divider(color: Colors.white24)),
                                  Padding(
                                    padding: const EdgeInsets.symmetric(horizontal: 8.0),
                                    child: Text(
                                      "OU",
                                      style: TextStyle(color: Colors.white54, fontSize: 12),
                                    ),
                                  ),
                                  const Expanded(child: Divider(color: Colors.white24)),
                                ],
                              ),
                              const SizedBox(height: 16),

                              ElevatedButton.icon(
                                onPressed: _isLoading ? null : _loginWithGoogle,
                                icon: Image.asset(
                                  'assets/branding/google_logo.png', // Fallback icon
                                  height: 20,
                                  errorBuilder: (context, error, stackTrace) => const Icon(Icons.g_mobiledata, size: 28),
                                ),
                                label: Text(
                                  AppLocalizations.of(context)!.googleSignInButton,
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.white,
                                  foregroundColor: Colors.black87,
                                  padding: const EdgeInsets.symmetric(vertical: 16),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
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

                  // Mot de passe oublié
                  TextButton(
                    onPressed: _isLoading ? null : _resetPassword,
                    child: const Text(
                      "Code d'accès perdu ?",
                      style: TextStyle(color: Colors.redAccent),
                    ),
                  ),

                  // Redirection Register
                  TextButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const RegisterScreen(),
                        ),
                      );
                    },
                    child: const Text(
                      "Nouveau candidat ? Rejoindre l'Ordre OSIRION.",
                      style: TextStyle(color: Colors.white54),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }
}

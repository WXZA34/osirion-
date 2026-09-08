import '../../l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/providers/locale_provider.dart';
import '../../core/providers/repository_providers.dart';
import '../../core/navigation/main_navigation_shell.dart';
import 'onboarding/setup_flow/sanctuary_setup_screen.dart';
import 'login_screen.dart';
import 'register_screen.dart';

class WelcomeScreen extends ConsumerStatefulWidget {
  const WelcomeScreen({super.key});

  @override
  ConsumerState<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends ConsumerState<WelcomeScreen> {
  bool _isLoading = false;

  Future<void> _loginWithGoogle() async {
    setState(() {
      _isLoading = true;
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
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString().replaceAll("Exception: ", "")),
            backgroundColor: Colors.redAccent,
          ),
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

  @override
  Widget build(BuildContext context) {
    final currentLocale = ref.watch(localeProvider);

    return Scaffold(
      backgroundColor: const Color(0xFF0A0C10),
      body: Stack(
        children: [
          // Background Image
          Positioned.fill(
            child: Image.asset(
              'assets/branding/1234.jpeg',
              fit: BoxFit.cover,
            ),
          ),
          // Dark overlay to ensure text remains readable
          Positioned.fill(
            child: Container(
              color: Colors.black.withValues(alpha: 0.3),
            ),
          ),
          SafeArea(
            child: Stack(
            children: [
              Positioned(
                top: 16,
                right: 16,
                child: GestureDetector(
                  onTap: () {
                    final newLocale = currentLocale.languageCode == 'fr' ? 'en' : 'fr';
                    ref.read(localeProvider.notifier).setLocale(Locale(newLocale));
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: const Color(0xFFFFD700).withValues(alpha: 0.3)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.language, color: Color(0xFFFFD700), size: 16),
                        const SizedBox(width: 6),
                        Text(
                          currentLocale.languageCode.toUpperCase(),
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1.2,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 32.0,
                  vertical: 48.0,
                ),
                child: Column(
                  children: [
                    const Spacer(flex: 2),



                    Text(
                      AppLocalizations.of(context)!.authBienvenueDansLOrdre,
                      style: const TextStyle(
                        color: Color(0xFFFFD700),
                        fontSize: 14,
                        letterSpacing: 4,
                        fontWeight: FontWeight.bold,
                      ),
                    ),

                    const SizedBox(height: 12),

                    Text(AppLocalizations.of(context)!.appTitle,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 48,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 8,
                      ),
                    ),

                    const SizedBox(height: 16),

                    Text(
                      AppLocalizations.of(context)!.authForceLoyautSagesse,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: Colors.white54,
                        fontSize: 16,
                        letterSpacing: 1.5,
                      ),
                    ),

                    const Spacer(flex: 3),

                    // Bouton S'enrôler (Créer compte)
                    ElevatedButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const RegisterScreen(),
                          ),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFFFD700),
                        foregroundColor: Colors.black,
                        minimumSize: const Size(double.infinity, 56),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        elevation: 8,
                        shadowColor: const Color(0xFFFFD700).withValues(alpha: 0.4),
                      ),
                      child: Text(
                        AppLocalizations.of(context)!.authSEnrLerMaintenant,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 1.2,
                        ),
                      ),
                    ),

                    const SizedBox(height: 16),

                    // Bouton Google Sign-In
                    _isLoading
                        ? const CircularProgressIndicator(color: Color(0xFFFFD700))
                        : ElevatedButton.icon(
                            onPressed: _loginWithGoogle,
                            icon: Image.asset(
                              'assets/branding/google_logo.png', // Fallback icon si pas présent
                              height: 24,
                              errorBuilder: (context, error, stackTrace) => const Icon(Icons.g_mobiledata, size: 32),
                            ),
                            label: Text(
                              AppLocalizations.of(context)!.googleSignInButton,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 1.1,
                              ),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.white,
                              foregroundColor: Colors.black87,
                              minimumSize: const Size(double.infinity, 56),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                              elevation: 4,
                            ),
                          ),

                    const SizedBox(height: 16),

                    // Bouton Connexion (Déjà membre)
                    OutlinedButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const LoginScreen(),
                          ),
                        );
                      },
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.white,
                        side: const BorderSide(color: Colors.white24, width: 2),
                        minimumSize: const Size(double.infinity, 56),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      child: Text(
                        AppLocalizations.of(context)!.authDJMembreDe,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1.1,
                        ),
                      ),
                    ),

                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ],
          ),
        ),
        ],
      ),
    );
  }
}

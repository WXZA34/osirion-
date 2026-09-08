import '../../l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/providers/locale_provider.dart';
import 'login_screen.dart';
import 'register_screen.dart';

class WelcomeScreen extends ConsumerWidget {
  const WelcomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
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

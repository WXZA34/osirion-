import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/providers/locale_provider.dart';
import '../../../l10n/app_localizations.dart';
import 'onboarding_carousel_screen.dart';

class LanguageSelectionScreen extends ConsumerWidget {
  const LanguageSelectionScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // Background Image (Glassmorphism effect)
          Positioned.fill(
            child: Image.asset(
              'assets/branding/background.jpeg',
              fit: BoxFit.cover,
            ),
          ),
          Positioned.fill(
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
              child: Container(
                color: Colors.black.withOpacity(0.5),
              ),
            ),
          ),
          
          SafeArea(
            child: Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.language,
                      color: Colors.white,
                      size: 64,
                    ),
                    const SizedBox(height: 24),
                    const Text(
                      "Choisis ta langue\nChoose your language",
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 2,
                      ),
                    ),
                    const SizedBox(height: 48),
                    
                    _buildLanguageButton(
                      context: context,
                      ref: ref,
                      languageName: "Français",
                      localeCode: 'fr',
                    ),
                    const SizedBox(height: 16),
                    _buildLanguageButton(
                      context: context,
                      ref: ref,
                      languageName: "English",
                      localeCode: 'en',
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLanguageButton({
    required BuildContext context,
    required WidgetRef ref,
    required String languageName,
    required String localeCode,
  }) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: () async {
          await ref.read(localeProvider.notifier).setLocale(Locale(localeCode));
          if (context.mounted) {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => const OnboardingCarouselScreen()),
            );
          }
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.white.withOpacity(0.1),
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(color: Colors.white.withOpacity(0.3), width: 1),
          ),
        ),
        child: Text(
          languageName,
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }
}

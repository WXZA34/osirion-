import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import '../../main.dart';

class AnimatedSplashScreen extends StatefulWidget {
  const AnimatedSplashScreen({super.key});

  @override
  State<AnimatedSplashScreen> createState() => _AnimatedSplashScreenState();
}

class _AnimatedSplashScreenState extends State<AnimatedSplashScreen> {
  @override
  void initState() {
    super.initState();
    _navigateToNextScreen();
  }

  void _navigateToNextScreen() async {
    // Le Lottie va jouer et au bout de 4 secondes on passe à l'écran suivant
    await Future.delayed(const Duration(seconds: 4));
    if (mounted) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const AuthWrapper()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Center(
        child: SizedBox(
          width: 300,
          height: 300,
          child: Lottie.asset(
            'assets/branding/osirion-logo-animation12.json',
            fit: BoxFit.contain,
            errorBuilder: (context, error, stackTrace) {
              debugPrint('Lottie error: $error');
              // Fallback en cas d'erreur de parsing du JSON
              return Image.asset(
                'assets/branding/logo12.jpeg',
                width: 150,
                height: 150,
              );
            },
          ),
        ),
      ),
    );
  }
}

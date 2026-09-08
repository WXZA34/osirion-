import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../l10n/app_localizations.dart';
import '../welcome_screen.dart';

class OnboardingCarouselScreen extends StatefulWidget {
  const OnboardingCarouselScreen({super.key});

  @override
  State<OnboardingCarouselScreen> createState() => _OnboardingCarouselScreenState();
}

class _OnboardingCarouselScreenState extends State<OnboardingCarouselScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  final List<String> _backgrounds = [
    "assets/images/covers/forge_ton_corps.jpg",
    "assets/images/covers/heritage.jpg",
    "assets/images/covers/aether.jpg",
    "assets/images/covers/pantheon.jpg",
  ];

  Future<void> _completeOnboarding() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('onboarding_completed', true);

    if (mounted) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const WelcomeScreen()),
      );
    }
  }

  void _nextPage() {
    if (_currentPage < 3) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    } else {
      _completeOnboarding();
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    final List<Map<String, String>> _slides = [
      {
        "title": l10n.carouselTitle1,
        "desc": l10n.carouselDesc1,
      },
      {
        "title": l10n.carouselTitle2,
        "desc": l10n.carouselDesc2,
      },
      {
        "title": l10n.carouselTitle3,
        "desc": l10n.carouselDesc3,
      },
      {
        "title": l10n.carouselTitle4,
        "desc": l10n.carouselDesc4,
      },
    ];

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // Dynamic Background
          Positioned.fill(
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 500),
              child: Image.asset(
                _backgrounds[_currentPage],
                key: ValueKey<int>(_currentPage),
                fit: BoxFit.cover,
                width: double.infinity,
                height: double.infinity,
              ),
            ),
          ),
          
          // Dark Overlay for readability
          Positioned.fill(
            child: Container(
              color: Colors.black.withOpacity(0.5),
            ),
          ),
          
          SafeArea(
            child: Column(
              children: [
                Expanded(
                  child: PageView.builder(
                    controller: _pageController,
                    onPageChanged: (int page) {
                      setState(() {
                        _currentPage = page;
                      });
                    },
                    itemCount: _slides.length,
                    itemBuilder: (context, index) {
                      return Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 32.0),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Spacer(flex: 2),
                            Text(
                              _slides[index]["title"]!,
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 32,
                                fontWeight: FontWeight.w900,
                                letterSpacing: 2,
                              ),
                            ),
                            const SizedBox(height: 24),
                            Text(
                              _slides[index]["desc"]!,
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                color: Colors.white70,
                                fontSize: 18,
                                height: 1.5,
                              ),
                            ),
                            const Spacer(flex: 3),
                          ],
                        ),
                      );
                    },
                  ),
                ),
                
                // Indicators and Buttons
                Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Dots
                      Row(
                        children: List.generate(
                          _slides.length,
                          (index) => AnimatedContainer(
                            duration: const Duration(milliseconds: 300),
                            margin: const EdgeInsets.only(right: 8),
                            height: 8,
                            width: _currentPage == index ? 24 : 8,
                            decoration: BoxDecoration(
                              color: _currentPage == index ? Colors.white : Colors.white38,
                              borderRadius: BorderRadius.circular(4),
                            ),
                          ),
                        ),
                      ),
                      
                      // Next / Start button
                      ElevatedButton(
                        onPressed: _nextPage,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white,
                          foregroundColor: Colors.black,
                          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(24),
                          ),
                        ),
                        child: Text(
                          _currentPage == 3 ? l10n.carouselStart : l10n.carouselNext,
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                        ),
                      ),
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

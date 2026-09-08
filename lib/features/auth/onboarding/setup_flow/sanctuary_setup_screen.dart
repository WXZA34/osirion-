import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:valerion/core/domain/entities/user_entity.dart';
import 'package:valerion/core/providers/repository_providers.dart';
import 'package:valerion/core/navigation/main_navigation_shell.dart';

class SanctuarySetupScreen extends ConsumerStatefulWidget {
  const SanctuarySetupScreen({super.key});

  @override
  ConsumerState<SanctuarySetupScreen> createState() => _SanctuarySetupScreenState();
}

class _SanctuarySetupScreenState extends ConsumerState<SanctuarySetupScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;
  bool _isLoading = false;

  // Selections
  String? _selectedPath;
  String? _selectedOath;
  
  final TextEditingController _weightController = TextEditingController();
  final TextEditingController _heightController = TextEditingController();

  final List<String> _backgrounds = [
    "assets/images/covers/la_voie_du_gardien.jpg",
    "assets/images/covers/les_fondations.jpg",
    "assets/images/covers/le_serment.jpg",
  ];

  void _nextPage() {
    if (_currentPage < 2) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeInOut,
      );
      setState(() {
        _currentPage++;
      });
    } else {
      _completeSetup();
    }
  }

  Future<void> _completeSetup() async {
    setState(() => _isLoading = true);
    try {
      final userStream = ref.read(userProfileProvider);
      final user = userStream.value;
      if (user != null) {
        final valerionRepo = ref.read(valerionRepositoryProvider);
        
        final updatedUser = user.copyWith(
          guardianPath: _selectedPath,
          ultimateOath: _selectedOath,
          weight: double.tryParse(_weightController.text),
          height: int.tryParse(_heightController.text),
        );
        
        await valerionRepo.saveUserProfile(updatedUser);
      }
      
      if (mounted) {
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (context) => const MainNavigationShell()),
          (route) => false,
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Erreur: ${e.toString()}")),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          // Background Images Transition
          Positioned.fill(
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 800),
              layoutBuilder: (currentChild, previousChildren) {
                return Stack(
                  fit: StackFit.expand,
                  children: <Widget>[
                    ...previousChildren,
                    if (currentChild != null) currentChild,
                  ],
                );
              },
              child: Image.asset(
                _backgrounds[_currentPage],
                fit: BoxFit.cover,
                key: ValueKey<int>(_currentPage),
              ),
            ),
          ),
          
          // Subtle Dark Overlay for text readability
          Positioned.fill(
            child: Container(
              color: Colors.black.withOpacity(0.25),
            ),
          ),
          
          SafeArea(
            child: PageView(
              controller: _pageController,
              physics: const NeverScrollableScrollPhysics(),
              children: [
                _buildPathStep(),
                _buildFoundationsStep(),
                _buildOathStep(),
              ],
            ),
          ),
          
          if (_isLoading)
            const Positioned.fill(
              child: Center(
                child: CircularProgressIndicator(color: Colors.yellowAccent),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildPathStep() {
    return _buildStepContainer(
      icon: Icons.balance,
      iconColor: Colors.cyanAccent,
      title: "LA VOIE DU GARDIEN",
      subtitle: "Quelle énergie guidera la fondation de ton Sanctuaire ?",
      content: Column(
        children: [
          _buildSelectableCard(
            title: "L'acier et le sang",
            subtitle: "Bonus Force",
            isSelected: _selectedPath == "force",
            onTap: () => setState(() => _selectedPath = "force"),
          ),
          const SizedBox(height: 16),
          _buildSelectableCard(
            title: "Le calme et l'esprit",
            subtitle: "Bonus Sagesse",
            isSelected: _selectedPath == "sagesse",
            onTap: () => setState(() => _selectedPath = "sagesse"),
          ),
          const SizedBox(height: 16),
          _buildSelectableCard(
            title: "L'équilibre parfait",
            subtitle: "Harmonie Initiale",
            isSelected: _selectedPath == "harmonie",
            onTap: () => setState(() => _selectedPath = "harmonie"),
          ),
          const SizedBox(height: 32),
          if (_selectedPath != null)
            _buildNextButton("CONFIRMER LA VOIE"),
        ],
      ),
    );
  }

  Widget _buildFoundationsStep() {
    return _buildStepContainer(
      icon: Icons.science,
      iconColor: Colors.orangeAccent,
      title: "LES FONDATIONS",
      subtitle: "Le Laboratoire Biométrique a besoin de tes données de base.",
      content: Column(
        children: [
          _buildTextField(
            controller: _weightController,
            label: "Poids initial (kg)",
            keyboardType: TextInputType.number,
          ),
          const SizedBox(height: 24),
          _buildTextField(
            controller: _heightController,
            label: "Taille (cm)",
            keyboardType: TextInputType.number,
          ),
          const SizedBox(height: 40),
          _buildNextButton("VALIDER LES DONNÉES", color: Colors.amber),
        ],
      ),
    );
  }

  Widget _buildOathStep() {
    return _buildStepContainer(
      icon: Icons.local_fire_department,
      iconColor: Colors.redAccent,
      title: "LE SERMENT",
      subtitle: "Quelle est la quête ultime de ton Sanctuaire ?",
      content: Column(
        children: [
          _buildSelectableCard(
            title: "Dépasser mes limites physiques",
            subtitle: "Objectif: Puissance",
            isSelected: _selectedOath == "puissance",
            onTap: () => setState(() => _selectedOath = "puissance"),
          ),
          const SizedBox(height: 16),
          _buildSelectableCard(
            title: "Forger un mental de fer",
            subtitle: "Objectif: Discipline",
            isSelected: _selectedOath == "discipline",
            onTap: () => setState(() => _selectedOath = "discipline"),
          ),
          const SizedBox(height: 16),
          _buildSelectableCard(
            title: "Devenir la meilleure version de moi-même",
            subtitle: "Objectif: Évolution Globale",
            isSelected: _selectedOath == "evolution",
            onTap: () => setState(() => _selectedOath = "evolution"),
          ),
          const SizedBox(height: 32),
          if (_selectedOath != null)
            _buildNextButton("PRÊTER SERMENT"),
        ],
      ),
    );
  }

  Widget _buildStepContainer({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
    required Widget content,
  }) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
      child: Column(
        children: [
          Icon(icon, size: 80, color: iconColor),
          const SizedBox(height: 24),
          Text(
            title,
            style: const TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.w900,
              color: Colors.white,
              letterSpacing: 2,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          Text(
            subtitle,
            style: const TextStyle(
              fontSize: 16,
              color: Colors.white70,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 48),
          content,
        ],
      ),
    );
  }

  Widget _buildSelectableCard({
    required String title,
    required String subtitle,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: isSelected 
                  ? [
                      Colors.white.withValues(alpha: 0.25),
                      Colors.white.withValues(alpha: 0.1),
                    ]
                  : [
                      Colors.white.withValues(alpha: 0.1),
                      Colors.white.withValues(alpha: 0.02),
                    ],
              ),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: isSelected ? Colors.yellowAccent : Colors.white.withOpacity(0.2),
                width: isSelected ? 2 : 1,
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        subtitle,
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.6),
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required TextInputType keyboardType,
  }) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: TextField(
          controller: controller,
          keyboardType: keyboardType,
          style: const TextStyle(color: Colors.white),
          decoration: InputDecoration(
            labelText: label,
            labelStyle: TextStyle(color: Colors.white.withOpacity(0.6)),
            filled: true,
            fillColor: Colors.white.withValues(alpha: 0.1),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.white.withOpacity(0.2)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Colors.yellowAccent),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNextButton(String text, {Color color = Colors.white}) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          foregroundColor: Colors.black,
          padding: const EdgeInsets.symmetric(vertical: 18),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          elevation: 0,
        ),
        onPressed: _nextPage,
        child: Text(
          text,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            letterSpacing: 1,
          ),
        ),
      ),
    );
  }
}

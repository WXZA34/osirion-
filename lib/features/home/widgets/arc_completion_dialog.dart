import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/arc_data.dart';
import '../../../core/providers/repository_providers.dart';
import '../../../core/domain/entities/user_entity.dart';
import 'package:confetti/confetti.dart';

class ArcCompletionDialog extends ConsumerStatefulWidget {
  final ArcData arc;
  final UserEntity user;

  const ArcCompletionDialog({super.key, required this.arc, required this.user});

  @override
  ConsumerState<ArcCompletionDialog> createState() => _ArcCompletionDialogState();
}

class _ArcCompletionDialogState extends ConsumerState<ArcCompletionDialog> {
  late ConfettiController _confettiController;
  Map<String, dynamic>? _rewards;
  bool _isLoading = true;
  bool _isClaimed = false;

  @override
  void initState() {
    super.initState();
    _confettiController = ConfettiController(duration: const Duration(seconds: 5));
    _loadRewards();
  }

  Future<void> _loadRewards() async {
    final repo = ref.read(valerionRepositoryProvider);
    final results = await repo.calculateArcRewards(widget.user.id, widget.arc);
    if (mounted) {
      setState(() {
        _rewards = results;
        _isLoading = false;
      });
      _confettiController.play();
    }
  }

  Future<void> _claimRewards() async {
    if (_rewards == null || _isClaimed) return;
    setState(() => _isClaimed = true);

    try {
      final repo = ref.read(valerionRepositoryProvider);
      await repo.claimArcRewards(widget.user.id, widget.arc.arcType.name, _rewards!);
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Récompenses ajoutées à ton profil ! 🏆")),
        );
      }
    } catch (e) {
      setState(() => _isClaimed = false);
    }
  }

  @override
  void dispose() {
    _confettiController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final accent = widget.arc.primaryColor;

    return Dialog(
      backgroundColor: const Color(0xFF020617),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(30),
        side: Border.all(color: accent.withValues(alpha: 0.3)).top, // Correction: RoundedRectangleBorder uses 'side' not 'border'
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          ConfettiWidget(
            confettiController: _confettiController,
            blastDirectionality: BlastDirectionality.explosive,
            colors: [accent, Colors.white, Colors.amber],
          ),
          Padding(
            padding: const EdgeInsets.all(30.0),
            child: _isLoading 
              ? const SizedBox(height: 200, child: Center(child: CircularProgressIndicator()))
              : Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.emoji_events, color: Colors.amber, size: 64),
                    const SizedBox(height: 20),
                    Text(
                      "ARC TERMINÉ",
                      style: TextStyle(
                        color: accent,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 4,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      widget.arc.title,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 24),
                    _buildStatRow("Assiduité", "${((_rewards!['ratio'] as double) * 100).round()}%"),
                    const Divider(color: Colors.white10),
                    _buildStatRow("Aether gagné", "+${_rewards!['aether']} 💎"),
                    _buildStatRow("Expérience", "+${_rewards!['xp']} XP"),
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: accent.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: accent.withValues(alpha: 0.2)),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.military_tech, color: Colors.amber, size: 20),
                          const SizedBox(width: 8),
                          Text(
                            "TITRE : ${_rewards!['title']}",
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 30),
                    ElevatedButton(
                      onPressed: _isClaimed ? null : _claimRewards,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: accent,
                        foregroundColor: Colors.black,
                        minimumSize: const Size(double.infinity, 50),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                      ),
                      child: _isClaimed 
                        ? const CircularProgressIndicator(color: Colors.black)
                        : const Text("RÉCLAMER ET ENTRER DANS LA LUMIÈRE", style: TextStyle(fontWeight: FontWeight.bold)),
                    ),
                  ],
                ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: Colors.white54, fontSize: 13)),
          Text(value, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
        ],
      ),
    );
  }
}

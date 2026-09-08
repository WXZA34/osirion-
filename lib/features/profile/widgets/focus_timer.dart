import 'package:valerion/l10n/app_localizations.dart';
import '../../../l10n/app_localizations.dart';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/providers/repository_providers.dart';

class FocusTimer extends ConsumerStatefulWidget {
  const FocusTimer({super.key});

  @override
  ConsumerState<FocusTimer> createState() => _FocusTimerState();
}

class _FocusTimerState extends ConsumerState<FocusTimer> {
  static const int _focusDurationSeconds = 15 * 60; // 15 minutes
  int _secondsRemaining = _focusDurationSeconds;
  Timer? _timer;
  bool _isRunning = false;

  final List<String> _quotes = [
    "« La maîtrise de soi est le véritable pouvoir. »",
    "« Ce n'est pas parce que les choses sont difficiles que nous n'osons pas, c'est parce que nous n'osons pas qu'elles sont difficiles. » - Sénèque",
    "« L'homme qui déplace une montagne commence par les petites pierres. » - Confucius",
    "« Le bonheur dépend de l'attitude, pas de ce qui se passe à l'extérieur. »",
    "« La paix vient de l'intérieur. Ne la cherchez pas à l'extérieur. » - Bouddha",
  ];
  String _currentQuote = "";

  @override
  void initState() {
    super.initState();
    _currentQuote = _quotes[0];
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _startTimer() {
    setState(() {
      _isRunning = true;
      _currentQuote = _quotes[DateTime.now().second % _quotes.length];
    });

    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_secondsRemaining > 0) {
        setState(() {
          _secondsRemaining--;
        });
      } else {
        _stopTimer(completed: true);
      }
    });
  }

  void _pauseTimer() {
    _timer?.cancel();
    setState(() {
      _isRunning = false;
    });
  }

  void _resetTimer() {
    _timer?.cancel();
    setState(() {
      _isRunning = false;
      _secondsRemaining = _focusDurationSeconds;
    });
  }

  Future<void> _stopTimer({required bool completed}) async {
    _timer?.cancel();
    setState(() {
      _isRunning = false;
      _secondsRemaining = _focusDurationSeconds;
    });

    if (completed) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppLocalizations.of(context)!.profileMDitationAchevE),
          backgroundColor: Colors.purpleAccent,
        ),
      );

      final user = ref.read(userProfileProvider).valueOrNull;
      if (user != null) {
        final repo = ref.read(valerionRepositoryProvider);
        // Ajout de 30 XP de sagesse (Sécurisé via serveur)
        await repo.addManualReward(user.id, 'focus');
      }
    }
  }

  String _formatTime(int seconds) {
    int minutes = seconds ~/ 60;
    int remainingSeconds = seconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${remainingSeconds.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    double progress = 1.0 - (_secondsRemaining / _focusDurationSeconds);

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: const Color(0xFF0A0A0A),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.purpleAccent.withValues(alpha: 0.3)),
        boxShadow: [
          if (_isRunning)
            BoxShadow(
              color: Colors.purpleAccent.withValues(alpha: 0.1),
              blurRadius: 20,
              spreadRadius: 2,
            ),
        ],
      ),
      child: Column(
        children: [
          Text(AppLocalizations.of(context)!.profileMDitationDeepWork,
            style: TextStyle(
              color: Colors.white54,
              letterSpacing: 2,
              fontSize: 10,
            ),
          ),
          const SizedBox(height: 24),
          Stack(
            alignment: Alignment.center,
            children: [
              SizedBox(
                width: 150,
                height: 150,
                child: CircularProgressIndicator(
                  value: progress,
                  strokeWidth: 8,
                  backgroundColor: Colors.white10,
                  color: Colors.purpleAccent,
                  strokeCap: StrokeCap.round,
                ),
              ),
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    _formatTime(_secondsRemaining),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 36,
                      fontWeight: FontWeight.w300,
                      fontFeatures: [FontFeature.tabularFigures()],
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 32),
          Text(
            _currentQuote,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Colors.white70,
              fontStyle: FontStyle.italic,
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 32),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (!_isRunning)
                ElevatedButton.icon(
                  onPressed: _startTimer,
                  icon: const Icon(Icons.play_arrow, color: Colors.black),
                  label: Text(
                    _secondsRemaining < _focusDurationSeconds
                        ? "REPRENDRE"
                        : "COMMENCER",
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.purpleAccent,
                    foregroundColor: Colors.black,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 12,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                  ),
                )
              else
                ElevatedButton.icon(
                  onPressed: _pauseTimer,
                  icon: const Icon(Icons.pause, color: Colors.black),
                  label: Text(AppLocalizations.of(context)!.commonSuspend),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white70,
                    foregroundColor: Colors.black,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 12,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                  ),
                ),
              if (_secondsRemaining < _focusDurationSeconds && !_isRunning) ...[
                const SizedBox(width: 16),
                IconButton(
                  onPressed: _resetTimer,
                  icon: const Icon(Icons.stop),
                  color: Colors.white54,
                  tooltip: AppLocalizations.of(context)!.profileRInitialiser,
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}

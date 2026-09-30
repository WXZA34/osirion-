import 'package:flutter/material.dart';
import '../widgets/camera_workout_view.dart';
import '../widgets/exercise_selection_sheet.dart';
import '../widgets/strict_ai_score_indicator.dart';
import '../widgets/tug_of_war_bar.dart';
import '../widgets/world_boss_card.dart';
import 'league_ladder_screen.dart'; // for LeagueRank

enum GameMode { duel, league, raid }

extension GameModeExtension on GameMode {
  String get title {
    switch (this) {
      case GameMode.duel:
        return "Duel";
      case GameMode.league:
        return "Ligue";
      case GameMode.raid:
        return "Raid";
    }
  }

  Color get accentColor {
    switch (this) {
      case GameMode.duel:
        return Colors.deepOrangeAccent;
      case GameMode.league:
        return Colors.cyanAccent;
      case GameMode.raid:
        return Colors.redAccent;
    }
  }
}

class BattleSummary {
  final GameMode mode;
  final ExerciseType exercise;
  final bool isVictory;
  final double playerReps;
  final double opponentReps; // or boss damage
  final int xpEarned;
  final int goldEarned;
  final int mmrDelta;
  final int crystalsEarned;
  final String? newRelicUnlocked;

  const BattleSummary({
    required this.mode,
    required this.exercise,
    required this.isVictory,
    required this.playerReps,
    required this.opponentReps,
    required this.xpEarned,
    required this.goldEarned,
    required this.mmrDelta,
    required this.crystalsEarned,
    this.newRelicUnlocked,
  });
}

class ArenaUiState {
  final bool isSearchingMatch;
  final bool isFinished;
  final GameMode? activeMode;
  final ExerciseType? activeExercise;
  final BattleSummary? summary;
  
  // Duel/League states
  final String opponentName;
  final int opponentLevel;
  final double playerScore;
  final double opponentScore;
  final double tugPosition;
  final double handicapMultiplier;
  final int playerRepsFull;
  final int playerRepsHalf;
  final int timeRemainingSeconds;

  // Raid states
  final int worldBossHp;
  final int worldBossMaxHp;
  final int playerRaidDamage;
  final String communityTicker;

  // Camera states
  final double currentRepProgress;
  final String lastFormQuality;

  const ArenaUiState({
    this.isSearchingMatch = false,
    this.isFinished = false,
    this.activeMode,
    this.activeExercise,
    this.summary,
    this.opponentName = "Unknown",
    this.opponentLevel = 1,
    this.playerScore = 0.0,
    this.opponentScore = 0.0,
    this.tugPosition = 0.5,
    this.handicapMultiplier = 1.0,
    this.playerRepsFull = 0,
    this.playerRepsHalf = 0,
    this.timeRemainingSeconds = 60,
    this.worldBossHp = 1000000,
    this.worldBossMaxHp = 1000000,
    this.playerRaidDamage = 0,
    this.communityTicker = "",
    this.currentRepProgress = 0.0,
    this.lastFormQuality = "",
  });
}

class WorkoutArenaScreen extends StatelessWidget {
  final ArenaUiState state;
  final String username;
  final int userLevel;
  final int userMmr;
  final Function(bool) onTriggerRep;
  final VoidCallback onFinishWorkout;
  final VoidCallback onExitArena;
  final bool hasCameraPermission;
  final VoidCallback onRequestPermission;
  final Widget cameraStreamWidget;
  final Function(GameMode)? onModeChanged;

  const WorkoutArenaScreen({
    Key? key,
    required this.state,
    required this.username,
    required this.userLevel,
    required this.userMmr,
    required this.onTriggerRep,
    required this.onFinishWorkout,
    required this.onExitArena,
    required this.hasCameraPermission,
    required this.onRequestPermission,
    required this.cameraStreamWidget,
    this.onModeChanged,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final mode = state.activeMode ?? GameMode.duel;
    final exercise = state.activeExercise ?? ExerciseType.allExercises.first;

    if (state.isSearchingMatch) {
      return Scaffold(
        backgroundColor: const Color(0xFF0B0C10),
        body: _MatchmakingSearchingView(
          mode: mode,
          exercise: exercise,
          onCancel: onExitArena,
        ),
      );
    }

    if (state.isFinished && state.summary != null) {
      return Scaffold(
        backgroundColor: const Color(0xFF0B0C10),
        body: _BattleFinishedSummaryView(
          summary: state.summary!,
          onReturn: onExitArena,
        ),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFF0B0C10),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              // Top Bar
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  IconButton(
                    onPressed: onExitArena,
                    icon: const Icon(Icons.close, color: Colors.white),
                    style: IconButton.styleFrom(
                      backgroundColor: const Color(0xFF2C2F33),
                      shape: const CircleBorder(side: BorderSide(color: Color(0xFF15171C))),
                    ),
                  ),
                  Column(
                    children: [
                      Text(
                        mode.title.toUpperCase(),
                        style: TextStyle(
                          color: mode.accentColor,
                          fontSize: 16,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 1.0,
                        ),
                      ),
                      Text(
                        "${exercise.iconEmoji} ${exercise.title}",
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                  ElevatedButton(
                    onPressed: onFinishWorkout,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF2C2F33),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      side: const BorderSide(color: Color(0xFF15171C)),
                    ),
                    child: const Text("Terminer", style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
              const SizedBox(height: 10),

              // Mode Selection Bar (3 modules)
              if (onModeChanged != null) ...[
                Container(
                  margin: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: const Color(0xFF15171C),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.white10),
                  ),
                  child: Row(
                    children: [
                      Expanded(child: _buildModeTab(GameMode.duel, mode, context)),
                      Expanded(child: _buildModeTab(GameMode.league, mode, context)),
                      Expanded(child: _buildModeTab(GameMode.raid, mode, context)),
                    ],
                  ),
                ),
                const SizedBox(height: 10),
              ],

              // Mode Specific HUD Banner
              if (mode == GameMode.duel)
                TugOfWarBar(
                  playerName: username,
                  playerLevel: userLevel,
                  playerReps: state.playerScore,
                  opponentName: state.opponentName,
                  opponentLevel: state.opponentLevel,
                  opponentReps: state.opponentScore,
                  tugPosition: state.tugPosition,
                  handicapMultiplier: state.handicapMultiplier,
                )
              else if (mode == GameMode.league)
                StrictAiScoreIndicator(
                  playerFullReps: state.playerRepsFull,
                  playerHalfReps: state.playerRepsHalf,
                  playerScore: state.playerScore,
                  opponentName: state.opponentName,
                  opponentScore: state.opponentScore,
                  timeRemainingSeconds: state.timeRemainingSeconds,
                  currentLeague: LeagueRank.fromMmr(userMmr),
                )
              else if (mode == GameMode.raid)
                WorldBossCard(
                  currentHp: state.worldBossHp,
                  maxHp: state.worldBossMaxHp,
                  playerContributionDamage: state.playerRaidDamage,
                  liveCommunityFeed: state.communityTicker,
                ),

              const SizedBox(height: 10),

              // Camera HUD
              Expanded(
                child: CameraWorkoutView(
                  exercise: exercise,
                  currentRepProgress: state.currentRepProgress,
                  lastFormQuality: state.lastFormQuality,
                  hasCameraPermission: hasCameraPermission,
                  onManualRepTrigger: () => onTriggerRep(false),
                  onRequestPermission: onRequestPermission,
                  cameraStreamWidget: cameraStreamWidget,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildModeTab(GameMode tabMode, GameMode currentMode, BuildContext context) {
    final isSelected = tabMode == currentMode;
    return GestureDetector(
      onTap: () {
        if (!isSelected && onModeChanged != null) {
          onModeChanged!(tabMode);
        }
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? tabMode.accentColor.withValues(alpha: 0.15) : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected ? tabMode.accentColor.withValues(alpha: 0.5) : Colors.transparent,
          ),
        ),
        child: Center(
          child: Text(
            tabMode.title.toUpperCase(),
            style: TextStyle(
              color: isSelected ? tabMode.accentColor : Colors.white54,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
              fontSize: 13,
              letterSpacing: 0.5,
            ),
          ),
        ),
      ),
    );
  }
}

class _MatchmakingSearchingView extends StatefulWidget {
  final GameMode mode;
  final ExerciseType exercise;
  final VoidCallback onCancel;

  const _MatchmakingSearchingView({
    required this.mode,
    required this.exercise,
    required this.onCancel,
  });

  @override
  State<_MatchmakingSearchingView> createState() => _MatchmakingSearchingViewState();
}

class _MatchmakingSearchingViewState extends State<_MatchmakingSearchingView> with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;
  late Animation<double> _pulseSize;
  late Animation<double> _pulseAlpha;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1600),
    )..repeat();

    _pulseSize = Tween<double>(begin: 0.5, end: 1.3).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
    _pulseAlpha = Tween<double>(begin: 0.8, end: 0.0).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SizedBox(
              width: 160,
              height: 160,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  AnimatedBuilder(
                    animation: _pulseController,
                    builder: (context, child) {
                      return Container(
                        width: 140 * _pulseSize.value,
                        height: 140 * _pulseSize.value,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: widget.mode.accentColor.withOpacity(_pulseAlpha.value),
                            width: 2,
                          ),
                        ),
                      );
                    },
                  ),
                  Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      color: widget.mode.accentColor.withOpacity(0.2),
                      shape: BoxShape.circle,
                      border: Border.all(color: widget.mode.accentColor, width: 2),
                    ),
                    alignment: Alignment.center,
                    child: Icon(Icons.radar, color: widget.mode.accentColor, size: 42),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),
            const Text(
              "RECHERCHE D'ADVERSAIRE",
              style: TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.w900,
                letterSpacing: 2.0,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              widget.mode == GameMode.duel
                  ? "Balayage des guerriers en direct ou connexion au Fantôme d'un joueur..."
                  : widget.mode == GameMode.league
                      ? "Matchmaking strict dans votre division de Ligue..."
                      : "Connexion à l'instance mondiale du Golem de Fer...",
              style: const TextStyle(
                color: Colors.white70,
                fontSize: 14,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
              decoration: BoxDecoration(
                color: const Color(0xFF2C2F33),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: const Color(0xFF15171C)),
              ),
              child: Text(
                "Discipline : ${widget.exercise.iconEmoji} ${widget.exercise.title}",
                style: const TextStyle(
                  color: Colors.amberAccent,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
            ),
            const SizedBox(height: 48),
            OutlinedButton(
              onPressed: widget.onCancel,
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.white70,
                side: const BorderSide(color: Colors.white30),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: const Text("Annuler la recherche"),
            ),
          ],
        ),
      ),
    );
  }
}

class _BattleFinishedSummaryView extends StatelessWidget {
  final BattleSummary summary;
  final VoidCallback onReturn;

  const _BattleFinishedSummaryView({
    required this.summary,
    required this.onReturn,
  });

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Container(
          width: double.infinity,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: summary.mode.accentColor.withOpacity(0.55), width: 1.5),
            gradient: const LinearGradient(
              colors: [Color(0xFF2C2F33), Color(0xFF15171C), Color(0xFF0B0C10)],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
          ),
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                children: [
                  const SizedBox(height: 8),
                  // Outcome icon
                  Container(
                    width: 76,
                    height: 76,
                    decoration: BoxDecoration(
                      color: summary.isVictory ? Colors.amber.withOpacity(0.15) : const Color(0xFF2C2F33),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: summary.isVictory ? Colors.amber : const Color(0xFF15171C),
                        width: 1.5,
                      ),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      summary.mode == GameMode.raid ? "👹💥" : summary.isVictory ? "🏆" : "⚔️",
                      style: const TextStyle(fontSize: 34),
                    ),
                  ),
                  const SizedBox(height: 14),
                  Text(
                    summary.mode == GameMode.raid 
                        ? "ASSAUT TERMINÉ !" 
                        : summary.isVictory 
                            ? "VICTOIRE ÉCLATANTE !" 
                            : "COMBAT TERMINÉ",
                    style: TextStyle(
                      color: summary.isVictory ? Colors.amberAccent : Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  Text(
                    "${summary.mode.title} • ${summary.exercise.title}",
                    style: TextStyle(
                      color: summary.mode.accentColor,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Recap
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: const Color(0xFF15171C),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: const Color(0xFF2C2F33)),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        Column(
                          children: [
                            const Text("VOS RÉPÉTITIONS", style: TextStyle(color: Colors.white70, fontSize: 10)),
                            Text(
                              summary.playerReps.toStringAsFixed(1),
                              style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w900),
                            ),
                          ],
                        ),
                        Container(width: 1, height: 36, color: const Color(0xFF2C2F33)),
                        Column(
                          children: [
                            Text(
                              summary.mode == GameMode.raid ? "DÉGÂTS BOSS" : "ADVERSAIRE",
                              style: const TextStyle(color: Colors.white70, fontSize: 10),
                            ),
                            Text(
                              summary.mode == GameMode.raid 
                                  ? "${summary.playerReps.toInt()} PV"
                                  : summary.opponentReps.toStringAsFixed(1),
                              style: TextStyle(color: summary.mode.accentColor, fontSize: 22, fontWeight: FontWeight.w900),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    "BUTIN & RÉCOMPENSES",
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 10,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 1.0,
                    ),
                  ),
                  const SizedBox(height: 8),

                  Row(
                    children: [
                      Expanded(child: _RewardBadge(label: "+${summary.xpEarned} XP", sub: "Niveau Joueur", color: Colors.amberAccent)),
                      const SizedBox(width: 8),
                      Expanded(child: _RewardBadge(label: "+${summary.goldEarned} Or", sub: "Pièces", color: Colors.amber)),
                      const SizedBox(width: 8),
                      if (summary.mode == GameMode.league)
                        Expanded(child: _RewardBadge(label: "${summary.mmrDelta >= 0 ? "+" : ""}${summary.mmrDelta} MMR", sub: "Ladder", color: Colors.cyanAccent))
                      else if (summary.crystalsEarned > 0)
                        Expanded(child: _RewardBadge(label: "+${summary.crystalsEarned} 💎", sub: "Cristaux", color: Colors.purpleAccent)),
                    ],
                  ),

                  if (summary.newRelicUnlocked != null) ...[
                    const SizedBox(height: 14),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFF15171C),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: Colors.amber.withOpacity(0.5), width: 1.2),
                      ),
                      child: Row(
                        children: [
                          const Text("✨", style: TextStyle(fontSize: 24)),
                          const SizedBox(width: 10),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                "NOUVELLE RELIQUE ÉPIQUE !",
                                style: TextStyle(color: Colors.amberAccent, fontSize: 10, fontWeight: FontWeight.w900),
                              ),
                              Text(
                                summary.newRelicUnlocked!,
                                style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
              
              // Return Button
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: onReturn,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: summary.mode.accentColor,
                    foregroundColor: const Color(0xFF141518),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                  child: const Text(
                    "RETOUR AU PANTHÉON",
                    style: TextStyle(fontWeight: FontWeight.w900, letterSpacing: 0.8),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _RewardBadge extends StatelessWidget {
  final String label;
  final String sub;
  final Color color;

  const _RewardBadge({
    required this.label,
    required this.sub,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
      decoration: BoxDecoration(
        color: const Color(0xFF15171C),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.45)),
      ),
      child: Column(
        children: [
          Text(label, style: TextStyle(color: color, fontSize: 14, fontWeight: FontWeight.w900)),
          Text(sub, style: const TextStyle(color: Colors.white70, fontSize: 10)),
        ],
      ),
    );
  }
}

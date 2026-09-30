import 'package:flutter/material.dart';

class MatchHistoryEntity {
  final String id;
  final String mode; // DUEL, LEAGUE, RAID
  final String outcome; // VICTOIRE, DÉFAITE, DÉGÂTS INFLIGÉS
  final String exercise;
  final String opponentName;
  final double playerReps;
  final double opponentReps;
  final int xpGained;
  final int mmrDelta;

  const MatchHistoryEntity({
    required this.id,
    required this.mode,
    required this.outcome,
    required this.exercise,
    required this.opponentName,
    required this.playerReps,
    required this.opponentReps,
    required this.xpGained,
    required this.mmrDelta,
  });
}

class MatchHistoryScreen extends StatelessWidget {
  const MatchHistoryScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Mocked data for demonstration
    final List<MatchHistoryEntity> matches = [
      const MatchHistoryEntity(
        id: "1",
        mode: "LEAGUE",
        outcome: "VICTOIRE",
        exercise: "Pompes",
        opponentName: "IronClad_44",
        playerReps: 45.0,
        opponentReps: 42.5,
        xpGained: 150,
        mmrDelta: 24,
      ),
      const MatchHistoryEntity(
        id: "2",
        mode: "DUEL",
        outcome: "DÉFAITE",
        exercise: "Squats",
        opponentName: "Valkyrie_99",
        playerReps: 60.0,
        opponentReps: 65.0,
        xpGained: 50,
        mmrDelta: 0, // Duel has no MMR
      ),
      const MatchHistoryEntity(
        id: "3",
        mode: "RAID",
        outcome: "DÉGÂTS INFLIGÉS",
        exercise: "Pompes",
        opponentName: "Golem de Fer",
        playerReps: 120.0,
        opponentReps: 0.0,
        xpGained: 300,
        mmrDelta: 0,
      ),
    ];

    return Scaffold(
      backgroundColor: const Color(0xFF0B0C10),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text(
          "Historique",
          style: TextStyle(fontWeight: FontWeight.w900),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        physics: const BouncingScrollPhysics(),
        children: [
          // Header
          const Text(
            "JOURNAL DE GUERRE",
            style: TextStyle(
              color: Colors.amberAccent,
              fontSize: 24,
              fontWeight: FontWeight.w900,
              letterSpacing: 1.5,
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            "Historique de vos Duels, combats de Ligue et frappes de Raid.",
            style: TextStyle(color: Colors.white70, fontSize: 14),
          ),
          const SizedBox(height: 24),

          if (matches.isEmpty)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(32),
              decoration: BoxDecoration(
                color: const Color(0xFF15171C),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.white10),
              ),
              child: Column(
                children: const [
                  Text("⚔️", style: TextStyle(fontSize: 32)),
                  SizedBox(height: 8),
                  Text(
                    "Aucun combat récent",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    "Lancez un Duel ou un Raid dans l'onglet Domination !",
                    style: TextStyle(color: Colors.white70, fontSize: 12),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            )
          else
            ...matches.map((match) {
              Color modeColor;
              String modeIcon;
              switch (match.mode) {
                case "DUEL":
                  modeColor = Colors.deepOrangeAccent;
                  modeIcon = "⚔️";
                  break;
                case "LEAGUE":
                  modeColor = Colors.cyanAccent;
                  modeIcon = "🥇";
                  break;
                case "RAID":
                  modeColor = Colors.redAccent;
                  modeIcon = "👹";
                  break;
                default:
                  modeColor = Colors.amber;
                  modeIcon = "🏆";
              }

              final bool isSuccess = match.outcome == "VICTOIRE" || match.outcome.contains("DÉGÂTS");

              return Container(
                margin: const EdgeInsets.only(bottom: 14),
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: const Color(0xFF15171C),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: Colors.white10),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 42,
                      height: 42,
                      decoration: BoxDecoration(
                        color: modeColor.withOpacity(0.15),
                        shape: BoxShape.circle,
                      ),
                      alignment: Alignment.center,
                      child: Text(modeIcon, style: const TextStyle(fontSize: 18)),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text(
                                match.outcome,
                                style: TextStyle(
                                  color: isSuccess ? Colors.greenAccent : Colors.redAccent,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                              const SizedBox(width: 6),
                              Text(
                                "• ${match.exercise}",
                                style: const TextStyle(
                                  color: Colors.white70,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                          Text(
                            "vs ${match.opponentName}",
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          Text(
                            "Score : ${match.playerReps.toStringAsFixed(1)} réps vs ${match.opponentReps.toStringAsFixed(1)} réps",
                            style: const TextStyle(
                              color: Colors.white54,
                              fontSize: 11,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          "+${match.xpGained} XP",
                          style: const TextStyle(
                            color: Colors.amberAccent,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        if (match.mmrDelta != 0)
                          Text(
                            "${match.mmrDelta > 0 ? "+" : ""}${match.mmrDelta} MMR",
                            style: const TextStyle(
                              color: Colors.cyanAccent,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
              );
            }).toList(),
            
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}

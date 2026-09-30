import 'package:flutter/material.dart';
import '../screens/league_ladder_screen.dart'; // To get LeagueRank

class StrictAiScoreIndicator extends StatelessWidget {
  final int playerFullReps;
  final int playerHalfReps;
  final double playerScore;
  final String opponentName;
  final double opponentScore;
  final int timeRemainingSeconds;
  final LeagueRank currentLeague;

  const StrictAiScoreIndicator({
    Key? key,
    required this.playerFullReps,
    required this.playerHalfReps,
    required this.playerScore,
    required this.opponentName,
    required this.opponentScore,
    required this.timeRemainingSeconds,
    required this.currentLeague,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: const Color(0xFF15171C),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white10),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14.0),
        child: Column(
          children: [
            // Header: League badge and timer
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
                  decoration: BoxDecoration(
                    color: currentLeague.color.withOpacity(0.18),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: currentLeague.color.withOpacity(0.4)),
                  ),
                  child: Text(
                    "🥇 ${currentLeague.name.toUpperCase()}",
                    style: TextStyle(
                      color: currentLeague.color,
                      fontSize: 10,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 0.6,
                    ),
                  ),
                ),
                
                const Text(
                  "LADDER OFFICIEL",
                  style: TextStyle(
                    color: Colors.cyanAccent,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.6,
                  ),
                ),
                
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
                  decoration: BoxDecoration(
                    color: const Color(0xFF2C2F33),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.white12),
                  ),
                  child: Text(
                    "⏱️ ${timeRemainingSeconds}s",
                    style: TextStyle(
                      color: timeRemainingSeconds <= 10 ? Colors.redAccent : Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 12),
            
            // Score Battle Board
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                // Player Side
                Column(
                  children: [
                    const Text(
                      "VOTRE SCORE",
                      style: TextStyle(color: Colors.white70, fontSize: 10, fontWeight: FontWeight.bold),
                    ),
                    Text(
                      playerScore.toStringAsFixed(1),
                      style: const TextStyle(
                        color: Colors.cyanAccent,
                        fontSize: 32,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    Row(
                      children: [
                        Text(
                          "$playerFullReps pleines (1.0)",
                          style: const TextStyle(color: Colors.greenAccent, fontSize: 11),
                        ),
                        const SizedBox(width: 6),
                        const Text("•", style: TextStyle(color: Colors.white70)),
                        const SizedBox(width: 6),
                        Text(
                          "$playerHalfReps demies (0.5)",
                          style: const TextStyle(color: Colors.amberAccent, fontSize: 11),
                        ),
                      ],
                    ),
                  ],
                ),
                
                // Divider
                Container(
                  height: 44,
                  width: 1,
                  color: Colors.white10,
                ),
                
                // Opponent Side
                Column(
                  children: [
                    Text(
                      opponentName,
                      style: const TextStyle(color: Colors.white70, fontSize: 10, fontWeight: FontWeight.bold),
                    ),
                    Text(
                      opponentScore.toStringAsFixed(1),
                      style: TextStyle(
                        color: opponentScore > playerScore ? Colors.redAccent : Colors.white,
                        fontSize: 32,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const Text(
                      "Même Ligue • Strict",
                      style: TextStyle(color: Colors.white70, fontSize: 11),
                    ),
                  ],
                ),
              ],
            ),
            
            const SizedBox(height: 12),
            
            // Strict IA referee reminder
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.cyan.withOpacity(0.12),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.cyan.withOpacity(0.3)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.gavel, color: Colors.cyanAccent, size: 14),
                  const SizedBox(width: 6),
                  const Text(
                    "Arbitrage IA Strict : 1 pleine = 1.0 pt | demi-amplitude = 0.5 pt",
                    style: TextStyle(color: Colors.cyanAccent, fontSize: 10, fontWeight: FontWeight.w600),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class WorldBossCard extends StatelessWidget {
  final String bossName;
  final String bossSubtitle;
  final int currentHp;
  final int maxHp;
  final int playerContributionDamage;
  final String liveCommunityFeed;

  const WorldBossCard({
    Key? key,
    this.bossName = "LE GOLEM DE FER",
    this.bossSubtitle = "Colosse Titanesque des Forges",
    required this.currentHp,
    this.maxHp = 1000000,
    required this.playerContributionDamage,
    required this.liveCommunityFeed,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final double hpFraction = (currentHp / maxHp).clamp(0.0, 1.0);
    final numberFormat = NumberFormat.decimalPattern('fr_FR');

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: const Color(0xFF15171C),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.redAccent.withOpacity(0.45), width: 1.2),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14.0),
        child: Column(
          children: [
            // Header: Boss Tag, Event Timer
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: Colors.redAccent.withOpacity(0.15),
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.redAccent.withOpacity(0.35)),
                      ),
                      alignment: Alignment.center,
                      child: const Text("👹", style: TextStyle(fontSize: 16)),
                    ),
                    const SizedBox(width: 8),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          bossName,
                          style: const TextStyle(
                            color: Colors.redAccent,
                            fontSize: 14,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 0.8,
                          ),
                        ),
                        Text(
                          bossSubtitle,
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                // Event countdown
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.redAccent.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.redAccent.withOpacity(0.3)),
                  ),
                  child: Row(
                    children: const [
                      Icon(Icons.whatshot, color: Colors.redAccent, size: 13),
                      SizedBox(width: 4),
                      Text(
                        "FIN : 2j 14h",
                        style: TextStyle(
                          color: Colors.redAccent,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 12),

            // Massive HP Bar
            Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      "BARRE DE VIE COMMUNE",
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      "${numberFormat.format(currentHp)} / ${numberFormat.format(maxHp)} PV (${(hpFraction * 100).toInt()}%)",
                      style: const TextStyle(
                        color: Colors.redAccent,
                        fontSize: 10,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Container(
                  width: double.infinity,
                  height: 18,
                  decoration: BoxDecoration(
                    color: const Color(0xFF0B0C10),
                    borderRadius: BorderRadius.circular(9),
                    border: Border.all(color: const Color(0xFF2C2F33)),
                  ),
                  child: TweenAnimationBuilder<double>(
                    tween: Tween<double>(begin: hpFraction, end: hpFraction),
                    duration: const Duration(milliseconds: 300),
                    builder: (context, animatedHp, child) {
                      return FractionallySizedBox(
                        alignment: Alignment.centerLeft,
                        widthFactor: animatedHp,
                        child: Container(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(9),
                            gradient: const LinearGradient(
                              colors: [Color(0xFF8B0000), Colors.redAccent],
                              begin: Alignment.centerLeft,
                              end: Alignment.centerRight,
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),

            const SizedBox(height: 12),

            // User contribution & Live community strikes ticker
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // User personal strike
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      "VOTRE CONTRIBUTION",
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 10,
                      ),
                    ),
                    Text(
                      "$playerContributionDamage Dégâts (1 rép = 1 PV)",
                      style: const TextStyle(
                        color: Colors.amberAccent,
                        fontSize: 12,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ],
                ),
                // Relic guarantee badge
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.amber.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: Colors.amber.withOpacity(0.35)),
                  ),
                  child: const Text(
                    "✨ Relique Épique Garantie",
                    style: TextStyle(
                      color: Colors.amberAccent,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 10),

            // Live Community Feed Ticker
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: const Color(0xFF2C2F33),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.white12),
              ),
              child: Row(
                children: [
                  const Icon(Icons.crisis_alert, color: Colors.redAccent, size: 14),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      "En direct : $liveCommunityFeed",
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 11,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
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

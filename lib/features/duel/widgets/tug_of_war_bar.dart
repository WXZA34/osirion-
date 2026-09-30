import 'package:flutter/material.dart';

class TugOfWarBar extends StatelessWidget {
  final String playerName;
  final int playerLevel;
  final double playerReps;
  final String opponentName;
  final int opponentLevel;
  final double opponentReps;
  final double tugPosition; // 0.0 (Player Win) to 1.0 (Opponent Win), 0.5 = Dead Center
  final double handicapMultiplier;

  const TugOfWarBar({
    Key? key,
    required this.playerName,
    required this.playerLevel,
    required this.playerReps,
    required this.opponentName,
    required this.opponentLevel,
    required this.opponentReps,
    required this.tugPosition,
    required this.handicapMultiplier,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Clamp the animated position between 0.05 and 0.95
    final double safePosition = tugPosition.clamp(0.05, 0.95);

    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: safePosition, end: safePosition),
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOutBack,
      builder: (context, animatedPosition, child) {
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
                // Header: Player vs Opponent
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Player side
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              width: 24,
                              height: 24,
                              decoration: const BoxDecoration(
                                color: Colors.amber,
                                shape: BoxShape.circle,
                              ),
                              alignment: Alignment.center,
                              child: const Text(
                                "VOUS",
                                style: TextStyle(
                                  fontSize: 7,
                                  fontWeight: FontWeight.w900,
                                  color: Color(0xFF121316),
                                ),
                              ),
                            ),
                            const SizedBox(width: 6),
                            Text(
                              playerName,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        Text(
                          "Niv. $playerLevel • ${playerReps.toInt()} réps",
                          style: const TextStyle(
                            color: Colors.amberAccent,
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),

                    // Center VS Icon
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.deepOrangeAccent.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: Colors.deepOrangeAccent.withOpacity(0.35)),
                      ),
                      child: const Text(
                        "⚔️ TUG OF WAR",
                        style: TextStyle(
                          color: Colors.orangeAccent,
                          fontSize: 10,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 0.8,
                        ),
                      ),
                    ),

                    // Opponent side
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Row(
                          children: [
                            Text(
                              opponentName,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(width: 6),
                            Container(
                              width: 24,
                              height: 24,
                              decoration: const BoxDecoration(
                                color: Colors.deepOrangeAccent,
                                shape: BoxShape.circle,
                              ),
                              alignment: Alignment.center,
                              child: const Text(
                                "ADV",
                                style: TextStyle(
                                  fontSize: 7,
                                  fontWeight: FontWeight.w900,
                                  color: Color(0xFF121316),
                                ),
                              ),
                            ),
                          ],
                        ),
                        Text(
                          "Niv. $opponentLevel • ${opponentReps.toInt()} réps",
                          style: const TextStyle(
                            color: Colors.orangeAccent,
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),

                const SizedBox(height: 14),

                // The Physical Tug of War Rope Bar
                Container(
                  width: double.infinity,
                  height: 24,
                  decoration: BoxDecoration(
                    color: const Color(0xFF0B0C10),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFF2C2F33)),
                  ),
                  child: Stack(
                    children: [
                      // Player territory gradient (left)
                      Positioned(
                        left: 0,
                        top: 0,
                        bottom: 0,
                        right: MediaQuery.of(context).size.width * animatedPosition,
                        child: Container(
                          decoration: BoxDecoration(
                            borderRadius: const BorderRadius.only(
                              topLeft: Radius.circular(12),
                              bottomLeft: Radius.circular(12),
                            ),
                            gradient: LinearGradient(
                              colors: [Colors.amber.withOpacity(0.8), Colors.cyan.withOpacity(0.4)],
                              begin: Alignment.centerLeft,
                              end: Alignment.centerRight,
                            ),
                          ),
                        ),
                      ),

                      // Opponent territory gradient (right)
                      Positioned(
                        right: 0,
                        top: 0,
                        bottom: 0,
                        left: MediaQuery.of(context).size.width * (1.0 - animatedPosition),
                        child: Container(
                          decoration: BoxDecoration(
                            borderRadius: const BorderRadius.only(
                              topRight: Radius.circular(12),
                              bottomRight: Radius.circular(12),
                            ),
                            gradient: LinearGradient(
                              colors: [Colors.deepOrangeAccent.withOpacity(0.4), Colors.deepOrangeAccent.withOpacity(0.85)],
                              begin: Alignment.centerLeft,
                              end: Alignment.centerRight,
                            ),
                          ),
                        ),
                      ),

                      // Center neutral marker
                      const Align(
                        alignment: Alignment.center,
                        child: SizedBox(
                          width: 2,
                          child: ColoredBox(color: Color(0xFF2C2F33)),
                        ),
                      ),

                      // Central Tug Knot / Clashing Crest
                      Positioned(
                        left: 0,
                        right: 0,
                        top: 0,
                        bottom: 0,
                        child: FractionallySizedBox(
                          alignment: Alignment.centerLeft,
                          widthFactor: animatedPosition,
                          child: Align(
                            alignment: Alignment.centerRight,
                            child: Container(
                              width: 24,
                              height: 24,
                              decoration: BoxDecoration(
                                color: const Color(0xFF2C2F33),
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: animatedPosition < 0.5 ? Colors.amber : Colors.deepOrangeAccent,
                                  width: 1.5,
                                ),
                              ),
                              alignment: Alignment.center,
                              child: const Text(
                                "⚔️",
                                style: TextStyle(fontSize: 11),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 10),

                // Handicap Balancing Notice
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: Colors.amber.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.amber.withOpacity(0.25)),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text(
                        "⚖️ Système Handicap Actif : ",
                        style: TextStyle(
                          color: Colors.amberAccent,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        ((handicapMultiplier - 1.0) * 100).toInt() > 0
                            ? "+${((handicapMultiplier - 1.0) * 100).toInt()}% de poids par rép"
                            : "Poids équilibré (1.0x)",
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

import 'package:flutter/material.dart';

class TugOfWarBar extends StatelessWidget {
  final String playerName;
  final int playerReps;
  final String opponentName;
  final int opponentReps;
  final double tugPosition; // 0.0 to 1.0

  const TugOfWarBar({
    Key? key,
    required this.playerName,
    required this.playerReps,
    required this.opponentName,
    required this.opponentReps,
    required this.tugPosition,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final double safePosition = tugPosition.clamp(0.05, 0.95);

    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: safePosition, end: safePosition),
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOutBack,
      builder: (context, animatedPosition, child) {
        return Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: Colors.black87,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.white24),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    "$playerName : ${playerReps.toInt()}",
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Text(
                    "VS",
                    style: TextStyle(
                      color: Colors.white54,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    "${opponentReps.toInt()} : $opponentName",
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Container(
                width: double.infinity,
                height: 12,
                decoration: BoxDecoration(
                  color: Colors.grey[900],
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Stack(
                  children: [
                    // Player side (White)
                    Positioned(
                      left: 0,
                      top: 0,
                      bottom: 0,
                      right: MediaQuery.of(context).size.width * animatedPosition,
                      child: Container(
                        decoration: const BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.only(
                            topLeft: Radius.circular(6),
                            bottomLeft: Radius.circular(6),
                          ),
                        ),
                      ),
                    ),
                    // Opponent side (Dark Red)
                    Positioned(
                      right: 0,
                      top: 0,
                      bottom: 0,
                      left: MediaQuery.of(context).size.width * (1.0 - animatedPosition),
                      child: Container(
                        decoration: const BoxDecoration(
                          color: Colors.redAccent,
                          borderRadius: BorderRadius.only(
                            topRight: Radius.circular(6),
                            bottomRight: Radius.circular(6),
                          ),
                        ),
                      ),
                    ),
                    // Center separator
                    const Align(
                      alignment: Alignment.center,
                      child: SizedBox(
                        width: 2,
                        child: ColoredBox(color: Colors.black),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

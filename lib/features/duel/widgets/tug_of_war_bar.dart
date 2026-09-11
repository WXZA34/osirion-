import 'package:flutter/material.dart';

class TugOfWarBar extends StatelessWidget {
  final int myReps;
  final int opponentReps;
  final Color myColor;
  final Color opponentColor;

  const TugOfWarBar({
    Key? key,
    required this.myReps,
    required this.opponentReps,
    this.myColor = Colors.cyanAccent,
    this.opponentColor = Colors.pinkAccent,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    int totalReps = myReps + opponentReps;
    // Prevent division by zero. If both are 0, it's 50/50.
    double myRatio = totalReps == 0 ? 0.5 : myReps / totalReps;

    return Container(
      height: 30,
      width: double.infinity,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(15),
        color: Colors.black54,
        border: Border.all(color: Colors.white24, width: 2),
      ),
      child: Stack(
        children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            width: MediaQuery.of(context).size.width * myRatio,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.only(
                topLeft: const Radius.circular(15),
                bottomLeft: const Radius.circular(15),
                topRight: myRatio == 1 ? const Radius.circular(15) : Radius.zero,
                bottomRight: myRatio == 1 ? const Radius.circular(15) : Radius.zero,
              ),
              color: myColor,
            ),
          ),
          Positioned.fill(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12.0),
                  child: Text(
                    myReps.toString(),
                    style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12.0),
                  child: Text(
                    opponentReps.toString(),
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
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

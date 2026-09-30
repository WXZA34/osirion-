import 'package:flutter/material.dart';

class LeagueRank {
  final String name;
  final int minMmr;
  final Color color;

  const LeagueRank(this.name, this.minMmr, this.color);

  static const List<LeagueRank> allRanks = [
    LeagueRank("Bronze", 0, Color(0xFFCD7F32)),
    LeagueRank("Argent", 500, Color(0xFFC0C0C0)),
    LeagueRank("Or", 1000, Color(0xFFFFD700)),
    LeagueRank("Platine", 1500, Color(0xFFE5E4E2)),
    LeagueRank("Diamant", 2000, Color(0xFF00FFFF)),
    LeagueRank("Valérion", 2900, Color(0xFFA020F0)),
  ];

  static LeagueRank fromMmr(int mmr) {
    for (int i = allRanks.length - 1; i >= 0; i--) {
      if (mmr >= allRanks[i].minMmr) {
        return allRanks[i];
      }
    }
    return allRanks[0];
  }
}

class LadderPlayer {
  final int rank;
  final String name;
  final int mmr;
  final String winRate;
  final bool isUser;

  const LadderPlayer({
    required this.rank,
    required this.name,
    required this.mmr,
    required this.winRate,
    this.isUser = false,
  });
}

class LeagueLadderScreen extends StatelessWidget {
  final int userMmr = 1350; // Mocked MMR
  final int seasonDaysRemaining = 12;

  const LeagueLadderScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final currentRank = LeagueRank.fromMmr(userMmr);
    
    final List<LadderPlayer> rivals = [
      const LadderPlayer(rank: 1, name: "Ares_Olympus", mmr: 1495, winRate: "78%"),
      LadderPlayer(rank: 2, name: "Spartan_Kaiser", mmr: userMmr, winRate: "75%", isUser: true),
      const LadderPlayer(rank: 3, name: "Valkyrie_99", mmr: 1360, winRate: "71%"),
      const LadderPlayer(rank: 4, name: "Goliath_FR", mmr: 1340, winRate: "65%"),
      const LadderPlayer(rank: 5, name: "Titan_Striker", mmr: 1310, winRate: "62%"),
      const LadderPlayer(rank: 6, name: "Leonidas_Rep", mmr: 1285, winRate: "58%"),
      const LadderPlayer(rank: 7, name: "IronClad_44", mmr: 1240, winRate: "54%"),
      const LadderPlayer(rank: 8, name: "Shadow_Push", mmr: 1215, winRate: "51%"),
    ];

    return Scaffold(
      backgroundColor: const Color(0xFF0B0C10),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text(
          "Classement",
          style: TextStyle(fontWeight: FontWeight.w900),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        physics: const BouncingScrollPhysics(),
        children: [
          // Header
          const Text(
            "LA LIGUE OFFICIELLE",
            style: TextStyle(
              color: Colors.cyanAccent,
              fontSize: 24,
              fontWeight: FontWeight.w900,
              letterSpacing: 1.5,
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            "Mode Classé • Arbitrage strict • Rangs Bronze à Valérion",
            style: TextStyle(color: Colors.white70, fontSize: 14),
          ),
          const SizedBox(height: 24),

          // Current League Card
          Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: currentRank.color.withOpacity(0.6), width: 1.2),
              gradient: const LinearGradient(
                colors: [Color(0xFF1E2128), Color(0xFF15171C), Color(0xFF0B0C10)],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
            padding: const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          "VOTRE DIVISION ACTUELLE",
                          style: TextStyle(
                            color: Colors.white70,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          currentRank.name.toUpperCase(),
                          style: TextStyle(
                            color: currentRank.color,
                            fontSize: 22,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ],
                    ),
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: currentRank.color.withOpacity(0.15),
                        shape: BoxShape.circle,
                        border: Border.all(color: currentRank.color.withOpacity(0.4)),
                      ),
                      alignment: Alignment.center,
                      child: const Text("🥇", style: TextStyle(fontSize: 22)),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text("COTE MMR", style: TextStyle(color: Colors.white70, fontSize: 10)),
                        Text(
                          "$userMmr PTS",
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ],
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        const Text("FIN DE SAISON", style: TextStyle(color: Colors.white70, fontSize: 10)),
                        Text(
                          "$seasonDaysRemaining JOURS",
                          style: const TextStyle(
                            color: Colors.redAccent,
                            fontSize: 18,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                
                // Next rank checkpoint
                Builder(
                  builder: (context) {
                    final currentIndex = LeagueRank.allRanks.indexOf(currentRank);
                    if (currentIndex < LeagueRank.allRanks.length - 1) {
                      final nextRank = LeagueRank.allRanks[currentIndex + 1];
                      final ptsNeeded = nextRank.minMmr - userMmr;
                      return Text(
                        "Prochain Palier : ${nextRank.name} dans $ptsNeeded MMR",
                        style: const TextStyle(
                          color: Colors.cyanAccent,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      );
                    } else {
                      return const Text(
                        "👑 Vous avez atteint le rang suprême : LIGUE VALÉRION !",
                        style: TextStyle(
                          color: Colors.purpleAccent,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      );
                    }
                  }
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Tier Progression Ribbon
          const Text(
            "ÉCHELLE DES RANGS",
            style: TextStyle(
              color: Colors.white70,
              fontSize: 12,
              fontWeight: FontWeight.w900,
              letterSpacing: 1,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: LeagueRank.allRanks.map((rank) {
              final isCurrentOrBelow = userMmr >= rank.minMmr;
              return Expanded(
                child: Container(
                  height: 6,
                  margin: const EdgeInsets.symmetric(horizontal: 2),
                  decoration: BoxDecoration(
                    color: isCurrentOrBelow ? rank.color : Colors.white10,
                    borderRadius: BorderRadius.circular(3),
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 24),

          // Top Valerion Callout
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: const Color(0xFF15171C),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.purple.withOpacity(0.4)),
            ),
            child: Row(
              children: [
                const Text("👑", style: TextStyle(fontSize: 24)),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: const [
                      Text(
                        "RANG SUPRÊME : LIGUE VALÉRION (2900+ MMR)",
                        style: TextStyle(
                          color: Colors.purpleAccent,
                          fontSize: 10,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      Text(
                        "Les 100 meilleurs guerriers mondiaux obtiennent l'Armure Astrale de Valerion et l'immortalité au Panthéon.",
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Leaderboard Table
          Text(
            "CLASSEMENT DE VOTRE DIVISION (${currentRank.name.toUpperCase()})",
            style: const TextStyle(
              color: Colors.white,
              fontSize: 14,
              fontWeight: FontWeight.w900,
              letterSpacing: 1,
            ),
          ),
          const SizedBox(height: 12),

          ...rivals.map((player) {
            final isTop3 = player.rank <= 3;
            return Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              decoration: BoxDecoration(
                color: player.isUser ? const Color(0xFF15171C) : const Color(0xFF1E2128),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: player.isUser ? Colors.amber : Colors.white10,
                  width: player.isUser ? 1.5 : 1.0,
                ),
              ),
              child: Row(
                children: [
                  SizedBox(
                    width: 36,
                    child: Text(
                      "#${player.rank}",
                      style: TextStyle(
                        color: isTop3 ? Colors.amber : Colors.white70,
                        fontSize: 14,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(
                              player.name,
                              style: TextStyle(
                                color: player.isUser ? Colors.amber : Colors.white,
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            if (player.isUser) ...[
                              const SizedBox(width: 6),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                                decoration: BoxDecoration(
                                  color: Colors.amber,
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: const Text(
                                  "VOUS",
                                  style: TextStyle(
                                    color: Color(0xFF141518),
                                    fontSize: 8,
                                    fontWeight: FontWeight.w900,
                                  ),
                                ),
                              ),
                            ]
                          ],
                        ),
                        Text(
                          "Taux de victoire : ${player.winRate}",
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Text(
                    "${player.mmr} MMR",
                    style: const TextStyle(
                      color: Colors.cyanAccent,
                      fontSize: 14,
                      fontWeight: FontWeight.w900,
                    ),
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

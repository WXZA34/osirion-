import 'package:flutter/material.dart';

class UserProfileEntity {
  final String username;
  final String title;
  final int level;
  final String league;
  final int currentXp;
  final int requiredXpForNextLevel;
  final int goldCoins;
  final int energyCrystals;
  final int mmr;
  final int totalPushups;
  final int totalSquats;
  final int totalSitups;
  final int duelWins;
  final int duelLosses;
  final int raidDamageTotal;

  const UserProfileEntity({
    required this.username,
    required this.title,
    required this.level,
    required this.league,
    required this.currentXp,
    required this.requiredXpForNextLevel,
    required this.goldCoins,
    required this.energyCrystals,
    required this.mmr,
    required this.totalPushups,
    required this.totalSquats,
    required this.totalSitups,
    required this.duelWins,
    required this.duelLosses,
    required this.raidDamageTotal,
  });
}

class RelicEntity {
  final String id;
  final String name;
  final String iconEmoji;
  final String rarity;
  final String originBoss;
  final String bonusDescription;

  const RelicEntity({
    required this.id,
    required this.name,
    required this.iconEmoji,
    required this.rarity,
    required this.originBoss,
    required this.bonusDescription,
  });
}

class PantheonProfileScreen extends StatelessWidget {
  const PantheonProfileScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Mock Data for the profile
    const profile = UserProfileEntity(
      username: "Roland",
      title: "Guerrier de l'Aube",
      level: 12,
      league: "Or III",
      currentXp: 4500,
      requiredXpForNextLevel: 5000,
      goldCoins: 12500,
      energyCrystals: 340,
      mmr: 1640,
      totalPushups: 1540,
      totalSquats: 2100,
      totalSitups: 980,
      duelWins: 45,
      duelLosses: 12,
      raidDamageTotal: 45000,
    );

    // Mock Data for relics
    final List<RelicEntity> relics = [
      const RelicEntity(
        id: "1",
        name: "Cœur de Forge",
        iconEmoji: "🔥",
        rarity: "ÉPIQUE",
        originBoss: "Golem de Fer",
        bonusDescription: "+5% de dégâts de base en Raid",
      ),
      const RelicEntity(
        id: "2",
        name: "Brassard du Titan",
        iconEmoji: "💪",
        rarity: "LÉGENDAIRE",
        originBoss: "Titan Oublié",
        bonusDescription: "Bonus MMR en victoire +10%",
      ),
    ];

    final double xpProgress = (profile.currentXp / profile.requiredXpForNextLevel).clamp(0.0, 1.0);

    return Scaffold(
      backgroundColor: const Color(0xFF0B0C10),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text(
          "Profil du Panthéon",
          style: TextStyle(fontWeight: FontWeight.w900, color: Colors.white),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        physics: const BouncingScrollPhysics(),
        children: [
          const SizedBox(height: 8),
          
          // Profile Hero Card
          Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.amber.withOpacity(0.5), width: 1.2),
              gradient: const LinearGradient(
                colors: [Color(0xFF2C2F33), Color(0xFF15171C), Color(0xFF0B0C10)],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
            padding: const EdgeInsets.all(18),
            child: Column(
              children: [
                Row(
                  children: [
                    Container(
                      width: 56,
                      height: 56,
                      decoration: BoxDecoration(
                        color: Colors.amber.withOpacity(0.15),
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.amber, width: 1.5),
                      ),
                      alignment: Alignment.center,
                      child: const Text("🛡️", style: TextStyle(fontSize: 26)),
                    ),
                    const SizedBox(width: 14),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          profile.username,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 22,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        Text(
                          profile.title,
                          style: const TextStyle(
                            color: Colors.amberAccent,
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        Text(
                          "Niveau ${profile.level} • ${profile.league}",
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                
                // XP Progress Bar
                Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          "PROGRESSION DU GUERRIER",
                          style: TextStyle(
                            color: Colors.white70,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          "${profile.currentXp} / ${profile.requiredXpForNextLevel} XP",
                          style: const TextStyle(
                            color: Colors.amberAccent,
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Container(
                      width: double.infinity,
                      height: 8,
                      decoration: BoxDecoration(
                        color: const Color(0xFF0B0C10),
                        borderRadius: BorderRadius.circular(4),
                        border: Border.all(color: const Color(0xFF2C2F33)),
                      ),
                      child: FractionallySizedBox(
                        alignment: Alignment.centerLeft,
                        widthFactor: xpProgress,
                        child: Container(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(4),
                            gradient: const LinearGradient(
                              colors: [Colors.amber, Colors.amberAccent],
                              begin: Alignment.centerLeft,
                              end: Alignment.centerRight,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                
                // Currencies Row
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _CurrencyPill(label: "${profile.goldCoins}", sub: "Pièces d'Or", emoji: "🪙", color: Colors.amberAccent),
                    _CurrencyPill(label: "${profile.energyCrystals}", sub: "Cristaux", emoji: "💎", color: Colors.purpleAccent),
                    _CurrencyPill(label: "${profile.mmr}", sub: "MMR Classé", emoji: "📈", color: Colors.cyanAccent),
                  ],
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 16),
          
          // Relics Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                "RELIQUES DU PANTHÉON",
                style: TextStyle(
                  color: Colors.amberAccent,
                  fontSize: 16,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1.0,
                ),
              ),
              Text(
                "${relics.length} Obtenues",
                style: const TextStyle(color: Colors.white70, fontSize: 11),
              ),
            ],
          ),
          
          const SizedBox(height: 16),
          
          if (relics.isEmpty)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: const Color(0xFF15171C),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.white10),
              ),
              child: Column(
                children: const [
                  Text("🏛️", style: TextStyle(fontSize: 32)),
                  SizedBox(height: 8),
                  Text(
                    "Aucune Relique débloquée pour l'instant",
                    style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold),
                  ),
                  Text(
                    "Participez au Raid Mondial du Golem de Fer pour obtenir votre première relique !",
                    style: TextStyle(color: Colors.white70, fontSize: 12),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            )
          else
            ...relics.map((relic) {
              return Container(
                margin: const EdgeInsets.only(bottom: 16),
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: const Color(0xFF15171C),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: Colors.amber.withOpacity(0.35)),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: Colors.amber.withOpacity(0.12),
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.amber.withOpacity(0.3)),
                      ),
                      alignment: Alignment.center,
                      child: Text(relic.iconEmoji, style: const TextStyle(fontSize: 20)),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text(
                                relic.name,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(width: 6),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: Colors.amber.withOpacity(0.15),
                                  borderRadius: BorderRadius.circular(4),
                                  border: Border.all(color: Colors.amber.withOpacity(0.3)),
                                ),
                                child: Text(
                                  relic.rarity,
                                  style: const TextStyle(
                                    color: Colors.amberAccent,
                                    fontSize: 9,
                                    fontWeight: FontWeight.w900,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          Text(
                            "Origine : ${relic.originBoss}",
                            style: const TextStyle(color: Colors.white70, fontSize: 11),
                          ),
                          Text(
                            relic.bonusDescription,
                            style: const TextStyle(color: Colors.cyanAccent, fontSize: 11, fontWeight: FontWeight.w500),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
            
          const SizedBox(height: 4),
          const Text(
            "VOLUMÉTRIE D'ENTRAÎNEMENT",
            style: TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.w900,
              letterSpacing: 1.0,
            ),
          ),
          const SizedBox(height: 16),
          
          Row(
            children: [
              Expanded(child: _StatCard(title: "Pompes", value: "${profile.totalPushups}", emoji: "💪")),
              const SizedBox(width: 10),
              Expanded(child: _StatCard(title: "Squats", value: "${profile.totalSquats}", emoji: "🦵")),
              const SizedBox(width: 10),
              Expanded(child: _StatCard(title: "Abdos", value: "${profile.totalSitups}", emoji: "⚡")),
            ],
          ),
          
          const SizedBox(height: 16),
          
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFF15171C),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: Colors.white10),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                Column(
                  children: [
                    const Text("DUELS DISPUTÉS", style: TextStyle(color: Colors.white70, fontSize: 11)),
                    Text(
                      "${profile.duelWins}V / ${profile.duelLosses}D",
                      style: const TextStyle(
                        color: Colors.deepOrangeAccent,
                        fontSize: 16,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ],
                ),
                Container(
                  width: 1,
                  height: 30,
                  color: Colors.white10,
                ),
                Column(
                  children: [
                    const Text("DÉGÂTS TOTAL RAID", style: TextStyle(color: Colors.white70, fontSize: 11)),
                    Text(
                      "${profile.raidDamageTotal} PV",
                      style: const TextStyle(
                        color: Colors.redAccent,
                        fontSize: 16,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}

class _CurrencyPill extends StatelessWidget {
  final String label;
  final String sub;
  final String emoji;
  final Color color;

  const _CurrencyPill({
    required this.label,
    required this.sub,
    required this.emoji,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          children: [
            Text(emoji, style: const TextStyle(fontSize: 14)),
            const SizedBox(width: 4),
            Text(
              label,
              style: TextStyle(
                color: color,
                fontSize: 16,
                fontWeight: FontWeight.w900,
              ),
            ),
          ],
        ),
        Text(
          sub,
          style: const TextStyle(
            color: Colors.white70,
            fontSize: 10,
          ),
        ),
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  final String title;
  final String value;
  final String emoji;

  const _StatCard({
    required this.title,
    required this.value,
    required this.emoji,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF15171C),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white10),
      ),
      child: Column(
        children: [
          Text(emoji, style: const TextStyle(fontSize: 20)),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 22,
              fontWeight: FontWeight.w900,
            ),
          ),
          Text(
            title,
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }
}

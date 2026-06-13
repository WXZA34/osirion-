import 'package:flutter/material.dart';

class Relic {
  final String id;
  final String name;
  final String description;
  final IconData icon;
  final Color color;
  final int cost;
  final String type; // 'halo', 'title', 'boost', 'theme'
  final int? requiredLevel; // Niveau requis pour les déblocages automatiques

  const Relic({
    required this.id,
    required this.name,
    required this.description,
    required this.icon,
    required this.color,
    required this.cost,
    required this.type,
    this.requiredLevel,
  });

  static Relic? findById(String? id) {
    if (id == null) return null;
    return [...arsenalRelics, ...levelTitles].firstWhere(
      (r) => r.id == id,
      orElse: () => arsenalRelics.first,
    );
  }

  factory Relic.fromMap(String id, Map<String, dynamic> map) {
    return Relic(
      id: id,
      name: map['name'] ?? '',
      description: map['description'] ?? '',
      icon: IconData(map['iconCodePoint'] ?? Icons.help.codePoint, fontFamily: 'MaterialIcons'),
      color: Color(map['colorValue'] ?? 0xFFFFFFFF),
      cost: map['cost'] ?? 0,
      type: map['type'] ?? 'boost',
      requiredLevel: map['requiredLevel'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'description': description,
      'iconCodePoint': icon.codePoint,
      'colorValue': color.value,
      'cost': cost,
      'type': type,
      'requiredLevel': requiredLevel,
    };
  }
}

final List<Relic> arsenalRelics = [
  // --- TITRES (Boutique) ---
  const Relic(
    id: 'title_perseverant',
    name: 'Le Persévérant',
    description: 'Prouve votre détermination continue.',
    icon: Icons.directions_run,
    color: Colors.greenAccent,
    cost: 100,
    type: 'title',
  ),
  const Relic(
    id: 'title_eveille',
    name: "L'Éveillé",
    description: 'Titre spirituel pour un esprit clair.',
    icon: Icons.remove_red_eye,
    color: Colors.blueAccent,
    cost: 300,
    type: 'title',
  ),
  const Relic(
    id: 'title_titan',
    name: 'Titan de Fer',
    description: 'Réservé aux machines inarrêtables.',
    icon: Icons.fitness_center,
    color: Colors.redAccent,
    cost: 1000,
    type: 'title',
  ),

  // --- HALOS ---
  const Relic(
    id: 'halo_fire',
    name: 'Halo de Feu',
    description: 'Une aura incandescente brille sur votre profil.',
    icon: Icons.local_fire_department,
    color: Colors.deepOrangeAccent,
    cost: 500,
    type: 'halo',
  ),
  const Relic(
    id: 'halo_frost',
    name: 'Halo Glacial',
    description: 'Un blizzard permanent fige votre carte.',
    icon: Icons.ac_unit,
    color: Colors.cyanAccent,
    cost: 800,
    type: 'halo',
  ),

  // --- BOOSTS ---
  const Relic(
    id: 'boost_vitality',
    name: 'Cristal de Vitalité',
    description: '(Consommable) +50% XP Dojo pendant 30m.',
    icon: Icons.diamond,
    color: Colors.purpleAccent,
    cost: 50,
    type: 'boost',
  ),
];

// --- TITRES DÉBLOCABLES PAR NIVEAU ---
final List<Relic> levelTitles = [
  const Relic(
    id: 'title_lvl2',
    name: 'Initié(e)',
    description: 'Niveau 2 atteint.',
    icon: Icons.school,
    color: Colors.grey,
    cost: 0,
    type: 'title',
    requiredLevel: 2,
  ),
  const Relic(
    id: 'title_lvl5',
    name: 'Disciple',
    description: 'Niveau 5 atteint.',
    icon: Icons.sports_martial_arts,
    color: Colors.blueGrey,
    cost: 0,
    type: 'title',
    requiredLevel: 5,
  ),
  const Relic(
    id: 'title_lvl10',
    name: 'Guerrier(e)',
    description: 'Niveau 10 atteint.',
    icon: Icons.shield,
    color: Colors.blue,
    cost: 0,
    type: 'title',
    requiredLevel: 10,
  ),
  const Relic(
    id: 'title_lvl15',
    name: 'Spartiate',
    description: 'Niveau 15 atteint.',
    icon: Icons.hardware,
    color: Colors.orange,
    cost: 0,
    type: 'title',
    requiredLevel: 15,
  ),
  const Relic(
    id: 'title_lvl20',
    name: 'Chevalier(e)',
    description: 'Niveau 20 atteint.',
    icon: Icons.security,
    color: Colors.deepOrange,
    cost: 0,
    type: 'title',
    requiredLevel: 20,
  ),
  const Relic(
    id: 'title_lvl30',
    name: 'Légende',
    description: 'Niveau 30 atteint.',
    icon: Icons.star,
    color: Colors.amber,
    cost: 0,
    type: 'title',
    requiredLevel: 30,
  ),
  const Relic(
    id: 'title_lvl40',
    name: 'Demi-Dieu',
    description: 'Niveau 40 atteint.',
    icon: Icons.flash_on,
    color: Colors.yellowAccent,
    cost: 0,
    type: 'title',
    requiredLevel: 40,
  ),
  const Relic(
    id: 'title_lvl50',
    name: 'Dieu de la Guerre',
    description: 'Niveau 50 atteint.',
    icon: Icons.whatshot,
    color: Colors.red,
    cost: 0,
    type: 'title',
    requiredLevel: 50,
  ),
  const Relic(
    id: 'title_lvl75',
    name: 'Entité Cosmique',
    description: 'Niveau 75 atteint.',
    icon: Icons.auto_awesome,
    color: Colors.purpleAccent,
    cost: 0,
    type: 'title',
    requiredLevel: 75,
  ),
  const Relic(
    id: 'title_lvl100',
    name: 'Alpha Suprême',
    description: 'Le paroxysme de la puissance. Niveau 100.',
    icon: Icons.diamond,
    color: Colors.cyanAccent,
    cost: 0,
    type: 'title',
    requiredLevel: 100,
  ),
];

import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/material.dart';
import '../../../core/providers/repository_providers.dart';
import '../models/arc_data.dart';

// Modèle de Quête
class Quest {
  final String title;
  final String desc;
  final IconData icon;
  bool isDone;
  final bool
  isVerifiable; // Indique si la quête nécessite une preuve externe (IA, GPS)

  Quest({
    required this.title,
    required this.desc,
    required this.icon,
    this.isDone = false,
    this.isVerifiable = false,
  });

  Map<String, dynamic> toJson() => {
    'title': title,
    'desc': desc,
    'icon': icon.codePoint, // Sauvegarder l'icône via son code
    'isDone': isDone,
    'isVerifiable': isVerifiable,
  };

  factory Quest.fromJson(Map<String, dynamic> json) => Quest(
    title: json['title'],
    desc: json['desc'],
    icon: Icons.check_circle, // L'icône réelle sera reconstruite via _questBank pour préserver le Tree Shaking
    isDone: json['isDone'],
    isVerifiable: json['isVerifiable'] ?? false,
  );
}

// ===============================
// BANQUE DE QUÊTES (Templates)
// ===============================
final List<Quest> _questBank = [
  // PHYSIQUE (8)
  Quest(title: "Pilier Physique", desc: "Faire 50 pompes", icon: Icons.fitness_center, isVerifiable: true),
  Quest(title: "Pilier Physique", desc: "Faire 20 tractions", icon: Icons.fitness_center, isVerifiable: true),
  Quest(title: "Pilier Physique", desc: "Faire 40 dips", icon: Icons.fitness_center, isVerifiable: true),
  Quest(title: "Pilier Physique", desc: "Courir 3 km", icon: Icons.directions_run),
  Quest(title: "Pilier Physique", desc: "10000 pas aujourd'hui", icon: Icons.directions_walk),
  Quest(title: "Pilier Physique", desc: "Faire 50 squats", icon: Icons.accessibility_new),
  Quest(title: "Pilier Physique", desc: "Maintenir la planche (2 min)", icon: Icons.timer),
  Quest(title: "Pilier Physique", desc: "Sauter à la corde (5 min)", icon: Icons.bolt),

  // MENTAL (9)
  Quest(title: "Pilier Mental", desc: "15 min de méditation", icon: Icons.self_improvement),
  Quest(title: "Pilier Mental", desc: "Lire 20 pages (Codex)", icon: Icons.menu_book),
  Quest(title: "Pilier Mental", desc: "Apprendre 1 nouveau concept", icon: Icons.lightbulb),
  Quest(title: "Pilier Mental", desc: "Écrire 3 gratitudes", icon: Icons.edit_note),
  Quest(title: "Pilier Mental", desc: "Écouter 1 audio Valerion", icon: Icons.headset),
  Quest(title: "Pilier Mental", desc: "Planifier demain", icon: Icons.event_note),
  Quest(title: "Pilier Mental", desc: "10 min de visualisation", icon: Icons.visibility),
  Quest(title: "Pilier Mental", desc: "Respiration Wim Hof (1 cycle)", icon: Icons.air),
  Quest(title: "Pilier Mental", desc: "Zéro réseaux sociaux (matin)", icon: Icons.phonelink_off),

  // LIFESTYLE (8)
  Quest(title: "Action Lifestyle", desc: "Douche froide (3 min)", icon: Icons.water_drop),
  Quest(title: "Action Lifestyle", desc: "Zéro Sucre Ajouté", icon: Icons.no_food),
  Quest(title: "Action Lifestyle", desc: "Dormir 8 heures", icon: Icons.bedtime),
  Quest(title: "Action Lifestyle", desc: "Zéro Alcool aujourd'hui", icon: Icons.no_drinks),
  Quest(title: "Action Lifestyle", desc: "Jeûne intermittent (16h)", icon: Icons.timer_off),
  Quest(title: "Action Lifestyle", desc: "Prendre le soleil (15 min)", icon: Icons.wb_sunny),
  Quest(title: "Action Lifestyle", desc: "Pas d'écran 1h avant lit", icon: Icons.phonelink_off),
  Quest(title: "Action Lifestyle", desc: "Cuisiner un repas sain", icon: Icons.restaurant),
];

class DailyPulseNotifier extends StateNotifier<List<Quest>> {
  final Ref ref;

  DailyPulseNotifier(this.ref) : super([]) {
    refreshQuests();
  }

  Future<void> refreshQuests() async {
    final prefs = await SharedPreferences.getInstance();
    final now = DateTime.now();
    final todayStr = "${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}";
    
    final savedDateStr = prefs.getString('daily_pulse_date');
    final savedQuestsJson = prefs.getString('daily_pulse_quests');

    if (savedDateStr == todayStr && savedQuestsJson != null) {
      // Charger les quêtes sauvegardées pour aujourd'hui
      final List<dynamic> decoded = jsonDecode(savedQuestsJson);
      final List<Quest> quests = decoded.map((e) {
        final q = Quest.fromJson(e);
        try {
          final original = _questBank.firstWhere((b) => b.desc == q.desc);
          return Quest(
            title: q.title,
            desc: q.desc,
            icon: original.icon, // Restauration sécurisée de l'icône
            isDone: q.isDone,
            isVerifiable: q.isVerifiable,
          );
        } catch (_) {
          return q; // Fallback avec Icons.check_circle si non trouvé
        }
      }).toList();
      state = quests;
    } else {
      // Changement de jour détecté
      if (savedDateStr != null && savedQuestsJson != null) {
        // Enregistrer l'activité finale du jour précédent
        final List<dynamic> decoded = jsonDecode(savedQuestsJson);
        final completedCount = decoded.where((q) => q['isDone'] == true).length;
        
        final user = ref.read(userProfileProvider).valueOrNull;
        if (user != null) {
          final repo = ref.read(valerionRepositoryProvider);
          final arc = ArcData.getCurrentArc();
          
          await repo.recordDailyActivity(
            uid: user.id,
            arcId: arc.arcType.name,
            questsDone: completedCount,
            totalQuests: decoded.length,
          );
        }
      }

      // Générer 5 nouvelles quêtes
      _generateNewQuests(prefs, todayStr);
    }
  }

  void _generateNewQuests(SharedPreferences prefs, String todayStr) {
    // Mélanger la banque locale
    final List<Quest> shuffledBank = List.from(_questBank)..shuffle();

    // Sélection intelligente pour garantir la diversité (Catégories)
    List<Quest> selection = [];
    
    // 1 Physique
    final phys = shuffledBank.firstWhere((q) => q.title.contains("Physique"));
    selection.add(phys);
    
    // 1 Mental
    final ment = shuffledBank.firstWhere((q) => q.title.contains("Mental"));
    selection.add(ment);
    
    // 1 Lifestyle
    final life = shuffledBank.firstWhere((q) => q.title.contains("Lifestyle"));
    selection.add(life);

    // Compléter à 5 avec des quêtes aléatoires non encore sélectionnées
    for (var q in shuffledBank) {
      if (selection.length >= 5) break;
      if (!selection.contains(q)) {
        selection.add(q);
      }
    }

    // Créer des copies indépendantes
    final List<Quest> newQuests = selection.map((q) => Quest(
      title: q.title,
      desc: q.desc,
      icon: q.icon,
      isVerifiable: q.isVerifiable,
    )).toList();

    state = newQuests;

    // Sauvegarder
    prefs.setString('daily_pulse_date', todayStr);
    _saveStateToPrefs(prefs, newQuests);
  }

  Future<void> _saveStateToPrefs(
    SharedPreferences prefs,
    List<Quest> quests,
  ) async {
    final questsJson = jsonEncode(quests.map((q) => q.toJson()).toList());
    await prefs.setString('daily_pulse_quests', questsJson);
  }

  // Utilisé par le clic utilisateur (interdit si la quête est vérifiable par l'IA)
  Future<void> toggleQuestState(int index) async {
    if (index < 0 || index >= state.length) return;

    // ANTI-TRICHE : Empêcher le clic manuel sur les quêtes vérifiables
    if (state[index].isVerifiable) {
      return;
    }

    await _setQuestDone(index, !state[index].isDone);
  }

  // Utilisé par le code métier (IA du Dojo, Podomètre, etc.) pour forcer la validation
  Future<void> autoValidateQuest(String expectedDesc) async {
    final int index = state.indexWhere((q) => q.desc == expectedDesc);
    if (index != -1 && !state[index].isDone) {
      await _setQuestDone(index, true);
    }
  }

  Future<void> _setQuestDone(int index, bool newValue) async {
    // Obtenir l'état actuel
    final quests = [...state];
    final bool previousState = quests[index].isDone;

    // Si pas de changement réel, on ne fait rien
    if (previousState == newValue) return;

    quests[index].isDone = newValue;

    // Mettre à jour l'UI
    state = quests;

    // Sauvegarder la persistence
    final prefs = await SharedPreferences.getInstance();
    _saveStateToPrefs(prefs, quests);

    // Si on vient de cocher la quête, donner de l'XP Firebase !
    if (newValue == true) {
      final user = ref.read(userProfileProvider).valueOrNull;
      if (user != null) {
        final repo = ref.read(valerionRepositoryProvider);
        try {
          await repo.completeQuest(user.id, quests[index].desc);

          // Nouveau : Enregistrer l'activité quotidienne pour le calendrier de cohérence
          final arc = ArcData.getCurrentArc();
          final int completed = quests.where((q) => q.isDone).length;
          await repo.recordDailyActivity(
            uid: user.id,
            arcId: arc.arcType.name,
            questsDone: completed,
            totalQuests: quests.length,
          );

          debugPrint(
            "✅ Quête terminée : 20 XP, 5 Aether et Activité enregistrée pour ${user.username}",
          );
        } catch (e) {
          debugPrint("❌ Erreur XP/Aether Quête: $e");
        }
      }
    }
  }
}

final dailyPulseProvider =
    StateNotifierProvider<DailyPulseNotifier, List<Quest>>((ref) {
      return DailyPulseNotifier(ref);
    });

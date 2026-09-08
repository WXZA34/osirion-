import 'package:flutter/material.dart';

class QuestTranslator {
  static String translateTitle(BuildContext context, String title) {
    if (Localizations.localeOf(context).languageCode != 'en') return title;
    
    switch (title) {
      case "Pilier Physique": return "Physical Pillar";
      case "Pilier Mental": return "Mental Pillar";
      case "Action Lifestyle": return "Action Lifestyle";
      default: return title;
    }
  }

  static String translateDesc(BuildContext context, String desc) {
    if (Localizations.localeOf(context).languageCode != 'en') return desc;

    switch (desc) {
      // Physique
      case "Faire 50 pompes": return "Do 50 push-ups";
      case "Faire 20 tractions": return "Do 20 pull-ups";
      case "Faire 40 dips": return "Do 40 dips";
      case "Courir 3 km": return "Run 3 km";
      case "10000 pas aujourd'hui": return "10,000 steps today";
      case "Faire 50 squats": return "Do 50 squats";
      case "Maintenir la planche (2 min)": return "Hold plank (2 min)";
      case "Sauter à la corde (5 min)": return "Jump rope (5 min)";
      
      // Mental
      case "15 min de méditation": return "15 min meditation";
      case "Lire 20 pages (Codex)": return "Read 20 pages (Codex)";
      case "Apprendre 1 nouveau concept": return "Learn 1 new concept";
      case "Écrire 3 gratitudes": return "Write 3 gratitudes";
      case "Écouter 1 audio Valerion": return "Listen to 1 Valerion audio";
      case "Planifier demain": return "Plan tomorrow";
      case "10 min de visualisation": return "10 min visualization";
      case "Respiration Wim Hof (1 cycle)": return "Wim Hof breathing (1 cycle)";
      case "Zéro réseaux sociaux (matin)": return "No social media (morning)";
      
      // Lifestyle
      case "Douche froide (3 min)": return "Cold shower (3 min)";
      case "Zéro Sucre Ajouté": return "Zero Added Sugar";
      case "Dormir 8 heures": return "Sleep 8 hours";
      case "Zéro Alcool aujourd'hui": return "Zero Alcohol today";
      case "Jeûne intermittent (16h)": return "Intermittent fasting (16h)";
      case "Prendre le soleil (15 min)": return "Get sun (15 min)";
      case "Pas d'écran 1h avant lit": return "No screens 1h before bed";
      case "Cuisiner un repas sain": return "Cook a healthy meal";
      
      default: return desc;
    }
  }
}

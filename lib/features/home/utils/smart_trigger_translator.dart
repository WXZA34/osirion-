import 'package:flutter/material.dart';

class SmartTriggerTranslator {
  static String translateTitle(BuildContext context, String title) {
    if (Localizations.localeOf(context).languageCode != 'en') return title;
    
    switch (title) {
      case "REPLI TACTIQUE": return "TACTICAL RETREAT";
      case "DÉFRICHER L'AUBE": return "CLEAR THE DAWN";
      case "FOCUS MENTAL / MOBILITÉ": return "MENTAL FOCUS / MOBILITY";
      case "LA FORGE DU SOIR (AU CHAUD)": return "EVENING FORGE (WARM)";
      case "LA FORGE DU SOIR": return "EVENING FORGE";
      default: return title;
    }
  }

  static String translateSubtitle(BuildContext context, String subtitle) {
    if (Localizations.localeOf(context).languageCode != 'en') return subtitle;

    if (subtitle.startsWith("Il fait froid (")) {
       return subtitle.replaceFirst("Il fait froid (", "It's cold (").replaceFirst("). Objectif: Force.", "). Goal: Strength.");
    }

    switch (subtitle) {
      case "Pluie détectée. Session Dojo recommandée.": return "Rain detected. Dojo session recommended.";
      case "Temps clair. Courir dans l'Arène.": return "Clear weather. Run in the Arena.";
      case "Idéal pour l'apprentissage et le stretching.": return "Ideal for learning and stretching.";
      case "Entraînement de force (Dojo) ou Arène nocturne.": return "Strength training (Dojo) or night Arena.";
      default: return subtitle;
    }
  }
}

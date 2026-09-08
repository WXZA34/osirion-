import 'package:flutter/material.dart';

class ArcTranslator {
  static String translate(BuildContext context, String text) {
    if (Localizations.localeOf(context).languageCode != 'en') return text;
    
    switch (text) {
      // Arc Titles
      case "ROYAL ARC": return "ROYAL ARC";
      case "SUMMER BODY": return "SUMMER BODY";
      case "WINTER ARC": return "WINTER ARC";
      
      // Arc Subtitles
      case "LE COURONNEMENT ALPHA": return "THE ALPHA CORONATION";
      case "L'ÉCLAT DE L'EFFORT": return "THE BRILLIANCE OF EFFORT";
      case "LA FORGE DANS L'OMBRE": return "FORGED IN THE SHADOWS";
      
      // Quotes
      case "\"La grandeur n'est pas reçue, elle est manifestée.\"": return "\"Greatness is not given, it is manifested.\"";
      case "\"La lumière ne se trouve pas, elle se forge.\"": return "\"Light is not found, it is forged.\"";
      case "\"Le progrès n'est pas un don, c'est une conquête.\"": return "\"Progress is not a gift, it is a conquest.\"";
      
      // Video Card Messages
      case "SIGNAL PERDU": return "SIGNAL LOST";
      case "La transmission Alpha est actuellement hors-ligne.": return "Alpha transmission is currently offline.";
      case "SIGNAL FAIBLE": return "WEAK SIGNAL";
      case "En attente du prochain briefing tactique...": return "Waiting for the next tactical briefing...";
      case "ERREUR SYSTÈME": return "SYSTEM ERROR";
      
      default: 
        if (text.startsWith("Échec de synchronisation avec le satellite Alpha : ")) {
          return text.replaceFirst("Échec de synchronisation avec le satellite Alpha : ", "Failed to sync with Alpha satellite: ");
        }
        return text;
    }
  }
}

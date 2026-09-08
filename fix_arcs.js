const fs = require('fs');

// 1. Create ArcTranslator
const translatorCode = `import 'package:flutter/material.dart';

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
      case "\\"La grandeur n'est pas reçue, elle est manifestée.\\"": return "\\"Greatness is not given, it is manifested.\\"";
      case "\\"La lumière ne se trouve pas, elle se forge.\\"": return "\\"Light is not found, it is forged.\\"";
      case "\\"Le progrès n'est pas un don, c'est une conquête.\\"": return "\\"Progress is not a gift, it is a conquest.\\"";
      
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
`;
fs.writeFileSync('lib/features/home/utils/arc_translator.dart', translatorCode);

// 2. Fix ArcCard
let acPath = 'lib/features/home/widgets/arc_card.dart';
let ac = fs.readFileSync(acPath, 'utf8');
if (!ac.includes("import 'package:valerion/features/home/utils/arc_translator.dart';")) {
  ac = "import 'package:valerion/features/home/utils/arc_translator.dart';\n" + ac;
}
ac = ac.replace(/widget\.arc\.title,/g, 'ArcTranslator.translate(context, widget.arc.title),');
ac = ac.replace(/widget\.arc\.subtitle,/g, 'ArcTranslator.translate(context, widget.arc.subtitle),');
ac = ac.replace(/widget\.arc\.quote,/g, 'ArcTranslator.translate(context, widget.arc.quote),');
fs.writeFileSync(acPath, ac);

// 3. Fix DailyVideoCard
let dvcPath = 'lib/features/home/widgets/daily_video_card.dart';
let dvc = fs.readFileSync(dvcPath, 'utf8');
if (!dvc.includes("import 'package:valerion/features/home/utils/arc_translator.dart';")) {
  dvc = "import 'package:valerion/features/home/utils/arc_translator.dart';\n" + dvc;
}
dvc = dvc.replace(/_buildOfflinePlaceholder\(currentArc, "SIGNAL PERDU", "La transmission Alpha est actuellement hors-ligne."\)/, 
                  '_buildOfflinePlaceholder(context, currentArc, "SIGNAL PERDU", "La transmission Alpha est actuellement hors-ligne.")');
dvc = dvc.replace(/_buildOfflinePlaceholder\(currentArc, "SIGNAL FAIBLE", "En attente du prochain briefing tactique..."\)/, 
                  '_buildOfflinePlaceholder(context, currentArc, "SIGNAL FAIBLE", "En attente du prochain briefing tactique...")');
dvc = dvc.replace(/_buildOfflinePlaceholder\(\s*currentArc,\s*"ERREUR SYSTÈME",/g, 
                  '_buildOfflinePlaceholder(context, currentArc, "ERREUR SYSTÈME",');
dvc = dvc.replace(/Widget _buildOfflinePlaceholder\(ArcData arc, String title, String message\)/, 
                  'Widget _buildOfflinePlaceholder(BuildContext context, ArcData arc, String title, String message)');
dvc = dvc.replace(/Text\(\s*title,\s*style/g, 'Text(\n            ArcTranslator.translate(context, title),\n            style');
dvc = dvc.replace(/Text\(\s*message,\s*textAlign/g, 'Text(\n            ArcTranslator.translate(context, message),\n            textAlign');
fs.writeFileSync(dvcPath, dvc);

console.log('Arc and video card translations fixed.');

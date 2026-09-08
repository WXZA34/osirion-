const fs = require('fs');

// 1. Create SmartTriggerTranslator
const translatorCode = `import 'package:flutter/material.dart';

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
`;
fs.writeFileSync('lib/features/home/utils/smart_trigger_translator.dart', translatorCode);

// 2. Fix DailyPulse
let dpPath = 'lib/features/home/widgets/daily_pulse.dart';
let dp = fs.readFileSync(dpPath, 'utf8');
if (!dp.includes("import '../../../l10n/app_localizations.dart';")) {
  dp = "import '../../../l10n/app_localizations.dart';\n" + dp;
}
dp = dp.replace(/"PULSE QUOTIDIEN"/g, 'AppLocalizations.of(context)!.homePulseQuotidien');
fs.writeFileSync(dpPath, dp);

// 3. Fix SmartTrigger widget
let stPath = 'lib/features/home/widgets/smart_trigger.dart';
let st = fs.readFileSync(stPath, 'utf8');
if (!st.includes("import 'package:valerion/features/home/utils/smart_trigger_translator.dart';")) {
  st = "import 'package:valerion/features/home/utils/smart_trigger_translator.dart';\n" + st;
}
st = st.replace(/"ALERTE - "/g, 'Localizations.localeOf(context).languageCode == "en" ? "ALERT - " : "ALERTE - "');

// We have to be careful with text replacements for title and subtitle
st = st.replace(/Text\(\s*data\.title,\s*style:/, 'Text(SmartTriggerTranslator.translateTitle(context, data.title), style:');
st = st.replace(/Text\(\s*data\.subtitle,\s*style:/, 'Text(SmartTriggerTranslator.translateSubtitle(context, data.subtitle), style:');

fs.writeFileSync(stPath, st);
console.log('Missing translations fixed.');

const fs = require('fs');

// Fix daily_pulse.dart
let dpPath = 'lib/features/home/widgets/daily_pulse.dart';
let dp = fs.readFileSync(dpPath, 'utf8');
dp = dp.replace("import 'package:valerion/core/providers/arc_provider.dart';", 
                "import 'package:valerion/core/providers/arc_provider.dart';\nimport 'package:valerion/features/home/utils/quest_translator.dart';");
dp = dp.replace(/Text\(\s*quest\.title,\s*style/g, "Text(\n                    QuestTranslator.translateTitle(context, quest.title),\n                    style");
dp = dp.replace(/Text\(\s*quest\.desc,\s*style/g, "Text(\n                    QuestTranslator.translateDesc(context, quest.desc),\n                    style");
fs.writeFileSync(dpPath, dp);

// Fix home_screen.dart drawer
let hsPath = 'lib/features/home/home_screen.dart';
let hs = fs.readFileSync(hsPath, 'utf8');
hs = hs.replace(/"La Bibliothèque"/g, 'AppLocalizations.of(context)!.localeName == "en" ? "The Library" : "La Bibliothèque"');
hs = hs.replace(/"Le Sanctuaire"/g, 'AppLocalizations.of(context)!.localeName == "en" ? "The Sanctuary" : "Le Sanctuaire"');
hs = hs.replace(/"Le Panthéon"/g, 'AppLocalizations.of(context)!.localeName == "en" ? "The Pantheon" : "Le Panthéon"');
hs = hs.replace(/"L'Arsenal"/g, 'AppLocalizations.of(context)!.localeName == "en" ? "The Arsenal" : "L\'Arsenal"');
hs = hs.replace(/"Le Laboratoire"/g, 'AppLocalizations.of(context)!.localeName == "en" ? "The Laboratory" : "Le Laboratoire"');
fs.writeFileSync(hsPath, hs);

console.log("Done!");

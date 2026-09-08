const fs = require('fs');

function replaceFile(path, replacer) {
  let c = fs.readFileSync(path, 'utf8');
  let init = c;
  
  if (!c.includes("import 'package:valerion/l10n/app_localizations.dart';") && 
      !c.includes("import '../../l10n/app_localizations.dart';") &&
      !c.includes("import '../../../l10n/app_localizations.dart';")) {
    // try adding it if AppLocalizations is used
  }

  c = replacer(c);
  if (c !== init) {
    fs.writeFileSync(path, c);
    console.log('Updated ' + path);
  }
}

// 1. arena_active_screen.dart
replaceFile('lib/features/arena/arena_active_screen.dart', (c) => {
  if (!c.includes('app_localizations.dart')) {
    c = c.replace("import 'package:flutter/material.dart';", "import 'package:flutter/material.dart';\nimport 'package:valerion/l10n/app_localizations.dart';");
  }
  return c.replace('const Text("RETOUR",', 'Text(AppLocalizations.of(context)!.commonReturn,');
});

// 2. arena_report_screen.dart
replaceFile('lib/features/arena/arena_report_screen.dart', (c) => {
  if (!c.includes('app_localizations.dart')) {
    c = c.replace("import 'package:flutter/material.dart';", "import 'package:flutter/material.dart';\nimport 'package:valerion/l10n/app_localizations.dart';");
  }
  c = c.replace('Text("IGNORER",', 'Text(AppLocalizations.of(context)!.commonSkip,');
  c = c.replace('Text("ERREUR DE GRAVURE : $e")', 'Text("${AppLocalizations.of(context)!.commonErrorSimple} $e")');
  return c;
});

// 3. arena_screen.dart
replaceFile('lib/features/arena/arena_screen.dart', (c) => {
  if (!c.includes('app_localizations.dart')) {
    c = c.replace("import 'package:flutter/material.dart';", "import 'package:flutter/material.dart';\nimport 'package:valerion/l10n/app_localizations.dart';");
  }
  c = c.replace('Tab(text: "FORGE", icon: Icon(Icons.flash_on, size: 22))', 'Tab(text: AppLocalizations.of(context)!.arenaForge, icon: const Icon(Icons.flash_on, size: 22))');
  c = c.replace('Tab(text: "ZONES", icon: Icon(Icons.grid_view, size: 22))', 'Tab(text: AppLocalizations.of(context)!.arenaZones, icon: const Icon(Icons.grid_view, size: 22))');
  c = c.replace('Tab(text: "SPOTS", icon: Icon(Icons.location_on, size: 22))', 'Tab(text: AppLocalizations.of(context)!.arenaSpots, icon: const Icon(Icons.location_on, size: 22))');
  c = c.replace('Tab(text: "RIVAUX", icon: Icon(Icons.groups, size: 22))', 'Tab(text: AppLocalizations.of(context)!.arenaRivaux, icon: const Icon(Icons.groups, size: 22))');
  return c;
});

// 4. share_selection_dialog.dart
replaceFile('lib/features/arena/widgets/share_selection_dialog.dart', (c) => {
  c = c.replace('const _SectionHeader(title: "RÉSEAU ATHLÈTES")', '_SectionHeader(title: AppLocalizations.of(context)!.arenaRSeauAthlTes)');
  c = c.replace('const _SectionHeader(title: "ÉQUIPES & CLUBS")', '_SectionHeader(title: AppLocalizations.of(context)!.arenaQuipesClubs)');
  c = c.replace('const Text("ANNULER",', 'Text(AppLocalizations.of(context)!.commonCancel,');
  c = c.replace('const Text("PARTAGER",', 'Text(AppLocalizations.of(context)!.commonShare,');
  c = c.replace('Text("Erreur: $e",', 'Text("${AppLocalizations.of(context)!.commonErrorSimple} $e",');
  c = c.replace('Text("Erreur lors de la transmission : $e")', 'Text("${AppLocalizations.of(context)!.commonErrorSimple} $e")');
  c = c.replace('const _EmptyList(message: "Aucun disciple trouvé.")', '_EmptyList(message: AppLocalizations.of(context)!.arenaAucunDiscipleTrouve)');
  c = c.replace('const _EmptyList(message: "Aucune faction rejointe.")', '_EmptyList(message: AppLocalizations.of(context)!.arenaAucuneFactionRejointe)');
  return c;
});

// 5. colosseum_tab.dart
replaceFile('lib/features/arena/tabs/colosseum_tab.dart', (c) => {
  if (!c.includes('app_localizations.dart')) {
    c = c.replace("import 'package:flutter/material.dart';", "import 'package:flutter/material.dart';\nimport 'package:valerion/l10n/app_localizations.dart';");
  }
  c = c.replace('Text("Erreur : $e",', 'Text("${AppLocalizations.of(context)!.commonErrorSimple} $e",');
  return c;
});

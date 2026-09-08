const fs = require('fs');

let c = fs.readFileSync('lib/features/arena/arena_screen.dart', 'utf8');

// Add import if needed
if (!c.includes('app_localizations.dart')) {
  c = "import '../../l10n/app_localizations.dart';\n" + c;
}

// Replace title
c = c.replace('"L\'AR^NE"', 'AppLocalizations.of(context)!.arenaLArNe');
c = c.replace('"L\'ARÊNE"', 'AppLocalizations.of(context)!.arenaLArNe');
c = c.replace('"L\'ARENE"', 'AppLocalizations.of(context)!.arenaLArNe');

// Replace tabs
c = c.replace('tabs: const [', 'tabs: [');

c = c.replace('Tab(text: "FORGE", icon: Icon(Icons.flash_on, size: 22))', 'Tab(text: AppLocalizations.of(context)!.arenaForge, icon: const Icon(Icons.flash_on, size: 22))');
c = c.replace('Tab(text: "ZONES", icon: Icon(Icons.grid_view, size: 22))', 'Tab(text: AppLocalizations.of(context)!.arenaZones, icon: const Icon(Icons.grid_view, size: 22))');
c = c.replace('Tab(text: "SPOTS", icon: Icon(Icons.location_on, size: 22))', 'Tab(text: AppLocalizations.of(context)!.arenaSpots, icon: const Icon(Icons.location_on, size: 22))');
c = c.replace('Tab(text: "RIVAUX", icon: Icon(Icons.groups, size: 22))', 'Tab(text: AppLocalizations.of(context)!.arenaRivaux, icon: const Icon(Icons.groups, size: 22))');

fs.writeFileSync('lib/features/arena/arena_screen.dart', c);
console.log('Fixed arena_screen.dart');

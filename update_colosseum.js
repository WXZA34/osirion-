const fs = require('fs');

let c = fs.readFileSync('lib/features/arena/tabs/colosseum_tab.dart', 'utf8');

c = c.replace('"AUCUN TRACÉ DE $sportName GRAVÉ"', 'AppLocalizations.of(context)!.arenaAucunTraceDeGrave(sportName)');
c = c.replace('"PAR ${run.creatorPseudo.toUpperCase()}"', 'AppLocalizations.of(context)!.arenaParPrefix + run.creatorPseudo.toUpperCase()');
c = c.replace('"DÉFIER ${run.creatorPseudo.toUpperCase()}"', 'AppLocalizations.of(context)!.arenaDefierPrefix + run.creatorPseudo.toUpperCase()');
c = c.replace('"Distance"', 'AppLocalizations.of(context)!.commonDistanceTitle');
c = c.replace('"Record"', 'AppLocalizations.of(context)!.commonRecordTitle');

fs.writeFileSync('lib/features/arena/tabs/colosseum_tab.dart', c);

const fs = require('fs');
const file = 'lib/features/arena/tabs/colosseum_tab.dart';
let content = fs.readFileSync(file, 'utf8');

content = content.replace(/"AUCUN TRACÉ DE \$sportName GRAVÉ"/g, 'AppLocalizations.of(context)!.arenaAucunTraceDeGrave(sportName)');
content = content.replace(/"Soyez le premier à graver votre exploit !"/g, 'AppLocalizations.of(context)!.arenaSoyezLePremierGraver');

content = content.replace(/"PAR \$\{run\.creatorPseudo\.toUpperCase\(\)\}"/g, 'AppLocalizations.of(context)!.arenaParPrefix + run.creatorPseudo.toUpperCase()');
content = content.replace(/"MATCHMAKING GLOBAL ALPHA DISPONIBLE"/g, 'AppLocalizations.of(context)!.arenaMatchmakingGlobalAlphaDisponible');

content = content.replace(/"DÉFIER \$\{run\.creatorPseudo\.toUpperCase\(\)\}"/g, 'AppLocalizations.of(context)!.arenaDefierPrefix + run.creatorPseudo.toUpperCase()');
content = content.replace(/"Mode : Matchmaking Relatif Global"/g, 'AppLocalizations.of(context)!.arenaModeMatchmakingRelatifGlobal');
content = content.replace(/"Vous allez affronter le fantôme de ce coureur sur votre propre terrain."/g, 'AppLocalizations.of(context)!.arenaVousAllezAffronterLe');

content = content.replace(/"Distance"/g, 'AppLocalizations.of(context)!.commonDistanceTitle');
content = content.replace(/"Record"/g, 'AppLocalizations.of(context)!.commonRecordTitle');

content = content.replace(/"ANNULER"/g, 'AppLocalizations.of(context)!.commonCancel');
content = content.replace(/"LANCER LE DUEL"/g, 'AppLocalizations.of(context)!.arenaLancerLeDuel');

fs.writeFileSync(file, content);

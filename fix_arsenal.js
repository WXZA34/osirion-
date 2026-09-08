const fs = require('fs');
const file = 'lib/features/arsenal/arsenal_screen.dart';
let content = fs.readFileSync(file, 'utf8');

content = content.replace(/"Débloqué au Niveau \$\{titleRelic.requiredLevel\}"/g, 'AppLocalizations.of(context)!.arsenalUnlockedAtLevel(titleRelic.requiredLevel)');
content = content.replace(/Text\(isEquipped \? "ÉQUIPÉ" : "ÉQUIPER"\)/g, 'Text(isEquipped ? AppLocalizations.of(context)!.arsenalEquipped : AppLocalizations.of(context)!.arsenalEquip)');
content = content.replace(/"Le Forgeron"/g, 'AppLocalizations.of(context)!.arsenalTheBlacksmith');
content = content.replace(/"Grades"/g, 'AppLocalizations.of(context)!.arsenalRanks');
content = content.replace(/"Mes Reliques"/g, 'AppLocalizations.of(context)!.arsenalMyRelics');
content = content.replace(/"Type: \$\{relic.type.toUpperCase\(\)\}"/g, '\"${AppLocalizations.of(context)!.arsenalTypePrefix}: ${relic.type.toUpperCase()}\"');
content = content.replace(/"Échanger \$\{relic.cost\} Aether contre '\$\{relic.name\}' \?"/g, 'AppLocalizations.of(context)!.arsenalExchangeAetherFor(relic.cost.toString(), relic.name)');
content = content.replace(/"Refuser"/g, 'AppLocalizations.of(context)!.commonRefuse');
content = content.replace(/"Relique acquise : \$\{relic.name\}"/g, 'AppLocalizations.of(context)!.arsenalRelicAcquired(relic.name)');
content = content.replace(/"CONSOMMABLE"/g, 'AppLocalizations.of(context)!.arsenalConsumable');
content = content.replace(/"\$\{relic.name\} équipé avec succès !"/g, 'AppLocalizations.of(context)!.arsenalEquippedSuccess(relic.name)');
content = content.replace(/"\$\{relic.name\} déséquipé."/g, 'AppLocalizations.of(context)!.arsenalUnequipped(relic.name)');
content = content.replace(/"Erreur d'équipement : \$e"/g, 'AppLocalizations.of(context)!.arsenalEquipError(e.toString())');

fs.writeFileSync(file, content);

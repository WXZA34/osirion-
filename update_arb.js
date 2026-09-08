const fs = require('fs');

function addKey(file, key, value) {
  let content = fs.readFileSync(file, 'utf8');
  let obj = JSON.parse(content);
  obj[key] = value;
  fs.writeFileSync(file, JSON.stringify(obj, null, 2));
}

addKey('lib/l10n/app_en.arb', 'arenaParcoursDePrefix', 'Route of ');
addKey('lib/l10n/app_fr.arb', 'arenaParcoursDePrefix', 'Parcours de ');

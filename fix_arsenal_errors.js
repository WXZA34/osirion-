const fs = require('fs');
const file = 'lib/features/arsenal/arsenal_screen.dart';
let content = fs.readFileSync(file, 'utf8');

// Fix nullable int issue
content = content.replace(
  /arsenalUnlockedAtLevel\(titleRelic\.requiredLevel\)/g,
  'arsenalUnlockedAtLevel(titleRelic.requiredLevel ?? 0)'
);

// Fix const keyword issue for CONSUMABLE
content = content.replace(
  /const Text\(\n?\s*AppLocalizations\.of\(context\)!\.arsenalConsumable/g,
  'Text(AppLocalizations.of(context)!.arsenalConsumable'
);
// In case it's on the same line
content = content.replace(
  /const Text\(AppLocalizations\.of\(context\)!\.arsenalConsumable/g,
  'Text(AppLocalizations.of(context)!.arsenalConsumable'
);

fs.writeFileSync(file, content);

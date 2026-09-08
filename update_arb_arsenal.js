const fs = require('fs'); 
const enPath = 'lib/l10n/app_en.arb'; 
const frPath = 'lib/l10n/app_fr.arb'; 
let en = JSON.parse(fs.readFileSync(enPath, 'utf8')); 
let fr = JSON.parse(fs.readFileSync(frPath, 'utf8')); 

en.arsenalUnlockedAtLevel = 'Unlocked at Level {level}';
en['@arsenalUnlockedAtLevel'] = { placeholders: { level: { type: 'int' } } };
fr.arsenalUnlockedAtLevel = 'Débloqué au Niveau {level}';
fr['@arsenalUnlockedAtLevel'] = { placeholders: { level: { type: 'int' } } };

en.arsenalEquipped = 'EQUIPPED';
fr.arsenalEquipped = 'ÉQUIPÉ';

en.arsenalEquip = 'EQUIP';
fr.arsenalEquip = 'ÉQUIPER';

en.arsenalTheBlacksmith = 'The Blacksmith';
fr.arsenalTheBlacksmith = 'Le Forgeron';

en.arsenalRanks = 'Ranks';
fr.arsenalRanks = 'Grades';

en.arsenalMyRelics = 'My Relics';
fr.arsenalMyRelics = 'Mes Reliques';

en.arsenalTypePrefix = 'Type';
fr.arsenalTypePrefix = 'Type';

en.arsenalExchangeAetherFor = 'Exchange {cost} Aether for \'{name}\'?';
en['@arsenalExchangeAetherFor'] = { placeholders: { cost: { type: 'String' }, name: { type: 'String' } } };
fr.arsenalExchangeAetherFor = 'Échanger {cost} Aether contre \'{name}\' ?';
fr['@arsenalExchangeAetherFor'] = { placeholders: { cost: { type: 'String' }, name: { type: 'String' } } };

en.commonRefuse = 'Decline';
fr.commonRefuse = 'Refuser';

en.arsenalRelicAcquired = 'Relic acquired: {name}';
en['@arsenalRelicAcquired'] = { placeholders: { name: { type: 'String' } } };
fr.arsenalRelicAcquired = 'Relique acquise : {name}';
fr['@arsenalRelicAcquired'] = { placeholders: { name: { type: 'String' } } };

en.arsenalConsumable = 'CONSUMABLE';
fr.arsenalConsumable = 'CONSOMMABLE';

en.arsenalEquippedSuccess = '{name} successfully equipped!';
en['@arsenalEquippedSuccess'] = { placeholders: { name: { type: 'String' } } };
fr.arsenalEquippedSuccess = '{name} équipé avec succès !';
fr['@arsenalEquippedSuccess'] = { placeholders: { name: { type: 'String' } } };

en.arsenalUnequipped = '{name} unequipped.';
en['@arsenalUnequipped'] = { placeholders: { name: { type: 'String' } } };
fr.arsenalUnequipped = '{name} déséquipé.';
fr['@arsenalUnequipped'] = { placeholders: { name: { type: 'String' } } };

en.arsenalEquipError = 'Equip error: {error}';
en['@arsenalEquipError'] = { placeholders: { error: { type: 'String' } } };
fr.arsenalEquipError = 'Erreur d\'équipement : {error}';
fr['@arsenalEquipError'] = { placeholders: { error: { type: 'String' } } };

fs.writeFileSync(enPath, JSON.stringify(en, null, 2)); 
fs.writeFileSync(frPath, JSON.stringify(fr, null, 2)); 
console.log('Updated ARB files');

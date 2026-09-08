const fs = require('fs');

let translator = fs.readFileSync('lib/features/dojo/utils/dojo_translator.dart', 'utf8');

const missingNamesMap = {
  "Dips aux anneaux ou Dips bulgares": "Ring dips or Bulgarian dips",
  "Pompes Pseudo-Planche": "Pseudo-Planche Push-ups",
  "Dips sur banc": "Bench dips",
  "Glute Bridge unilatéral": "Unilateral Glute Bridge",
  "Step-ups explosifs": "Explosive step-ups",
  "Crunches classiques au sol": "Classic crunches",
  "Bicyclette": "Bicycle crunches",
  "Gainage coudes": "Elbow plank",
  "Jackknives assis sur un banc de parc": "Seated jackknives on a park bench",
  "Chaise contre un poteau ou muret": "Wall sit against a pole or wall",
  "Pont": "Bridge",
  "Maintien de fausse prise": "False grip hold",
  "Élévations de mollets unilatérales": "Unilateral calf raises",
  "Pompes au mur": "Wall push-ups",
  "Tractions australiennes très inclinées": "Very inclined Australian pull-ups",
  "Step-ups très lents et sans élan sur un tout petit trottoir": "Very slow step-ups on a curb",
  "Balanciers de jambe": "Leg swings",
  "Rotations du buste debout": "Standing torso rotations",
  "Flexions/extensions de poignets dans le vide": "Empty wrist flexions/extensions"
};

const missingDescsMap = {
  "Tuck planche, Straddle ou Full": "Tuck planche, Straddle or Full",
  "Handstand push-ups - HSPU": "Handstand push-ups - HSPU",
  "Drapeau": "Flag",
  "HSPU": "HSPU",
  "Bench dips": "Bench dips",
  "maintien isométrique au sol ou sur parallettes": "isometric hold on floor or parallettes",
  "Relevés de genoux obliques à la barre, avec pause": "Oblique knee raises on bar, with pause",
  "Gainage cuillère, bas du dos plaqué, maintien long": "Hollow body hold, lower back flat, long hold",
  "Petits battements en position de Dragon Flag": "Small flutters in Dragon Flag position",
  "engage massivement les lombaires et la ceinture abdo": "massively engages lower back and core",
  "Bicycle crunches": "Bicycle crunches",
  "Planche - tenir le temps maximum": "Plank - hold for max time",
  "genou vers coude opposé": "knee to opposite elbow",
  "Portefeuille rapide": "Fast V-ups",
  "Battements de jambes au sol, ras de l'herbe": "Flutter kicks on ground",
  "sans poids, focus sur la vitesse de rotation": "no weight, focus on rotation speed",
  "Knee raises, rythme rapide": "Knee raises, fast pace",
  "Tractions scapulaires, bras tendus, haussements d'épaules": "Scapular pull-ups, straight arms, shrugs",
  "Pompes scapulaires au sol": "Scapular push-ups on floor",
  "étirement actif des pecs/épaules": "active stretch for pecs/shoulders",
  "Lock-off": "Lock-off",
  "Wall sit": "Wall sit",
  "Bridge hold": "Bridge hold",
  "False grip": "False grip",
  "Pompes sur les poignets ou dos des mains, sur les genoux": "Wrist push-ups on knees",
  "maintien de 10 sec en contraction maximale": "10 sec hold in max contraction",
  "suspension inversée aux anneaux/barre, étirement actif des épaules": "inverted hang on rings/bar, active shoulder stretch",
  "genou arrière à 1 cm du sol": "back knee 1 cm from ground",
  "Star plank": "Star plank",
  "Suspension passive à la barre - le plus longtemps possible pour décompresser": "Passive bar hang - as long as possible to decompress",
  "Wall push-ups - séries très longues, effort minime": "Wall push-ups - very long sets, minimal effort",
  "Arm circles à vide - séries de 100": "Empty arm circles - sets of 100",
  "presque debout, tirages légers": "almost standing, light pulls",
  "Leg swings avant/arrière et latéraux pour la hanche": "Leg swings forward/back and lateral for hips",
  "Twists légers": "Light twists",
  "pour les avant-bras": "for forearms",
  "moulinage très rapide et léger": "very fast and light circling",
  "Dos rond / Dos creux au sol sur l'herbe": "Cat-cow on the grass",
  "sans poids, focus sur le mouvement": "no weight, focus on movement",
  "Flow, déliement articulaire": "Flow, joint mobility"
};

let caseStatements = "";
for (const [k, v] of Object.entries(missingNamesMap)) {
  caseStatements += `      case "${k}": return "${v}";\n`;
}
// Insert cases before 'default:' in translate
translator = translator.replace('// Fallback', caseStatements + '\n      // Fallback');

let ifStatements = "";
for (const [k, v] of Object.entries(missingDescsMap)) {
  ifStatements += `    if (text == "${k}") return "${v}";\n`;
}
// Insert ifs at the end of translateDescription
translator = translator.replace('return text;\n  }\n}', ifStatements + '    return text;\n  }\n}');

fs.writeFileSync('lib/features/dojo/utils/dojo_translator.dart', translator);
console.log('Translator updated.');

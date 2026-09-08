const fs = require('fs');

function replaceAll(str, search, replacement) {
  return str.split(search).join(replacement);
}

function replaceFile(path, replacer) {
  let c = fs.readFileSync(path, 'utf8');
  let init = c;
  
  if (!c.includes("import 'package:valerion/l10n/app_localizations.dart';") && 
      !c.includes("import '../../l10n/app_localizations.dart';") &&
      !c.includes("import '../../../l10n/app_localizations.dart';")) {
    c = c.replace("import 'package:flutter/material.dart';", "import 'package:flutter/material.dart';\nimport 'package:valerion/l10n/app_localizations.dart';");
  }

  c = replacer(c);
  if (c !== init) {
    fs.writeFileSync(path, c);
    console.log('Updated ' + path);
  }
}

// 1. performance_card.dart
replaceFile('lib/features/arena/widgets/performance_card.dart', (c) => {
  c = replaceAll(c, '"DISTANCE"', 'AppLocalizations.of(context)!.commonDistanceCaps');
  c = replaceAll(c, '"TEMPS"', 'AppLocalizations.of(context)!.commonTempsCaps');
  c = replaceAll(c, '"VITESSE MOY."', 'AppLocalizations.of(context)!.commonVitesseMoyCaps');
  c = replaceAll(c, '"PRECISION IA"', 'AppLocalizations.of(context)!.arenaPrecisionIa');
  c = replaceAll(c, '"FORCE"', 'AppLocalizations.of(context)!.arenaForce');
  c = replaceAll(c, '"SAGESSE"', 'AppLocalizations.of(context)!.arenaSagesse');
  c = replaceAll(c, '"AETHER"', 'AppLocalizations.of(context)!.arenaAether');
  return c;
});

// 2. arena_active_screen.dart (might have some)
replaceFile('lib/features/arena/arena_active_screen.dart', (c) => {
  c = replaceAll(c, 'Text("GÉNÉRATION EN COURS..."', 'Text(AppLocalizations.of(context)!.arenaGenerationEnCours');
  return c;
});

// 3. forge_tab.dart
replaceFile('lib/features/arena/tabs/forge_tab.dart', (c) => {
  c = replaceAll(c, '"1. DISCIPLINE"', 'AppLocalizations.of(context)!.arenaForgeDiscipline');
  c = replaceAll(c, '"Course"', 'AppLocalizations.of(context)!.commonCourse');
  c = replaceAll(c, '"Marche"', 'AppLocalizations.of(context)!.commonMarche');
  c = replaceAll(c, '"Vélo"', 'AppLocalizations.of(context)!.commonVelo');
  c = replaceAll(c, '"2. DÉNIVELÉ"', 'AppLocalizations.of(context)!.arenaForgeDenivele');
  c = replaceAll(c, '"Plat"', 'AppLocalizations.of(context)!.arenaForgePlat');
  c = replaceAll(c, '"Vallonné"', 'AppLocalizations.of(context)!.arenaForgeVallonne');
  c = replaceAll(c, '"3. DISTANCE (BOUCLE IA)"', 'AppLocalizations.of(context)!.arenaForgeDistanceBoucle');
  c = replaceAll(c, '"GÉNÉRER MA PERFORMANCE CARD"', 'AppLocalizations.of(context)!.arenaGenererPerformanceCard');
  return c;
});

// 4. colosseum_tab.dart
replaceFile('lib/features/arena/tabs/colosseum_tab.dart', (c) => {
  c = replaceAll(c, '"COURSE"', 'AppLocalizations.of(context)!.commonCourse.toUpperCase()');
  c = replaceAll(c, '"MARCHE"', 'AppLocalizations.of(context)!.commonMarche.toUpperCase()');
  c = replaceAll(c, '"VÉLO"', 'AppLocalizations.of(context)!.commonVelo.toUpperCase()');
  c = replaceAll(c, 'Text("AUCUN TRACÉ DE $sportName GRAVÉ"', 'Text(AppLocalizations.of(context)!.arenaAucunTraceDeGrave(sportName)');
  c = replaceAll(c, '"PAR ${run.creatorPseudo.toUpperCase()}"', 'AppLocalizations.of(context)!.arenaParPrefix + run.creatorPseudo.toUpperCase()');
  c = replaceAll(c, '"DÉFIER ${run.creatorPseudo.toUpperCase()}"', 'AppLocalizations.of(context)!.arenaDefierPrefix + run.creatorPseudo.toUpperCase()');
  c = replaceAll(c, '"Distance"', 'AppLocalizations.of(context)!.commonDistanceTitle');
  c = replaceAll(c, '"Record"', 'AppLocalizations.of(context)!.commonRecordTitle');
  c = replaceAll(c, '"ANNULER"', 'AppLocalizations.of(context)!.commonCancel');
  return c;
});

// 5. bastions_tab.dart
replaceFile('lib/features/arena/tabs/bastions_tab.dart', (c) => {
  c = replaceAll(c, '"TRACTIONS"', 'AppLocalizations.of(context)!.arenaTractions');
  c = replaceAll(c, '"DIPS"', 'AppLocalizations.of(context)!.arenaDips');
  c = replaceAll(c, '"POMPES"', 'AppLocalizations.of(context)!.arenaPompes');
  c = replaceAll(c, '"ABDOS"', 'AppLocalizations.of(context)!.arenaAbdos');
  
  c = replaceAll(c, '"ANNULER"', 'AppLocalizations.of(context)!.commonCancel');
  
  c = replaceAll(c, '"ERREUR DE TRANSMISSION."', 'AppLocalizations.of(context)!.arenaErreurTransmission');
  c = replaceAll(c, '"ÉCHEC : SIGNAL GPS DÉGRADÉ OU TROP LOIN DU SPOT."', 'AppLocalizations.of(context)!.arenaEchecSignalGps');
  
  c = replaceAll(c, '"LE PLUS PROCHE : ${_formatDistance(_spots.first.position)}"', 'AppLocalizations.of(context)!.arenaLePlusProche + _formatDistance(_spots.first.position)');
  c = replaceAll(c, '"SCAN DES STATIONS À PROXIMITÉ"', 'AppLocalizations.of(context)!.arenaScanDesStations');
  c = replaceAll(c, 'ESTIMATION: ', '${AppLocalizations.of(context)!.arenaEstimation}');
  c = replaceAll(c, '"BOSS: ${currentBoss.pseudo.toUpperCase()}"', 'AppLocalizations.of(context)!.arenaBossPrefix + currentBoss.pseudo.toUpperCase()');
  c = replaceAll(c, '"ZONE VIERGE"', 'AppLocalizations.of(context)!.arenaZoneVierge');
  c = replaceAll(c, '"RÈGNE DEPUIS: ${_getReignTime(currentBoss.achievedAt)}"', 'AppLocalizations.of(context)!.arenaRegneDepuis + _getReignTime(currentBoss.achievedAt)');
  c = replaceAll(c, '" REPS"', 'AppLocalizations.of(context)!.arenaRepsSuffix');
  c = replaceAll(c, '"⚠️ RENSEIGNEMENT : ${spot.failedAttemptsCount} JOUEURS ONT ÉCHOUÉ CETTE SEMAINE"', 'AppLocalizations.of(context)!.arenaRenseignementEchecs(spot.failedAttemptsCount.toString())');
  c = replaceAll(c, '"📝 BRIEFING TACTIQUE (OSM) : ${spot.osmNote!.toUpperCase()}"', 'AppLocalizations.of(context)!.arenaBriefingTactiquePrefix + spot.osmNote!.toUpperCase()');
  
  c = replaceAll(c, '"INFO"', 'AppLocalizations.of(context)!.arenaInfo');
  c = replaceAll(c, '"TRACER"', 'AppLocalizations.of(context)!.arenaTracer');
  c = replaceAll(c, '"DÉFI"', 'AppLocalizations.of(context)!.arenaDefiAction');
  
  c = replaceAll(c, '"MOINS D\'UNE MINUTE"', 'AppLocalizations.of(context)!.arenaMoinsDuneMinute');
  c = replaceAll(c, '"ENV. $minutes MIN"', 'AppLocalizations.of(context)!.arenaEnvMinutes(minutes.toString())');
  c = replaceAll(c, '" JOURS"', 'AppLocalizations.of(context)!.arenaJoursSuffix');
  c = replaceAll(c, '" HEURES"', 'AppLocalizations.of(context)!.arenaHeuresSuffix');
  c = replaceAll(c, '"RÉCENT"', 'AppLocalizations.of(context)!.arenaRecent');
  
  c = replaceAll(c, '"TRANSMETTRE LE RENSEIGNEMENT (+250 XP)"', 'AppLocalizations.of(context)!.arenaTransmettreRenseignement');
  c = replaceAll(c, '"COMPLÉTER LE RENSEIGNEMENT (${spot.images.length}/4)"', 'AppLocalizations.of(context)!.arenaCompleterRenseignement(spot.images.length.toString())');
  c = replaceAll(c, '"ARSENAL TACTIQUE"', 'AppLocalizations.of(context)!.arenaArsenalTactique');
  c = replaceAll(c, '"RENSEIGNEMENT ALPHA"', 'AppLocalizations.of(context)!.arenaRenseignementAlpha');
  c = replaceAll(c, '"Boss Actuel"', 'AppLocalizations.of(context)!.arenaBossActuel');
  c = replaceAll(c, '"INCONNU"', 'AppLocalizations.of(context)!.arenaInconnuCaps');
  c = replaceAll(c, '"Record d\'Effort"', 'AppLocalizations.of(context)!.arenaRecordEffort');
  c = replaceAll(c, '"Temps de Règne"', 'AppLocalizations.of(context)!.arenaTempsDeRegne');
  c = replaceAll(c, '"Échecs récents"', 'AppLocalizations.of(context)!.arenaEchecsRecents');
  c = replaceAll(c, '" TENTATIVES"', 'AppLocalizations.of(context)!.arenaTentativesSuffix');
  c = replaceAll(c, '"BRIEFING TACTIQUE (OSM)"', 'AppLocalizations.of(context)!.arenaBriefingTactiqueSansIcone');
  c = replaceAll(c, '"COORDONNÉES DE MISSION"', 'AppLocalizations.of(context)!.arenaCoordonneesMission');
  c = replaceAll(c, '"Quartier"', 'AppLocalizations.of(context)!.arenaQuartier');
  c = replaceAll(c, '"Inconnu"', 'AppLocalizations.of(context)!.arenaInconnuCamel');
  c = replaceAll(c, '"Latitude"', 'AppLocalizations.of(context)!.arenaLatitude');
  c = replaceAll(c, '"Longitude"', 'AppLocalizations.of(context)!.arenaLongitude');
  
  c = replaceAll(c, '"DÉFI : ${spot.name}"', 'AppLocalizations.of(context)!.arenaDefiPrefix + spot.name');
  c = replaceAll(c, '"CONQUÊTE RÉUSSIE : $total REPS TOTALES ! VOUS ÊTES LE BOSS DE ${spot.name.toUpperCase()}."', 'AppLocalizations.of(context)!.arenaConqueteReussie(total.toString(), spot.name.toUpperCase())');
  
  return c;
});

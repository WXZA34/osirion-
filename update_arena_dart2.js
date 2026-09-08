const fs = require('fs');

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
  c = c.replace('"DISTANCE"', 'AppLocalizations.of(context)!.commonDistanceCaps');
  c = c.replace('"TEMPS"', 'AppLocalizations.of(context)!.commonTempsCaps');
  c = c.replace('"VITESSE MOY."', 'AppLocalizations.of(context)!.commonVitesseMoyCaps');
  c = c.replace('"PRECISION IA"', 'AppLocalizations.of(context)!.arenaPrecisionIa');
  c = c.replace('"FORCE"', 'AppLocalizations.of(context)!.arenaForce');
  c = c.replace('"SAGESSE"', 'AppLocalizations.of(context)!.arenaSagesse');
  c = c.replace('"AETHER"', 'AppLocalizations.of(context)!.arenaAether');
  return c;
});

// 2. arena_active_screen.dart (might have some)
replaceFile('lib/features/arena/arena_active_screen.dart', (c) => {
  c = c.replace('Text("GÉNÉRATION EN COURS..."', 'Text(AppLocalizations.of(context)!.arenaGenerationEnCours');
  return c;
});

// 3. forge_tab.dart
replaceFile('lib/features/arena/tabs/forge_tab.dart', (c) => {
  c = c.replace('"1. DISCIPLINE"', 'AppLocalizations.of(context)!.arenaForgeDiscipline');
  c = c.replace('"Course"', 'AppLocalizations.of(context)!.commonCourse');
  c = c.replace('"Marche"', 'AppLocalizations.of(context)!.commonMarche');
  c = c.replace('"Vélo"', 'AppLocalizations.of(context)!.commonVelo');
  c = c.replace('"2. DÉNIVELÉ"', 'AppLocalizations.of(context)!.arenaForgeDenivele');
  c = c.replace('"Plat"', 'AppLocalizations.of(context)!.arenaForgePlat');
  c = c.replace('"Vallonné"', 'AppLocalizations.of(context)!.arenaForgeVallonne');
  c = c.replace('"3. DISTANCE (BOUCLE IA)"', 'AppLocalizations.of(context)!.arenaForgeDistanceBoucle');
  c = c.replace('"GÉNÉRER MA PERFORMANCE CARD"', 'AppLocalizations.of(context)!.arenaGenererPerformanceCard');
  return c;
});

// 4. colosseum_tab.dart
replaceFile('lib/features/arena/tabs/colosseum_tab.dart', (c) => {
  c = c.replace('"COURSE"', 'AppLocalizations.of(context)!.commonCourse.toUpperCase()');
  c = c.replace('"MARCHE"', 'AppLocalizations.of(context)!.commonMarche.toUpperCase()');
  c = c.replace('"VÉLO"', 'AppLocalizations.of(context)!.commonVelo.toUpperCase()');
  c = c.replace('Text("AUCUN TRACÉ DE $sportName GRAVÉ"', 'Text(AppLocalizations.of(context)!.arenaAucunTraceDeGrave(sportName)');
  c = c.replace('"PAR ${run.creatorPseudo.toUpperCase()}"', 'AppLocalizations.of(context)!.arenaParPrefix + run.creatorPseudo.toUpperCase()');
  c = c.replace('"DÉFIER ${run.creatorPseudo.toUpperCase()}"', 'AppLocalizations.of(context)!.arenaDefierPrefix + run.creatorPseudo.toUpperCase()');
  c = c.replace('"Distance"', 'AppLocalizations.of(context)!.commonDistanceTitle');
  c = c.replace('"Record"', 'AppLocalizations.of(context)!.commonRecordTitle');
  return c;
});

// 5. bastions_tab.dart
replaceFile('lib/features/arena/tabs/bastions_tab.dart', (c) => {
  c = c.replace('"TRACTIONS"', 'AppLocalizations.of(context)!.arenaTractions');
  c = c.replace('"DIPS"', 'AppLocalizations.of(context)!.arenaDips');
  c = c.replace('"POMPES"', 'AppLocalizations.of(context)!.arenaPompes');
  c = c.replace('"ABDOS"', 'AppLocalizations.of(context)!.arenaAbdos');
  
  c = c.replace('"ANNULER"', 'AppLocalizations.of(context)!.commonCancel');
  
  c = c.replace('"ERREUR DE TRANSMISSION."', 'AppLocalizations.of(context)!.arenaErreurTransmission');
  c = c.replace('"ÉCHEC : SIGNAL GPS DÉGRADÉ OU TROP LOIN DU SPOT."', 'AppLocalizations.of(context)!.arenaEchecSignalGps');
  
  c = c.replace('"LE PLUS PROCHE : ${_formatDistance(_spots.first.position)}"', 'AppLocalizations.of(context)!.arenaLePlusProche + _formatDistance(_spots.first.position)');
  c = c.replace('"SCAN DES STATIONS À PROXIMITÉ"', 'AppLocalizations.of(context)!.arenaScanDesStations');
  c = c.replace('ESTIMATION: ', '${AppLocalizations.of(context)!.arenaEstimation}');
  c = c.replace('"BOSS: ${currentBoss.pseudo.toUpperCase()}"', 'AppLocalizations.of(context)!.arenaBossPrefix + currentBoss.pseudo.toUpperCase()');
  c = c.replace('"ZONE VIERGE"', 'AppLocalizations.of(context)!.arenaZoneVierge');
  c = c.replace('"RÈGNE DEPUIS: ${_getReignTime(currentBoss.achievedAt)}"', 'AppLocalizations.of(context)!.arenaRegneDepuis + _getReignTime(currentBoss.achievedAt)');
  c = c.replace('" REPS"', 'AppLocalizations.of(context)!.arenaRepsSuffix');
  c = c.replace('"⚠️ RENSEIGNEMENT : ${spot.failedAttemptsCount} JOUEURS ONT ÉCHOUÉ CETTE SEMAINE"', 'AppLocalizations.of(context)!.arenaRenseignementEchecs(spot.failedAttemptsCount.toString())');
  c = c.replace('"📝 BRIEFING TACTIQUE (OSM) : ${spot.osmNote!.toUpperCase()}"', 'AppLocalizations.of(context)!.arenaBriefingTactiquePrefix + spot.osmNote!.toUpperCase()');
  
  c = c.replace('"INFO"', 'AppLocalizations.of(context)!.arenaInfo');
  c = c.replace('"TRACER"', 'AppLocalizations.of(context)!.arenaTracer');
  c = c.replace('"DÉFI"', 'AppLocalizations.of(context)!.arenaDefiAction');
  
  c = c.replace('"MOINS D\'UNE MINUTE"', 'AppLocalizations.of(context)!.arenaMoinsDuneMinute');
  c = c.replace('"ENV. $minutes MIN"', 'AppLocalizations.of(context)!.arenaEnvMinutes(minutes.toString())');
  c = c.replace('" JOURS"', 'AppLocalizations.of(context)!.arenaJoursSuffix');
  c = c.replace('" HEURES"', 'AppLocalizations.of(context)!.arenaHeuresSuffix');
  c = c.replace('"RÉCENT"', 'AppLocalizations.of(context)!.arenaRecent');
  
  c = c.replace('"TRANSMETTRE LE RENSEIGNEMENT (+250 XP)"', 'AppLocalizations.of(context)!.arenaTransmettreRenseignement');
  c = c.replace('"COMPLÉTER LE RENSEIGNEMENT (${spot.images.length}/4)"', 'AppLocalizations.of(context)!.arenaCompleterRenseignement(spot.images.length.toString())');
  c = c.replace('"ARSENAL TACTIQUE"', 'AppLocalizations.of(context)!.arenaArsenalTactique');
  c = c.replace('"RENSEIGNEMENT ALPHA"', 'AppLocalizations.of(context)!.arenaRenseignementAlpha');
  c = c.replace('"Boss Actuel"', 'AppLocalizations.of(context)!.arenaBossActuel');
  c = c.replace('"INCONNU"', 'AppLocalizations.of(context)!.arenaInconnuCaps');
  c = c.replace('"Record d\'Effort"', 'AppLocalizations.of(context)!.arenaRecordEffort');
  c = c.replace('"Temps de Règne"', 'AppLocalizations.of(context)!.arenaTempsDeRegne');
  c = c.replace('"Échecs récents"', 'AppLocalizations.of(context)!.arenaEchecsRecents');
  c = c.replace('" TENTATIVES"', 'AppLocalizations.of(context)!.arenaTentativesSuffix');
  c = c.replace('"BRIEFING TACTIQUE (OSM)"', 'AppLocalizations.of(context)!.arenaBriefingTactiqueSansIcone');
  c = c.replace('"COORDONNÉES DE MISSION"', 'AppLocalizations.of(context)!.arenaCoordonneesMission');
  c = c.replace('"Quartier"', 'AppLocalizations.of(context)!.arenaQuartier');
  c = c.replace('"Inconnu"', 'AppLocalizations.of(context)!.arenaInconnuCamel');
  c = c.replace('"Latitude"', 'AppLocalizations.of(context)!.arenaLatitude');
  c = c.replace('"Longitude"', 'AppLocalizations.of(context)!.arenaLongitude');
  
  // Custom interpolations
  c = c.replace('"DÉFI : ${spot.name}"', 'AppLocalizations.of(context)!.arenaDefiPrefix + spot.name');
  c = c.replace('"CONQUÊTE RÉUSSIE : $total REPS TOTALES ! VOUS ÊTES LE BOSS DE ${spot.name.toUpperCase()}."', 'AppLocalizations.of(context)!.arenaConqueteReussie(total.toString(), spot.name.toUpperCase())');
  
  return c;
});

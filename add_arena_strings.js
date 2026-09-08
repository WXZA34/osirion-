const fs = require('fs');

let en = JSON.parse(fs.readFileSync('lib/l10n/app_en.arb'));
let fr = JSON.parse(fs.readFileSync('lib/l10n/app_fr.arb'));

const newStrings = {
  "arenaTractions": { fr: "TRACTIONS", en: "PULL-UPS" },
  "arenaDips": { fr: "DIPS", en: "DIPS" },
  "arenaPompes": { fr: "POMPES", en: "PUSH-UPS" },
  "arenaAbdos": { fr: "ABDOS", en: "SIT-UPS" },
  "arenaDefiPrefix": { fr: "DÉFI : ", en: "CHALLENGE: " },
  "arenaDefiAction": { fr: "DÉFI", en: "CHALLENGE" },
  "arenaErreurTransmission": { fr: "ERREUR DE TRANSMISSION.", en: "TRANSMISSION ERROR." },
  "arenaEchecSignalGps": { fr: "ÉCHEC : SIGNAL GPS DÉGRADÉ OU TROP LOIN DU SPOT.", en: "FAILED: POOR GPS SIGNAL OR TOO FAR FROM SPOT." },
  "arenaLePlusProche": { fr: "LE PLUS PROCHE : ", en: "CLOSEST: " },
  "arenaScanDesStations": { fr: "SCAN DES STATIONS À PROXIMITÉ", en: "SCANNING NEARBY STATIONS" },
  "arenaEstimation": { fr: "ESTIMATION: ", en: "ESTIMATED: " },
  "arenaBossPrefix": { fr: "BOSS: ", en: "BOSS: " },
  "arenaZoneVierge": { fr: "ZONE VIERGE", en: "UNCLAIMED ZONE" },
  "arenaRegneDepuis": { fr: "RÈGNE DEPUIS: ", en: "RULING SINCE: " },
  "arenaRepsSuffix": { fr: " REPS", en: " REPS" },
  "arenaBriefingTactiquePrefix": { fr: "📝 BRIEFING TACTIQUE (OSM) : ", en: "📝 TACTICAL BRIEFING (OSM): " },
  "arenaInfo": { fr: "INFO", en: "INFO" },
  "arenaTracer": { fr: "TRACER", en: "TRACK" },
  "arenaMoinsDuneMinute": { fr: "MOINS D'UNE MINUTE", en: "LESS THAN A MINUTE" },
  "arenaJoursSuffix": { fr: " JOURS", en: " DAYS" },
  "arenaHeuresSuffix": { fr: " HEURES", en: " HOURS" },
  "arenaRecent": { fr: "RÉCENT", en: "RECENT" },
  "arenaTransmettreRenseignement": { fr: "TRANSMETTRE LE RENSEIGNEMENT (+250 XP)", en: "TRANSMIT INTEL (+250 XP)" },
  "arenaArsenalTactique": { fr: "ARSENAL TACTIQUE", en: "TACTICAL ARSENAL" },
  "arenaRenseignementAlpha": { fr: "RENSEIGNEMENT ALPHA", en: "ALPHA INTEL" },
  "arenaBossActuel": { fr: "Boss Actuel", en: "Current Boss" },
  "arenaInconnuCaps": { fr: "INCONNU", en: "UNKNOWN" },
  "arenaInconnuCamel": { fr: "Inconnu", en: "Unknown" },
  "arenaRecordEffort": { fr: "Record d'Effort", en: "Effort Record" },
  "arenaTempsDeRegne": { fr: "Temps de Règne", en: "Reign Time" },
  "arenaEchecsRecents": { fr: "Échecs récents", en: "Recent Failures" },
  "arenaTentativesSuffix": { fr: " TENTATIVES", en: " ATTEMPTS" },
  "arenaBriefingTactiqueSansIcone": { fr: "BRIEFING TACTIQUE (OSM)", en: "TACTICAL BRIEFING (OSM)" },
  "arenaCoordonneesMission": { fr: "COORDONNÉES DE MISSION", en: "MISSION COORDINATES" },
  "arenaQuartier": { fr: "Quartier", en: "District" },
  "arenaLatitude": { fr: "Latitude", en: "Latitude" },
  "arenaLongitude": { fr: "Longitude", en: "Longitude" },
  "arenaForgeDiscipline": { fr: "1. DISCIPLINE", en: "1. DISCIPLINE" },
  "commonCourse": { fr: "Course", en: "Running" },
  "commonMarche": { fr: "Marche", en: "Walking" },
  "commonVelo": { fr: "Vélo", en: "Cycling" },
  "arenaForgeDenivele": { fr: "2. DÉNIVELÉ", en: "2. ELEVATION" },
  "arenaForgePlat": { fr: "Plat", en: "Flat" },
  "arenaForgeVallonne": { fr: "Vallonné", en: "Hilly" },
  "arenaForgeDistanceBoucle": { fr: "3. DISTANCE (BOUCLE IA)", en: "3. DISTANCE (AI LOOP)" },
  "arenaGenererPerformanceCard": { fr: "GÉNÉRER MA PERFORMANCE CARD", en: "GENERATE MY PERFORMANCE CARD" },
  "arenaParPrefix": { fr: "PAR ", en: "BY " },
  "arenaDefierPrefix": { fr: "DÉFIER ", en: "CHALLENGE " },
  "commonDistanceTitle": { fr: "Distance", en: "Distance" },
  "commonRecordTitle": { fr: "Record", en: "Record" },
  "commonTempsTitle": { fr: "Temps", en: "Time" },
  "commonVitesseMoy": { fr: "Vitesse Moy.", en: "Avg. Speed" },
  "commonVitesseMoyCaps": { fr: "VITESSE MOY.", en: "AVG. SPEED" },
  "commonDistanceCaps": { fr: "DISTANCE", en: "DISTANCE" },
  "commonTempsCaps": { fr: "TEMPS", en: "TIME" },
  "arenaPrecisionIa": { fr: "PRECISION IA", en: "AI PRECISION" },
  "arenaForce": { fr: "FORCE", en: "STRENGTH" },
  "arenaSagesse": { fr: "SAGESSE", en: "WISDOM" },
  "arenaAether": { fr: "AETHER", en: "AETHER" },
  "arenaGenerationEnCours": { fr: "GÉNÉRATION EN COURS...", en: "GENERATING..." }
};

for (const [key, val] of Object.entries(newStrings)) {
  en[key] = val.en;
  fr[key] = val.fr;
}

// Add strings with placeholders
en["arenaConqueteReussie"] = "CONQUEST SUCCESSFUL: {total} TOTAL REPS! YOU ARE THE BOSS OF {spotName}.";
en["@arenaConqueteReussie"] = {
  "placeholders": {
    "total": { "type": "String" },
    "spotName": { "type": "String" }
  }
};
fr["arenaConqueteReussie"] = "CONQUÊTE RÉUSSIE : {total} REPS TOTALES ! VOUS ÊTES LE BOSS DE {spotName}.";
fr["@arenaConqueteReussie"] = {
  "placeholders": {
    "total": { "type": "String" },
    "spotName": { "type": "String" }
  }
};

en["arenaRenseignementEchecs"] = "⚠️ INTEL: {count} PLAYERS FAILED THIS WEEK";
en["@arenaRenseignementEchecs"] = { "placeholders": { "count": { "type": "String" } } };
fr["arenaRenseignementEchecs"] = "⚠️ RENSEIGNEMENT : {count} JOUEURS ONT ÉCHOUÉ CETTE SEMAINE";
fr["@arenaRenseignementEchecs"] = { "placeholders": { "count": { "type": "String" } } };

en["arenaEnvMinutes"] = "APPROX. {minutes} MIN";
en["@arenaEnvMinutes"] = { "placeholders": { "minutes": { "type": "String" } } };
fr["arenaEnvMinutes"] = "ENV. {minutes} MIN";
fr["@arenaEnvMinutes"] = { "placeholders": { "minutes": { "type": "String" } } };

en["arenaCompleterRenseignement"] = "COMPLETE INTEL ({count}/4)";
en["@arenaCompleterRenseignement"] = { "placeholders": { "count": { "type": "String" } } };
fr["arenaCompleterRenseignement"] = "COMPLÉTER LE RENSEIGNEMENT ({count}/4)";
fr["@arenaCompleterRenseignement"] = { "placeholders": { "count": { "type": "String" } } };

en["arenaAucunTraceDeGrave"] = "NO {sportName} TRACK GRAVED";
en["@arenaAucunTraceDeGrave"] = { "placeholders": { "sportName": { "type": "String" } } };
fr["arenaAucunTraceDeGrave"] = "AUCUN TRACÉ DE {sportName} GRAVÉ";
fr["@arenaAucunTraceDeGrave"] = { "placeholders": { "sportName": { "type": "String" } } };


fs.writeFileSync('lib/l10n/app_en.arb', JSON.stringify(en, null, 2));
fs.writeFileSync('lib/l10n/app_fr.arb', JSON.stringify(fr, null, 2));
console.log("ARB files updated.");

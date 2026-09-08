const fs = require('fs');

const path = 'lib/l10n/app_en.arb';
let raw = fs.readFileSync(path, 'utf8');
let json = JSON.parse(raw);

const translations = {
  "dojoQuTeQuotidienneAccomplie": "🏆 DAILY QUEST ACCOMPLISHED: 50 PUSH-UPS! (+20 XP)",
  "dojoConnexionNeurologique": "Neurological Connection...",
  "dojoCalibrationIaEnCours": "AI CALIBRATION IN PROGRESS...",
  "dojoAdaptationVotreMorphologie": "ADAPTING TO YOUR MORPHOLOGY",
  "dojoCorpsNonDTect": "BODY NOT DETECTED",
  "dojoRSultatsSynchronisS": "Results synchronized!",
  "dojoRapportDeMission": "MISSION REPORT",
  "dojoValiderLEntraNement": "VALIDATE TRAINING",
  "dojoLeDojoConfiguration": "THE DOJO: CONFIGURATION",
  "dojoModeVision": "VISION MODE",
  "dojoIaActiveTrackingDes": "Active AI • Joint Tracking • Auto Feedback",
  "dojoModeGuide": "GUIDE MODE",
  "dojoSimulation3dModeChrono": "3D Simulation • Timer Mode • Manual Validation",
  "dojoDMonstration": "DEMONSTRATION",
  "dojoAngleCamRaRequis": "REQUIRED CAMERA ANGLE",
  "dojoCommencerLeProtocole": "START PROTOCOL",
  "dojoPrPareToi": "GET READY",
  "dojoVidODeD": "Demonstration video\\ncoming soon",
  "dojoChargementDMo": "LOADING DEMO...",
  "dojoVidONonDisponible": "Video unavailable\\nYou can still start the exercise",
  "dojoIgnorerLaDMo": "SKIP DEMO",
  "dojoSLectionDeL": "EXERCISE SELECTION",
  "dojoAucunProtocoleDisponiblePour": "No protocol available for this configuration.",
  "dojoSimulationHq": "HQ SIMULATION",
  "dojoCalibrageDuFlux": "CALIBRATING STREAM...",
  "dojoDMarrerLEntra": "START TRAINING",
  "dojoPrParezVous": "GET READY...",
  "dojoRPTitions": "REPETITIONS",
  "dojoTapezLeCercleChaque": "(Tap the circle for each repetition)",
  "dojoEmptyKey": "🧠",
  "dojoDurE": "DURATION",
  "dojoXpGagnS": "XP EARNED",
  "dojoChoixCible": "1. TARGET SELECTION",
  "dojoTypeEntrainement": "2. TRAINING TYPE",
  "dojoModeExecution": "3. EXECUTION MODE",
  "dojoSelectionnezMode": "SELECT A MODE",
  "dojoDemarrerProtocole": "START PROTOCOL",
  "dojoCorpsEntier": "Full Body",
  "dojoHautDuCorps": "Upper Body",
  "dojoBasDuCorps": "Lower Body",
  "dojoSangleAbdos": "Core",
  "dojoCiblageIsole": "Isolated",
  "dojoLentControle": "Slow & Controlled",
  "dojoCardioLong": "Long Cardio"
};

for (const [key, value] of Object.entries(translations)) {
  if (json[key] !== undefined) {
    json[key] = value;
  }
}

fs.writeFileSync(path, JSON.stringify(json, null, 2));
console.log('Translations applied successfully.');

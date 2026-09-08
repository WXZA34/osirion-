const fs = require('fs');
const path = 'lib/l10n/app_en.arb';

let enData = JSON.parse(fs.readFileSync(path, 'utf8'));

const translations = {
  "homeMenuAlpha": "ALPHA MENU",
  "homeQuitterLaSession": "QUIT SESSION",
  "homeBalanceDesForces": "BALANCE OF POWER",
  "homeRoyalArc": "ROYAL ARC",
  "homeLeCouronnementAlpha": "THE ALPHA CROWNING",
  "homeSummerBody": "SUMMER BODY",
  "homeLClatDeL": "THE SHINE OF EFFORT",
  "homeWinterArc": "WINTER ARC",
  "homeLaForgeDansL": "THE FORGE IN THE SHADOW",
  "homePilierPhysique": "Physical Pillar",
  "homePilierMental": "Mental Pillar",
  "homeActionLifestyle": "Action Lifestyle",
  "homeSuggestionsLecture": "Reading Suggestions",
  "homeLaBibliothQueDu": "The Winter Arc Library",
  "homeRCompensesAjoutEs": "Rewards added to your profile! 🏆",
  "homeArcTermin": "ARC COMPLETED",
  "homeRClamerEtEntrer": "CLAIM AND ENTER THE LIGHT",
  "homePulseQuotidien": "DAILY PULSE",
  "homeTransmissionAlpha": "ALPHA TRANSMISSION",
  "homeOuvrirLaVidO": "OPEN VIDEO"
};

for (const key in translations) {
  if (enData[key]) {
    enData[key] = translations[key];
  }
}

fs.writeFileSync(path, JSON.stringify(enData, null, 2));
console.log('Home translations updated!');

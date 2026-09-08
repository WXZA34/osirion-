const fs = require('fs');

const frPath = 'lib/l10n/app_fr.arb';
const enPath = 'lib/l10n/app_en.arb';

const frData = JSON.parse(fs.readFileSync(frPath, 'utf8'));
const enData = JSON.parse(fs.readFileSync(enPath, 'utf8'));

const newFrKeys = {
  "commonClose": "FERMER",
  "commonCancel": "ANNULER",
  "commonModify": "MODIFIER",
  "commonErase": "EFFACER",
  "commonSend": "ENVOYER",
  "commonReplay": "REJOUER",
  "commonFinish": "TERMINER",
  "commonAccept": "Accepter",
  "commonSuspend": "SUSPENDRE",
  "commonPurge": "PURGER",
  "commonError": "Erreur : {error}",
  "@commonError": {
    "placeholders": {
      "error": {
        "type": "String"
      }
    }
  },
  "commonErrorSimple": "Erreur : ",
  "commonFrench": "Français",
  "commonEnglish": "English"
};

const newEnKeys = {
  "commonClose": "CLOSE",
  "commonCancel": "CANCEL",
  "commonModify": "EDIT",
  "commonErase": "ERASE",
  "commonSend": "SEND",
  "commonReplay": "REPLAY",
  "commonFinish": "FINISH",
  "commonAccept": "Accept",
  "commonSuspend": "PAUSE",
  "commonPurge": "PURGE",
  "commonError": "Error: {error}",
  "@commonError": {
    "placeholders": {
      "error": {
        "type": "String"
      }
    }
  },
  "commonErrorSimple": "Error: ",
  "commonFrench": "French",
  "commonEnglish": "English"
};

Object.assign(frData, newFrKeys);
Object.assign(enData, newEnKeys);

fs.writeFileSync(frPath, JSON.stringify(frData, null, 2));
fs.writeFileSync(enPath, JSON.stringify(enData, null, 2));

console.log('ARB files updated successfully!');

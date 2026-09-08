const fs = require('fs');

const enFile = 'lib/l10n/app_en.arb';
const frFile = 'lib/l10n/app_fr.arb';
const dartFile = 'lib/core/domain/entities/library_audio_entity.dart';

let enData = fs.readFileSync(enFile, 'utf8');
let frData = fs.readFileSync(frFile, 'utf8');
let dartData = fs.readFileSync(dartFile, 'utf8');

enData = enData.replace(/"audioMaîtriserTitle"/g, '"audioMaitriserTitle"');
enData = enData.replace(/"audioMaîtriserSub"/g, '"audioMaitriserSub"');

frData = frData.replace(/"audioMaîtriserTitle"/g, '"audioMaitriserTitle"');
frData = frData.replace(/"audioMaîtriserSub"/g, '"audioMaitriserSub"');

dartData = dartData.replace(/audioMaîtriserTitle/g, 'audioMaitriserTitle');
dartData = dartData.replace(/audioMaîtriserSub/g, 'audioMaitriserSub');

fs.writeFileSync(enFile, enData);
fs.writeFileSync(frFile, frData);
fs.writeFileSync(dartFile, dartData);
console.log('Fixed ARB keys');

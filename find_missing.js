const fs = require('fs');

const translator = fs.readFileSync('lib/features/dojo/utils/dojo_translator.dart', 'utf8');
const config = fs.readFileSync('lib/features/dojo/models/exercise_config.dart', 'utf8');

const nameRegex = /name: "(.*?)",/g;
const descRegex = /description: "(.*?)",/g;

const missingNames = new Set();
const missingDescs = new Set();

let match;
while ((match = nameRegex.exec(config)) !== null) {
  if (!translator.includes('"' + match[1] + '"')) {
    missingNames.add(match[1]);
  }
}

while ((match = descRegex.exec(config)) !== null) {
  if (!translator.includes('"' + match[1] + '"')) {
    missingDescs.add(match[1]);
  }
}

console.log("Missing Names:");
missingNames.forEach(n => console.log(n));

console.log("\nMissing Descriptions:");
missingDescs.forEach(d => console.log(d));

const fs = require('fs');
const text = fs.readFileSync('lib/core/constants/default_relics.dart', 'utf-8');
const regex = /id:\s*'([^']+)'[^}]+?cost:\s*(\d+)/g;
let match;
let output = '    relicPrices: {\n';
const items = [];
while ((match = regex.exec(text)) !== null) {
    items.push(`        '${match[1]}': ${match[2]}`);
}
output += items.join(',\n');
output += '\n    }';
console.log(output);

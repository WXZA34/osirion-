const fs = require('fs');
const path = require('path');

function walk(dir) {
  let results = [];
  const list = fs.readdirSync(dir);
  list.forEach(file => {
    file = path.join(dir, file);
    const stat = fs.statSync(file);
    if (stat && stat.isDirectory()) {
      results = results.concat(walk(file));
    } else if (file.endsWith('.dart')) {
      results.push(file);
    }
  });
  return results;
}

walk('lib/features/dojo').forEach(f => {
  const content = fs.readFileSync(f, 'utf8');
  // Cherche les chaines entre guillemets avec des lettres accentuées
  const matches = content.match(/"[^"]*[éèàêç][^"]*"/g);
  if (matches) {
    console.log(f, matches);
  }
});

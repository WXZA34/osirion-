const fs = require('fs');
const path = require('path');

function walkDir(dir, callback) {
  fs.readdirSync(dir).forEach(f => {
    let dirPath = path.join(dir, f);
    let isDirectory = fs.statSync(dirPath).isDirectory();
    isDirectory ? walkDir(dirPath, callback) : callback(path.join(dir, f));
  });
}

let strings = new Set();
let fileLines = {};

walkDir('lib/features/arena', (file) => {
  if (file.endsWith('.dart')) {
    let c = fs.readFileSync(file, 'utf8');
    let lines = c.split('\n');
    lines.forEach((line, idx) => {
      // Find all quoted strings
      let m = line.match(/(['"])([^'"]+)(['"])/g);
      if (m) {
        m.forEach(match => {
          let str = match.slice(1, -1);
          // basic filter for French UI text
          if (str.length > 2 && /[A-Za-zÀ-ÿ]/.test(str) && !/^[a-z_]+$/.test(str) && !str.includes('package:') && !str.includes('.png') && !str.includes('http') && !['Feature', 'FeatureCollection', 'Point', 'LineString', 'type'].includes(str) && !str.includes('assets/')) {
            // Check if it has at least one space or uppercase
            if (/\s|[A-ZÀ-Ÿ]/.test(str)) {
                strings.add(str);
            }
          }
        });
      }
    });
  }
});

console.log(Array.from(strings).join('\n'));

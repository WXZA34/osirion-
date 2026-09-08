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
walkDir('lib/features/library', (file) => {
  if (file.endsWith('.dart')) {
    let c = fs.readFileSync(file, 'utf8');
    let lines = c.split('\n');
    lines.forEach((line, idx) => {
      let m = line.match(/(['"])([^'"]+)(['"])/g);
      if (m) {
        m.forEach(match => {
          let str = match.slice(1, -1);
          if (str.length > 2 && /[A-Za-zÀ-ÿ]/.test(str) && !/^[a-z_0-9\.]+$/.test(str) && !str.includes('package:') && !str.includes('.png') && !str.includes('.json') && !str.includes('http') && !str.includes('assets/')) {
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

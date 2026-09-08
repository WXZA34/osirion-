const fs = require('fs');
const files = [
  'lib/features/arena/arena_active_screen.dart', 
  'lib/features/arena/arena_report_screen.dart',
  'lib/features/arena/tabs/colosseum_tab.dart',
  'lib/features/arena/tabs/bastions_tab.dart'
];

for(const f of files) {
  if(!fs.existsSync(f)) continue;
  const matches = fs.readFileSync(f, 'utf8').match(/"([^"\\]*(\\.[^"\\]*)*)"/g) || fs.readFileSync(f, 'utf8').match(/'([^'\\]*(\\.[^'\\]*)*)'/g);
  if(matches) {
    console.log(`\n--- ${f} ---`);
    matches.forEach(m => {
      if(m.length > 5 && !m.includes('/') && m.toLowerCase() !== m && m.toUpperCase() !== m && m.includes(' ')) console.log(m);
    });
  }
}

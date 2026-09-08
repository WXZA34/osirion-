const fs = require('fs');
const content = fs.readFileSync('lib/features/arsenal/arsenal_screen.dart', 'utf8');
const lines = content.split('\n');
lines.forEach((line, index) => {
    const matches = line.match(/"([^"]+)"/g);
    if (matches && !line.includes('import') && !line.includes('==')) {
        console.log(`${index + 1}: ${line.trim()}`);
    }
});

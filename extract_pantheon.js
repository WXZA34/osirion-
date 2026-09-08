const fs = require('fs');

const file = fs.readFileSync('lib/features/pantheon/pantheon_screen.dart', 'utf8');

// A simple regex to find all double-quoted strings
const matches = file.match(/"([^"\\]*(\\.[^"\\]*)*)"/g);

if (matches) {
    const uniqueStrings = [...new Set(matches)];
    for (const s of uniqueStrings) {
        // filter out empty, single char, simple IDs, URLs, asset paths, emojis
        if (s.length > 3 && !s.includes('/') && !s.includes('.png') && !s.includes('.jpg') && !s.includes('.webp') && !s.includes('.json')) {
            // Further filter out very simple strings that are probably system IDs or keys
            if (s.toLowerCase() !== s && s.toUpperCase() !== s && s.includes(' ')) {
                 console.log(s);
            } else if (['"Classements"', '"Le Panthéon"', '"Vidéos"', '"Mon Clan"'].includes(s)) {
                 console.log(s);
            }
        }
    }
}

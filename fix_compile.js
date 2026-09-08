const fs = require('fs');

// Fix library_screen.dart
let c = fs.readFileSync('lib/features/library/library_screen.dart', 'utf8');

c = c.replace('loading: () => _buildStaticFallback(),', 'loading: () => _buildStaticFallback(context),');
c = c.replace('error: (err, stack) => _buildStaticFallback(),', 'error: (err, stack) => _buildStaticFallback(context),');
c = c.replace('Widget _buildStaticFallback() {', 'Widget _buildStaticFallback(BuildContext context) {');

// Do it again because there are two occurrences
c = c.replace('loading: () => _buildStaticFallback(),', 'loading: () => _buildStaticFallback(context),');
c = c.replace('error: (err, stack) => _buildStaticFallback(),', 'error: (err, stack) => _buildStaticFallback(context),');
c = c.replace('Widget _buildStaticFallback() {', 'Widget _buildStaticFallback(BuildContext context) {');

// Fix getLibraryCatalog(context) without context being defined in some places?
// Wait, inside _DynamicBookList, we had: final staticBooks = getLibraryCatalog(context)[activeArc]
// Now context is passed to _buildStaticFallback(BuildContext context)

// Wait, inside _DynamicBookList build method, we also used it:
// final staticBooks = getLibraryCatalog(context)[activeArc] ?? [];
// BuildContext context is available there.
fs.writeFileSync('lib/features/library/library_screen.dart', c);


// Fix book_entity.dart
let b = fs.readFileSync('lib/features/library/models/book_entity.dart', 'utf8');
if (b.endsWith('};\r\n')) {
  b = b.substring(0, b.length - 4) + '};\n}\n';
} else if (b.endsWith('};\n')) {
  b = b.substring(0, b.length - 3) + '};\n}\n';
} else if (b.endsWith('};')) {
  b = b + '\n}\n';
}
fs.writeFileSync('lib/features/library/models/book_entity.dart', b);

console.log('Fixed compile errors.');

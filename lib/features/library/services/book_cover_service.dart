import 'dart:convert';
import 'package:http/http.dart' as http;

class BookCoverService {
  // Cache en mémoire pour éviter de rappeler l'API lors du scroll
  static final Map<String, String?> _cache = {};

  static Future<String?> fetchCoverUrl(String title, String author) async {
    final cacheKey = '$title-$author';
    if (_cache.containsKey(cacheKey)) {
      return _cache[cacheKey];
    }

    try {
      // Une recherche simple "titre auteur" donne de meilleurs résultats qu'un intitle strict avec des espaces
      final query = Uri.encodeComponent(
        '${title.toLowerCase()} ${author.toLowerCase()}',
      );
      final url = Uri.parse(
        'https://www.googleapis.com/books/v1/volumes?q=$query&maxResults=1',
      );

      final response = await http.get(url);
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['items'] != null && data['items'].isNotEmpty) {
          final volumeInfo = data['items'][0]['volumeInfo'];
          if (volumeInfo['imageLinks'] != null) {
            String thumbnailUrl = volumeInfo['imageLinks']['thumbnail'];
            // L'API Google Books renvoie souvent du HTTP, on force le HTTPS
            thumbnailUrl = thumbnailUrl.replaceFirst('http://', 'https://');
            _cache[cacheKey] = thumbnailUrl;
            return thumbnailUrl;
          }
        }
      }
    } catch (e) {
      // Si on échoue, on retournera l'image par défaut sans faire crasher l'app
    }

    _cache[cacheKey] = null;
    return null;
  }
}

import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';

Future<void> main() async {
  final books = [
    {'title': 'Hagakure : Le Code du Samouraï', 'author': 'Yamamoto Tsunetomo'},
    {'title': 'Le Manuel', 'author': 'Épictète'},
    {'title': 'Atomic Habits', 'author': 'James Clear'},
  ];

  for (var book in books) {
    final title = book['title']!;
    final author = book['author']!;
    debugPrint('Testing: $title by $author');
    
    try {
      final query = Uri.encodeComponent('${title.toLowerCase()} ${author.toLowerCase()}');
      final url = Uri.parse('https://www.googleapis.com/books/v1/volumes?q=$query&maxResults=1');
      debugPrint('URL: $url');

      final response = await http.get(url);
      debugPrint('Status: ${response.statusCode}');
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['items'] != null && data['items'].isNotEmpty) {
          final volumeInfo = data['items'][0]['volumeInfo'];
          if (volumeInfo['imageLinks'] != null) {
            String thumbnailUrl = volumeInfo['imageLinks']['thumbnail'];
            debugPrint('Found Thumbnail: $thumbnailUrl');
          } else {
            debugPrint('No imageLinks found.');
          }
        } else {
          debugPrint('No items found.');
        }
      } else {
        debugPrint('Error response: ${response.body}');
      }
    } catch (e) {
      debugPrint('Exception: $e');
    }
    debugPrint('---');
  }
}

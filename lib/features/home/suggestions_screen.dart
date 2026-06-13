import 'package:flutter/material.dart';

class SuggestionsScreen extends StatelessWidget {
  const SuggestionsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Suggestions Lecture")),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(
            "La Bibliothèque du Winter Arc",
            style: Theme.of(
              context,
            ).textTheme.headlineSmall?.copyWith(color: Colors.white),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 20),
          _buildBookCard(
            "Atomic Habits",
            "James Clear",
            "Construction d'habitudes",
          ),
          _buildBookCard("Can't Hurt Me", "David Goggins", "Force mentale"),
          _buildBookCard(
            "Meditations",
            "Marcus Aurelius",
            "Philosophie stoïcienne",
          ),
          _buildBookCard("Deep Work", "Cal Newport", "Concentration intense"),
        ],
      ),
    );
  }

  Widget _buildBookCard(String title, String author, String tag) {
    return Card(
      color: Colors.white10,
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            Container(
              width: 50,
              height: 70,
              color: Colors.grey[800],
              child: const Icon(Icons.book, color: Colors.white54),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  Text(author, style: const TextStyle(color: Colors.white70)),
                  const SizedBox(height: 4),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.blueAccent.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      tag,
                      style: const TextStyle(
                        color: Colors.blueAccent,
                        fontSize: 10,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

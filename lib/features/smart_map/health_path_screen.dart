import '../../l10n/app_localizations.dart';
import 'package:flutter/material.dart';


class HealthPathScreen extends StatelessWidget {
  const HealthPathScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(AppLocalizations.of(context)!.smartMapParcoursDeSant)),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.directions_run,
              size: 80,
              color: Colors.blueAccent,
            ),
            const SizedBox(height: 20),
            Text(
              AppLocalizations.of(context)!.smartMapParcoursOptimisS,
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            const SizedBox(height: 10),
            Text(AppLocalizations.of(context)!.smartMapDCouvrezDesItin),
            const SizedBox(height: 30),
            // Placeholder list
            _buildPathCard(context, "Circuit Forêt", "5 km", "Modéré"),
            _buildPathCard(context, "Sprint Urbain", "2 km", "Intense"),
            _buildPathCard(context, "Promenade du Lac", "8 km", "Facile"),
          ],
        ),
      ),
    );
  }

  Widget _buildPathCard(
    BuildContext context,
    String title,
    String distance,
    String difficulty,
  ) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      color: Colors.white10,
      child: ListTile(
        leading: const Icon(Icons.map, color: Colors.blueAccent),
        title: Text(title, style: const TextStyle(color: Colors.white)),
        subtitle: Text(
          "$distance • $difficulty",
          style: const TextStyle(color: Colors.white70),
        ),
        trailing: const Icon(
          Icons.arrow_forward_ios,
          color: Colors.white54,
          size: 16,
        ),
        onTap: () {
          // Navigation désactivée - redirection future vers ArenaActiveScreen
        },
      ),
    );
  }
}

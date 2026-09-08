import 'package:valerion/features/home/utils/smart_trigger_translator.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/smart_trigger_provider.dart';
import '../models/arc_data.dart';
import 'package:valerion/core/providers/arc_provider.dart';

class SmartTrigger extends ConsumerWidget {
  final Function(String)? onNavigate;

  const SmartTrigger({super.key, this.onNavigate});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final triggerAsyncValue = ref.watch(smartTriggerProvider);
    final arc = ref.watch(arcProvider);

    return triggerAsyncValue.when(
      loading: () => _buildLoadingCard(),
      error: (err, stack) => _buildErrorCard(),
      data: (data) => _buildCard(context, data, arc),
    );
  }

  Widget _buildLoadingCard() {
    return Container(
      width: double.infinity,
      height: 100,
      decoration: BoxDecoration(
        color: Colors.white10,
        borderRadius: BorderRadius.circular(30),
      ),
      child: const Center(child: CircularProgressIndicator(color: Colors.cyan)),
    );
  }

  Widget _buildErrorCard() {
    return const SizedBox.shrink(); // Ne rien afficher si erreur Météo
  }

  Widget _buildCard(BuildContext context, SmartTriggerData data, ArcData arc) {
    final bool isSummer = arc.arcType == AlphaArc.summer;

    // Si pluie ou froid intense, on utilise une couleur d'alerte plus vive
    final bool isAlert = data.isRaining || data.temperature < 5;
    final Color cardColor = isAlert ? Colors.orangeAccent : data.color;

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: isSummer ? Colors.white : null,
        gradient: isSummer 
          ? null 
          : LinearGradient(
              colors: [
                cardColor.withValues(alpha: 0.8),
                cardColor.withValues(alpha: 0.4),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
        borderRadius: BorderRadius.circular(30),
        boxShadow: [
          BoxShadow(
            color: isSummer ? Colors.white.withValues(alpha: 0.3) : cardColor.withValues(alpha: 0.2),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(30),
          onTap: () {
            if (onNavigate != null) {
              String tab = 'exercises';
              if (data.targetRoute == 'ARENA') {
                tab = 'maps';
              }
              onNavigate!(tab);
            }
          },
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: isSummer ? arc.primaryColor.withValues(alpha: 0.1) : Colors.white24,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(data.icon, color: isSummer ? arc.primaryColor : Colors.white, size: 32),
                ),
                const SizedBox(width: 20),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              (isAlert ? Localizations.localeOf(context).languageCode == "en" ? "ALERT - " : "ALERTE - " : "SMART TRIGGER - ") + data.cityName.toUpperCase(),
                              style: TextStyle(
                                color: isSummer ? arc.primaryColor.withValues(alpha: 0.7) : Colors.white70,
                                fontWeight: FontWeight.w900,
                                fontSize: 8,
                                letterSpacing: 2,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Icon(
                            data.isRaining ? Icons.water_drop : Icons.wb_sunny,
                            size: 10,
                            color: isSummer ? arc.primaryColor : Colors.white70,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            "${data.temperature.toStringAsFixed(1)}°C",
                            style: TextStyle(
                              color: isSummer ? arc.primaryColor : Colors.white70,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(SmartTriggerTranslator.translateTitle(context, data.title), style: TextStyle(
                          color: isSummer ? Colors.black87 : Colors.white,
                          fontWeight: FontWeight.w900,
                          fontSize: 14,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(SmartTriggerTranslator.translateSubtitle(context, data.subtitle), style: TextStyle(
                          color: isSummer ? Colors.black54 : Colors.white,
                          fontSize: 11,
                          height: 1.3,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.arrow_forward_ios,
                  color: isSummer ? arc.primaryColor : Colors.white54,
                  size: 16,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

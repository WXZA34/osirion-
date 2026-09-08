import '../../../l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../arena_active_screen.dart';
import '../../home/models/arc_data.dart';
import '../../../core/providers/arc_provider.dart';

class ForgeTab extends ConsumerStatefulWidget {
  const ForgeTab({super.key});

  @override
  ConsumerState<ForgeTab> createState() => _ForgeTabState();
}

class _ForgeTabState extends ConsumerState<ForgeTab> {
  String _selectedSport = 'RUNNING'; 
  double _targetDistanceKm = 5.0;
  String _terrainType = 'PLAT'; // PLAT, VALLONNE

  ArcData get _currentArc => ref.watch(arcProvider);
  Color get _surfaceColor => _currentArc.surfaceColor;
  Color get _accentColor => _currentArc.primaryColor;

  @override
  Widget build(BuildContext context) {
    bool isSummer = _currentArc.arcType == AlphaArc.summer;
    
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 140),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildHeader(AppLocalizations.of(context)!.arenaForgeDiscipline),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildSportOption("RUNNING", AppLocalizations.of(context)!.commonCourse, Icons.directions_run, Colors.redAccent),
              _buildSportOption("WALKING", AppLocalizations.of(context)!.commonMarche, Icons.directions_walk, Colors.blueAccent),
              _buildSportOption("CYCLING", AppLocalizations.of(context)!.commonVelo, Icons.directions_bike, Colors.greenAccent),
            ],
          ),
          const SizedBox(height: 40),

          _buildHeader(AppLocalizations.of(context)!.arenaForgeDenivele),
          const SizedBox(height: 16),
          Row(
            children: [
              _buildTerrainOption("PLAT", AppLocalizations.of(context)!.arenaForgePlat, Icons.straighten),
              const SizedBox(width: 12),
              _buildTerrainOption("VALLONNE", AppLocalizations.of(context)!.arenaForgeVallonne, Icons.terrain),
            ],
          ),
          const SizedBox(height: 40),

          _buildHeader(AppLocalizations.of(context)!.arenaForgeDistanceBoucle),
          const SizedBox(height: 16),
          _buildDistanceSelector(isSummer),
          const SizedBox(height: 48),

          ElevatedButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => ArenaActiveScreen(
                    sportType: _selectedSport,
                    targetDistanceKm: _targetDistanceKm,
                  ),
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: _accentColor,
              padding: const EdgeInsets.symmetric(vertical: 20),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              shadowColor: _accentColor.withValues(alpha: 0.5),
              elevation: 10,
            ),
            child: Text(
              AppLocalizations.of(context)!.arenaGNRerLa,
              style: TextStyle(
                color: isSummer ? Colors.white : Colors.black,
                fontWeight: FontWeight.w900,
                fontSize: 16,
                letterSpacing: 1,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(String title) {
    return Text(
      title,
      style: TextStyle(
        color: _currentArc.arcType == AlphaArc.summer ? _currentArc.onSurfaceColor.withValues(alpha: 0.4) : Colors.white54,
        fontSize: 11,
        fontWeight: FontWeight.w900,
        letterSpacing: 1.5,
      ),
    );
  }

  Widget _buildSportOption(String id, String label, IconData icon, Color color) {
    bool isSelected = _selectedSport == id;
    bool isSummer = _currentArc.arcType == AlphaArc.summer;
    
    return GestureDetector(
      onTap: () => setState(() => _selectedSport = id),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: 90,
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: isSelected ? (isSummer ? color : color.withValues(alpha: 0.15)) : _surfaceColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? color : (isSummer ? Colors.black.withValues(alpha: 0.05) : Colors.white10),
            width: isSelected ? 2 : 1,
          ),
          boxShadow: isSelected ? [BoxShadow(color: color.withValues(alpha: 0.3), blurRadius: 10)] : [],
        ),
        child: Column(
          children: [
            Icon(icon, color: isSelected ? (isSummer ? Colors.white : color) : (isSummer ? _currentArc.onSurfaceColor.withValues(alpha: 0.4) : Colors.white54), size: 28),
            const SizedBox(height: 8),
            Text(label.toUpperCase(), style: TextStyle(color: isSelected ? (isSummer ? Colors.white : color) : (isSummer ? _currentArc.onSurfaceColor : Colors.white70), fontSize: 9, fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }

  Widget _buildTerrainOption(String id, String label, IconData icon) {
    bool isSelected = _terrainType == id;
    bool isSummer = _currentArc.arcType == AlphaArc.summer;
    Color color = _accentColor;

    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _terrainType = id),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 14),
          decoration: BoxDecoration(
            color: isSelected ? color.withValues(alpha: 0.1) : _surfaceColor,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: isSelected ? color : (isSummer ? Colors.black12 : Colors.white10)),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: isSelected ? color : Colors.white30, size: 18),
              const SizedBox(width: 8),
              Text(label, style: TextStyle(color: isSelected ? color : Colors.white70, fontWeight: FontWeight.bold, fontSize: 13)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDistanceSelector(bool isSummer) {
    return Column(
      children: [
        Text(
          "${_targetDistanceKm.toStringAsFixed(1)} KM",
          style: TextStyle(
            color: _accentColor,
            fontSize: 40,
            fontWeight: FontWeight.w900,
            shadows: [BoxShadow(color: _accentColor.withValues(alpha: 0.5), blurRadius: 15)],
          ),
        ),
        const SizedBox(height: 20),
        SliderTheme(
          data: SliderTheme.of(context).copyWith(
            activeTrackColor: _accentColor,
            inactiveTrackColor: isSummer ? Colors.black.withValues(alpha: 0.05) : Colors.white10,
            thumbColor: _accentColor,
            trackHeight: 6,
          ),
          child: Slider(
            value: _targetDistanceKm,
            min: 2.0,
            max: 42.0,
            divisions: 80,
            onChanged: (value) => setState(() => _targetDistanceKm = (value * 2).roundToDouble() / 2),
          ),
        ),
      ],
    );
  }
}

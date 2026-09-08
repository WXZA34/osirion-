import 'package:valerion/features/dojo/utils/dojo_translator.dart';
import '../../l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'exercise_selector_screen.dart';

import '../home/models/arc_data.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/providers/arc_provider.dart';

class DojoScreen extends ConsumerStatefulWidget {
  const DojoScreen({super.key});

  @override
  ConsumerState<DojoScreen> createState() => _DojoScreenState();
}

class _DojoScreenState extends ConsumerState<DojoScreen> {
  // Config State
  String _selectedTarget = "FULL_BODY";
  String _selectedType = "FORCE";
  String? _selectedMode; // VISION or GUIDE

  // Colors based on Arc theme
  ArcData get _currentArc => ref.watch(arcProvider);
  Color get _surfaceDojo => _currentArc.surfaceColor;
  final Color _accentVision = Colors.greenAccent; // AI Color
  final Color _accentGuide = Colors.blueAccent; // Simulation Color
  final Color _accentNeutral = Colors.cyan;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(20, 10, 20, 140),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.only(bottom: 16.0),
            child: Text(
              AppLocalizations.of(context)!.dojoLeDojoConfiguration,
              style: TextStyle(
                color: _currentArc.arcType == AlphaArc.summer ? Colors.white : Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w900,
                fontStyle: FontStyle.italic,
                letterSpacing: 1,
              ),
            ),
          ),


          // Etape 1 : Le Ciblage Corporel
          _buildSectionTitle(
            AppLocalizations.of(context)!.dojoChoixCible,
            Icons.accessibility_new,
            _accentNeutral,
          ),
          const SizedBox(height: 12),
          _buildTargetSelector(),
          const SizedBox(height: 24),

          // Etape 2 : L'Intensité (Type d'exercice)
          _buildSectionTitle(
            AppLocalizations.of(context)!.dojoTypeEntrainement,
            Icons.local_fire_department,
            Colors.orangeAccent,
          ),
          const SizedBox(height: 12),
          _buildTypeSelector(),
          const SizedBox(height: 32),

          // Etape 3 : Le Mode d'Interaction (Vision vs Guide)
          _buildSectionTitle(
            AppLocalizations.of(context)!.dojoModeExecution,
            Icons.remove_red_eye,
            _accentVision,
          ),
          const SizedBox(height: 16),
          _buildModeSelector(),

          const SizedBox(height: 32),

          // Bouton de lancement
          ElevatedButton(
            onPressed:
                _selectedMode == null
                    ? null
                    : () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder:
                              (context) => ExerciseSelectorScreen(
                                targetBodyPart: _selectedTarget,
                                trainingType: _selectedType,
                                mode: _selectedMode!,
                              ),
                        ),
                      );
                    },
            style: ElevatedButton.styleFrom(
              backgroundColor:
                  _selectedMode == 'VISION' ? _accentVision : _accentGuide,
              disabledBackgroundColor: Colors.white10,
              padding: const EdgeInsets.symmetric(vertical: 20),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
            child: Text(
              _selectedMode == null
                  ? AppLocalizations.of(context)!.dojoSelectionnezMode
                  : AppLocalizations.of(context)!.dojoDemarrerProtocole,
              style: TextStyle(
                color: _selectedMode == null ? Colors.white54 : Colors.black,
                fontWeight: FontWeight.w900,
                fontSize: 16,
                letterSpacing: 1,
              ),
            ),
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  // --- Step 1: Body Target ---
  Widget _buildTargetSelector() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _currentArc.arcType == AlphaArc.summer ? Colors.white.withValues(alpha: 0.9) : _surfaceDojo,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _currentArc.arcType == AlphaArc.summer ? Colors.black.withValues(alpha: 0.05) : Colors.white10),
        boxShadow: [
          if (_currentArc.arcType == AlphaArc.summer)
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
        ],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildTargetOption(
                "FULL_BODY",
                AppLocalizations.of(context)!.dojoCorpsEntier,
                Icons.sports_gymnastics,
              ),
              _buildTargetOption(
                "UPPER",
                AppLocalizations.of(context)!.dojoHautDuCorps,
                Icons.fitness_center,
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildTargetOption("LOWER", AppLocalizations.of(context)!.dojoBasDuCorps, Icons.directions_run),
              _buildTargetOption(
                "CORE",
                AppLocalizations.of(context)!.dojoSangleAbdos,
                Icons.sports_martial_arts,
              ),
            ],
          ),
          const SizedBox(height: 12),
          _buildTargetOption(
            "LIMB",
            AppLocalizations.of(context)!.dojoCiblageIsole,
            Icons.accessibility,
            isWide: true,
          ),
        ],
      ),
    );
  }

  Widget _buildTargetOption(
    String id,
    String label,
    IconData icon, {
    bool isWide = false,
  }) {
    bool isSelected = _selectedTarget == id;
    Widget content = GestureDetector(
      onTap: () => setState(() => _selectedTarget = id),
      child: Container(
        width: isWide ? double.infinity : 150,
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
        decoration: BoxDecoration(
          color:
              isSelected
                  ? (ArcData.getCurrentArc().arcType == AlphaArc.summer ? ArcData.getCurrentArc().primaryColor : _accentNeutral.withValues(alpha: 0.2))
                  : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected 
                ? (ArcData.getCurrentArc().arcType == AlphaArc.summer ? ArcData.getCurrentArc().primaryColor : _accentNeutral) 
                : (ArcData.getCurrentArc().arcType == AlphaArc.summer ? Colors.black.withValues(alpha: 0.05) : Colors.white24),
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              color: isSelected 
                  ? (ArcData.getCurrentArc().arcType == AlphaArc.summer ? Colors.white : _accentNeutral) 
                  : (_currentArc.arcType == AlphaArc.summer ? _currentArc.onSurfaceColor.withValues(alpha: 0.5) : Colors.white54),
              size: 24,
            ),
            const SizedBox(height: 8),
            Text(
              label,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: isSelected 
                    ? (ArcData.getCurrentArc().arcType == AlphaArc.summer ? Colors.white : _accentNeutral) 
                    : (ArcData.getCurrentArc().arcType == AlphaArc.summer ? ArcData.getCurrentArc().onSurfaceColor : Colors.white70),
                fontSize: 10,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );

    if (isWide) {
      return content; // Pas d'Expanded si c'est la ligne seule (Ciblage Isolé)
    } else {
      return Expanded(
        child: content,
      ); // Expanded nécessaire si dans une Row (Haut, Bas, Full...)
    }
  }

  // --- Step 2: Training Type ---
  Widget _buildTypeSelector() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          _buildTypeOption(
            "FORCE",
            AppLocalizations.of(context)!.dojoLentControle,
            Icons.shield,
            Colors.redAccent,
          ),
          const SizedBox(width: 12),
          _buildTypeOption(
            "ENDURANCE",
            AppLocalizations.of(context)!.dojoCardioLong,
            Icons.timer,
            Colors.orangeAccent,
          ),
        ],
      ),
    );
  }

  Widget _buildTypeOption(
    String id,
    String desc,
    IconData icon,
    Color baseColor,
  ) {
    bool isSelected = _selectedType == id;
    return GestureDetector(
      onTap: () => setState(() => _selectedType = id),
      child: Container(
        width: 140,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isSelected 
              ? (ArcData.getCurrentArc().arcType == AlphaArc.summer ? baseColor : baseColor.withValues(alpha: 0.2)) 
              : _surfaceDojo,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected 
                ? baseColor 
                : (_currentArc.arcType == AlphaArc.summer ? Colors.black.withValues(alpha: 0.05) : Colors.white10),
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(
              icon,
              color: isSelected 
                  ? (ArcData.getCurrentArc().arcType == AlphaArc.summer ? Colors.white : baseColor) 
                  : (_currentArc.arcType == AlphaArc.summer ? _currentArc.onSurfaceColor.withValues(alpha: 0.5) : Colors.white54),
              size: 20,
            ),
            const SizedBox(height: 8),
            Text(
              DojoTranslator.translate(context, id),
              style: TextStyle(
                color: isSelected 
                    ? (ArcData.getCurrentArc().arcType == AlphaArc.summer ? Colors.white : baseColor) 
                    : (_currentArc.arcType == AlphaArc.summer ? _currentArc.onSurfaceColor : Colors.white),
                fontWeight: FontWeight.bold,
                fontSize: 12,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              desc,
              style: TextStyle(
                color: isSelected 
                    ? (ArcData.getCurrentArc().arcType == AlphaArc.summer ? Colors.white70 : Colors.white54) 
                    : (_currentArc.arcType == AlphaArc.summer ? _currentArc.onSurfaceColor.withValues(alpha: 0.6) : Colors.white54), 
                fontSize: 10
              ),
            ),
          ],
        ),
      ),
    );
  }

  // --- Step 3: Interaction Mode ---
  Widget _buildModeSelector() {
    return Row(
      children: [
        Expanded(
          child: GestureDetector(
            onTap: () => setState(() => _selectedMode = 'VISION'),
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color:
                    _selectedMode == 'VISION'
                        ? _accentVision.withValues(alpha: 0.1)
                        : _surfaceDojo,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color:
                      _selectedMode == 'VISION'
                          ? _accentVision
                          : Colors.white10,
                  width: _selectedMode == 'VISION' ? 2 : 1,
                ),
                boxShadow:
                    _selectedMode == 'VISION'
                        ? [
                          BoxShadow(
                            color: _accentVision.withValues(alpha: 0.2),
                            blurRadius: 15,
                          ),
                        ]
                        : [],
              ),
              child: Column(
                children: [
                  Icon(
                    Icons.camera_front,
                    color:
                        _selectedMode == 'VISION'
                            ? _accentVision
                            : Colors.white54,
                    size: 32,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    AppLocalizations.of(context)!.dojoModeVision,
                    style: TextStyle(
                      color:
                          _selectedMode == 'VISION'
                              ? _accentVision
                              : Colors.white,
                      fontWeight: FontWeight.w900,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    AppLocalizations.of(context)!.dojoIaActiveTrackingDes,
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: Colors.white54, fontSize: 10),
                  ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: GestureDetector(
            onTap: () => setState(() => _selectedMode = 'GUIDE'),
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color:
                    _selectedMode == 'GUIDE'
                        ? _accentGuide.withValues(alpha: 0.1)
                        : _surfaceDojo,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color:
                      _selectedMode == 'GUIDE' ? _accentGuide : Colors.white10,
                  width: _selectedMode == 'GUIDE' ? 2 : 1,
                ),
                boxShadow:
                    _selectedMode == 'GUIDE'
                        ? [
                          BoxShadow(
                            color: _accentGuide.withValues(alpha: 0.2),
                            blurRadius: 15,
                          ),
                        ]
                        : [],
              ),
              child: Column(
                children: [
                  Icon(
                    Icons.play_circle_fill,
                    color:
                        _selectedMode == 'GUIDE'
                            ? _accentGuide
                            : Colors.white54,
                    size: 32,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    AppLocalizations.of(context)!.dojoModeGuide,
                    style: TextStyle(
                      color:
                          _selectedMode == 'GUIDE'
                              ? _accentGuide
                              : Colors.white,
                      fontWeight: FontWeight.w900,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    AppLocalizations.of(context)!.dojoSimulation3dModeChrono,
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: Colors.white54, fontSize: 10),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSectionTitle(String title, IconData icon, Color iconColor) {
    final bool isSummer = _currentArc.arcType == AlphaArc.summer;
    return Row(
      children: [
        Icon(icon, color: iconColor, size: 16),
        const SizedBox(width: 8),
        Text(
          title,
          style: TextStyle(
            color: isSummer ? Colors.white.withValues(alpha: 0.9) : Colors.white54,
            fontSize: 12,
            fontWeight: FontWeight.w900,
            letterSpacing: 1,
          ),
        ),
      ],
    );
  }
}

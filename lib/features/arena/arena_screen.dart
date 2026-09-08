import '../../l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../home/models/arc_data.dart';
import '../../core/providers/arc_provider.dart';
import 'tabs/forge_tab.dart';
import 'tabs/territories_tab.dart';
import 'tabs/bastions_tab.dart';
import 'tabs/colosseum_tab.dart';
import 'package:geolocator/geolocator.dart';

class ArenaScreen extends ConsumerStatefulWidget {
  const ArenaScreen({super.key});

  @override
  ConsumerState<ArenaScreen> createState() => _ArenaScreenState();
}

class _ArenaScreenState extends ConsumerState<ArenaScreen> {
  ArcData get _currentArc => ref.watch(arcProvider);

  @override
  void initState() {
    super.initState();
    // Demander les permissions dès l'entrée dans l'Arène
    _checkPermissions();
  }

  Future<void> _checkPermissions() async {
    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) return;

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
  }

  @override
  Widget build(BuildContext context) {
    final isSummer = _currentArc.arcType == AlphaArc.summer;
    final accentColor = _currentArc.primaryColor;

    return DefaultTabController(
      length: 4,
      child: Scaffold(
        backgroundColor: isSummer ? Colors.white : const Color(0xFF0A0C10),
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          toolbarHeight: 60,
          centerTitle: true,
          title: Text(
            "L'ARÈNE",
            style: TextStyle(
              color: isSummer ? _currentArc.onSurfaceColor : Colors.white,
              fontWeight: FontWeight.w900,
              letterSpacing: 3,
              fontSize: 20,
              fontStyle: FontStyle.italic,
            ),
          ),
          bottom: PreferredSize(
            preferredSize: const Size.fromHeight(80),
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              padding: const EdgeInsets.symmetric(vertical: 4),
              decoration: BoxDecoration(
                color: isSummer ? Colors.black.withValues(alpha: 0.05) : Colors.black.withValues(alpha: 0.4),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(
                  color: isSummer ? Colors.black12 : Colors.white.withValues(alpha: 0.1),
                ),
              ),
              child: TabBar(
                isScrollable: false,
                indicatorColor: accentColor,
                labelColor: accentColor,
                dividerColor: Colors.transparent,
                unselectedLabelColor: isSummer ? Colors.black38 : Colors.white30,
                indicatorWeight: 4,
                indicatorSize: TabBarIndicatorSize.tab,
                padding: EdgeInsets.zero,
                indicator: UnderlineTabIndicator(
                  borderSide: BorderSide(width: 4.0, color: accentColor),
                  insets: const EdgeInsets.symmetric(horizontal: 24.0),
                  borderRadius: BorderRadius.circular(2),
                ),
                labelStyle: const TextStyle(
                  fontSize: 9,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 0.5,
                ),
                tabs: [
                  Tab(text: AppLocalizations.of(context)!.arenaForge, icon: const Icon(Icons.flash_on, size: 22)),
                  Tab(text: AppLocalizations.of(context)!.arenaZones, icon: const Icon(Icons.grid_view, size: 22)),
                  Tab(text: AppLocalizations.of(context)!.arenaSpots, icon: const Icon(Icons.location_on, size: 22)),
                  Tab(text: AppLocalizations.of(context)!.arenaRivaux, icon: const Icon(Icons.groups, size: 22)),
                ],
              ),
            ),
          ),
        ),
        body: Container(
          color: _currentArc.surfaceColor,
          child: const SafeArea(
            child: TabBarView(
              physics: NeverScrollableScrollPhysics(),
              children: [
                ForgeTab(),
                TerritoriesTab(),
                BastionsTab(),
                ColosseumTab(),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

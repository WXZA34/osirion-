import '../../l10n/app_localizations.dart';
import 'package:flutter/material.dart';


class SmartMapScreen extends StatefulWidget {
  SmartMapScreen({super.key});

  @override
  State<SmartMapScreen> createState() => _SmartMapScreenState();
}

class _SmartMapScreenState extends State<SmartMapScreen> {
  // Mock State
  int _selectedFilterIndex = 0; // 0: Nature, 1: Urbain, 2: Dénivelé
  double _loopDistance = 6.0;
  bool _audioGuidanceEnabled = true;
  bool _safetySyncEnabled = false;

  // Theme Colors (Winter Arc Default)
  final Color _bgMap = Color(0xFF0F172A); // Very Dark Navy
  final Color _accentColor = Colors.cyanAccent; // Cold Neon Blue
  final Color _surfaceColor = Color(0xFF1E293B);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFF020617),
      appBar: AppBar(
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.explore, color: _accentColor, size: 20),
            SizedBox(width: 8),
            Text(AppLocalizations.of(context)!.arenaLArNe,
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w900,
                letterSpacing: 2,
                fontSize: 18,
              ),
            ),
          ],
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        actions: [
          IconButton(
            icon: Icon(
              Icons.sos,
              color: Colors.redAccent.withValues(alpha: 0.8),
            ),
            onPressed: () {
              // SOS Action
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(AppLocalizations.of(context)!.smartMapSignalDeDTresse),
                  backgroundColor: Colors.redAccent,
                ),
              );
            },
          ),
        ],
      ),
      body: Stack(
        children: [
          // 1. Map Mockup BackLayer
          Positioned.fill(child: _buildMapMockup()),

          // 2. Draggable/Scrollable Content Layer overlaying the map
          Positioned.fill(
            child: SingleChildScrollView(
              physics: BouncingScrollPhysics(),
              child: Column(
                children: [
                  // Transparent space to see the map
                  SizedBox(height: MediaQuery.of(context).size.height * 0.35),

                  // Wrap content in a styled container
                  Container(
                    decoration: BoxDecoration(
                      color: Color(0xFF020617).withValues(alpha: 0.95),
                      borderRadius: BorderRadius.only(
                        topLeft: Radius.circular(30),
                        topRight: Radius.circular(30),
                      ),
                      border: Border.all(color: Colors.white10),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.5),
                          blurRadius: 20,
                          offset: Offset(0, -5),
                        ),
                      ],
                    ),
                    padding: EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Drag Indicator
                        Center(
                          child: Container(
                            width: 40,
                            height: 4,
                            margin: EdgeInsets.only(bottom: 24),
                            decoration: BoxDecoration(
                              color: Colors.white24,
                              borderRadius: BorderRadius.circular(2),
                            ),
                          ),
                        ),

                        _buildRouteGenerator(),
                        SizedBox(height: 32),

                        _buildStreetWorkoutSpots(),
                        SizedBox(height: 32),

                        _buildGhostRunSection(),
                        SizedBox(height: 32),

                        _buildAudioSettings(),
                        SizedBox(height: 32),

                        _buildSafetySettings(),
                        SizedBox(height: 100), // Padding for BottomBar
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: _accentColor,
        foregroundColor: Colors.black,
        icon: Icon(Icons.play_arrow, size: 28),
        label: Text(AppLocalizations.of(context)!.smartMapDMarrer,
          style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16),
        ),
        onPressed: () {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(AppLocalizations.of(context)!.smartMapPhaseDInitialisationAr))
          );
        },
      ),
    );
  }

  // --- Map Mockup Background ---
  Widget _buildMapMockup() {
    return Container(
      color: _bgMap,
      child: Stack(
        children: [
          CustomPaint(
            painter: _GridPainter(color: _accentColor.withValues(alpha: 0.1)),
            size: Size.infinite,
          ),
          // User Location
          Align(
            alignment: Alignment(0, -0.5),
            child: Container(
              width: 16,
              height: 16,
              decoration: BoxDecoration(
                color: _accentColor,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: _accentColor.withValues(alpha: 0.5),
                    blurRadius: 10,
                    spreadRadius: 4,
                  ),
                ],
              ),
            ),
          ),
          // Route Mockup
          Align(
            alignment: Alignment(0, -0.4),
            child: CustomPaint(
              painter: _RoutePainter(color: _accentColor),
              size: Size(200, 200),
            ),
          ),
          // Ghost Marker
          Align(
            alignment: Alignment(-0.2, -0.2),
            child: Icon(
              Icons.adjust,
              color: Colors.purpleAccent.withValues(alpha: 0.8),
              size: 20,
            ),
          ),
          // Spot Marker
          Align(
            alignment: Alignment(0.4, -0.7),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.fitness_center, color: Colors.amber, size: 24),
                Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: 4,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.black54,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(AppLocalizations.of(context)!.smartMapParcNord,
                    style: TextStyle(color: Colors.white, fontSize: 8),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // --- Route Generator (Loop Engine) ---
  Widget _buildRouteGenerator() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _buildSectionTitle(
          "GÉNÉRATEUR DE BOUCLES (IA)",
          Icons.refresh,
          _accentColor,
        ),
        SizedBox(height: 16),
        Container(
          padding: EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: _surfaceColor,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.white10),
          ),
          child: Column(
            children: [
              // Distance Slider
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(AppLocalizations.of(context)!.smartMapDistanceCible,
                    style: TextStyle(color: Colors.white70, fontSize: 12),
                  ),
                  Text(
                    "${_loopDistance.toStringAsFixed(1)} km",
                    style: TextStyle(
                      color: _accentColor,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
              Slider(
                value: _loopDistance,
                min: 3.0,
                max: 15.0,
                divisions: 24,
                activeColor: _accentColor,
                inactiveColor: Colors.white10,
                onChanged: (val) => setState(() => _loopDistance = val),
              ),
              SizedBox(height: 12),
              // Filters
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildFilterChip(0, "Nature", Icons.park),
                  _buildFilterChip(1, "Urbain", Icons.location_city),
                  _buildFilterChip(2, "Dénivelé", Icons.terrain),
                ],
              ),
              SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: () {},
                icon: Icon(Icons.generating_tokens, size: 16),
                label: Text(AppLocalizations.of(context)!.smartMapGNRer3),
                style: ElevatedButton.styleFrom(
                  backgroundColor: _accentColor.withValues(alpha: 0.2),
                  foregroundColor: _accentColor,
                  minimumSize: Size(double.infinity, 40),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildFilterChip(int index, String label, IconData icon) {
    bool isSelected = _selectedFilterIndex == index;
    return GestureDetector(
      onTap: () => setState(() => _selectedFilterIndex = index),
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color:
              isSelected
                  ? _accentColor.withValues(alpha: 0.2)
                  : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: isSelected ? _accentColor : Colors.white24),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              color: isSelected ? _accentColor : Colors.white54,
              size: 14,
            ),
            SizedBox(width: 4),
            Text(
              label,
              style: TextStyle(
                color: isSelected ? _accentColor : Colors.white70,
                fontSize: 10,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // --- Street Workout Spots ---
  Widget _buildStreetWorkoutSpots() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _buildSectionTitle(
          "SPOTS DE STREET WORKOUT",
          Icons.fitness_center,
          Colors.amber,
        ),
        SizedBox(height: 16),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              _buildSpotCard(
                AppLocalizations.of(context)!.smartMapParcNord,
                "Affluence: Faible",
                "Barres, Dips, Banc",
                1.2,
                true,
              ),
              _buildSpotCard(
                "Berges du Rhône",
                "Affluence: Forte",
                "Tractions, Anneaux",
                3.5,
                false,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSpotCard(
    String name,
    String status,
    String equipment,
    double distance,
    bool isApproved,
  ) {
    return Container(
      width: 200,
      margin: EdgeInsets.only(right: 16),
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _surfaceColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color:
              isApproved ? Colors.amber.withValues(alpha: 0.5) : Colors.white10,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  name,
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (isApproved)
                Icon(Icons.verified, color: Colors.amber, size: 16),
            ],
          ),
          SizedBox(height: 4),
          Text(
            "$distance km",
            style: TextStyle(color: Colors.white54, fontSize: 10),
          ),
          SizedBox(height: 12),
          Text(
            equipment,
            style: TextStyle(color: Colors.amber, fontSize: 10),
          ),
          SizedBox(height: 4),
          Text(
            status,
            style: TextStyle(color: Colors.white70, fontSize: 10),
          ),
          SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              onPressed: () {},
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.white,
                side: BorderSide(color: Colors.white24),
              ),
              child: Text(AppLocalizations.of(context)!.smartMapSYRendreGps,
                style: TextStyle(fontSize: 10),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // --- Ghost Run Mode ---
  Widget _buildGhostRunSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _buildSectionTitle(
          "MODE COURSE FANTÔME",
          Icons.visibility_off,
          Colors.purpleAccent,
        ),
        SizedBox(height: 16),
        Container(
          padding: EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.purpleAccent.withValues(alpha: 0.05),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: Colors.purpleAccent.withValues(alpha: 0.3),
            ),
          ),
          child: Column(
            children: [
              Row(
                children: [
                  Icon(Icons.directions_run, color: Colors.purpleAccent),
                  SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      AppLocalizations.of(context)!.smartMapOmbrePersonnelle,
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                  ),
                  Text(
                    AppLocalizations.of(context)!.smartMapRecord2845,
                    style: TextStyle(
                      color: Colors.purpleAccent,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              SizedBox(height: 12),
              Text(AppLocalizations.of(context)!.smartMapCourezContreVotrePerformance,
                style: TextStyle(color: Colors.white70, fontSize: 10),
              ),
              SizedBox(height: 16),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton.icon(
                  onPressed: () {},
                  icon: Icon(
                    Icons.emoji_events,
                    size: 14,
                    color: Colors.purpleAccent,
                  ),
                  label: Text(AppLocalizations.of(context)!.smartMapLeaderboardsSegments,
                    style: TextStyle(
                      color: Colors.purpleAccent,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // --- Audio Guidance ---
  Widget _buildAudioSettings() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _buildSectionTitle("GUIDAGE & AUDIO", Icons.headphones, Colors.cyan),
        SizedBox(height: 16),
        Container(
          padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: _surfaceColor,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Row(
            children: [
              Icon(Icons.spatial_audio_off, color: Colors.cyan, size: 24),
              SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      AppLocalizations.of(context)!.smartMapCoachVocalDucking,
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      AppLocalizations.of(context)!.smartMapAttNueSpotifyLors,
                      style: TextStyle(color: Colors.white54, fontSize: 10),
                    ),
                  ],
                ),
              ),
              Switch(
                value: _audioGuidanceEnabled,
                activeColor: Colors.cyan,
                inactiveTrackColor: Colors.white10,
                onChanged: (val) => setState(() => _audioGuidanceEnabled = val),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // --- Safety Sync ---
  Widget _buildSafetySettings() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _buildSectionTitle(
          "SÉCURITÉ & ASSISTANCE",
          Icons.shield,
          Colors.redAccent,
        ),
        SizedBox(height: 16),
        Container(
          padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: _surfaceColor,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Row(
            children: [
              Icon(
                Icons.share_location,
                color: Colors.redAccent,
                size: 24,
              ),
              SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      AppLocalizations.of(context)!.smartMapSafetySync,
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      AppLocalizations.of(context)!.smartMapPartageEnDirectContact,
                      style: TextStyle(color: Colors.white54, fontSize: 10),
                    ),
                  ],
                ),
              ),
              Switch(
                value: _safetySyncEnabled,
                activeColor: Colors.redAccent,
                inactiveTrackColor: Colors.white10,
                onChanged: (val) => setState(() => _safetySyncEnabled = val),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSectionTitle(String title, IconData icon, Color color) {
    return Row(
      children: [
        Icon(icon, color: color, size: 14),
        SizedBox(width: 8),
        Text(
          title,
          style: TextStyle(
            color: color,
            fontWeight: FontWeight.bold,
            fontSize: 12,
            letterSpacing: 1,
          ),
        ),
      ],
    );
  }
}

// --- Map Custom Painters --- //

class _GridPainter extends CustomPainter {
  final Color color;
  _GridPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint =
        Paint()
          ..color = color
          ..strokeWidth = 1;

    for (double i = 0; i < size.width; i += 40) {
      canvas.drawLine(Offset(i, 0), Offset(i, size.height), paint);
    }
    for (double i = 0; i < size.height; i += 40) {
      canvas.drawLine(Offset(0, i), Offset(size.width, i), paint);
    }

    final radarPaint =
        Paint()
          ..color = color.withValues(alpha: 0.2)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2;
    canvas.drawCircle(Offset(size.width / 2, size.height / 2), 80, radarPaint);
    canvas.drawCircle(Offset(size.width / 2, size.height / 2), 160, radarPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _RoutePainter extends CustomPainter {
  final Color color;
  _RoutePainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint =
        Paint()
          ..color = color.withValues(alpha: 0.8)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 4
          ..strokeCap = StrokeCap.round
          ..strokeJoin = StrokeJoin.round;

    final path = Path();
    path.moveTo(0, size.height * 0.8);
    path.quadraticBezierTo(
      size.width * 0.2,
      size.height * 0.2,
      size.width * 0.5,
      size.height * 0.4,
    );
    path.quadraticBezierTo(
      size.width * 0.8,
      size.height * 0.6,
      size.width,
      size.height * 0.1,
    );

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

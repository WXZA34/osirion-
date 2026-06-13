import 'package:flutter/material.dart';

class WorkoutOverlay extends StatefulWidget {
  final bool isDojoMode; // True for AI Cam, False for GPS Map
  final VoidCallback onPause;

  const WorkoutOverlay({
    super.key,
    this.isDojoMode = true,
    required this.onPause,
  });

  @override
  State<WorkoutOverlay> createState() => _WorkoutOverlayState();
}

class _WorkoutOverlayState extends State<WorkoutOverlay>
    with SingleTickerProviderStateMixin {
  late AnimationController _opacityController;
  bool _isVisible = true;

  @override
  void initState() {
    super.initState();
    // Fade out after 5 seconds of inactivity (simulated here)
    _opacityController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1),
      value: 1.0,
    );

    Future.delayed(const Duration(seconds: 5), () {
      if (mounted) _fadeOut();
    });
  }

  void _fadeOut() {
    _isVisible = false;
    _opacityController.reverse();
  }

  void _wakeUp() {
    if (!_isVisible) {
      _isVisible = true;
      _opacityController.forward();
      // Auto-hide again after 5s
      Future.delayed(const Duration(seconds: 5), () {
        if (mounted) _fadeOut();
      });
    }
  }

  @override
  void dispose() {
    _opacityController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Winter Arc styling: Frosty, Deep Black, White Text
    final Color bgColor = Colors.black.withValues(alpha: 0.7);
    const Color accentColor = Colors.blueAccent;

    return GestureDetector(
      behavior: HitTestBehavior.translucent,
      onTap: _wakeUp,
      onDoubleTap: widget.onPause, // Double tap emergency pause
      child: FadeTransition(
        opacity: _opacityController,
        child: IgnorePointer(
          ignoring:
              !_isVisible, // Ignore touches when invisible to interact with the map/cam below
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 16.0,
                vertical: 24.0,
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Top Section: AI Status & Time
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (widget.isDojoMode)
                        _buildAISyncIndicator(bgColor, accentColor),
                      if (!widget.isDojoMode)
                        _buildGPSGuidance(bgColor, accentColor),
                    ],
                  ),

                  // Bottom Section: Core Metrics & Controls
                  _buildMetricsRow(bgColor, accentColor),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAISyncIndicator(Color bgColor, Color accentColor) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: Colors.greenAccent.withValues(alpha: 0.5),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: const [
          Icon(Icons.person_outline, color: Colors.greenAccent, size: 16),
          SizedBox(width: 6),
          Text(
            "VISION SYNC",
            style: TextStyle(
              color: Colors.greenAccent,
              fontSize: 10,
              fontWeight: FontWeight.bold,
              letterSpacing: 1,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGPSGuidance(Color bgColor, Color accentColor) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: accentColor.withValues(alpha: 0.5), width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.turn_right, color: accentColor, size: 16),
          const SizedBox(width: 6),
          Text(
            "Dans 150m",
            style: TextStyle(
              color: accentColor,
              fontSize: 10,
              fontWeight: FontWeight.bold,
              letterSpacing: 1,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMetricsRow(Color bgColor, Color accentColor) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: Colors.white10),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.5), blurRadius: 20),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Time
          Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: const [
              Text(
                "TEMPS",
                style: TextStyle(
                  color: Colors.white54,
                  fontSize: 10,
                  letterSpacing: 1,
                ),
              ),
              Text(
                "12:45",
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.w900,
                  fontFamily: 'monospace',
                ),
              ),
            ],
          ),

          // Main Primary Metric (Distance or Reps)
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                widget.isDojoMode ? "RÉPÉTITIONS" : "DISTANCE",
                style: TextStyle(
                  color: accentColor,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 2,
                ),
              ),
              Text(
                widget.isDojoMode ? "14" : "2.4 km",
                style: TextStyle(
                  color: accentColor,
                  fontSize: 32,
                  fontWeight: FontWeight.w900,
                  fontFamily: 'monospace',
                ),
              ),
            ],
          ),

          // Secondary Metric (Pace or Quality)
          Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                widget.isDojoMode ? "QUALITÉ" : "ALLURE",
                style: const TextStyle(
                  color: Colors.white54,
                  fontSize: 10,
                  letterSpacing: 1,
                ),
              ),
              Row(
                children: [
                  if (widget.isDojoMode)
                    const Icon(Icons.star, color: Colors.greenAccent, size: 14),
                  if (widget.isDojoMode) const SizedBox(width: 4),
                  Text(
                    widget.isDojoMode ? "95%" : "5:12",
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      fontFamily: 'monospace',
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'dart:math' as math;
import 'exercise_selection_sheet.dart';

class CameraWorkoutView extends StatefulWidget {
  final Widget cameraStreamWidget;
  final ExerciseType exercise;
  final double currentRepProgress; // 0.0 to 1.0
  final String lastFormQuality; // "EXCELLENT", "DEMI-REP", "DESCENDS PLUS BAS"
  final bool hasCameraPermission;
  final VoidCallback onManualRepTrigger;
  final VoidCallback onRequestPermission;

  const CameraWorkoutView({
    Key? key,
    required this.cameraStreamWidget,
    required this.exercise,
    required this.currentRepProgress,
    required this.lastFormQuality,
    required this.hasCameraPermission,
    required this.onManualRepTrigger,
    required this.onRequestPermission,
  }) : super(key: key);

  @override
  State<CameraWorkoutView> createState() => _CameraWorkoutViewState();
}

class _CameraWorkoutViewState extends State<CameraWorkoutView> with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;
  late Animation<double> _gridAlpha;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    )..repeat(reverse: true);

    _gridAlpha = Tween<double>(begin: 0.12, end: 0.28).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF0B0C10),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFF15171C)),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Stack(
          fit: StackFit.expand,
          children: [
            // Background / Camera
            if (widget.hasCameraPermission)
              widget.cameraStreamWidget
            else
              _buildAiVisionFallback(),

            // HUD Overlay
            _buildAiTrackingHudOverlay(),
          ],
        ),
      ),
    );
  }

  Widget _buildAiVisionFallback() {
    return Stack(
      fit: StackFit.expand,
      children: [
        // Radial Gradient Background
        Container(
          decoration: const BoxDecoration(
            gradient: RadialGradient(
              colors: [Color(0xFF2C2F33), Color(0xFF0B0C10)],
              center: Alignment(0, 0.2),
              radius: 1.5,
            ),
          ),
        ),
        
        // Grid & Target Drawing
        AnimatedBuilder(
          animation: _gridAlpha,
          builder: (context, child) {
            return CustomPaint(
              painter: _AiVisionGridPainter(alpha: _gridAlpha.value),
            );
          },
        ),

        // Permission Request UI
        Center(
          child: Padding(
            padding: const EdgeInsets.all(32.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 76,
                  height: 76,
                  decoration: BoxDecoration(
                    color: Colors.cyanAccent.withOpacity(0.15),
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.cyanAccent.withOpacity(0.6), width: 1.5),
                  ),
                  alignment: Alignment.center,
                  child: const Icon(
                    Icons.videocam,
                    color: Colors.cyanAccent,
                    size: 38,
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  "VISION IA ACTIVE",
                  style: TextStyle(
                    color: Colors.cyanAccent,
                    fontSize: 16,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1.5,
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(top: 8, bottom: 18),
                  child: Text(
                    "Cadrez votre corps entier pour la détection de vos ${widget.exercise.title}.",
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 14,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
                ElevatedButton.icon(
                  onPressed: widget.onRequestPermission,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.cyanAccent,
                    foregroundColor: const Color(0xFF121316),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  icon: const Icon(Icons.camera_alt, size: 18),
                  label: const Text(
                    "Autoriser Caméra Direct",
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildAiTrackingHudOverlay() {
    return Stack(
      children: [
        // Top status badge
        Positioned(
          top: 16,
          left: 16,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: const Color(0xFF15171C).withOpacity(0.92),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFF2C2F33)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: widget.hasCameraPermission ? Colors.greenAccent : Colors.amber,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  widget.hasCameraPermission ? "CAMÉRA DIRECT" : "VISION IA • CALIBRATION",
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.5,
                  ),
                ),
              ],
            ),
          ),
        ),

        // Live Pose Angle & Calibration Box in the center
        Center(
          child: Container(
            width: 240,
            height: 280,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.cyanAccent.withOpacity(0.25)),
            ),
            child: CustomPaint(
              painter: _TargetCornersPainter(),
            ),
          ),
        ),

        // Bottom HUD
        Positioned(
          bottom: 16,
          left: 0,
          right: 0,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Feedback badge
              if (widget.lastFormQuality.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                    decoration: BoxDecoration(
                      color: widget.lastFormQuality.toUpperCase().contains("PARFAITE") || 
                             widget.lastFormQuality.contains("1.0")
                          ? Colors.greenAccent
                          : widget.lastFormQuality.toUpperCase().contains("DEMI") || 
                            widget.lastFormQuality.contains("0.5")
                              ? Colors.amber
                              : Colors.redAccent,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.check_circle, color: Color(0xFF141518), size: 16),
                        const SizedBox(width: 6),
                        Text(
                          widget.lastFormQuality,
                          style: const TextStyle(
                            color: Color(0xFF141518),
                            fontSize: 12,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

              // Amplitude gauge bar
              Container(
                width: MediaQuery.of(context).size.width * 0.85,
                height: 8,
                decoration: BoxDecoration(
                  color: const Color(0xFF2C2F33),
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(color: const Color(0xFF15171C)),
                ),
                child: FractionallySizedBox(
                  alignment: Alignment.centerLeft,
                  widthFactor: widget.currentRepProgress.clamp(0.0, 1.0),
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(4),
                      gradient: const LinearGradient(
                        colors: [Colors.amber, Colors.cyanAccent],
                      ),
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 10),

              // Manual Rep Trigger (Testing)
              OutlinedButton(
                onPressed: widget.onManualRepTrigger,
                style: OutlinedButton.styleFrom(
                  backgroundColor: const Color(0xFF2C2F33),
                  foregroundColor: Colors.white,
                  side: const BorderSide(color: Color(0xFF15171C)),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                ),
                child: Text(
                  "Valider Rép ${widget.exercise.iconEmoji} (+1)",
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _AiVisionGridPainter extends CustomPainter {
  final double alpha;
  _AiVisionGridPainter({required this.alpha});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.cyanAccent.withOpacity(alpha * 0.4)
      ..strokeWidth = 1.0;

    final step = 48.0;

    // Vertical lines
    for (double x = 0; x < size.width; x += step) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }

    // Horizontal lines
    for (double y = 0; y < size.height; y += step) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }

    final center = Offset(size.width / 2, size.height / 2);
    
    // Target circles
    canvas.drawCircle(center, 160, Paint()..color = Colors.cyanAccent.withOpacity(0.10));
    canvas.drawCircle(
      center, 
      130, 
      Paint()
        ..color = Colors.cyanAccent.withOpacity(0.30)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5,
    );
  }

  @override
  bool shouldRepaint(covariant _AiVisionGridPainter oldDelegate) => alpha != oldDelegate.alpha;
}

class _TargetCornersPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.cyanAccent
      ..strokeWidth = 2.5
      ..style = PaintingStyle.stroke;
      
    final len = 22.0;

    // Top-Left
    canvas.drawLine(const Offset(0, 0), Offset(len, 0), paint);
    canvas.drawLine(const Offset(0, 0), Offset(0, len), paint);
    // Top-Right
    canvas.drawLine(Offset(size.width, 0), Offset(size.width - len, 0), paint);
    canvas.drawLine(Offset(size.width, 0), Offset(size.width, len), paint);
    // Bottom-Left
    canvas.drawLine(Offset(0, size.height), Offset(len, size.height), paint);
    canvas.drawLine(Offset(0, size.height), Offset(0, size.height - len), paint);
    // Bottom-Right
    canvas.drawLine(Offset(size.width, size.height), Offset(size.width - len, size.height), paint);
    canvas.drawLine(Offset(size.width, size.height), Offset(size.width, size.height - len), paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

import 'package:valerion/features/home/utils/arc_translator.dart';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/arc_data.dart';

class ArcCard extends ConsumerStatefulWidget {
  final ArcData arc;

  const ArcCard({super.key, required this.arc});

  @override
  ConsumerState<ArcCard> createState() => _ArcCardState();
}

class _ArcCardState extends ConsumerState<ArcCard> {
  Timer? _timer;
  Duration _timeLeft = Duration.zero;

  @override
  void initState() {
    super.initState();
    _updateTimeLeft();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      _updateTimeLeft();
    });
  }

  void _updateTimeLeft() {
    final now = DateTime.now();
    if (widget.arc.endDate.isAfter(now)) {
      setState(() {
        _timeLeft = widget.arc.endDate.difference(now);
      });
    } else {
      setState(() {
        _timeLeft = Duration.zero;
      });
      _timer?.cancel();
    }
  }


  @override
  void didUpdateWidget(ArcCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.arc.arcType != widget.arc.arcType || oldWidget.arc.endDate != widget.arc.endDate) {
      _timer?.cancel();
      _updateTimeLeft();
      _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
        _updateTimeLeft();
      });
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  String _formatDuration(Duration d) {
    String days = d.inDays.toString().padLeft(2, '0');
    String hours = (d.inHours % 24).toString().padLeft(2, '0');
    String minutes = (d.inMinutes % 60).toString().padLeft(2, '0');
    String seconds = (d.inSeconds % 60).toString().padLeft(2, '0');
    return "$days j : $hours h : $minutes m : $seconds s";
  }

  @override
  Widget build(BuildContext context) {

    final bool isSummer = widget.arc.arcType == AlphaArc.summer;
    
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(30),
      // Fond dynamique selon l'Arc
      decoration: BoxDecoration(
        color: isSummer ? Colors.white : const Color(0xFF0F172A),
        borderRadius: BorderRadius.circular(40),
        border: Border.all(
          color: isSummer ? Colors.black12 : widget.arc.primaryColor.withValues(alpha: 0.3),
        ),
        boxShadow: [
          BoxShadow(
            color: isSummer ? Colors.black.withValues(alpha: 0.05) : widget.arc.primaryColor.withValues(alpha: 0.1),
            blurRadius: 15,
            spreadRadius: 2,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      ArcTranslator.translate(context, widget.arc.title),
                      style: TextStyle(
                        color: isSummer ? widget.arc.onSurfaceColor : Colors.white,
                        fontSize: 28,
                        fontWeight: FontWeight.w900,
                        fontStyle: FontStyle.italic,
                        letterSpacing: -1,
                        shadows: [
                          if (!isSummer)
                            Shadow(
                              color: widget.arc.primaryColor.withValues(
                                alpha: 0.5,
                              ),
                              blurRadius: 10,
                            ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      ArcTranslator.translate(context, widget.arc.subtitle),
                      style: TextStyle(
                        color: widget.arc.primaryColor,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 2,
                      ),
                    ),
                  ],
                ),
              ),
              // Icône d'arc
              Icon(
                widget.arc.arcType == AlphaArc.winter
                    ? Icons.ac_unit
                    : widget.arc.arcType == AlphaArc.summer
                    ? Icons.wb_sunny
                    : Icons.account_balance,
                color: widget.arc.primaryColor.withValues(alpha: 0.8),
                size: 32,
              ),
            ],
          ),
          const SizedBox(height: 24),

          // Compteur
          Container(
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
            decoration: BoxDecoration(
              color: isSummer ? widget.arc.onSurfaceColor.withValues(alpha: 0.1) : Colors.black26,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: isSummer ? Colors.transparent : Colors.white10),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.timer, color: Colors.white54, size: 16),
                const SizedBox(width: 6),
                Expanded(
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(
                      _formatDuration(_timeLeft),
                      style: TextStyle(
                        color: isSummer ? widget.arc.onSurfaceColor : Colors.white,
                        fontFamily: 'monospace',
                        fontWeight: FontWeight.bold,
                        letterSpacing: 2,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Citation
          Text(
            ArcTranslator.translate(context, widget.arc.quote),
            style: TextStyle(
              color: isSummer ? Colors.black54 : Colors.white70,
              fontStyle: FontStyle.italic,
              fontSize: 12,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }
}

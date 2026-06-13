import 'package:flutter/material.dart';
import 'dart:async';
import 'package:wakelock_plus/wakelock_plus.dart';
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';
import '../models/book_entity.dart';
import '../../home/models/arc_data.dart';

class ReadingSessionScreen extends StatefulWidget {
  final BookEntity book;
  final int durationMinutes;
  final String ambientSound;

  const ReadingSessionScreen({
    super.key,
    required this.book,
    required this.durationMinutes,
    required this.ambientSound,
  });

  @override
  State<ReadingSessionScreen> createState() => _ReadingSessionScreenState();
}

class _ReadingSessionScreenState extends State<ReadingSessionScreen> {
  late int _remainingSeconds;
  Timer? _timer;

  ArcData get _currentArc => ArcData.getCurrentArc();
  Color get _accentColor => _currentArc.primaryColor;
  Color get _surfaceColor => _currentArc.surfaceColor;

  @override
  void initState() {
    super.initState();
    _remainingSeconds = widget.durationMinutes * 60;

    // Empêche l'écran de s'éteindre pendant la lecture
    WakelockPlus.enable();

    _startTimer();
  }

  void _startTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) return;
      setState(() {
        if (_remainingSeconds > 0) {
          _remainingSeconds--;
        } else {
          _timer?.cancel();
          _showTimeUpDialog();
        }
      });
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    WakelockPlus.disable();
    super.dispose();
  }

  String _formatTime(int seconds) {
    int m = seconds ~/ 60;
    int s = seconds % 60;
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  void _pauseOrResume() {
    if (_timer != null && _timer!.isActive) {
      _timer!.cancel();
      setState(() {});
    } else {
      _startTimer();
    }
  }

  void _showTimeUpDialog() {
    // Si l'utilisateur quitte sans faire le contrat, il n'a qu'une moitié d'XP (ou rien). On le guidera.
    showDialog(
      context: context,
      barrierDismissible: false,
      builder:
          (context) => AlertDialog(
            backgroundColor: _surfaceColor,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
              side: BorderSide(color: _accentColor),
            ),
            title: const Text(
              "TEMPS ÉCOULÉ",
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w900,
                letterSpacing: 2,
              ),
              textAlign: TextAlign.center,
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.hourglass_bottom,
                  color: _accentColor,
                  size: 50,
                ),
                const SizedBox(height: 16),
                Text(
                  "Vous avez terminé votre session sur '${widget.book.title}'.",
                  style: const TextStyle(color: Colors.white70),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),
                const Text(
                  "Souhaitez-vous continuer à lire pour 15 minutes supplémentaires, ou sceller la session et rédiger votre contrat d'honneur ?",
                  style: TextStyle(color: Colors.white54, fontSize: 13),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
            actionsAlignment: MainAxisAlignment.center,
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.pop(context); // Ferme la modal
                  setState(() {
                    _remainingSeconds += 15 * 60;
                  });
                  _startTimer();
                },
                child: const Text(
                  "FORGER (+15 MIN)",
                  style: TextStyle(color: Colors.white54),
                ),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: _accentColor,
                  foregroundColor: Colors.black,
                ),
                onPressed: () {
                  Navigator.pop(context); // Ferme la modal
                  Navigator.pop(
                    context,
                    true,
                  ); // Ferme la page de lecture et renvoie 'true' pour aller au Contrat
                },
                child: const Text(
                  "SCELLER LA SESSION",
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close, color: Colors.white54),
          onPressed: () => Navigator.pop(context, false),
        ),
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.menu_book, color: _accentColor, size: 16),
            const SizedBox(width: 8),
            Text(
              "SESSION ${widget.durationMinutes} MIN",
              style: TextStyle(
                color: _accentColor,
                letterSpacing: 2,
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        centerTitle: true,
      ),
      body: Column(
        children: [
          // Timer Widget Horizontal
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            color: _surfaceColor,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      "Temps Restant",
                      style: TextStyle(color: Colors.white54, fontSize: 10),
                    ),
                    Text(
                      _formatTime(_remainingSeconds),
                      style: TextStyle(
                        color:
                            (_timer?.isActive ?? false)
                                ? Colors.white
                                : Colors.amber,
                        fontSize: 28,
                        fontWeight: FontWeight.w300,
                      ),
                    ),
                  ],
                ),
                IconButton(
                  onPressed: _pauseOrResume,
                  icon: Icon(
                    (_timer?.isActive ?? false)
                        ? Icons.pause_circle_filled
                        : Icons.play_circle_fill,
                    color: _accentColor,
                    size: 40,
                  ),
                ),
              ],
            ),
          ),

          // Contenu Immersif (Fiche Livre ou PDF)
          Expanded(
            child:
                widget.book.pdfPath != null
                    ? SfPdfViewer.asset(widget.book.pdfPath!)
                    : SingleChildScrollView(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 32,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Text(
                            widget.book.title,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              fontFamily: 'Noto Serif',
                              height: 1.3,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            "par ${widget.book.author}",
                            style: TextStyle(
                              color: _accentColor,
                              fontSize: 14,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 48),

                          // Section Thème
                          _buildSection("THÈME CENTRAL", widget.book.theme),

                          // Section Pourquoi Intégrer
                          _buildSection(
                            "POURQUOI L'INTÉGRER ?",
                            widget.book.whyRead,
                          ),

                          // Section Citation Clé
                          Container(
                            margin: const EdgeInsets.only(top: 24),
                            padding: const EdgeInsets.all(24),
                            decoration: BoxDecoration(
                              border: Border(
                                left: BorderSide(
                                  color: _accentColor,
                                  width: 4,
                                ),
                              ),
                              color: Colors.white10.withValues(alpha: 0.05),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Icon(
                                  Icons.format_quote,
                                  color: _accentColor,
                                  size: 30,
                                ),
                                const SizedBox(height: 12),
                                Text(
                                  widget.book.keyPhrase,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 18,
                                    fontStyle: FontStyle.italic,
                                    fontFamily: 'Noto Serif',
                                    height: 1.5,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
          ),
        ],
      ),
    );
  }

  Widget _buildSection(String title, String content) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 32.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              color: Colors.white54,
              letterSpacing: 2,
              fontWeight: FontWeight.w900,
              fontSize: 11,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            content,
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 16,
              height: 1.6,
            ),
          ),
        ],
      ),
    );
  }
}

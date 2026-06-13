import 'package:flutter_tts/flutter_tts.dart';

class TtsService {
  static final TtsService _instance = TtsService._internal();
  factory TtsService() => _instance;
  TtsService._internal();

  final FlutterTts _flutterTts = FlutterTts();
  bool _isInitialized = false;

  Future<void> init() async {
    if (_isInitialized) return;
    
    await _flutterTts.setLanguage("fr-FR");
    await _flutterTts.setSpeechRate(0.8);
    await _flutterTts.setVolume(1.0);
    await _flutterTts.setPitch(1.0);
    
    _isInitialized = true;
  }

  Future<void> speak(String text) async {
    if (!_isInitialized) await init();
    await _flutterTts.speak(text);
  }

  /// Pour les instructions de coaching (ex: "Gardez le dos droit")
  Future<void> speakInstruction(String text) async {
    if (!_isInitialized) await init();
    // On baisse un peu le débit pour que l'instruction soit claire
    await _flutterTts.setSpeechRate(0.5);
    await _flutterTts.speak(text);
    // On remet le débit normal
    await _flutterTts.setSpeechRate(0.8);
  }

  Future<void> stop() async {
    await _flutterTts.stop();
  }
}

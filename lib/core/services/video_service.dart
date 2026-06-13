import 'dart:io';
import 'dart:async';
import 'package:video_compress/video_compress.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:battery_plus/battery_plus.dart';
import 'package:flutter/foundation.dart';

/// Service gérant le "Smart Video Pipeline" d'OSIRION.
/// Gère la compression adaptative selon le réseau et la batterie.
class SmartVideoService {
  final Battery _battery = Battery();
  final StreamController<double> _progressController = StreamController<double>.broadcast();
  Subscription? _subscription;

  SmartVideoService() {
    _subscription = VideoCompress.compressProgress$.subscribe((progress) {
      _progressController.add(progress / 100); // Normalisation 0.0 - 1.0
    });
  }

  /// Compresse une vidéo selon une stratégie adaptative.
  /// Retourne le fichier compressé ou le fichier original en cas d'erreur.
  Future<File?> processAndCompress(String videoPath) async {
    try {
      final connectivityResult = await Connectivity().checkConnectivity();
      final batteryLevel = await _battery.batteryLevel;
      final batteryState = await _battery.batteryState;

      VideoQuality quality = VideoQuality.MediumQuality;
      
      // LOGIQUE ADAPTATIVE :
      bool isWifi = connectivityResult.contains(ConnectivityResult.wifi);
      bool isLowBattery = batteryLevel < 20 && batteryState != BatteryState.charging;

      if (isWifi && !isLowBattery) {
        quality = VideoQuality.DefaultQuality; 
        debugPrint("📡 SmartVideo: Mode WiFi détecté -> Qualité Haute");
      } else if (isLowBattery) {
        quality = VideoQuality.LowQuality;
        debugPrint("🔋 SmartVideo: Batterie faible -> Qualité Éco");
      } else {
        quality = VideoQuality.MediumQuality;
        debugPrint("📶 SmartVideo: Données Mobiles -> Qualité Équilibrée");
      }

      debugPrint("🎬 SmartVideo: Début de la compression native (H.264)...");
      
      final MediaInfo? info = await VideoCompress.compressVideo(
        videoPath,
        quality: quality,
        deleteOrigin: false,
        includeAudio: true,
      );

      if (info != null && info.file != null) {
        final originalSize = File(videoPath).lengthSync();
        final compressedSize = info.file!.lengthSync();
        final reduction = ((originalSize - compressedSize) / originalSize * 100).toStringAsFixed(1);
        
        debugPrint("📊 Réduction : $reduction% (${(originalSize / 1024 / 1024).toStringAsFixed(1)}MB -> ${(compressedSize / 1024 / 1024).toStringAsFixed(1)}MB)");
        
        return info.file;
      }
      
      return File(videoPath);
    } catch (e) {
      debugPrint("❌ SmartVideo Error: $e");
      return File(videoPath);
    }
  }

  /// Nettoie les fichiers temporaires de compression et ferme les flux.
  Future<void> dispose() async {
    _subscription?.unsubscribe();
    await _progressController.close();
    await VideoCompress.deleteAllCache();
  }

  /// Stream de progression normalisé (0.0 à 1.0) pour l'UI.
  Stream<double> get compressionProgress => _progressController.stream;
}

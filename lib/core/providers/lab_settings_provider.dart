import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LabSettings {
  final double aiSensitivity;
  final bool showSkeleton;
  final double gpsFrequency;

  LabSettings({
    required this.aiSensitivity,
    required this.showSkeleton,
    required this.gpsFrequency,
  });

  LabSettings copyWith({
    double? aiSensitivity,
    bool? showSkeleton,
    double? gpsFrequency,
  }) {
    return LabSettings(
      aiSensitivity: aiSensitivity ?? this.aiSensitivity,
      showSkeleton: showSkeleton ?? this.showSkeleton,
      gpsFrequency: gpsFrequency ?? this.gpsFrequency,
    );
  }
}

class LabSettingsNotifier extends StateNotifier<LabSettings> {
  LabSettingsNotifier()
      : super(LabSettings(
          aiSensitivity: 0.7,
          showSkeleton: true,
          gpsFrequency: 1.0,
        )) {
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    state = LabSettings(
      aiSensitivity: prefs.getDouble('ai_sensitivity') ?? 0.7,
      showSkeleton: prefs.getBool('show_skeleton') ?? true,
      gpsFrequency: prefs.getDouble('gps_frequency') ?? 1.0,
    );
  }

  Future<void> updateAiSensitivity(double value) async {
    state = state.copyWith(aiSensitivity: value);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble('ai_sensitivity', value);
  }

  Future<void> updateShowSkeleton(bool value) async {
    state = state.copyWith(showSkeleton: value);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('show_skeleton', value);
  }

  Future<void> updateGpsFrequency(double value) async {
    state = state.copyWith(gpsFrequency: value);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble('gps_frequency', value);
  }
}

final labSettingsProvider =
    StateNotifierProvider<LabSettingsNotifier, LabSettings>((ref) {
  return LabSettingsNotifier();
});

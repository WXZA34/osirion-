import 'dart:convert';
import 'package:http/http.dart' as http;

class WeatherService {
  /// Appelle l'API Open-Meteo asynchrone pour obtenir le code météo et la température.
  /// L'API retourne un wmo code (https://open-meteo.com/en/docs)
  static Future<Map<String, dynamic>> getCurrentWeather(
    double lat,
    double lon,
  ) async {
    try {
      final url = Uri.parse(
        'https://api.open-meteo.com/v1/forecast?latitude=$lat&longitude=$lon&current=temperature_2m,weather_code',
      );
      final response = await http.get(url).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final current = data['current'];

        return {
          'temperature': current['temperature_2m'],
          'weather_code':
              current['weather_code'], // WMO Weather interpretation codes
          'is_raining': _isRaining(current['weather_code']),
        };
      }
    } catch (e) {
      // Échec silencieux, renvoyer des données par défaut saines
    }

    // Fallback par défaut
    return {
      'temperature': 20.0,
      'weather_code': 0, // Ciel clair
      'is_raining': false,
    };
  }

  /// Décode les codes météo WMO pour savoir s'il pleut/neige
  /// (Codes >= 50 indiquent des précipitations, bruine, pluie, neige, orage)
  static bool _isRaining(int wmoCode) {
    if (wmoCode >= 51 && wmoCode <= 99) return true;
    return false;
  }
}

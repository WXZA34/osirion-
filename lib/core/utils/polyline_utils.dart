// lib/core/utils/polyline_utils.dart

import '../models/lat_lng.dart';

class PolylineUtils {
  /// Encodes a list of LatLng points into a Google Polyline string.
  /// Standard algorithm: https://developers.google.com/maps/documentation/utilities/polylinealgorithm
  static String encode(List<LatLng> points) {
    var lastLat = 0;
    var lastLng = 0;
    var result = StringBuffer();

    for (final point in points) {
      final lat = (point.latitude * 1e5).round();
      final lng = (point.longitude * 1e5).round();

      _encode(lat - lastLat, result);
      _encode(lng - lastLng, result);

      lastLat = lat;
      lastLng = lng;
    }

    return result.toString();
  }

  static void _encode(int value, StringBuffer result) {
    var v = value < 0 ? ~(value << 1) : (value << 1);
    while (v >= 0x20) {
      result.write(String.fromCharCode((0x20 | (v & 0x1f)) + 63));
      v >>= 5;
    }
    result.write(String.fromCharCode(v + 63));
  }
}

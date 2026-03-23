import 'dart:math';

class GeoUtils {
  /// Calculates the Haversine distance between two points on the Earth.
  /// Returns the distance in kilometers.
  static double calculateDistance(double lat1, double lng1, double lat2, double lng2) {
    const R = 6371.0; // Earth's radius in km
    final dLat = _rad(lat2 - lat1);
    final dLng = _rad(lng2 - lng1);
    final a = sin(dLat / 2) * sin(dLat / 2) +
        cos(_rad(lat1)) * cos(_rad(lat2)) * sin(dLng / 2) * sin(dLng / 2);
    return R * 2 * atan2(sqrt(a), sqrt(1 - a));
  }

  static double _rad(double deg) => deg * pi / 180;
}

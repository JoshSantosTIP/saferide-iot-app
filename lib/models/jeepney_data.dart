class JeepneyData {
  final String id;
  final String route;
  final String status; // "Available" or "Full"
  final double currentWeight;
  final double maxWeightCapacity;
  final int passengerCount;
  final int maxSeatCapacity;
  final double latitude;
  final double longitude;
  final double speed;
  final bool isOverloaded;
  final int etaSeconds; // Mock ETA
  final int lastUpdated;
  final String? operatorName;
  final String? plateNumber;
  final String? jeepneyName;
  final String? routeDescription;

  JeepneyData({
    required this.id,
    required this.route,
    required this.status,
    required this.currentWeight,
    required this.maxWeightCapacity,
    required this.passengerCount,
    required this.maxSeatCapacity,
    required this.latitude,
    required this.longitude,
    required this.speed,
    required this.isOverloaded,
    required this.etaSeconds,
    required this.lastUpdated,
    this.operatorName,
    this.plateNumber,
    this.jeepneyName,
    this.routeDescription,
  });

  factory JeepneyData.fromMap(String id, Map<dynamic, dynamic> map) {
    return JeepneyData(
      id: id,
      route: map['route'] as String? ?? 'Montalban - San Mateo',
      status: map['status'] as String? ?? 'Available',
      currentWeight: (map['current_weight'] as num?)?.toDouble() ?? 0.0,
      maxWeightCapacity:
          (map['max_weight_capacity'] as num?)?.toDouble() ?? 1000.0,
      passengerCount: (map['passenger_count'] as num?)?.toInt() ?? 0,
      maxSeatCapacity: (map['max_seat_capacity'] as num?)?.toInt() ?? 20,
      latitude: (map['latitude'] as num?)?.toDouble() ?? 14.7338,
      longitude: (map['longitude'] as num?)?.toDouble() ?? 121.1249,
      speed: (map['speed'] as num?)?.toDouble() ?? 0.0,
      isOverloaded: map['is_overloaded'] as bool? ?? false,
      etaSeconds:
          (map['eta_seconds'] as num?)?.toInt() ?? 1200, // Default 20 mins
      lastUpdated:
          (map['last_updated'] as num?)?.toInt() ??
          DateTime.now().millisecondsSinceEpoch,
      operatorName: map['operator_name'] as String? ?? 'Juan Dela Cruz', // Mock default
      plateNumber: map['plate_number'] as String? ?? 'ABC 1234', // Mock default
      jeepneyName: map['jeepney_name'] as String? ?? 'Golden Arc Expressway', // Mock default
      routeDescription: map['route_description'] as String? ?? 'via Commonwealth, Litex', // Mock default
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'route': route,
      'status': status,
      'current_weight': currentWeight,
      'max_weight_capacity': maxWeightCapacity,
      'passenger_count': passengerCount,
      'max_seat_capacity': maxSeatCapacity,
      'latitude': latitude,
      'longitude': longitude,
      'speed': speed,
      'is_overloaded': isOverloaded,
      'eta_seconds': etaSeconds,
      'last_updated': lastUpdated,
      'operator_name': operatorName,
      'plate_number': plateNumber,
      'jeepney_name': jeepneyName,
      'route_description': routeDescription,
    };
  }
}

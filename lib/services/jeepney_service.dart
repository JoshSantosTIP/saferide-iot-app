import 'dart:async';
import 'dart:convert';
import 'package:firebase_database/firebase_database.dart';
import 'package:geolocator/geolocator.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:http/http.dart' as http;
import '../models/jeepney_data.dart';
import '../models/user_profile.dart';

class JeepneyService {
  final DatabaseReference _dbRef = FirebaseDatabase.instance.ref();
  final FlutterLocalNotificationsPlugin _notificationsPlugin =
      FlutterLocalNotificationsPlugin();

  // Singleton pattern
  static final JeepneyService _instance = JeepneyService._internal();
  factory JeepneyService() => _instance;
  JeepneyService._internal();

  final Map<String, bool> _overloadStates = {};

  // Initialize Notifications
  Future<void> initializeNotifications() async {
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    // Note: iOS permissions handling is skipped for brevity but would go here
    const InitializationSettings initializationSettings =
        InitializationSettings(android: initializationSettingsAndroid);

    await _notificationsPlugin.initialize(initializationSettings);
  }

  // Task 2: Service Layer - Incoming (Sensor Data)
  Stream<JeepneyData> streamJeepneyData(String jeepId) {
    return _dbRef.child('jeepneys/$jeepId').onValue.map<JeepneyData>((event) {
      final value = event.snapshot.value;
      if (value == null) {
        // Return default data if node doesn't exist yet
        return JeepneyData(
          id: jeepId,
          route: 'Montalban - Cubao',
          plateNumber: 'Unknown',
          vehicleModel: 'Unknown',
          status: 'Available',
          currentWeight: 0,
          maxWeightCapacity: 1000,
          passengerCount: 0,
          maxSeatCapacity: 20,
          latitude: 14.7338,
          longitude: 121.1249,
          speed: 0.0,
          isOverloaded: false,
          etaSeconds: 1200,
          lastUpdated: DateTime.now().millisecondsSinceEpoch,
        );
      }
      return JeepneyData.fromMap(jeepId, value as Map<dynamic, dynamic>);
    }).asBroadcastStream();
  }

  // Task: Service Layer - Incoming All Jeepneys (Map Screen)
  Stream<List<JeepneyData>> streamAllJeepneys() {
    return _dbRef.child('jeepneys').onValue.map<List<JeepneyData>>((event) {
      final value = event.snapshot.value;
      if (value == null) return [];

      final Map<dynamic, dynamic> jeepneysMap = value as Map<dynamic, dynamic>;
      return jeepneysMap.entries.map((entry) {
        return JeepneyData.fromMap(
          entry.key.toString(),
          entry.value as Map<dynamic, dynamic>,
        );
      }).toList();
    }).asBroadcastStream();
  }

  final Map<String, bool> _weightStates = {};
  final Map<String, bool> _seatStates = {};

  // Task 2: Incoming - Check for alerts within the stream listener (side effect)
  void checkSystemAlerts(JeepneyData data) {
    bool isWeightOverloaded = data.currentWeight > data.maxWeightCapacity;
    bool isSeatFull = data.passengerCount >= data.maxSeatCapacity;

    final wasWeightOverloaded = _weightStates[data.id] ?? false;
    final wasSeatFull = _seatStates[data.id] ?? false;

    // Trigger notification if state changes from False to True for THIS jeepney
    if (isWeightOverloaded && !wasWeightOverloaded) {
      _showSystemAlertNotification(
        0,
        'WEIGHT LIMIT EXCEEDED',
        'Vehicle ${data.id} weight is above capacity!',
      );
      _logSystemAlert(
        jeepId: data.id,
        type: 'weight_overload',
        message: 'Weight limit exceeded (${data.currentWeight.toStringAsFixed(0)}/${data.maxWeightCapacity}kg)',
        latitude: data.latitude,
        longitude: data.longitude,
      );
    }

    if (isSeatFull && !wasSeatFull) {
      _showSystemAlertNotification(
        1,
        'FULL SEATS',
        'Vehicle ${data.id}: Maximum passenger count reached!',
      );
      _logSystemAlert(
        jeepId: data.id,
        type: 'full_seats',
        message: 'No more seats available (${data.passengerCount}/${data.maxSeatCapacity})',
        latitude: data.latitude,
        longitude: data.longitude,
      );
    }

    _weightStates[data.id] = isWeightOverloaded;
    _seatStates[data.id] = isSeatFull;
  }

  Future<void> _logSystemAlert({
    required String jeepId,
    required String type,
    required String message,
    required double latitude,
    required double longitude,
  }) async {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final alertRef = _dbRef.child('jeepneys/$jeepId/system_alerts').push();
    
    // Push immediately so the UI doesn't lag waiting for HTTP reverse geocode
    await alertRef.set({
      'type': type,
      'message': message,
      'latitude': latitude,
      'longitude': longitude,
      'location_name': 'Locating...',
      'timestamp': timestamp,
    });
    
    // Resolve location quietly in the background
    reverseGeocode(latitude, longitude).then((name) {
      alertRef.update({'location_name': name});
    });
  }

  Stream<List<Map<String, dynamic>>> streamSystemAlerts(String jeepId) {
    return _dbRef
        .child('jeepneys/$jeepId/system_alerts')
        .onValue
        .map<List<Map<String, dynamic>>>((event) {
      final value = event.snapshot.value;
      if (value == null) return [];
      final map = value as Map<dynamic, dynamic>;
      final list = <Map<String, dynamic>>[];
      for (final entry in map.entries) {
        final data = Map<String, dynamic>.from(entry.value as Map);
        data['id'] = entry.key.toString();
        list.add(data);
      }
      list.sort((a, b) =>
          (b['timestamp'] as int? ?? 0).compareTo(a['timestamp'] as int? ?? 0));
      return list;
    });
  }

  Future<List<Map<String, dynamic>>> fetchHistoricalBoardingLogs(String jeepId) async {
    final snapshot = await _dbRef.child('jeepneys/$jeepId/boarding_logs').get();
    if (!snapshot.exists || snapshot.value == null) return [];
    
    final map = snapshot.value as Map<dynamic, dynamic>;
    final list = <Map<String, dynamic>>[];
    for (final entry in map.entries) {
      final data = Map<String, dynamic>.from(entry.value as Map);
      data['id'] = entry.key.toString();
      list.add(data);
    }
    list.sort((a, b) =>
        (b['timestamp'] as int? ?? 0).compareTo(a['timestamp'] as int? ?? 0));
    return list;
  }

  Future<List<Map<String, dynamic>>> fetchHistoricalAlerts(String jeepId) async {
    final snapshot = await _dbRef.child('jeepneys/$jeepId/system_alerts').get();
    if (!snapshot.exists || snapshot.value == null) return [];
    
    final map = snapshot.value as Map<dynamic, dynamic>;
    final list = <Map<String, dynamic>>[];
    for (final entry in map.entries) {
      final data = Map<String, dynamic>.from(entry.value as Map);
      data['id'] = entry.key.toString();
      list.add(data);
    }
    list.sort((a, b) =>
        (b['timestamp'] as int? ?? 0).compareTo(a['timestamp'] as int? ?? 0));
    return list;
  }

  Future<void> _showSystemAlertNotification(int id, String title, String body) async {
    const AndroidNotificationDetails androidPlatformChannelSpecifics =
        AndroidNotificationDetails(
          'parago_alerts',
          'ParaGo Alerts',
          channelDescription: 'Notifications for vehicle alerts',
          importance: Importance.max,
          priority: Priority.high,
          ticker: 'ticker',
        );

    const NotificationDetails platformChannelSpecifics = NotificationDetails(
      android: androidPlatformChannelSpecifics,
    );

    await _notificationsPlugin.show(id, title, body, platformChannelSpecifics);
  }

// ── Hardware GPS Module Handled Externally ──

  // Debug/Setup: Seed initial data
  Future<void> seedInitialData(String jeepId) async {
    await _dbRef.child('jeepneys/$jeepId').set({
      'route': 'Montalban - Cubao',
      'status': 'Available',
      'current_weight': 200,
      'max_weight_capacity': 1000,
      'passenger_count': 5,
      'max_seat_capacity': 20,
      'latitude': 14.7338,
      'longitude': 121.1249,
      'is_overloaded': false,
      'eta_seconds': 1200,
      'last_updated': DateTime.now().millisecondsSinceEpoch,
    });
  }

  // Check if a jeep exists (for Login Screen)
  Future<bool> checkJeepExists(String jeepId) async {
    final snapshot = await _dbRef.child('jeepneys/$jeepId').get();
    return snapshot.exists;
  }

  // Fetch Assigned Operator Profile for a Jeepney
  Future<UserProfile?> getOperatorProfile(String jeepId) async {
    DatabaseEvent event = await _dbRef
        .child('users')
        .orderByChild('role')
        .equalTo('operator')
        .once();

    if (event.snapshot.value != null) {
      final Map<dynamic, dynamic> usersMap =
          event.snapshot.value as Map<dynamic, dynamic>;
      
      for (var entry in usersMap.entries) {
        final userData = entry.value as Map<dynamic, dynamic>;
        final assignedJeep = userData['assignedJeepney'] ?? userData['assigned_jeepney'];
        
        if (assignedJeep == jeepId) {
          return UserProfile.fromMap(userData, entry.key.toString());
        }
      }
    }
    return null;
  }

  // Fetch all route polylines
  Future<Map<String, List<Map<String, double>>>> getAllRoutes() async {
    final snapshot = await _dbRef.child('routes').get();
    if (!snapshot.exists || snapshot.value == null) return {};

    final Map<dynamic, dynamic> routesMap = snapshot.value as Map<dynamic, dynamic>;
    final result = <String, List<Map<String, double>>>{};

    for (var entry in routesMap.entries) {
      final routeId = entry.key.toString();
      final routeData = entry.value as Map<dynamic, dynamic>;
      final waypoints = routeData['waypoints'];
      if (waypoints == null) continue;

      final List<Map<String, double>> points = [];
      if (waypoints is Map) {
        // Waypoints stored as map with numeric keys
        final sortedKeys = waypoints.keys.toList()
          ..sort((a, b) => int.parse(a.toString()).compareTo(int.parse(b.toString())));
        for (var key in sortedKeys) {
          final wp = waypoints[key] as Map<dynamic, dynamic>;
          points.add({
            'lat': (wp['lat'] as num).toDouble(),
            'lng': (wp['lng'] as num).toDouble(),
          });
        }
      } else if (waypoints is List) {
        for (var wp in waypoints) {
          if (wp != null) {
            points.add({
              'lat': (wp['lat'] as num).toDouble(),
              'lng': (wp['lng'] as num).toDouble(),
            });
          }
        }
      }

      if (points.isNotEmpty) {
        result[routeData['name']?.toString() ?? routeId] = points;
      }
    }
    return result;
  }

  /// Update the current route for a jeepney
  Future<void> updateJeepneyRoute(String jeepId, String routeName, {String? routeId}) async {
    final updates = <String, dynamic>{
      'route': routeName,
    };
    if (routeId != null) {
      updates['route_id'] = routeId;
    }
    await _dbRef.child('jeepneys/$jeepId').update(updates);
  }

  // ── Passenger Alert System ────────────────────────────────────────────────

  /// Send an alert from a passenger to the operator of a jeepney
  Future<void> sendPassengerAlert({
    required String jeepId,
    required String type,
    required String message,
    required String passengerName,
  }) async {
    await _dbRef.child('jeepneys/$jeepId/alerts').push().set({
      'type': type,
      'message': message,
      'passengerName': passengerName,
      'timestamp': DateTime.now().millisecondsSinceEpoch,
      'dismissed': false,
    });
  }

  /// Stream active (undismissed) alerts for a jeepney
  Stream<List<Map<String, dynamic>>> streamAlerts(String jeepId) {
    return _dbRef
        .child('jeepneys/$jeepId/alerts')
        .orderByChild('dismissed')
        .equalTo(false)
        .onValue
        .map<List<Map<String, dynamic>>>((event) {
      final value = event.snapshot.value;
      if (value == null) return [];

      final Map<dynamic, dynamic> alertsMap = value as Map<dynamic, dynamic>;
      final alerts = <Map<String, dynamic>>[];

      for (var entry in alertsMap.entries) {
        final data = Map<String, dynamic>.from(entry.value as Map);
        data['id'] = entry.key.toString();
        alerts.add(data);
      }

      // Sort by timestamp descending (newest first)
      alerts.sort((a, b) => (b['timestamp'] as int).compareTo(a['timestamp'] as int));
      return alerts;
    });
  }

  /// Dismiss an alert
  Future<void> dismissAlert(String jeepId, String alertId) async {
    await _dbRef.child('jeepneys/$jeepId/alerts/$alertId').update({
      'dismissed': true,
    });
  }

  // ── Boarding Log System ───────────────────────────────────────────────────

  /// Reverse-geocode a lat/lng to a human-readable place name via Nominatim.
  Future<String> reverseGeocode(double lat, double lng) async {
    try {
      final uri = Uri.parse(
        'https://nominatim.openstreetmap.org/reverse'
        '?format=json&lat=$lat&lon=$lng&zoom=17&addressdetails=1',
      );
      final resp = await http.get(uri, headers: {'User-Agent': 'ParaGo/1.0'})
          .timeout(const Duration(seconds: 5));
      if (resp.statusCode == 200) {
        final data = jsonDecode(resp.body) as Map<String, dynamic>;
        final addr = data['address'] as Map<String, dynamic>? ?? {};
        // Build a readable string: road (suburb/village/town)
        final road = addr['road'] ?? addr['pedestrian'] ?? addr['path'] ?? '';
        final area = addr['suburb'] ?? addr['village'] ?? addr['city_district'] ??
            addr['quarter'] ?? addr['town'] ?? addr['city'] ?? '';
        if (road.isNotEmpty && area.isNotEmpty) return '$road, $area';
        if (road.isNotEmpty) return road;
        if (area.isNotEmpty) return area;
        return data['display_name']?.toString().split(',').take(2).join(', ') ?? 'Unknown location';
      }
    } catch (_) {}
    return 'Unknown location';
  }

  /// Write a boarding event to Firebase when passenger count changes.
  Future<void> logBoardingEvent({
    required String jeepId,
    required int passengerCount,
    required int delta,           // +1 for board, -1 for alight
    required double latitude,
    required double longitude,
    String? locationName,
  }) async {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final logRef = _dbRef.child('jeepneys/$jeepId/boarding_logs').push();
    
    // Push immediately to keep the UI instant
    await logRef.set({
      'passenger_count': passengerCount,
      'delta': delta,
      'latitude': latitude,
      'longitude': longitude,
      'location_name': locationName ?? 'Locating...',
      'timestamp': timestamp,
    });

    // If an external location string wasn't provided, fetch it in background
    if (locationName == null || locationName.isEmpty) {
      reverseGeocode(latitude, longitude).then((name) {
        logRef.update({'location_name': name});
      });
    }
  }

  /// Stream all boarding log entries for a jeepney (newest first).
  Stream<List<Map<String, dynamic>>> streamBoardingLogs(String jeepId) {
    return _dbRef
        .child('jeepneys/$jeepId/boarding_logs')
        .onValue
        .map<List<Map<String, dynamic>>>((event) {
      final value = event.snapshot.value;
      if (value == null) return [];
      final map = value as Map<dynamic, dynamic>;
      final list = <Map<String, dynamic>>[];
      for (final entry in map.entries) {
        final data = Map<String, dynamic>.from(entry.value as Map);
        data['id'] = entry.key.toString();
        list.add(data);
      }
      list.sort((a, b) =>
          (b['timestamp'] as int? ?? 0).compareTo(a['timestamp'] as int? ?? 0));
      return list;
    });
  }
}

// Extension to throttle the stream
extension StreamThrottle<T> on Stream<T> {
  Stream<T> throttle(Duration duration) {
    Timer? timer;
    T? latestData;
    bool hasPendingData = false;

    return transform(
      StreamTransformer.fromHandlers(
        handleData: (data, sink) {
          latestData = data;
          hasPendingData = true;

          if (timer == null || !timer!.isActive) {
            sink.add(data);
            hasPendingData = false;
            timer = Timer(duration, () {
              if (hasPendingData && latestData != null) {
                sink.add(latestData as T);
                hasPendingData = false;
              }
              timer = null;
            });
          }
        },
      ),
    );
  }
}

import 'dart:async';
import 'package:firebase_database/firebase_database.dart';
import 'package:geolocator/geolocator.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import '../models/jeepney_data.dart';

class JeepneyService {
  final DatabaseReference _dbRef = FirebaseDatabase.instance.ref();
  final FlutterLocalNotificationsPlugin _notificationsPlugin =
      FlutterLocalNotificationsPlugin();

  // Singleton pattern
  static final JeepneyService _instance = JeepneyService._internal();
  factory JeepneyService() => _instance;
  JeepneyService._internal();

  bool _wasOverloaded = false;

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

  // Task 2: Incoming - Check for alerts within the stream listener (side effect)
  // Or handled in UI. Here we implement the check logic function as requested.
  // Task 2: Incoming - Check for alerts within the stream listener (side effect)
  // Or handled in UI. Here we implement the check logic function as requested.
  bool checkOverload(double weight, double maxWeight, int count, int maxCount) {
    bool isWeightOverloaded = weight > maxWeight;
    bool isPassengerOverloaded = count > maxCount;
    bool isOverloaded = isWeightOverloaded || isPassengerOverloaded;

    // Trigger notification if state changes from False to True
    // We track overall overload state for the return, but notifications are specific
    if (isOverloaded && !_wasOverloaded) {
      if (isWeightOverloaded) {
        _showOverloadNotification(
          'WEIGHT LIMIT EXCEEDED',
          'Vehicle weight is above capacity!',
        );
      }
      if (isPassengerOverloaded) {
        _showOverloadNotification(
          'PASSENGER LIMIT EXCEEDED',
          'Maximum passenger count reached!',
        );
      }
    }
    _wasOverloaded = isOverloaded;

    return isOverloaded;
  }

  Future<void> _showOverloadNotification(String title, String body) async {
    const AndroidNotificationDetails androidPlatformChannelSpecifics =
        AndroidNotificationDetails(
          'saferide_alerts',
          'SafeRide Alerts',
          channelDescription: 'Notifications for vehicle overload status',
          importance: Importance.max,
          priority: Priority.high,
          ticker: 'ticker',
        );

    const NotificationDetails platformChannelSpecifics = NotificationDetails(
      android: androidPlatformChannelSpecifics,
    );

    await _notificationsPlugin.show(0, title, body, platformChannelSpecifics);
  }

  // Task 2: Service Layer - Outgoing (Location Data)
  void startLocationUpdates(String jeepId) async {
    // Request permissions first
    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) return;
    }

    final LocationSettings locationSettings = LocationSettings(
      accuracy: LocationAccuracy.high,
      distanceFilter: 10, // Update every 10 meters change
    );

    // Get position stream
    Geolocator.getPositionStream(locationSettings: locationSettings)
        .throttle(Duration(seconds: 10)) // Throttle to every 10 seconds
        .listen((Position position) {
          _updateLocation(jeepId, position);
        });
  }

  Future<void> _updateLocation(String jeepId, Position position) async {
    await _dbRef.child('jeepneys/$jeepId').update({
      'latitude': position.latitude,
      'longitude': position.longitude,
      'speed': position.speed * 3.6, // Convert m/s to km/h
      'last_updated': DateTime.now().millisecondsSinceEpoch,
    });
  }

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

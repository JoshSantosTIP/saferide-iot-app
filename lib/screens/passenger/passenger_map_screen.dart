import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import '../../services/jeepney_service.dart';
import '../../models/jeepney_data.dart';
import 'vehicle_details_screen.dart';

class PassengerMapScreen extends StatefulWidget {
  const PassengerMapScreen({super.key});

  @override
  State<PassengerMapScreen> createState() => _PassengerMapScreenState();
}

class _PassengerMapScreenState extends State<PassengerMapScreen> {
  final JeepneyService _service = JeepneyService();
  late Stream<List<JeepneyData>> _jeepsStream;
  final MapController _mapController = MapController();
  Position? _userPosition;
  bool _isLocating = true;

  @override
  void initState() {
    super.initState();
    _jeepsStream = _service.streamAllJeepneys();
    _getUserLocation();
  }

  Future<void> _getUserLocation() async {
    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      setState(() => _isLocating = false);
      return;
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        setState(() => _isLocating = false);
        return;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      setState(() => _isLocating = false);
      return;
    }

    final position = await Geolocator.getCurrentPosition();
    setState(() {
      _userPosition = position;
      _isLocating = false;
    });
  }

  String? _selectedJeepId;
  String _etaString = "Calculating...";

  Future<void> _fetchETA(JeepneyData jeep, Position? userPos) async {
    if (userPos == null) {
      if (!mounted) return;
      setState(() {
        if (jeep.etaSeconds < 60) {
          _etaString = "< 1 min";
        } else {
          _etaString = "${jeep.etaSeconds ~/ 60} min";
        }
      });
      return;
    }

    if (!mounted) return;
    setState(() {
      _etaString = "Calculating...";
    });

    try {
      final apiKey = dotenv.env['ORS_API_KEY'];
      if (apiKey == null || apiKey.isEmpty) {
        throw Exception("API Key not found");
      }

      // ORS coordinates are [longitude, latitude]
      final String start = "${jeep.longitude},${jeep.latitude}";
      final String end = "${userPos.longitude},${userPos.latitude}";
      
      final url = Uri.parse(
          'https://api.openrouteservice.org/v2/directions/driving-car?api_key=$apiKey&start=$start&end=$end');

      final response = await http.get(url);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final double durationSeconds = data['features'][0]['properties']['summary']['duration'];
        final int minutes = (durationSeconds / 60).ceil();
        
        if (!mounted) return;
        setState(() {
          if (minutes <= 1) {
            _etaString = "< 1 min";
          } else {
            _etaString = "$minutes min";
          }
        });
      } else {
        throw Exception("Failed to fetch ETA");
      }
    } catch (e) {
      debugPrint("ETA Error: $e");
      // Fallback to straight line if API fails
      final distanceMeters = Geolocator.distanceBetween(
        userPos.latitude,
        userPos.longitude,
        jeep.latitude,
        jeep.longitude,
      );
      final estimatedMinutes = (distanceMeters / 333).ceil();
      if (!mounted) return;
      setState(() {
        if (estimatedMinutes <= 1) {
          _etaString = "< 1 min";
        } else {
          _etaString = "$estimatedMinutes min";
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLocating) {
      return const Scaffold(
        backgroundColor: Color(0xFFF5F7FA),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(color: Color(0xFF0056D2)),
              SizedBox(height: 16),
              Text(
                "Finding your location...",
                style: TextStyle(
                  color: Colors.black54,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      body: StreamBuilder<List<JeepneyData>>(
        stream: _jeepsStream,
        builder: (context, snapshot) {
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: CircularProgressIndicator());
          }
          final jeeps = snapshot.data!;

          // Find selected jeep data if any
          JeepneyData? selectedJeep;
          if (_selectedJeepId != null) {
            try {
              selectedJeep = jeeps.firstWhere((j) => j.id == _selectedJeepId);
            } catch (e) {
              selectedJeep = null;
            }
          }

          // Default center: User's location OR First jeep OR static location
          final centerLat =
              selectedJeep?.latitude ??
              (_userPosition?.latitude ??
                  (jeeps.isNotEmpty ? jeeps.first.latitude : 14.7338));
          final centerLng =
              selectedJeep?.longitude ??
              (_userPosition?.longitude ??
                  (jeeps.isNotEmpty ? jeeps.first.longitude : 121.1249));

          return Stack(
            children: [
              // 1. Full Screen Map
              FlutterMap(
                mapController: _mapController,
                options: MapOptions(
                  initialCenter: LatLng(centerLat, centerLng),
                  initialZoom: 15.0,
                  onTap: (_, _) {
                    setState(() {
                      _selectedJeepId = null; // Deselect on map tap
                      _etaString = "Calculating...";
                    });
                  },
                ),
                children: [
                  TileLayer(
                    urlTemplate:
                        'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                    userAgentPackageName: 'com.saferide.app',
                  ),
                  MarkerLayer(
                    markers: jeeps.map((jeep) {
                      final isSelected = _selectedJeepId == jeep.id;
                      return Marker(
                        point: LatLng(jeep.latitude, jeep.longitude),
                        width: isSelected ? 180 : 140,
                        height: isSelected ? 120 : 100,
                        child: GestureDetector(
                          onTap: () {
                            setState(() {
                              _selectedJeepId = jeep.id;
                            });
                            _fetchETA(jeep, _userPosition);
                          },
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              // Styled Label
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 6,
                                ),
                                decoration: BoxDecoration(
                                  color: isSelected
                                      ? const Color(0xFF0056D2)
                                      : Colors.white,
                                  borderRadius: BorderRadius.circular(20),
                                  boxShadow: [
                                    BoxShadow(
                                      blurRadius: 6,
                                      color: Colors.black.withValues(
                                        alpha: 0.3,
                                      ),
                                      offset: const Offset(0, 3),
                                    ),
                                  ],
                                ),
                                child: Text(
                                  jeep.route, // Show full route
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                    color: isSelected
                                        ? Colors.white
                                        : Colors.black87,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  textAlign: TextAlign.center,
                                ),
                              ),
                              const SizedBox(height: 4),
                              // Bus Icon
                              Icon(
                                Icons.directions_bus,
                                color: const Color(0xFF0056D2),
                                size: isSelected ? 56 : 48,
                              ),
                            ],
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                  if (_userPosition != null)
                    MarkerLayer(
                      markers: [
                        Marker(
                          point: LatLng(
                            _userPosition!.latitude,
                            _userPosition!.longitude,
                          ),
                          width: 40,
                          height: 40,
                          child: Container(
                            decoration: BoxDecoration(
                              color: Colors.blueAccent.withValues(alpha: 0.3),
                              shape: BoxShape.circle,
                            ),
                            child: Center(
                              child: Container(
                                width: 20,
                                height: 20,
                                decoration: BoxDecoration(
                                  color: Colors.blue,
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: Colors.white,
                                    width: 3,
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withValues(
                                        alpha: 0.2,
                                      ),
                                      blurRadius: 4,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                ],
              ), // End FlutterMap

              // 2. Back Button
              Positioned(
                top: 40,
                left: 20,
                child: CircleAvatar(
                  backgroundColor: Colors.white,
                  child: IconButton(
                icon: const Icon(Icons.arrow_back, color: Colors.black),
                onPressed: () => Navigator.pop(context),
              ),
            ),
          ),

              // 3. View Details Card (Conditional)
              if (selectedJeep != null)
                Positioned(
                  bottom: 40,
                  left: 20,
                  right: 20,
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.15),
                          blurRadius: 20,
                          offset: const Offset(0, 10),
                        ),
                      ],
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // ETA Section
                        Padding(
                          padding: const EdgeInsets.fromLTRB(20, 16, 20, 4),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text(
                                "Driver's on the way to you",
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w700,
                                  color: Color(0xFF1A1A1A),
                                ),
                              ),
                              Text(
                                _etaString,
                                style: const TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF1A1A1A),
                                ),
                              ),
                            ],
                          ),
                        ),

                        // Top part with simple indicator
                        Padding(
                          padding: const EdgeInsets.fromLTRB(20, 4, 20, 12),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      selectedJeep.route,
                                      style: const TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.black87,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      selectedJeep.routeDescription ?? 'No route description',
                                      style: const TextStyle(
                                        fontSize: 12,
                                        color: Colors.grey,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: selectedJeep.status == 'Available'
                                      ? Colors.green.withValues(alpha: 0.1)
                                      : Colors.orange.withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  selectedJeep.status,
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: selectedJeep.status == 'Available'
                                        ? Colors.green[700]
                                        : Colors.orange[800],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        
                        const Divider(height: 1, color: Color(0xFFEEEEEE)),
                        
                        // Middle part with details
                        Padding(
                          padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
                          child: Row(
                            children: [
                              // Avatar / Icon
                              Container(
                                width: 50,
                                height: 50,
                                decoration: BoxDecoration(
                                  color: const Color(0xFFF3F7FA),
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: const Color(0xFF0056D2).withValues(alpha: 0.2),
                                    width: 2,
                                  ),
                                ),
                                child: const Icon(
                                  Icons.person,
                                  color: Color(0xFF0056D2),
                                  size: 28,
                                ),
                              ),
                              const SizedBox(width: 16),
                              
                              // Operator and Jeep details
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      selectedJeep.plateNumber ?? 'Unknown Plate',
                                      style: const TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.w800,
                                        color: Color(0xFF1A1A1A),
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      "${selectedJeep.jeepneyName} • ${selectedJeep.operatorName}",
                                      style: const TextStyle(
                                        fontSize: 13,
                                        color: Colors.black54,
                                        fontWeight: FontWeight.w500,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),

                        // Bottom part with view details button
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: const BoxDecoration(
                            color: Color(0xFFF8F9FA),
                            borderRadius: BorderRadius.only(
                              bottomLeft: Radius.circular(16),
                              bottomRight: Radius.circular(16),
                            ),
                          ),
                          child: GestureDetector(
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) =>
                                      VehicleDetailsScreen(jeepId: selectedJeep!.id),
                                ),
                              );
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              width: double.infinity,
                              decoration: BoxDecoration(
                                color: const Color(0xFF0056D2),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              alignment: Alignment.center,
                              child: const Text(
                                "View Full Details",
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 14,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}

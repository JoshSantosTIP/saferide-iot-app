import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
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
      body: Stack(
        children: [
          // 1. Full Screen Map
          StreamBuilder<List<JeepneyData>>(
            stream: _jeepsStream,
            builder: (context, snapshot) {
              if (!snapshot.hasData || snapshot.data!.isEmpty) {
                return const Center(child: CircularProgressIndicator());
              }
              final jeeps = snapshot.data!;

              // Find selected jeep data if any
              JeepneyData? selectedJeep;
              try {
                selectedJeep = jeeps.firstWhere((j) => j.id == _selectedJeepId);
              } catch (e) {
                // If selected jeep went offline or hasn't loaded yet
                selectedJeep = null;
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

              return FlutterMap(
                mapController: _mapController,
                options: MapOptions(
                  initialCenter: LatLng(centerLat, centerLng),
                  initialZoom: 15.0,
                  onTap: (_, _) {
                    setState(() {
                      _selectedJeepId = null; // Deselect on map tap
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
              );
            },
          ),

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

          // 3. View Details Button (Conditional)
          if (_selectedJeepId != null)
            Positioned(
              bottom: 40,
              left: 20,
              right: 20,
              child: GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) =>
                          VehicleDetailsScreen(jeepId: _selectedJeepId!),
                    ),
                  );
                },
                child: Container(
                  padding: const EdgeInsets.all(20),
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
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Text(
                            "Jeepney Selected",
                            style: TextStyle(fontSize: 12, color: Colors.grey),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            "View Details for ${_selectedJeepId!.toUpperCase().replaceAll('_', ' ')}",
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF1A1A1A),
                            ),
                          ),
                        ],
                      ),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: const Color(0xFF0056D2),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.arrow_forward,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

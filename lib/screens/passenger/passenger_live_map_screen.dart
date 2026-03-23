import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import '../../services/jeepney_service.dart';
import '../../models/jeepney_data.dart';
import '../../models/user_profile.dart';
import 'vehicle_details_screen.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Full-screen live tracking map (opened when user taps search / jeep card)
// ─────────────────────────────────────────────────────────────────────────────
class PassengerLiveMapScreen extends StatefulWidget {
  final Position? userPosition;
  final String? initialSelectedJeepId;
  final String? selectedRoute;

  const PassengerLiveMapScreen({
    super.key,
    this.userPosition,
    this.initialSelectedJeepId,
    this.selectedRoute,
  });

  @override
  State<PassengerLiveMapScreen> createState() => _PassengerLiveMapScreenState();
}

class _PassengerLiveMapScreenState extends State<PassengerLiveMapScreen> {
  final JeepneyService _service = JeepneyService();
  late Stream<List<JeepneyData>> _jeepsStream;
  final MapController _mapController = MapController();

  String? _selectedJeepId;
  UserProfile? _operatorProfile;

  @override
  void initState() {
    super.initState();
    _jeepsStream = _service.streamAllJeepneys();
    _selectedJeepId = widget.initialSelectedJeepId;
    _loadRoutes();
    if (_selectedJeepId != null) {
      _loadOperatorProfile(_selectedJeepId!);
    }
  }

  Future<void> _loadOperatorProfile(String jeepId) async {
    final profile = await _service.getOperatorProfile(jeepId);
    if (mounted) {
      setState(() => _operatorProfile = profile);
    }
  }

  Map<String, List<LatLng>> _routes = {};

  Future<void> _loadRoutes() async {
    final routeData = await _service.getAllRoutes();
    if (mounted) {
      setState(() {
        _routes = routeData.map((name, points) => MapEntry(
          name,
          points.map((p) => LatLng(p['lat']!, p['lng']!)).toList(),
        ));
      });
      // Center map on selected route if specified
      if (widget.selectedRoute != null && _routes.containsKey(widget.selectedRoute)) {
        final points = _routes[widget.selectedRoute]!;
        if (points.isNotEmpty) {
          final bounds = LatLngBounds.fromPoints(points);
          _mapController.fitCamera(
            CameraFit.bounds(bounds: bounds, padding: const EdgeInsets.all(50)),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
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
                selectedJeep = null;
              }

              // Default center: User's location OR First jeep OR static location
              final centerLat =
                  selectedJeep?.latitude ??
                  (widget.userPosition?.latitude ??
                      (jeeps.isNotEmpty ? jeeps.first.latitude : 14.7338));
              final centerLng =
                  selectedJeep?.longitude ??
                  (widget.userPosition?.longitude ??
                      (jeeps.isNotEmpty ? jeeps.first.longitude : 121.1249));

          return Stack(
            children: [
              // 1. Full Screen Map
              FlutterMap(
                mapController: _mapController,
                options: MapOptions(
                  initialCenter: LatLng(centerLat, centerLng),
                  initialZoom: 15.0,
                  onTap: (tapPos, point) {
                    setState(() {
                      _selectedJeepId = null;
                      _operatorProfile = null;
                    });
                  },
                ),
                children: [
                  TileLayer(
                    urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                    userAgentPackageName: 'com.parago.app',
                  ),
                  // Route polylines
                  if (_routes.isNotEmpty)
                    PolylineLayer(
                      polylines: _routes.entries.expand((entry) {
                        return [
                          // White border/outline
                          Polyline(
                            points: entry.value,
                            strokeWidth: 8.0,
                            color: Colors.white.withOpacity(0.8),
                          ),
                          // Teal route line on top
                          Polyline(
                            points: entry.value,
                            strokeWidth: 5.0,
                            color: const Color(0xFF2D6A1E),
                          ),
                        ];
                      }).toList(),
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
                              _operatorProfile = null;
                            });
                            _loadOperatorProfile(jeep.id);
                          },
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 8,
                                ),
                                decoration: BoxDecoration(
                                  color: isSelected
                                      ? const Color(0xFF2D6A1E)
                                      : Colors.white,
                                  borderRadius: BorderRadius.circular(20),
                                  boxShadow: [
                                    BoxShadow(
                                      blurRadius: isSelected ? 12 : 6,
                                      color: Colors.black.withOpacity(isSelected ? 0.15 : 0.08),
                                      offset: const Offset(0, 4),
                                    ),
                                  ],
                                ),
                                child: Text(
                                  jeep.route,
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                    color: isSelected ? Colors.white : Colors.black87,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  textAlign: TextAlign.center,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Icon(
                                Icons.directions_bus,
                                color: isSelected ? const Color(0xFF2D6A1E) : const Color(0xFF4BA028),
                                size: isSelected ? 56 : 48,
                              ),
                            ],
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                  if (widget.userPosition != null)
                    MarkerLayer(
                      markers: [
                        Marker(
                          point: LatLng(
                            widget.userPosition!.latitude,
                            widget.userPosition!.longitude,
                          ),
                          width: 40,
                          height: 40,
                          child: Container(
                            decoration: BoxDecoration(
                              color: Colors.blueAccent.withOpacity(0.3),
                              shape: BoxShape.circle,
                            ),
                            child: Center(
                              child: Container(
                                width: 20,
                                height: 20,
                                decoration: BoxDecoration(
                                  color: Colors.blue,
                                  shape: BoxShape.circle,
                                  border: Border.all(color: Colors.white, width: 3),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.2),
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

          // 2. Back Button + Route Capsule
          Positioned(
            top: 40,
            left: 20,
            right: 20,
            child: Row(
              children: [
                CircleAvatar(
                  backgroundColor: Colors.white,
                  child: IconButton(
                    icon: const Icon(Icons.arrow_back, color: Colors.black),
                    onPressed: () => Navigator.pop(context),
                  ),
                ),
                if (widget.selectedRoute != null) ...[
                  const SizedBox(width: 12),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    decoration: BoxDecoration(
                      color: const Color(0xFF2D6A1E),
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.15),
                          blurRadius: 16,
                          offset: const Offset(0, 6),
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.route, color: Colors.white, size: 16),
                        const SizedBox(width: 6),
                        Text(
                          widget.selectedRoute!,
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),

          // 3. Details Card (Conditional)
          if (_selectedJeepId != null && selectedJeep != null)
            Positioned(
              bottom: 30,
              left: 16,
              right: 16,
              child: Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.06),
                      blurRadius: 32,
                      offset: const Offset(0, 12),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          selectedJeep!.status == 'Available'
                              ? "Driver is on the way"
                              : "Jeepney is full",
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: Colors.black87,
                          ),
                        ),
                        Text(
                          "${(selectedJeep!.etaSeconds / 60).round()} min",
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF4BA028),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        selectedJeep!.route,
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.grey[600],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        CircleAvatar(
                          radius: 24,
                          backgroundColor: const Color(0xFF4BA028).withOpacity(0.15),
                          backgroundImage: _operatorProfile?.profilePictureUrl != null
                              ? NetworkImage(_operatorProfile!.profilePictureUrl!)
                              : null,
                          child: _operatorProfile?.profilePictureUrl == null
                              ? const Icon(Icons.person, color: Color(0xFF2D6A1E), size: 26)
                              : null,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                _operatorProfile?.name ?? selectedJeep!.operatorName ?? 'Loading...',
                                style: const TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.black87,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Row(
                                children: [
                                  Icon(Icons.directions_bus, size: 14, color: Colors.grey[500]),
                                  const SizedBox(width: 4),
                                  Text(
                                    "Driver",
                                    style: TextStyle(fontSize: 12, color: Colors.grey[500]),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              selectedJeep!.plateNumber,
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.black87,
                              ),
                            ),
                            Text(
                              selectedJeep!.vehicleModel,
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey[500],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) =>
                                  VehicleDetailsScreen(jeepId: _selectedJeepId!),
                            ),
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF2D6A1E),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          elevation: 2,
                        ),
                        child: const Text(
                          "View Full Details",
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ); // End inner Stack
      }, // End StreamBuilder builder
    ), // End StreamBuilder
        ],
      ), // End body Stack
    ); // End Scaffold
  }
}

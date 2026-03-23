import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:geolocator/geolocator.dart';
import '../../models/jeepney_data.dart';
import '../../services/jeepney_service.dart';
import '../../utils/geo_utils.dart';
import 'vehicle_details_screen.dart';

class PassengerNearbyScreen extends StatefulWidget {
  const PassengerNearbyScreen({super.key});

  @override
  State<PassengerNearbyScreen> createState() => _PassengerNearbyScreenState();
}

class _PassengerNearbyScreenState extends State<PassengerNearbyScreen> {
  final JeepneyService _jeepService = JeepneyService();
  Position? _userPosition;
  String _selectedRouteFilter = 'All';
  final Map<String, String> _addressCache = {};
  final Map<String, int> _lastAddressUpdate = {}; // jeepId -> timestamp

  @override
  void initState() {
    super.initState();
    _getUserLocation();
  }

  Future<void> _getUserLocation() async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) return;

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) return;
      }
      if (permission == LocationPermission.deniedForever) return;

      final position = await Geolocator.getCurrentPosition();
      if (mounted) {
        setState(() => _userPosition = position);
      }
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9FBF9), // Match Home background
      body: SafeArea(
        bottom: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 76, 24, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "Nearby\nConnections",
                    style: TextStyle(
                      fontSize: 34,
                      fontWeight: FontWeight.w900,
                      color: Color(0xFF101828),
                      height: 1.15,
                      letterSpacing: -0.5,
                    ),
                  ).animate().fadeIn(duration: 600.ms).slideX(begin: -0.1, curve: Curves.easeOutCubic),
                  const SizedBox(height: 12),
                  Text(
                    "Find and track available jeepneys near your current location.",
                    style: TextStyle(
                      fontSize: 15,
                      color: Colors.grey[600],
                      height: 1.4,
                    ),
                  ).animate(delay: 200.ms).fadeIn(duration: 600.ms).slideX(begin: -0.05, curve: Curves.easeOutCubic),
                  const SizedBox(height: 24),
                ],
              ),
            ),
            
            // List
            Expanded(
              child: _buildNearbyJeepneys(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNearbyJeepneys() {
    return StreamBuilder<List<JeepneyData>>(
      stream: _jeepService.streamAllJeepneys(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator(color: Color(0xFF2D6A1E)));
        }
        if (snapshot.hasError) {
          return const Center(child: Text("Error loading jeepneys."));
        }
        
        final allJeeps = snapshot.data ?? [];
        
        // Extract unique routes from active jeepneys
        final Set<String> uniqueRoutes = {'All'};
        for (var jeep in allJeeps) {
          if (jeep.route.isNotEmpty) {
            uniqueRoutes.add(jeep.route);
          }
        }
        final routesList = uniqueRoutes.toList()..sort((a, b) {
          if (a == 'All') return -1;
          if (b == 'All') return 1;
          return a.compareTo(b);
        });

        if (allJeeps.isEmpty) {
          return Column(
            children: [
              _buildRouteSelector(['All']),
              Expanded(child: _emptyState("No active jeepneys found on the network.")),
            ],
          );
        }

        final nearbyJeeps = _filterJeeps(allJeeps);

        return Column(
          children: [
            _buildRouteSelector(routesList),
            const SizedBox(height: 8),
            Expanded(
              child: nearbyJeeps.isEmpty
                ? _emptyState("No jeepneys within range for this route.")
                : ListView.builder(
                    padding: const EdgeInsets.fromLTRB(24, 8, 24, 120),
                    itemCount: nearbyJeeps.length,
                    itemBuilder: (context, index) {
                      return _buildJeepCard(context, nearbyJeeps[index]);
                    },
                  ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildRouteSelector(List<String> routes) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 24),
      clipBehavior: Clip.none,
      child: Row(
        children: routes.map((route) {
          final isSelected = _selectedRouteFilter == route;
          return Padding(
            padding: const EdgeInsets.only(right: 12),
            child: GestureDetector(
              onTap: () => setState(() => _selectedRouteFilter = route),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                decoration: BoxDecoration(
                  color: isSelected ? const Color(0xFF2D6A1E) : Colors.white,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(
                    color: isSelected ? const Color(0xFF2D6A1E) : Colors.black.withOpacity(0.05),
                    width: 1.5,
                  ),
                  boxShadow: isSelected
                      ? [
                          BoxShadow(
                            color: const Color(0xFF2D6A1E).withOpacity(0.3),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ]
                      : [],
                ),
                child: Text(
                  route,
                  style: TextStyle(
                    color: isSelected ? Colors.white : Colors.grey[700],
                    fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _emptyState(String msg) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: Colors.black.withOpacity(0.05), width: 1.5),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.directions_bus_filled_outlined, size: 48, color: Colors.grey[300]),
            const SizedBox(height: 16),
            Text(
              msg,
              style: TextStyle(color: Colors.grey[500], fontSize: 14, fontWeight: FontWeight.w600),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  List<JeepneyData> _filterJeeps(List<JeepneyData> jeeps) {
    final lat = _userPosition?.latitude;
    final lng = _userPosition?.longitude;

    if (lat == null || lng == null) {
      if (_selectedRouteFilter != 'All') {
        return jeeps.where((j) => j.route == _selectedRouteFilter).toList();
      }
      return jeeps;
    }

    final filtered = jeeps.where((j) {
      final matchesRoute = _selectedRouteFilter == 'All' || j.route == _selectedRouteFilter;
      if (!matchesRoute) return false;

      final dist = GeoUtils.calculateDistance(lat, lng, j.latitude, j.longitude);
      return dist <= 50000; // 50km
    }).toList();

    filtered.sort((a, b) {
      final da = GeoUtils.calculateDistance(lat, lng, a.latitude, a.longitude);
      final db = GeoUtils.calculateDistance(lat, lng, b.latitude, b.longitude);
      return da.compareTo(db);
    });

    return filtered;
  }

  Future<void> _fetchAddress(String jeepId, double lat, double lng) async {
    final now = DateTime.now().millisecondsSinceEpoch;
    final lastUpdate = _lastAddressUpdate[jeepId] ?? 0;
    
    // Throttle: once every 30 seconds per jeep to respect Nominatim usage policy
    if (now - lastUpdate < 30000) return;
    
    _lastAddressUpdate[jeepId] = now;
    
    try {
      final url = Uri.parse('https://nominatim.openstreetmap.org/reverse?format=json&lat=$lat&lon=$lng&zoom=18');
      final response = await http.get(url, headers: {'User-Agent': 'ParaGo-App'});
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final address = data['address'];
        String locationName = "";
        
        if (address != null) {
          // Priority: Road > Suburb > Neighbourhood > City
          locationName = address['road'] ?? address['suburb'] ?? address['neighbourhood'] ?? address['city'] ?? "";
        }
        
        if (mounted && locationName.isNotEmpty) {
          setState(() {
            _addressCache[jeepId] = locationName;
          });
        }
      }
    } catch (_) {
      // Quietly fail for network/API issues
    }
  }

  Widget _buildJeepCard(BuildContext context, JeepneyData jeep) {
    final lat = _userPosition?.latitude;
    final lng = _userPosition?.longitude;
    final distanceKm = (lat != null && lng != null)
        ? GeoUtils.calculateDistance(lat, lng, jeep.latitude, jeep.longitude)
        : null;

    String distanceStr = "Distance unknown";
    if (distanceKm != null) {
      final distanceMeters = distanceKm * 1000;
      if (distanceMeters < 1000) {
        distanceStr = "${distanceMeters.toStringAsFixed(0)} m away";
      } else {
        distanceStr = "${distanceKm.toStringAsFixed(1)} km away";
      }
    }

    // Trigger address fetch if not in cache
    final String? cachedAddress = _addressCache[jeep.id];
    if (cachedAddress == null) {
      _fetchAddress(jeep.id, jeep.latitude, jeep.longitude);
    }

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => VehicleDetailsScreen(jeepId: jeep.id),
          ),
        );
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: Colors.black.withOpacity(0.04), width: 1.5),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.02),
              blurRadius: 15,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Minimal icon
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF3FBF5),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: const Icon(Icons.directions_bus_rounded, color: Color(0xFF2D6A1E), size: 24),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Expanded(
                            child: Text(
                              jeep.id.toUpperCase().replaceAll('_', ' '),
                              style: const TextStyle(
                                fontSize: 17,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF111827),
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.grey[100],
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(color: Colors.grey[300]!, width: 0.5),
                            ),
                            child: Text(
                              jeep.plateNumber,
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w800,
                                color: Colors.grey.shade600,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        jeep.route,
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.grey[700],
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Container(
                            width: 6,
                            height: 6,
                            decoration: const BoxDecoration(
                              color: Color(0xFF4BA028),
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              "Moving near ${cachedAddress ?? jeep.routeDescription ?? '... '}",
                              style: TextStyle(
                                fontSize: 11,
                                color: Colors.grey[500],
                                fontStyle: FontStyle.italic,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            // Metrics row
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildMiniMetric(Icons.location_on_rounded, distanceStr, isCritical: false, isPrimary: true),
                _buildMiniMetric(Icons.event_seat_rounded, "${jeep.availableSeats} seats", 
                  isCritical: jeep.isPassengerOverloaded),
                _buildMiniMetric(Icons.monitor_weight_outlined, "${jeep.currentWeight.toStringAsFixed(0)}kg", 
                  isCritical: jeep.isWeightOverloaded),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMiniMetric(IconData icon, String text, {required bool isCritical, bool isPrimary = false}) {
    final Color bgColor = isCritical ? const Color(0xFFFFF5F5) : (isPrimary ? const Color(0xFFF3FBF5) : Colors.white);
    final Color borderColor = isCritical ? const Color(0xFFFECACA) : (isPrimary ? const Color(0xFFD0F0D8) : Colors.black.withOpacity(0.05));
    final Color iconColor = isCritical ? const Color(0xFFD32F2F) : (isPrimary ? const Color(0xFF2D6A1E) : Colors.grey.shade600);
    final Color textColor = isCritical ? const Color(0xFF991B1B) : (isPrimary ? const Color(0xFF18331A) : Colors.grey.shade600);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: borderColor,
          width: 1.5,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: iconColor),
          const SizedBox(width: 6),
          Text(text, style: TextStyle(
            fontSize: 11.5,
            fontWeight: (isCritical || isPrimary) ? FontWeight.bold : FontWeight.w600,
            color: textColor,
          )),
        ],
      ),
    );
  }
}

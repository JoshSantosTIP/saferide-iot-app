import 'dart:convert';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import '../../services/jeepney_service.dart';
import '../../services/auth_service.dart';
import '../../models/jeepney_data.dart';
import '../../models/user_profile.dart';
import '../splash_screen.dart';
import '../login_screen.dart'; // Added import for LoginScreen
import 'vehicle_details_screen.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Home screen shown to passenger after login
// ─────────────────────────────────────────────────────────────────────────────
class PassengerMapScreen extends StatefulWidget {
  const PassengerMapScreen({super.key});

  @override
  State<PassengerMapScreen> createState() => _PassengerMapScreenState();
}

class _PassengerMapScreenState extends State<PassengerMapScreen> {
  final JeepneyService _jeepService = JeepneyService();
  final AuthService _authService = AuthService();

  Position? _userPosition;
  UserProfile? _userProfile;
  bool _isLocating = true;
  bool _isLoading = false;
  String? _locationAddress;

  @override
  void initState() {
    super.initState();
    _loadUserProfile();
    _getUserLocation();
  }

  String get _displayName {
    if (_userProfile?.name == null || _userProfile!.name.isEmpty) return 'Unknown';
    return _userProfile!.name;
  }

  String _greeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good morning';
    if (hour < 17) return 'Good afternoon';
    return 'Good evening';
  }

  Future<void> _loadUserProfile() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid != null) {
      final profile = await _authService.getUserProfile(uid);
      if (mounted) setState(() => _userProfile = profile);
    }
  }

  Future<void> _getUserLocation() async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        setState(() => _isLocating = false);
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();
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
      _reverseGeocode(position.latitude, position.longitude);
    } catch (e) {
      setState(() => _isLocating = false);
    }
  }

  Future<void> _reverseGeocode(double lat, double lng) async {
    try {
      final url = Uri.parse(
        'https://nominatim.openstreetmap.org/reverse?lat=$lat&lon=$lng&format=json&addressdetails=1',
      );
      final response = await http.get(url, headers: {
        'User-Agent': 'ParaGoApp/1.0',
      });
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final address = data['address'] as Map<String, dynamic>?;
        if (address != null && mounted) {
          // Build a readable address from parts
          final road = address['road'] ?? address['pedestrian'] ?? address['highway'];
          final suburb = address['suburb'] ?? address['neighbourhood'] ?? address['village'];
          final city = address['city'] ?? address['town'] ?? address['municipality'];
          
          final parts = <String>[];
          if (road != null) parts.add(road.toString());
          if (suburb != null) parts.add(suburb.toString());
          if (city != null) parts.add(city.toString());
          
          if (parts.isNotEmpty) {
            setState(() => _locationAddress = parts.join(', '));
          }
        }
      }
    } catch (e) {
      // Silently fail — coordinates will be shown as fallback
    }
  }

  String? _selectedJeepId;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF0F4F8),
      body: Stack( // Wrapped body in a Stack
        children: [
          Column(
            children: [
              // ── Teal header ──────────────────────────────────────────────────
              _buildHeader(context),

              // ── Scrollable body ──────────────────────────────────────────────
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Map card
                      _buildMapCard(),
                      const SizedBox(height: 16),

                      // Current location
                      _buildLocationRow(),
                      const SizedBox(height: 20),

                      // Select route
                      _buildRouteSelector(context),
                      const SizedBox(height: 20),

                      // Nearby jeepneys section
                      _buildNearbyJeepneys(context),
                    ],
                  ),
                ),
              ),
            ],
          ),
          if (_isLoading)
            Container(
              color: Colors.black.withOpacity(0.3),
              child: const Center(
                child: Card(
                  elevation: 8,
                  child: Padding(
                    padding: EdgeInsets.all(24.0),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        CircularProgressIndicator(color: Color(0xFF1A7D6F)),
                        SizedBox(height: 16),
                        Text("Logging out...", style: TextStyle(fontWeight: FontWeight.w600)),
                      ],
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  // ── HEADER ─────────────────────────────────────────────────────────────────
  Widget _buildHeader(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF1A7D6F), Color(0xFF25A896)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: Stack(
          children: [
            // Decorative city silhouette
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: SizedBox(
                height: 70,
                child: CustomPaint(
                  size: Size(MediaQuery.of(context).size.width, 70),
                  painter: _CitySkylinePainter(),
                ),
              ),
            ),

            // Content
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 56),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Top row: avatar + sign out
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      CircleAvatar(
                        radius: 20,
                        backgroundColor: Colors.white24,
                        backgroundImage: _userProfile?.profilePictureUrl != null
                            ? NetworkImage(_userProfile!.profilePictureUrl!)
                            : null,
                        child: _userProfile?.profilePictureUrl == null
                            ? const Icon(Icons.person, color: Colors.white, size: 22)
                            : null,
                      ),
                      IconButton(
                        icon: const Icon(Icons.logout, color: Colors.white70, size: 22),
                        onPressed: () {
                          final outerContext = context;
                          showDialog(
                            context: context,
                            builder: (dialogContext) => Dialog(
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                              child: Padding(
                                padding: const EdgeInsets.all(24.0),
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(16),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFF1A7D6F).withOpacity(0.1),
                                        shape: BoxShape.circle,
                                      ),
                                      child: const Icon(Icons.logout_rounded, color: Color(0xFF1A7D6F), size: 32),
                                    ),
                                    const SizedBox(height: 16),
                                    const Text(
                                      "Logout",
                                      style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF1A1A1A)),
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      "Are you sure you want to sign out of your account?",
                                      textAlign: TextAlign.center,
                                      style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                                    ),
                                    const SizedBox(height: 24),
                                    Row(
                                      children: [
                                        Expanded(
                                          child: TextButton(
                                            onPressed: () => Navigator.pop(dialogContext),
                                            style: TextButton.styleFrom(
                                              padding: const EdgeInsets.symmetric(vertical: 14),
                                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                            ),
                                            child: Text("Cancel", style: TextStyle(color: Colors.grey[600], fontWeight: FontWeight.w600)),
                                          ),
                                        ),
                                        const SizedBox(width: 12),
                                        Expanded(
                                          child: ElevatedButton(
                                            onPressed: () async {
                                              print("[PassengerMapScreen] Logout confirmed by user");
                                              Navigator.pop(dialogContext); // Close dialog
                                              
                                              setState(() => _isLoading = true); // Set _isLoading to true

                                              try {
                                                print("[PassengerMapScreen] Calling signOut with 5s timeout...");
                                                await _authService.signOut().timeout(
                                                  const Duration(seconds: 5),
                                                  onTimeout: () => print("[PassengerMapScreen] signOut timed out!"),
                                                );
                                              } catch (e) {
                                                print("[PassengerMapScreen] Error during signOut call: $e");
                                              }

                                              if (outerContext.mounted) {
                                                print("[PassengerMapScreen] Navigating directly to LoginScreen...");
                                                Navigator.of(outerContext).pushAndRemoveUntil(
                                                  MaterialPageRoute(builder: (_) => const LoginScreen()),
                                                  (_) => false,
                                                );
                                              }
                                              
                                              // Fallback if navigation somehow fails
                                              if (mounted) {
                                                setState(() => _isLoading = false);
                                              }
                                            },
                                            style: ElevatedButton.styleFrom(
                                              backgroundColor: const Color(0xFFD32F2F),
                                              foregroundColor: Colors.white,
                                              elevation: 0,
                                              padding: const EdgeInsets.symmetric(vertical: 14),
                                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                            ),
                                            child: const Text("Logout", style: TextStyle(fontWeight: FontWeight.bold)),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    "${_greeting()}, $_displayName",
                    style: const TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    "Track your nearest ParaGo jeepney.",
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.white70,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── MAP CARD ───────────────────────────────────────────────────────────────
  Widget _buildMapCard() {
    final lat = _userPosition?.latitude ?? 14.7338;
    final lng = _userPosition?.longitude ?? 121.1249;

    return Container(
      height: 200,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.10),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: _isLocating
            ? Container(
                color: Colors.grey[200],
                child: const Center(
                  child: CircularProgressIndicator(color: Color(0xFF25A896)),
                ),
              )
            : FlutterMap(
                options: MapOptions(
                  initialCenter: LatLng(lat, lng),
                  initialZoom: 15.0,
                  interactionOptions: const InteractionOptions(
                    flags: InteractiveFlag.none, // static preview
                  ),
                ),
                children: [
                  TileLayer(
                    urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                    userAgentPackageName: 'com.parago.app',
                  ),
                  MarkerLayer(
                    markers: [
                      Marker(
                        point: LatLng(lat, lng),
                        width: 40,
                        height: 40,
                        child: Container(
                          decoration: BoxDecoration(
                            color: const Color(0xFF25A896).withOpacity(0.25),
                            shape: BoxShape.circle,
                          ),
                          child: Center(
                            child: Container(
                              width: 18,
                              height: 18,
                              decoration: BoxDecoration(
                                color: const Color(0xFF1A7D6F),
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
              ),
      ),
    );
  }

  // ── CURRENT LOCATION ROW ───────────────────────────────────────────────────
  Widget _buildLocationRow() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: const Color(0xFF25A896).withOpacity(0.12),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.my_location, color: Color(0xFF1A7D6F), size: 22),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  "Your current location",
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                    color: Color(0xFF1A1A1A),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  _locationAddress ?? 
                    (_userPosition != null
                      ? "${_userPosition!.latitude.toStringAsFixed(4)}°N, ${_userPosition!.longitude.toStringAsFixed(4)}°E"
                      : "Location not available"),
                  style: TextStyle(fontSize: 13, color: Colors.grey[600]),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── SELECT ROUTE ─────────────────────────────────────────────────────────
  Widget _buildRouteSelector(BuildContext context) {
    return FutureBuilder<Map<String, List<Map<String, double>>>>(
      future: _jeepService.getAllRoutes(),
      builder: (context, snapshot) {
        final routes = snapshot.data?.keys.toList() ?? [];

        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.06),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                "Select a Route",
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 15,
                  color: Color(0xFF1A1A1A),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                "Choose your jeepney route to view the live map",
                style: TextStyle(fontSize: 13, color: Colors.grey[500]),
              ),
              const SizedBox(height: 14),
              if (routes.isEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Text(
                    "No routes available",
                    style: TextStyle(fontSize: 13, color: Colors.grey[400]),
                  ),
                )
              else
                ...routes.map((route) => Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(12),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => PassengerLiveMapScreen(
                            userPosition: _userPosition,
                            selectedRoute: route,
                          ),
                        ),
                      );
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                      decoration: BoxDecoration(
                        color: const Color(0xFF25A896).withOpacity(0.06),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: const Color(0xFF25A896).withOpacity(0.15),
                        ),
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: const Color(0xFF25A896).withOpacity(0.15),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.directions_bus,
                              color: Color(0xFF1A7D6F),
                              size: 20,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              route,
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF1A1A1A),
                              ),
                            ),
                          ),
                          const Icon(
                            Icons.arrow_forward_ios,
                            color: Color(0xFF25A896),
                            size: 16,
                          ),
                        ],
                      ),
                    ),
                  ),
                )),
            ],
          ),
        );
      },
    );
  }

  // ── NEARBY JEEPNEYS PREVIEW ────────────────────────────────────────────────
  Widget _buildNearbyJeepneys(BuildContext context) {
    return StreamBuilder<List<JeepneyData>>(
      stream: _jeepService.streamAllJeepneys(),
      builder: (context, snapshot) {
        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return const SizedBox.shrink();
        }

        final jeeps = snapshot.data!;
        // Sort by distance if we have user position
        List<JeepneyData> sorted = List.from(jeeps);
        if (_userPosition != null) {
          sorted.sort((a, b) {
            double distA = _dist(
              _userPosition!.latitude, _userPosition!.longitude,
              a.latitude, a.longitude,
            );
            double distB = _dist(
              _userPosition!.latitude, _userPosition!.longitude,
              b.latitude, b.longitude,
            );
            return distA.compareTo(distB);
          });
        }

        final nearby = sorted.take(3).toList();

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  "Nearby Jeepneys",
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1A1A1A),
                  ),
                ),
                GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => PassengerLiveMapScreen(
                          userPosition: _userPosition,
                        ),
                      ),
                    );
                  },
                  child: const Text(
                    "See all on map",
                    style: TextStyle(
                      fontSize: 13,
                      color: Color(0xFF25A896),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            ...nearby.map((jeep) => _buildJeepCard(context, jeep)),
          ],
        );
      },
    );
  }

  Widget _buildJeepCard(BuildContext context, JeepneyData jeep) {
    final distKm = _userPosition != null
        ? _dist(
            _userPosition!.latitude, _userPosition!.longitude,
            jeep.latitude, jeep.longitude,
          )
        : null;

    final distStr = distKm != null
        ? distKm < 1
            ? "${(distKm * 1000).toStringAsFixed(0)} m away"
            : "${distKm.toStringAsFixed(1)} km away"
        : "Distance unknown";

    final seatsLeft = jeep.maxSeatCapacity - jeep.passengerCount;

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => PassengerLiveMapScreen(
              userPosition: _userPosition,
              initialSelectedJeepId: jeep.id,
            ),
          ),
        );
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 8,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: jeep.status == 'Available'
                    ? const Color(0xFF25A896).withOpacity(0.12)
                    : Colors.orange.withOpacity(0.12),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                Icons.directions_bus,
                color: jeep.status == 'Available'
                    ? const Color(0xFF1A7D6F)
                    : Colors.orange[700],
                size: 24,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    jeep.route,
                    style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 14,
                      color: Color(0xFF1A1A1A),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 3),
                  Text(
                    "$distStr  •  ${jeep.plateNumber}",
                    style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(
                        Icons.event_seat,
                        size: 14,
                        color: seatsLeft > 0 ? const Color(0xFF25A896) : Colors.red[400],
                      ),
                      const SizedBox(width: 4),
                      Text(
                        seatsLeft > 0
                            ? "$seatsLeft seat${seatsLeft == 1 ? '' : 's'} available"
                            : "No seats available",
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: seatsLeft > 0 ? const Color(0xFF25A896) : Colors.red[400],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: jeep.status == 'Available'
                    ? const Color(0xFF25A896).withOpacity(0.12)
                    : Colors.orange.withOpacity(0.12),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                jeep.status,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: jeep.status == 'Available'
                      ? const Color(0xFF1A7D6F)
                      : Colors.orange[800],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  double _dist(double lat1, double lng1, double lat2, double lng2) {
    const R = 6371.0;
    final dLat = _rad(lat2 - lat1);
    final dLng = _rad(lng2 - lng1);
    final a = sin(dLat / 2) * sin(dLat / 2) +
        cos(_rad(lat1)) * cos(_rad(lat2)) * sin(dLng / 2) * sin(dLng / 2);
    return R * 2 * atan2(sqrt(a), sqrt(1 - a));
  }

  double _rad(double deg) => deg * pi / 180;
}

// ─────────────────────────────────────────────────────────────────────────────
// City skyline decorative painter
// ─────────────────────────────────────────────────────────────────────────────
class _CitySkylinePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = Colors.white.withOpacity(0.10);

    // Draw each building as a separate rect for simplicity
    final buildings = [
      [10.0, 50.0, 30.0],
      [45.0, 30.0, 25.0],
      [75.0, 45.0, 35.0],
      [115.0, 20.0, 20.0],
      [140.0, 38.0, 28.0],
      [175.0, 55.0, 22.0],
      [200.0, 25.0, 30.0],
      [240.0, 40.0, 25.0],
      [270.0, 50.0, 35.0],
      [315.0, 28.0, 20.0],
      [340.0, 42.0, 30.0],
    ];

    for (final b in buildings) {
      final x = b[0];
      final h = b[1];
      final w = b[2];
      canvas.drawRect(
        Rect.fromLTWH(x, size.height - h, w, h),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

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
  JeepneyData? _selectedJeep;
  Map<String, List<LatLng>> _routes = {};
  UserProfile? _operatorProfile;
  bool _isLoading = false; // Added _isLoading state

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
                // If selected jeep went offline or hasn't loaded yet
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
                  onTap: (_, _) {
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
                            color: Colors.white.withValues(alpha: 0.8),
                          ),
                          // Teal route line on top
                          Polyline(
                            points: entry.value,
                            strokeWidth: 5.0,
                            color: const Color(0xFF1A7D6F),
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
                                  horizontal: 10, vertical: 6,
                                ),
                                decoration: BoxDecoration(
                                  color: isSelected
                                      ? const Color(0xFF1A7D6F)
                                      : Colors.white,
                                  borderRadius: BorderRadius.circular(20),
                                  boxShadow: [
                                    BoxShadow(
                                      blurRadius: 6,
                                      color: Colors.black.withValues(alpha: 0.3),
                                      offset: const Offset(0, 3),
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
                                color: const Color(0xFF1A7D6F),
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
                                  border: Border.all(color: Colors.white, width: 3),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withValues(alpha: 0.2),
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
                      color: const Color(0xFF1A7D6F),
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.2),
                          blurRadius: 8,
                          offset: const Offset(0, 3),
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
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.12),
                      blurRadius: 24,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // ── Status row: "Driver is on the way" + ETA ──
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
                            color: Color(0xFF1A1A1A),
                          ),
                        ),
                        Text(
                          "${(selectedJeep!.etaSeconds / 60).round()} min",
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF25A896),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    // ── Route name ──
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
                    // ── Driver info + Plate ──
                    Row(
                      children: [
                        // Driver avatar
                        CircleAvatar(
                          radius: 24,
                          backgroundColor: const Color(0xFF25A896).withValues(alpha: 0.15),
                          backgroundImage: _operatorProfile?.profilePictureUrl != null
                              ? NetworkImage(_operatorProfile!.profilePictureUrl!)
                              : null,
                          child: _operatorProfile?.profilePictureUrl == null
                              ? const Icon(Icons.person, color: Color(0xFF1A7D6F), size: 26)
                              : null,
                        ),
                        const SizedBox(width: 12),
                        // Driver name
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                _operatorProfile?.name ?? selectedJeep!.operatorName ?? 'Loading...',
                                style: const TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w600,
                                  color: Color(0xFF1A1A1A),
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
                        // Plate number + Vehicle model
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              selectedJeep!.plateNumber,
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF1A1A1A),
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
                    // ── View Full Details button ──
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
                          backgroundColor: const Color(0xFF25A896),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16), // Increased padding
                          minimumSize: const Size(double.infinity, 54), // Explicit height and full width
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(30),
                          ),
                          elevation: 0,
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

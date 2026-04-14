import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import '../../widgets/chatbot_widget.dart';
import 'passenger_live_map_screen.dart';

class PassengerMapScreen extends StatefulWidget {
  const PassengerMapScreen({super.key});

  @override
  State<PassengerMapScreen> createState() => _PassengerMapScreenState();
}

class _PassengerMapScreenState extends State<PassengerMapScreen> {
  Position? _userPosition;
  bool _isLocating = true;
  String? _locationAddress;

  @override
  void initState() {
    super.initState();
    _getUserLocation();
  }

  Future<void> _getUserLocation() async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) { setState(() => _isLocating = false); return; }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          setState(() => _isLocating = false); return;
        }
      }
      if (permission == LocationPermission.deniedForever) {
        setState(() => _isLocating = false); return;
      }

      final position = await Geolocator.getCurrentPosition();
      setState(() { _userPosition = position; _isLocating = false; });
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
      final response = await http.get(url, headers: {'User-Agent': 'ParaGoApp/1.0'});
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final address = data['address'] as Map<String, dynamic>?;
        if (address != null && mounted) {
          final road = address['road'] ?? address['pedestrian'] ?? address['highway'];
          final suburb = address['suburb'] ?? address['neighbourhood'] ?? address['village'];
          final city = address['city'] ?? address['town'] ?? address['municipality'];
          final parts = <String>[];
          if (road != null) parts.add(road.toString());
          if (suburb != null) parts.add(suburb.toString());
          if (city != null) parts.add(city.toString());
          if (parts.isNotEmpty) setState(() => _locationAddress = parts.join(', '));
        }
      }
    } catch (e) { /* silently fail */ }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9FBF9), // Ultra-clean light background
      body: SafeArea(
        bottom: false,
        child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(24, 24, 24, 40), // Added top padding for global logo
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ── Greeting ───────────────────────────
                  const Text(
                    "Track your\njourney",
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
                    "Your intelligent companion for finding safe and secure transport across the city.",
                    style: TextStyle(
                      fontSize: 15,
                      color: Colors.grey[600],
                      height: 1.4,
                    ),
                  ).animate(delay: 200.ms).fadeIn(duration: 600.ms).slideX(begin: -0.05, curve: Curves.easeOutCubic),
                  const SizedBox(height: 16),
                  
                  // ── Location chip ──────────────────────
                  Row(
                    children: [
                      const Icon(Icons.location_on, color: Color(0xFF2D6A1E), size: 16),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          _isLocating
                              ? "Getting your location…"
                              : (_locationAddress ?? "Location unavailable"),
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.grey[600],
                            fontWeight: FontWeight.w500,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ).animate(delay: 400.ms).fadeIn(duration: 400.ms),
                  const SizedBox(height: 36),

                  // ── Map Card (Build my resume style) ───
                  _buildLargeFeatureCard(
                    context,
                    title: "Live Map View",
                    subtitle: "Track nearby jeepneys in real-time on your route.",
                    icon: Icons.map_rounded,
                    child: _buildMapWidget(context),
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => PassengerLiveMapScreen(userPosition: _userPosition)),
                    ),
                  ).animate(delay: 500.ms).fadeIn(duration: 600.ms).slideY(begin: 0.1, curve: Curves.easeOutCubic),

                ],
          ),
        ),
      ),
    );
  }

  Widget _buildLargeFeatureCard(BuildContext context, {
    required String title,
    required String subtitle,
    required IconData icon,
    required Widget child,
    VoidCallback? onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
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
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF3FBF5),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Icon(icon, color: const Color(0xFF2D6A1E), size: 24),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF111827),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        subtitle,
                        style: TextStyle(fontSize: 13, color: Colors.grey[500], height: 1.3),
                      ),
                    ],
                  ),
                ),
                if (onTap != null) ...[
                  const SizedBox(width: 12),
                  const Icon(Icons.arrow_forward_rounded, color: Color(0xFF2D6A1E), size: 20),
                ],
              ],
            ),
            const SizedBox(height: 20),
            child,
          ],
        ),
      ),
    );
  }

  Widget _buildMapWidget(BuildContext context) {
    final lat = _userPosition?.latitude ?? 14.7338;
    final lng = _userPosition?.longitude ?? 121.1249;

    return Container(
      height: 200,
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.black.withOpacity(0.05)),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: _isLocating
            ? const Center(child: CircularProgressIndicator(color: Color(0xFF2D6A1E)))
            : IgnorePointer(
                child: FlutterMap(
                  options: MapOptions(
                    initialCenter: LatLng(lat, lng),
                    initialZoom: 15.0,
                    interactionOptions: const InteractionOptions(flags: InteractiveFlag.none),
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
                          width: 44,
                          height: 44,
                          child: Container(
                            decoration: BoxDecoration(
                              color: const Color(0xFF2D6A1E).withOpacity(0.2),
                              shape: BoxShape.circle,
                            ),
                            child: Center(
                              child: Container(
                                width: 20,
                                height: 20,
                                decoration: BoxDecoration(
                                  color: const Color(0xFF2D6A1E),
                                  shape: BoxShape.circle,
                                  border: Border.all(color: Colors.white, width: 3),
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
      ),
    );
  }
}

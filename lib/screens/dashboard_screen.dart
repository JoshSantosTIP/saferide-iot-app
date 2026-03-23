import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../models/jeepney_data.dart';
import '../services/jeepney_service.dart';
import '../services/auth_service.dart';
import '../widgets/chatbot_widget.dart';
import 'login_screen.dart';

class DashboardScreen extends StatefulWidget {
  final String jeepId;

  const DashboardScreen({super.key, required this.jeepId});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen>
    with TickerProviderStateMixin {
  final JeepneyService _service = JeepneyService();
  late Stream<JeepneyData> _jeepStream;
  final MapController _mapController = MapController();

  // Passenger alerts
  List<Map<String, dynamic>> _alerts = [];
  late StreamSubscription _alertSubscription;
  bool _isLoggingOut = false;

  @override
  void initState() {
    super.initState();
    _jeepStream = _service.streamJeepneyData(widget.jeepId);
    _service.initializeNotifications();
    _service.startLocationUpdates(widget.jeepId);

    // Subscribe to passenger alerts
    _alertSubscription = _service.streamAlerts(widget.jeepId).listen((alerts) {
      if (mounted) setState(() => _alerts = alerts);
    });
  }

  @override
  void dispose() {
    _alertSubscription.cancel();
    super.dispose();
  }

  // Helper for smooth map movement
  void _animatedMapMove(LatLng destLocation, double destZoom) {
    final latTween = Tween<double>(
      begin: _mapController.camera.center.latitude,
      end: destLocation.latitude,
    );
    final lngTween = Tween<double>(
      begin: _mapController.camera.center.longitude,
      end: destLocation.longitude,
    );
    final zoomTween = Tween<double>(
      begin: _mapController.camera.zoom,
      end: destZoom,
    );

    final controller = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );

    final Animation<double> animation = CurvedAnimation(
      parent: controller,
      curve: Curves.fastOutSlowIn,
    );

    controller.addListener(() {
      _mapController.move(
        LatLng(latTween.evaluate(animation), lngTween.evaluate(animation)),
        zoomTween.evaluate(animation),
      );
    });

    animation.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        controller.dispose();
      } else if (status == AnimationStatus.dismissed) {
        controller.dispose();
      }
    });

    controller.forward();
  }

  String _timeAgo(int timestamp) {
    final diff = DateTime.now().difference(DateTime.fromMillisecondsSinceEpoch(timestamp));
    if (diff.inSeconds < 60) return "${diff.inSeconds}s ago";
    if (diff.inMinutes < 60) return "${diff.inMinutes}m ago";
    return "${diff.inHours}h ago";
  }

  IconData _alertIcon(String type) {
    switch (type) {
      case 'stop_request':
        return Icons.pan_tool_rounded;
      case 'emergency':
        return Icons.warning_rounded;
      case 'overloading':
        return Icons.groups_rounded;
      default:
        return Icons.notification_important_rounded;
    }
  }

  Color _alertColor(String type) {
    switch (type) {
      case 'stop_request':
        return const Color(0xFFFF9800);
      case 'emergency':
        return const Color(0xFFD32F2F);
      case 'overloading':
        return const Color(0xFF1565C0);
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9FBF9), // Premium light background
      floatingActionButton: const ChatbotFab(), // Add AI Assistant for Operator
      body: Stack(
        children: [
          Column(
            children: [
              _buildHeader(context),
              Expanded(
                child: StreamBuilder<JeepneyData>(
                  stream: _jeepStream,
                  builder: (context, snapshot) {
                    if (!snapshot.hasData) {
                      return const Center(child: CircularProgressIndicator(color: Color(0xFF2D6A1E)));
                    }

                    final data = snapshot.data!;
                    final isWeightOverloaded = data.isWeightOverloaded;
                    final isSafe = data.isSafe;
                    final loadPercent = data.weightLoadPercentage;

                    return Column(
                      children: [
                        // 1. Safety & Passenger Alerts
                        Expanded(
                          child: SingleChildScrollView(
                            padding: const EdgeInsets.fromLTRB(24, 12, 24, 40),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Safety Banner (Weight)
                                _buildSafetyStatusBanner(isSafe, isWeightOverloaded),
                                
                                // Passenger Alerts
                                if (_alerts.isNotEmpty) ...[
                                  const SizedBox(height: 16),
                                  const Text(
                                    "PASSENGER REQUESTS",
                                    style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: Colors.grey, letterSpacing: 1.0),
                                  ),
                                  const SizedBox(height: 8),
                                  ..._alerts.map((alert) => _buildPassengerAlertCard(alert)),
                                ],
                                
                                const SizedBox(height: 24),

                                // Map Card
                                _buildMinimapCard(data),
                                const SizedBox(height: 24),

                                // Stats Grid
                                Row(
                                  children: [
                                    Expanded(
                                      child: _buildMetricCard(
                                        icon: Icons.event_seat_rounded,
                                        label: "Seats",
                                        value: "${data.passengerCount}",
                                        sub: "Occupied",
                                        isCritical: false,
                                        primary: true,
                                      ),
                                    ),
                                    const SizedBox(width: 16),
                                    Expanded(
                                      child: _buildMetricCard(
                                        icon: Icons.monitor_weight_outlined,
                                        label: "Payload",
                                        value: "${loadPercent.toStringAsFixed(0)}%",
                                        sub: "Capacity",
                                        isCritical: isWeightOverloaded,
                                        primary: false,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 24),

                                // Vehicle Details
                                const Text(
                                  "VEHICLE READINGS",
                                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: Colors.grey, letterSpacing: 1.0),
                                ),
                                const SizedBox(height: 12),
                                _buildReadingsCard(data),
                              ],
                            ),
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ),
            ],
          ),
          if (_isLoggingOut)
            Container(
              color: Colors.black.withOpacity(0.4),
              child: const Center(
                child: Card(
                  elevation: 0,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(24))),
                  child: Padding(
                    padding: EdgeInsets.all(32),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        CircularProgressIndicator(color: Color(0xFF2D6A1E)),
                        SizedBox(height: 24),
                        Text(
                          "Ending shift...",
                          style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16, color: Color(0xFF111827)),
                        ),
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

  Widget _buildHeader(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(24)),
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 20, 24, 24),
          child: Row(
            children: [
              Image.asset('assets/images/logo.png', height: 40),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      "Operator Dashboard",
                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Color(0xFF2D6A1E), letterSpacing: 0.5),
                    ),
                    Text(
                      widget.jeepId.toUpperCase().replaceAll('_', ' '),
                      style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: Color(0xFF111827), letterSpacing: -0.5),
                    ),
                  ],
                ),
              ),
              GestureDetector(
                onTap: _handleLogout,
                child: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFF5F5),
                    shape: BoxShape.circle,
                    border: Border.all(color: const Color(0xFFFECACA)),
                  ),
                  child: const Icon(Icons.logout_rounded, color: Color(0xFFD32F2F), size: 20),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _handleLogout() async {
    setState(() => _isLoggingOut = true);
    try {
      await AuthService().signOut();
      if (mounted) {
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (context) => const LoginScreen()),
          (route) => false,
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error logging out: $e')),
        );
        setState(() => _isLoggingOut = false);
      }
    }
  }

  // ── Safety Status Banner ──────────────────────────────────────────────────
  Widget _buildSafetyStatusBanner(bool isSafe, bool isWeightOverloaded) {
    final banner = Container(
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
      decoration: BoxDecoration(
        color: isSafe ? const Color(0xFFF3FBF5) : const Color(0xFFFFF5F5),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isSafe ? const Color(0xFFD0F0D8) : const Color(0xFFFECACA),
          width: 1.5,
        ),
      ),
      child: Row(
        children: [
          Icon(
            isSafe ? Icons.gpp_good_rounded : Icons.warning_amber_rounded,
            color: isSafe ? const Color(0xFF2D6A1E) : const Color(0xFFD32F2F),
            size: 22,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              isSafe 
                ? "Vehicle is within safe weight limits." 
                : "Safety Alert: Vehicle weight limit exceeded!",
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: isSafe ? const Color(0xFF18331A) : const Color(0xFF991B1B),
              ),
            ),
          ),
        ],
      ),
    );

    if (isWeightOverloaded) {
      return banner.animate(onPlay: (controller) => controller.repeat(reverse: true))
          .tint(color: Colors.red.withOpacity(0.05), duration: 2.seconds);
    }
    return banner;
  }

  // ── Passenger Alert Card ──────────────────────────────────────────────────
  Widget _buildPassengerAlertCard(Map<String, dynamic> alert) {
    final String type = alert['type'] as String? ?? 'unknown';
    final String message = alert['message'] as String? ?? 'Alert from passenger';
    final String name = alert['passengerName'] as String? ?? 'A passenger';
    final int timestamp = alert['timestamp'] as int? ?? 0;
    final String alertId = alert['id'] as String? ?? '';
    final Color color = _alertColor(type);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.black.withOpacity(0.04)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(color: color.withOpacity(0.1), shape: BoxShape.circle),
            child: Icon(_alertIcon(type), color: color, size: 20),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  message,
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF111827)),
                ),
                const SizedBox(height: 2),
                Text(
                  "$name • ${_timeAgo(timestamp)}",
                  style: TextStyle(color: Colors.grey[500], fontSize: 11, fontWeight: FontWeight.w500),
                ),
              ],
            ),
          ),
          IconButton(
            icon: Icon(Icons.check_circle_outline_rounded, color: Colors.grey[400], size: 22),
            onPressed: () => _service.dismissAlert(widget.jeepId, alertId),
          ),
        ],
      ),
    ).animate(key: ValueKey(alertId))
     .slideX(begin: 0.1, end: 0, duration: 400.ms, curve: Curves.easeOutCubic)
     .fadeIn();
  }

  // ── Minimap Card ──────────────────────────────────────────────────────────
  Widget _buildMinimapCard(JeepneyData data) {
    return Container(
      height: 240,
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
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: Stack(
          children: [
            FlutterMap(
              mapController: _mapController,
              options: MapOptions(
                initialCenter: LatLng(data.latitude, data.longitude),
                initialZoom: 16.0,
              ),
              children: [
                TileLayer(
                  urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                ),
                MarkerLayer(
                  markers: [
                    Marker(
                      point: LatLng(data.latitude, data.longitude),
                      width: 60,
                      height: 60,
                      child: const Icon(Icons.location_on, color: Color(0xFFD32F2F), size: 36),
                    ),
                  ],
                ),
              ],
            ),
            Positioned(
              bottom: 16,
              right: 16,
              child: GestureDetector(
                onTap: () => _animatedMapMove(LatLng(data.latitude, data.longitude), 16.0),
                child: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 10, offset: const Offset(0, 4)),
                    ],
                  ),
                  child: const Icon(Icons.my_location, color: Color(0xFF111827), size: 20),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Metric Card ───────────────────────────────────────────────────────────
  Widget _buildMetricCard({
    required IconData icon,
    required String label,
    required String value,
    required String sub,
    required bool isCritical,
    required bool primary,
  }) {
    final color = isCritical ? const Color(0xFFD32F2F) : (primary ? const Color(0xFF2D6A1E) : const Color(0xFFF59E0B));
    
    final card = Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: isCritical ? color.withOpacity(0.3) : Colors.black.withOpacity(0.04),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: isCritical ? color.withOpacity(0.05) : Colors.black.withOpacity(0.02),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(color: color.withOpacity(0.1), shape: BoxShape.circle),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(height: 16),
          Text(
            value,
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.w900,
              color: isCritical ? color : const Color(0xFF111827),
            ),
          ),
          Text(
            sub,
            style: TextStyle(fontSize: 12, color: Colors.grey[500], fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );

    if (isCritical) {
      return card.animate(onPlay: (controller) => controller.repeat(reverse: true))
          .scale(duration: 3.seconds, begin: const Offset(1, 1), end: const Offset(1.01, 1.01), curve: Curves.easeInOut);
    }
    return card;
  }

  // ── Readings Card ─────────────────────────────────────────────────────────
  Widget _buildReadingsCard(JeepneyData data) {
    return Container(
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
        children: [
          _buildReadingRow(Icons.speed_rounded, "Velocity", "${data.speed.toStringAsFixed(1)} km/h"),
          const Divider(height: 32, thickness: 1),
          _buildReadingRow(Icons.scale_rounded, "Gross Weight", "${data.currentWeight.toStringAsFixed(0)} kg"),
          const Divider(height: 32, thickness: 1),
          _buildReadingRow(Icons.pin_drop_rounded, "Route", data.route),
          const Divider(height: 32, thickness: 1),
          _buildReadingRow(Icons.access_time_rounded, "Last Ping", _formatTimestamp(data.lastUpdated)),
        ],
      ),
    );
  }

  Widget _buildReadingRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(color: const Color(0xFFF3FBF5), borderRadius: BorderRadius.circular(10)),
          child: Icon(icon, size: 18, color: const Color(0xFF2D6A1E)),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Text(label, style: TextStyle(color: Colors.grey[500], fontSize: 14, fontWeight: FontWeight.w600)),
        ),
        Text(
          value,
          style: const TextStyle(fontWeight: FontWeight.w800, color: Color(0xFF111827), fontSize: 14),
        ),
      ],
    );
  }

  String _formatTimestamp(int timestamp) {
    final date = DateTime.fromMillisecondsSinceEpoch(timestamp);
    return "${date.hour}:${date.minute.toString().padLeft(2, '0')}:${date.second.toString().padLeft(2, '0')}";
  }
}

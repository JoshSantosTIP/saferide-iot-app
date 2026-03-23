import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../models/jeepney_data.dart';
import '../../models/user_profile.dart';
import '../../services/jeepney_service.dart';
import '../../services/auth_service.dart';

class VehicleDetailsScreen extends StatefulWidget {
  final String jeepId;
  const VehicleDetailsScreen({super.key, required this.jeepId});

  @override
  State<VehicleDetailsScreen> createState() => _VehicleDetailsScreenState();
}

class _VehicleDetailsScreenState extends State<VehicleDetailsScreen> {
  final JeepneyService _service = JeepneyService();
  final AuthService _authService = AuthService();
  late Stream<JeepneyData> _jeepStream;

  UserProfile? _userProfile;
  DateTime? _lastAlertTime;
  static const _alertCooldown = Duration(seconds: 30);

  @override
  void initState() {
    super.initState();
    _jeepStream = _service.streamJeepneyData(widget.jeepId);
    _loadUserProfile();
  }

  Future<void> _loadUserProfile() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid != null) {
      final profile = await _authService.getUserProfile(uid);
      if (mounted) setState(() => _userProfile = profile);
    }
  }

  bool get _canSendAlert {
    if (_lastAlertTime == null) return true;
    return DateTime.now().difference(_lastAlertTime!) >= _alertCooldown;
  }

  int get _cooldownRemaining {
    if (_lastAlertTime == null) return 0;
    final diff = _alertCooldown - DateTime.now().difference(_lastAlertTime!);
    return diff.inSeconds.clamp(0, 30);
  }

  Future<void> _sendAlert(String type, String message) async {
    if (!_canSendAlert) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Please wait $_cooldownRemaining seconds before sending another alert."),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    final name = _userProfile?.name ?? 'A passenger';

    await _service.sendPassengerAlert(
      jeepId: widget.jeepId,
      type: type,
      message: message,
      passengerName: name,
    );

    setState(() => _lastAlertTime = DateTime.now());

    if (mounted) {
      Navigator.pop(context); // Close bottom sheet
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Row(
            children: [
              Icon(Icons.check_circle, color: Colors.white, size: 20),
              SizedBox(width: 12),
              Text("Alert sent to operator!"),
            ],
          ),
          backgroundColor: Color(0xFF2D6A1E),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  void _showAlertSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        padding: const EdgeInsets.fromLTRB(24, 12, 24, 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Handle
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              "Alert Operator",
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1A1A1A),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              "Choose the type of alert to send",
              style: TextStyle(fontSize: 14, color: Colors.grey[600]),
            ),
            const SizedBox(height: 24),

            _buildAlertOption(
              icon: Icons.pan_tool_rounded,
              color: const Color(0xFFFF9800),
              title: "Request Stop",
              subtitle: "Notify operator you need to get off",
              onTap: () => _sendAlert(
                "stop_request",
                "A passenger is requesting a stop",
              ),
            ),
            const SizedBox(height: 12),
            _buildAlertOption(
              icon: Icons.warning_rounded,
              color: const Color(0xFFD32F2F),
              title: "Emergency",
              subtitle: "Report an emergency situation",
              onTap: () => _sendAlert(
                "emergency",
                "A passenger reported an emergency!",
              ),
            ),
            const SizedBox(height: 12),
            _buildAlertOption(
              icon: Icons.groups_rounded,
              color: const Color(0xFF1565C0),
              title: "Overloading Concern",
              subtitle: "Report suspected overloading",
              onTap: () => _sendAlert(
                "overloading",
                "A passenger flagged an overloading concern",
              ),
            ),

            if (!_canSendAlert) ...[
              const SizedBox(height: 16),
              Text(
                "Cooldown: ${_cooldownRemaining}s remaining",
                style: TextStyle(fontSize: 12, color: Colors.grey[500]),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildAlertOption({
    required IconData icon,
    required Color color,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: _canSendAlert ? onTap : null,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: _canSendAlert ? color.withOpacity(0.06) : Colors.grey[100],
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: _canSendAlert ? color.withOpacity(0.15) : Colors.grey[300]!,
            ),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: _canSendAlert ? color.withOpacity(0.15) : Colors.grey[200],
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: _canSendAlert ? color : Colors.grey, size: 24),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: _canSendAlert ? const Color(0xFF1A1A1A) : Colors.grey,
                      ),
                    ),
                    Text(
                      subtitle,
                      style: TextStyle(fontSize: 12, color: Colors.grey[500]),
                    ),
                  ],
                ),
              ),
              Icon(Icons.chevron_right, color: Colors.grey[400]),
            ],
          ),
        ),
      ),
    );
  }

  String _formatTimestamp(int timestamp) {
    final date = DateTime.fromMillisecondsSinceEpoch(timestamp);
    return "${date.hour}:${date.minute.toString().padLeft(2, '0')}:${date.second.toString().padLeft(2, '0')}";
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<JeepneyData>(
      stream: _jeepStream,
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Scaffold(
            backgroundColor: Color(0xFFF9FBF9),
            body: Center(child: CircularProgressIndicator(color: Color(0xFF2D6A1E))),
          );
        }

        final data = snapshot.data!;
        final isPassengerAtCapacity = data.passengerCount >= data.maxSeatCapacity;
        final isWeightOverloaded = data.isOverloaded || data.currentWeight > data.maxWeightCapacity;
        final isAnyOverload = isWeightOverloaded; // Only weight triggers safety alert
        final isSafe = !isAnyOverload;
        final seatAvailable = (data.maxSeatCapacity - data.passengerCount).clamp(0, 99);
        final loadPercent = (data.currentWeight / data.maxWeightCapacity * 100).clamp(0, 999);

        return Scaffold(
          backgroundColor: const Color(0xFFF9FBF9), // Match the extremely light background
          body: Column(
            children: [
              // ── Top Action Bar ───────────────────────────────────────────
              SafeArea(
                bottom: false,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
                  child: Row(
                    children: [
                      GestureDetector(
                        onTap: () => Navigator.pop(context),
                        child: Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.black.withOpacity(0.05)),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.03),
                                blurRadius: 10,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: const Icon(Icons.arrow_back_rounded, color: Color(0xFF18331A), size: 20),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              widget.jeepId.toUpperCase().replaceAll('_', ' '),
                              style: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.w900,
                                color: Color(0xFF111827),
                                letterSpacing: -0.5,
                              ),
                            ),
                            Text(
                              data.route,
                              style: TextStyle(fontSize: 13, color: Colors.grey[600], fontWeight: FontWeight.w500),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.grey[300]!, width: 1),
                        ),
                        child: Text(
                          data.plateNumber,
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0.5,
                            color: Color(0xFF111827),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // ── Main Content ─────────────────────────────────────────────
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(24, 12, 24, 40),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // ── Minimap Card ───────────────────────
                      _buildMinimapCard(data),
                      const SizedBox(height: 24),

                      // ── Safety Status ──────────────────────
                      _buildSafetyStatusCard(isSafe, isAnyOverload),
                      const SizedBox(height: 24),

                      // ── Key Metrics ────────────────────────
                      Row(
                        children: [
                          Expanded(
                            child: _buildMetricCard(
                              icon: Icons.event_seat_rounded,
                              label: "Seats",
                              value: "$seatAvailable",
                              sub: "Available",
                              isCritical: false, // Seats don't trigger critical state anymore
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

                      // ── Vehicle Details List ───────────────
                      const Text(
                        "VEHICLE READINGS",
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                          color: Colors.grey,
                          letterSpacing: 1.2,
                        ),
                      ),
                      const SizedBox(height: 12),
                      _buildReadingsCard(data),
                      
                      const SizedBox(height: 32),
                      // ── Action Button ──────────────────────
                      _buildAlertOperatorButton(),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildMinimapCard(JeepneyData data) {
    return Container(
      height: 200,
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
        child: FlutterMap(
          options: MapOptions(
            initialCenter: LatLng(data.latitude, data.longitude),
            initialZoom: 16.0,
            interactionOptions: const InteractionOptions(flags: InteractiveFlag.all),
          ),
          children: [
            TileLayer(
              urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
              userAgentPackageName: 'com.parago.app',
            ),
            MarkerLayer(
              markers: [
                Marker(
                  point: LatLng(data.latitude, data.longitude),
                  width: 60,
                  height: 60,
                  child: Column(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: const Color(0xFF2D6A1E),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          data.plateNumber,
                          style: const TextStyle(color: Colors.white, fontSize: 8, fontWeight: FontWeight.bold),
                        ),
                      ),
                      const Icon(Icons.location_on, color: Color(0xFFD32F2F), size: 30),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSafetyStatusCard(bool isSafe, bool isAnyOverload) {
    final card = Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isSafe ? const Color(0xFFF3FBF5) : const Color(0xFFFFF5F5),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: isSafe ? const Color(0xFFD0F0D8) : const Color(0xFFFECACA),
          width: 1.5,
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: isSafe ? const Color(0xFF2D6A1E).withOpacity(0.1) : Colors.red.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              isSafe ? Icons.gpp_good_rounded : Icons.warning_amber_rounded,
              color: isSafe ? const Color(0xFF2D6A1E) : const Color(0xFFD32F2F),
              size: 28,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isSafe ? "Safe Environment" : "Safety Alert",
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: isSafe ? const Color(0xFF18331A) : const Color(0xFF991B1B),
                  ),
                ),
                Text(
                  isSafe 
                    ? "Vehicle is operating within safe parameters."
                    : "This vehicle has exceeded its safety weight limit.",
                  style: TextStyle(
                    fontSize: 13,
                    color: isSafe ? const Color(0xFF2D6A1E).withOpacity(0.7) : const Color(0xFFB91C1C),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );

    if (isAnyOverload) {
      // Subtle pulsing instead of shake/shimmer
      return card.animate(onPlay: (controller) => controller.repeat(reverse: true))
          .tint(color: Colors.red.withOpacity(0.05), duration: 2.seconds);
    }
    return card;
  }

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
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
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
      // Very slow, subtle pulse
      return card.animate(onPlay: (controller) => controller.repeat(reverse: true))
          .scale(duration: 3.seconds, begin: const Offset(1, 1), end: const Offset(1.01, 1.01), curve: Curves.easeInOut);
    }
    return card;
  }

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
          decoration: BoxDecoration(
            color: const Color(0xFFF3FBF5),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, size: 18, color: const Color(0xFF2D6A1E)),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Text(
            label,
            style: TextStyle(color: Colors.grey[500], fontSize: 14, fontWeight: FontWeight.w600),
          ),
        ),
        Text(
          value,
          style: const TextStyle(fontWeight: FontWeight.w800, color: Color(0xFF111827), fontSize: 14),
        ),
      ],
    );
  }

  Widget _buildAlertOperatorButton() {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFD32F2F).withOpacity(0.2),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: ElevatedButton(
        onPressed: _showAlertSheet,
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFFD32F2F),
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 18),
          elevation: 0,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        ),
        child: const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.notifications_active_rounded, size: 20),
            SizedBox(width: 12),
            Text(
              "Report Issue to Operator",
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, letterSpacing: 0.5),
            ),
          ],
        ),
      ),
    );
  }
}

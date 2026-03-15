import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../models/jeepney_data.dart';
import '../services/jeepney_service.dart';

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

  @override
  void initState() {
    super.initState();
    _jeepStream = _service.streamJeepneyData(widget.jeepId);
    _service.initializeNotifications();
    _service.startLocationUpdates(widget.jeepId);
  }

  // Helper for smooth map movement
  void _animatedMapMove(LatLng destLocation, double destZoom) {
    // Create some variables that will be used for the animation
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

    // Create a animation controller that has a duration and a TickerProvider
    final controller = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );

    // The animation determines what path the animation will take. You can try different Curves values, although I found
    // fastOutSlowIn to be my favorite.
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        title: Text(
          widget.jeepId.toUpperCase().replaceAll('_', ' '),
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
        centerTitle: true,
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black87),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: StreamBuilder<JeepneyData>(
        stream: _jeepStream,
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final data = snapshot.data!;
          final isPassengerOverloaded =
              data.passengerCount >= data.maxSeatCapacity;
          // Better logic: derive weight overload manually if data.isOverloaded is ambiguous, but likely it reflects weight.
          // Let's use explicit check:
          final bool weightLimitExceeded =
              data.currentWeight > data.maxWeightCapacity;

          return Column(
            children: [
              // 1. Alert Banners
              if (weightLimitExceeded)
                _buildAlertBanner(
                  "WEIGHT LIMIT EXCEEDED!",
                  Icons.monitor_weight_outlined,
                ),
              if (isPassengerOverloaded)
                _buildAlertBanner(
                  "PASSENGER LIMIT EXCEEDED!",
                  Icons.groups_rounded,
                ),

              Expanded(
                child: SingleChildScrollView(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // 2. Map Card (Prominent, Top)
                        Container(
                          height: MediaQuery.of(context).size.height * 0.35,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(20),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.1),
                                blurRadius: 15,
                                offset: const Offset(0, 5),
                              ),
                            ],
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(20),
                            child: Stack(
                              children: [
                                FlutterMap(
                                  mapController: _mapController,
                                  options: MapOptions(
                                    initialCenter: LatLng(
                                      data.latitude,
                                      data.longitude,
                                    ),
                                    initialZoom: 16.0,
                                  ),
                                  children: [
                                    TileLayer(
                                      urlTemplate:
                                          'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                                    ),
                                    MarkerLayer(
                                      markers: [
                                        Marker(
                                          point: LatLng(
                                            data.latitude,
                                            data.longitude,
                                          ),
                                          width: 80,
                                          height: 80,
                                          child: const Icon(
                                            Icons.directions_bus,
                                            color: Color(0xFF1A7D6F),
                                            size: 40,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                                // Map Overlay Controls (e.g., Recenter)
                                Positioned(
                                  bottom: 16,
                                  right: 16,
                                  child: FloatingActionButton.small(
                                    backgroundColor: Colors.white,
                                    child: const Icon(
                                      Icons.my_location,
                                      color: Colors.black87,
                                    ),
                                    onPressed: () {
                                      _animatedMapMove(
                                        LatLng(data.latitude, data.longitude),
                                        16.0,
                                      );
                                    },
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),

                        const SizedBox(height: 24),

                        // 3. Stats Grid
                        Row(
                          children: [
                            Expanded(
                              child: _buildStatCard(
                                title: "PASSENGERS",
                                value: "${data.passengerCount}",
                                subValue: "/ ${data.maxSeatCapacity}",
                                icon: Icons.groups_rounded,
                                color: isPassengerOverloaded
                                    ? Colors.red
                                    : const Color(0xFF00C853),
                                isAlert: isPassengerOverloaded,
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: _buildStatCard(
                                title: "WEIGHT",
                                value:
                                    data.currentWeight.toStringAsFixed(0),
                                subValue: "kg",
                                icon: Icons.scale_rounded,
                                color: weightLimitExceeded
                                    ? Colors.red
                                    : const Color(0xFF1A7D6F),
                                isAlert: weightLimitExceeded,
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 24),

                        // 4. Vehicle Details (Minimalist)
                        Container(
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.05),
                                blurRadius: 10,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Column(
                            children: [
                              _buildInfoRow(
                                Icons.pin_drop_rounded,
                                "Route",
                                data.route,
                              ),
                              const Divider(height: 24),
                              _buildInfoRow(
                                Icons.speed_rounded,
                                "Speed",
                                "${data.speed.toStringAsFixed(1)} km/h",
                              ),
                              const Divider(height: 24),
                              _buildInfoRow(
                                Icons.access_time_rounded,
                                "Last Updated",
                                _formatTimestamp(data.lastUpdated),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildStatCard({
    required String title,
    required String value,
    required String subValue,
    required IconData icon,
    required Color color,
    required bool isAlert,
  }) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isAlert ? color.withValues(alpha: 0.1) : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isAlert ? color : Colors.transparent,
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.1),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 28),
          const SizedBox(height: 12),
          Text(
            title,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: Colors.grey[600],
              letterSpacing: 1.0,
            ),
          ),
          const SizedBox(height: 4),
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                value,
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
              const SizedBox(width: 4),
              Text(
                subValue,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: Colors.grey[500],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.grey[100],
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, size: 20, color: Colors.grey[600]),
        ),
        const SizedBox(width: 16),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: TextStyle(fontSize: 12, color: Colors.grey[500]),
            ),
            Text(
              value,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
          ],
        ),
      ],
    );
  }

  String _formatTimestamp(int timestamp) {
    final date = DateTime.fromMillisecondsSinceEpoch(timestamp);
    return "${date.hour}:${date.minute.toString().padLeft(2, '0')}:${date.second.toString().padLeft(2, '0')}";
  }

  Widget _buildAlertBanner(String message, IconData icon) {
    return Container(
      color: Colors.redAccent,
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
      margin: const EdgeInsets.only(bottom: 1), // Separator if multiple
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: Colors.white),
          const SizedBox(width: 8),
          Text(
            message,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 14,
              letterSpacing: 1.0,
            ),
          ),
        ],
      ),
    );
  }
}

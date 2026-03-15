import 'package:flutter/material.dart';
import '../../models/jeepney_data.dart';
import '../../services/jeepney_service.dart';

class VehicleDetailsScreen extends StatefulWidget {
  final String jeepId;
  const VehicleDetailsScreen({super.key, required this.jeepId});

  @override
  State<VehicleDetailsScreen> createState() => _VehicleDetailsScreenState();
}

class _VehicleDetailsScreenState extends State<VehicleDetailsScreen> {
  final JeepneyService _service = JeepneyService();
  late Stream<JeepneyData> _jeepStream;

  @override
  void initState() {
    super.initState();
    _jeepStream = _service.streamJeepneyData(widget.jeepId);
  }

  // Formatting helper
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
            backgroundColor: Color(0xFFF5F7FA),
            body: Center(child: CircularProgressIndicator()),
          );
        }

        final data = snapshot.data!;
        final isPassengerOverloaded =
            data.passengerCount >= data.maxSeatCapacity;
        final isWeightOverloaded =
            data.isOverloaded || data.currentWeight > data.maxWeightCapacity;
        final isSafe = !isPassengerOverloaded && !isWeightOverloaded;

        return Scaffold(
          backgroundColor: const Color(0xFFF5F7FA),
          appBar: AppBar(
            title: Column(
              children: [
                Text(
                  data.route, // Dynamic Route Name
                  style: const TextStyle(fontSize: 14, color: Colors.black54),
                ),
                Text(
                  widget.jeepId.toUpperCase().replaceAll('_', ' '),
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                    fontSize: 18,
                  ),
                ),
              ],
            ),
            centerTitle: true,
            backgroundColor: Colors.white,
            elevation: 0,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back, color: Colors.black87),
              onPressed: () => Navigator.pop(context),
            ),
          ),
          // Floating Action Button for Notification
          floatingActionButton: FloatingActionButton.extended(
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text(
                    "Notification Set! We'll alert you when it's near.",
                  ),
                ),
              );
            },
            backgroundColor: const Color(0xFF1A7D6F),
            foregroundColor: Colors.white,
            icon: const Icon(Icons.notifications_active_outlined),
            label: const Text("Notify Me"),
          ),
          floatingActionButtonLocation:
              FloatingActionButtonLocation.centerFloat,

          body: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // 1. "Am I Safe?" Indicator
                  Container(
                    padding: const EdgeInsets.symmetric(vertical: 32),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: [
                        BoxShadow(
                          color: isSafe
                              ? Colors.green.withValues(alpha: 0.1)
                              : Colors.red.withValues(alpha: 0.1),
                          blurRadius: 20,
                          offset: const Offset(0, 10),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        Icon(
                          isSafe
                              ? Icons.gpp_good_rounded
                              : Icons.warning_amber_rounded,
                          size: 80,
                          color: isSafe
                              ? const Color(0xFF00C853)
                              : Colors.redAccent,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          isSafe ? "Safe Capacity" : "Overloaded",
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: isSafe
                                ? const Color(0xFF00C853)
                                : Colors.redAccent,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          isSafe
                              ? "This vehicle is within safe limits."
                              : "This vehicle has exceeded safety limits.",
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            color: Colors.grey,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 32),

                  // 2. Stats Grid (Reusing Logic but Passenger Style)
                  Row(
                    children: [
                      Expanded(
                        child: _buildInfoCard(
                          title: "Seats",
                          value:
                              "${data.maxSeatCapacity - data.passengerCount}",
                          subValue: "Available",
                          icon: Icons.event_seat_rounded,
                          color: isPassengerOverloaded
                              ? Colors.redAccent
                              : const Color(0xFF1A7D6F),
                          isAlert: isPassengerOverloaded,
                        ),
                      ),
                      const SizedBox(width: 16),
                      // We can show current passengers instead of weight if weight is too technical,
                      // but user asked for transparency. Let's show Load %.
                      Expanded(
                        child: _buildInfoCard(
                          title: "Load",
                          value:
                              "${(data.currentWeight / data.maxWeightCapacity * 100).toStringAsFixed(0)}%",
                          subValue: "Capacity",
                          icon: Icons.pie_chart_rounded,
                          color: isWeightOverloaded
                              ? Colors.redAccent
                              : const Color(0xFF00C853),
                          isAlert: isWeightOverloaded,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 32),

                  // 3. Technical Details (For transparency)
                  const Text(
                    "Vehicle Status",
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Column(
                      children: [
                        _buildDetailRow(
                          "Current Weight",
                          "${data.currentWeight.toStringAsFixed(0)} kg",
                        ),
                        const Divider(),
                        _buildDetailRow(
                          "Max Weight",
                          "${data.maxWeightCapacity.toStringAsFixed(0)} kg",
                        ),
                        const Divider(),
                        _buildDetailRow(
                          "Last Update",
                          _formatTimestamp(data.lastUpdated),
                        ),
                      ],
                    ),
                  ),

                  // Spacing for FAB
                  const SizedBox(height: 80),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildInfoCard({
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
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isAlert ? color : Colors.transparent,
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(height: 16),
          Text(
            value,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          Text(
            subValue,
            style: TextStyle(fontSize: 12, color: Colors.grey[600]),
          ),
          const SizedBox(height: 4),
          Text(
            title.toUpperCase(),
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.bold,
              color: Colors.grey[400],
              letterSpacing: 1.2,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(color: Colors.grey[600], fontSize: 14)),
          Text(
            value,
            style: const TextStyle(
              fontWeight: FontWeight.w600,
              color: Colors.black87,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }
}

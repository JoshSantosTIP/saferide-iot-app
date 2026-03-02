import 'package:flutter/material.dart';
import 'conductor/login_screen.dart';
import 'passenger/passenger_map_screen.dart';

class RoleSelectionScreen extends StatelessWidget {
  const RoleSelectionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Spacer(),
              const Text(
                "Welcome to SafeRide",
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1A1A1A),
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                "Choose your role to continue",
                style: TextStyle(fontSize: 16, color: Colors.grey[600]),
                textAlign: TextAlign.center,
              ),
              const Spacer(),
              _buildRoleButton(
                context,
                title: "I am a Passenger",
                subtitle: "Track live locations & seat availability",
                icon: Icons.person_pin_circle,
                color: const Color(0xFF0056D2),
                isOutlined: false,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const PassengerMapScreen(),
                    ),
                  );
                },
              ),
              const SizedBox(height: 16),
              _buildRoleButton(
                context,
                title: "I am a Conductor",
                subtitle: "Manage your vehicle & passengers",
                icon: Icons.admin_panel_settings,
                color: Colors.white,
                isOutlined: true,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const ConductorLoginScreen(),
                    ),
                  );
                },
              ),
              const Spacer(),
              const Text(
                "SafeRide IoT • Version 1.0",
                style: TextStyle(fontSize: 12, color: Colors.grey),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRoleButton(
    BuildContext context, {
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    required bool isOutlined,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: isOutlined ? Colors.white : color,
          borderRadius: BorderRadius.circular(16),
          border: isOutlined ? Border.all(color: Colors.grey[300]!) : null,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isOutlined
                    ? const Color(0xFF0056D2).withValues(alpha: 0.1)
                    : Colors.white.withValues(alpha: 0.2),
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                color: isOutlined ? const Color(0xFF0056D2) : Colors.white,
                size: 28,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: isOutlined
                          ? const Color(0xFF1A1A1A)
                          : Colors.white,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 12,
                      color: isOutlined
                          ? Colors.grey[600]
                          : Colors.white.withValues(alpha: 0.8),
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.arrow_forward_ios,
              color: isOutlined
                  ? Colors.grey[400]
                  : Colors.white.withValues(alpha: 0.5),
              size: 16,
            ),
          ],
        ),
      ),
    );
  }
}

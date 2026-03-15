import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/auth_service.dart';
import 'login_screen.dart';
import 'passenger/passenger_map_screen.dart';
import 'dashboard_screen.dart';
import 'no_jeepney_assigned_screen.dart';

class SplashScreen extends StatefulWidget {
  final bool allowAutoLogin;
  const SplashScreen({super.key, this.allowAutoLogin = true});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _navigateToHome();
  }

  Future<void> _navigateToHome() async {
    // Show splash for at least 2 seconds
    await Future.delayed(const Duration(seconds: 2));
    if (!mounted) return;

    if (!widget.allowAutoLogin) {
      print("[SplashScreen] Auto-login disabled by flag. Redirecting to LoginScreen.");
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const LoginScreen()),
      );
      return;
    }

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      // Not logged in
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const LoginScreen()),
      );
      return;
    }

    // Is logged in, fetch profile to decide where to go
    try {
      final authService = AuthService();
      final profile = await authService.getUserProfile(user.uid);

      if (!mounted) return;

      if (profile == null) {
        // Logged in but no profile? Go to login (safety fallback)
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const LoginScreen()),
        );
        return;
      }

      // Navigate based on role (same logic as LoginScreen)
      if (profile.isOperator) {
        if (profile.assignedJeepney != null && profile.assignedJeepney!.isNotEmpty) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => DashboardScreen(jeepId: profile.assignedJeepney!),
            ),
          );
        } else {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => NoJeepneyAssignedScreen(userEmail: profile.email),
            ),
          );
        }
      } else {
        // Passenger
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => const PassengerMapScreen(),
          ),
        );
      }
    } catch (e) {
      debugPrint("Error in auto-login: $e");
      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const LoginScreen()),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Logo placeholder - utilizing Icon for now
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: const Color(0xFF1A7D6F).withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.directions_bus,
                size: 80,
                color: Color(0xFF1A7D6F),
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              "ParaGo",
              style: TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1A7D6F),
                letterSpacing: 1.5,
              ),
            ),
            const SizedBox(height: 16),
            const CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF1A7D6F)),
            ),
          ],
        ),
      ),
    );
  }
}

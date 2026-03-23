import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/auth_service.dart';
import 'login_screen.dart';
import 'onboarding_screen.dart';
import 'passenger/passenger_main_screen.dart';
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
      print("[SplashScreen] Auto-login disabled by flag. Redirecting to OnboardingScreen.");
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const OnboardingScreen()),
      );
      return;
    }

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      // Not logged in
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const OnboardingScreen()),
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
            builder: (context) => const PassengerMainScreen(),
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
            // Logo image from assets
            Image.asset(
              'assets/images/logo.png',
              width: 180,
              height: 180,
              fit: BoxFit.contain,
            ),
            const SizedBox(height: 24),
            const CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF4BA028)),
            ),
          ],
        ),
      ),
    );
  }
}

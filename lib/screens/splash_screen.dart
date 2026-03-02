import 'package:flutter/material.dart';
import 'role_selection_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

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
    await Future.delayed(const Duration(seconds: 3));
    if (!mounted) return;
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => const RoleSelectionScreen()),
    );
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
                color: const Color(0xFF0056D2).withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.directions_bus,
                size: 80,
                color: Color(0xFF0056D2),
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              "SafeRide",
              style: TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.bold,
                color: Color(0xFF0056D2),
                letterSpacing: 1.5,
              ),
            ),
            const SizedBox(height: 16),
            const CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF0056D2)),
            ),
          ],
        ),
      ),
    );
  }
}

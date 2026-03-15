import 'package:flutter/material.dart';
import '../../services/auth_service.dart';
import '../../models/user_profile.dart';
import 'passenger/passenger_map_screen.dart';
import 'dashboard_screen.dart';
import 'no_jeepney_assigned_screen.dart';
import 'signup_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final AuthService _authService = AuthService();
  
  bool _isLoading = false;
  String? _errorMessage;

  Future<void> _handleLogin({bool isGoogle = false}) async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final profile = isGoogle 
        ? await _authService.signInWithGoogle()
        : await _authService.signInWithEmail(
            _emailController.text.trim(), 
            _passwordController.text.trim()
          );

      if (profile != null) {
        _navigateBasedOnRole(profile);
      } else {
        setState(() {
          _errorMessage = "Sign in was cancelled or failed.";
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = e.toString().replaceFirst("Exception: ", "");
        });
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _navigateBasedOnRole(UserProfile profile) {
    if (!mounted) return;
    
    if (profile.isOperator) {
      if (profile.assignedJeepney != null && profile.assignedJeepney!.isNotEmpty) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => DashboardScreen(jeepId: profile.assignedJeepney!),
          ),
        );
      } else {
        Navigator.push(
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
  }

  @override
  Widget build(BuildContext context) {
     return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 32.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 48),
              const Icon(
                Icons.directions_bus_filled,
                size: 64,
                color: Color(0xFF1A7D6F),
              ),
              const SizedBox(height: 24),
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
                "Sign in to continue",
                style: TextStyle(fontSize: 16, color: Colors.grey[600]),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 48),
              
              if (_errorMessage != null)
                Container(
                  padding: const EdgeInsets.all(12),
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: Colors.red.shade50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.red.shade200),
                  ),
                  child: Text(
                    _errorMessage!,
                    style: TextStyle(color: Colors.red.shade800, fontSize: 14),
                  ),
                ),

              TextField(
                controller: _emailController,
                decoration: InputDecoration(
                  labelText: "Email address",
                  prefixIcon: const Icon(Icons.email_outlined),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  filled: true,
                  fillColor: Colors.grey[50],
                ),
                keyboardType: TextInputType.emailAddress,
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _passwordController,
                decoration: InputDecoration(
                  labelText: "Password",
                  prefixIcon: const Icon(Icons.lock_outline),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  filled: true,
                  fillColor: Colors.grey[50],
                ),
                obscureText: true,
              ),
              const SizedBox(height: 24),
              SizedBox(
                height: 50,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : () => _handleLogin(isGoogle: false),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF1A7D6F),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 2,
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          height: 20, width: 20,
                          child: CircularProgressIndicator(strokeWidth: 2, valueColor: AlwaysStoppedAnimation<Color>(Colors.white)),
                        )
                      : const Text("Sign In", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                ),
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(child: Divider(color: Colors.grey.shade300)),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Text("OR", style: TextStyle(color: Colors.grey.shade500, fontWeight: FontWeight.bold)),
                  ),
                  Expanded(child: Divider(color: Colors.grey.shade300)),
                ],
              ),
              const SizedBox(height: 24),
              SizedBox(
                 height: 50,
                 child: OutlinedButton.icon(
                    onPressed: _isLoading ? null : () => _handleLogin(isGoogle: true),
                    icon: const Icon(Icons.g_mobiledata, size: 32, color: Colors.black87), // Simple google-ish icon or image could be used
                    label: const Text(
                      "Sign in with Google",
                      style: TextStyle(
                         color: Colors.black87, 
                         fontSize: 16, 
                         fontWeight: FontWeight.bold
                      )
                    ),
                    style: OutlinedButton.styleFrom(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      side: BorderSide(color: Colors.grey.shade300),
                    ),
                 ),
              ),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                   Text("Don't have an account?", style: TextStyle(color: Colors.grey[700])),
                   TextButton(
                     onPressed: () {
                         Navigator.push(
                           context, 
                           MaterialPageRoute(builder: (context) => const SignupScreen())
                         );
                     }, 
                     child: const Text("Sign Up", style: TextStyle(color: Color(0xFF1A7D6F), fontWeight: FontWeight.bold))
                   )
                ],
              )
            ],
          ),
        ),
      ),
    );
  }
}

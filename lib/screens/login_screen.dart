import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../services/auth_service.dart';
import '../../models/user_profile.dart';
import 'passenger/passenger_main_screen.dart';
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
  bool _obscurePassword = true;
  String? _errorMessage;

  String _getFriendlyErrorMessage(String error) {
    if (error.contains('invalid-credential') || error.contains('wrong-password') || error.contains('user-not-found')) {
      return "The email or password you entered is incorrect.";
    } else if (error.contains('invalid-email')) {
      return "Please enter a valid email address.";
    } else if (error.contains('user-disabled')) {
      return "This account has been disabled. Please contact support.";
    } else if (error.contains('too-many-requests')) {
      return "Too many failed attempts. Please try again later.";
    } else if (error.contains('network-request-failed')) {
      return "Network error. Please check your internet connection.";
    }
    // Fallback: strip ugly firebase codes
    return error.replaceAll(RegExp(r'\[.*?\]\s*'), '').replaceFirst("Exception: ", "").trim();
  }

  Future<void> _handleLogin({bool isGoogle = false}) async {
    if (!isGoogle) {
      if (_emailController.text.trim().isEmpty || _passwordController.text.trim().isEmpty) {
        setState(() => _errorMessage = "Please fill in all fields");
        return;
      }
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final profile = isGoogle
          ? await _authService.signInWithGoogle()
          : await _authService.signInWithEmail(
              _emailController.text.trim(),
              _passwordController.text.trim(),
            );

      if (profile != null) {
        _navigateBasedOnRole(profile);
      } else {
        setState(() => _errorMessage = "Sign in was cancelled or failed.");
      }
    } catch (e) {
      if (mounted) {
        final errorStr = e.toString();
        if (errorStr.contains('popup-closed-by-user') || errorStr.contains('cancelled')) {
          setState(() => _errorMessage = null);
        } else {
          setState(() => _errorMessage = _getFriendlyErrorMessage(errorStr));
        }
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _navigateBasedOnRole(UserProfile profile) {
    if (!mounted) return;
    if (profile.isOperator) {
      if (profile.assignedJeepney != null && profile.assignedJeepney!.isNotEmpty) {
        Navigator.pushReplacement(context,
            MaterialPageRoute(builder: (_) => DashboardScreen(jeepId: profile.assignedJeepney!)));
      } else {
        Navigator.push(context,
            MaterialPageRoute(builder: (_) => NoJeepneyAssignedScreen(userEmail: profile.email)));
      }
    } else {
      Navigator.pushReplacement(context,
          MaterialPageRoute(builder: (_) => const PassengerMainScreen()));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          // Base Gradient
          Positioned.fill(
            child: DecoratedBox(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFFFFFFFF), Color(0xFFF5F9F3)],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
            ),
          ),
          
          // Floating Abstract Glow 1 (Top Right)
          Positioned(
            top: -50,
            right: -100,
            child: Container(
              width: 350,
              height: 350,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [Color(0x1F2D6A1E), Colors.transparent],
                  stops: [0.2, 1.0],
                ),
              ),
            ).animate(onPlay: (controller) => controller.repeat(reverse: true))
             .scaleXY(end: 1.15, duration: 5.seconds, curve: Curves.easeInOut),
          ),
          
          // Floating Abstract Glow 2 (Bottom Left)
          Positioned(
            bottom: -50,
            left: -150,
            child: Container(
              width: 450,
              height: 450,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [Color(0x142D6A1E), Colors.transparent],
                  stops: [0.1, 1.0],
                ),
              ),
            ).animate(onPlay: (controller) => controller.repeat(reverse: true))
             .slideX(begin: 0, end: 0.1, duration: 7.seconds, curve: Curves.easeInOut)
             .slideY(begin: 0, end: -0.05, duration: 7.seconds, curve: Curves.easeInOut),
          ),

          // Main Content
          SafeArea(
            child: LayoutBuilder(
              builder: (context, constraints) {
              return SingleChildScrollView(
                child: ConstrainedBox(
                  // Ensures the column is at least as tall as the visible area
                  constraints: BoxConstraints(minHeight: constraints.maxHeight),
                  child: IntrinsicHeight(
                    child: Column(
                      children: [
                        // ── Spacer (top breathing room) ────────────────────
                        const Spacer(),

                        // ── Logo ────────────────────────────────────────────
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 24),
                          child: Image.asset(
                            'assets/images/logo.png',
                            height: 160,
                            fit: BoxFit.contain,
                          ),
                        ).animate().fadeIn(duration: 800.ms).slideY(begin: -0.15, curve: Curves.easeOutBack),

                        const SizedBox(height: 28),

                        // ── White card ─────────────────────────────────────
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 24),
                          child: Container(
                            padding: const EdgeInsets.fromLTRB(28, 36, 28, 36),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(36),
                              boxShadow: [
                                BoxShadow(
                                  color: const Color(0xFF2D6A1E).withOpacity(0.08),
                                  blurRadius: 40,
                                  offset: const Offset(0, 12),
                                ),
                              ],
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                const Text(
                                  "Welcome Back",
                                  style: TextStyle(
                                    fontSize: 24,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF1A1A1A),
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  "Sign in to continue to ParaGo",
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: Colors.grey[500],
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                                const SizedBox(height: 32),

                                // Error banner
                                if (_errorMessage != null) ...[
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
                                    decoration: BoxDecoration(
                                      color: Colors.red.shade50,
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(color: Colors.red.shade200),
                                    ),
                                    child: Text(
                                      _errorMessage!,
                                      style: TextStyle(color: Colors.red.shade700, fontSize: 13),
                                    ),
                                  ),
                                  const SizedBox(height: 16),
                                ],

                                _buildField(
                                  controller: _emailController,
                                  label: "Email",
                                  keyboardType: TextInputType.emailAddress,
                                  suffixIcon: Icons.email_outlined,
                                ),
                                const SizedBox(height: 12),
                                _buildField(
                                  controller: _passwordController,
                                  label: "Password",
                                  obscureText: _obscurePassword,
                                  suffixIcon: _obscurePassword
                                      ? Icons.visibility_off_outlined
                                      : Icons.visibility_outlined,
                                  onSuffixTap: () => setState(() => _obscurePassword = !_obscurePassword),
                                ),

                                const SizedBox(height: 24),

                                // Primary button
                                SizedBox(
                                  height: 56,
                                  child: ElevatedButton(
                                    onPressed: _isLoading ? null : () => _handleLogin(),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: const Color(0xFF2D6A1E),
                                      foregroundColor: Colors.white,
                                      elevation: 0,
                                      shape: const StadiumBorder(),
                                    ),
                                    child: _isLoading
                                        ? const SizedBox(
                                            width: 20,
                                            height: 20,
                                            child: CircularProgressIndicator(
                                                color: Colors.white, strokeWidth: 2.5),
                                          )
                                        : const Text(
                                            "Sign In",
                                            style: TextStyle(
                                                fontSize: 16,
                                                fontWeight: FontWeight.bold,
                                                letterSpacing: 0.3),
                                          ),
                                  ),
                                ),

                                const SizedBox(height: 16),

                                // Divider
                                Row(
                                  children: [
                                    Expanded(child: Divider(color: Colors.grey.shade200)),
                                    Padding(
                                      padding: const EdgeInsets.symmetric(horizontal: 16),
                                      child: Text("OR",
                                          style: TextStyle(
                                              color: Colors.grey.shade400,
                                              fontSize: 11,
                                              fontWeight: FontWeight.w700,
                                              letterSpacing: 1)),
                                    ),
                                    Expanded(child: Divider(color: Colors.grey.shade200)),
                                  ],
                                ),

                                const SizedBox(height: 16),

                                // Google button
                                SizedBox(
                                  height: 56,
                                  child: ElevatedButton.icon(
                                    onPressed: _isLoading ? null : () => _handleLogin(isGoogle: true),
                                    icon: const Icon(Icons.g_mobiledata,
                                        size: 28, color: Color(0xFF2D6A1E)),
                                    label: const Text(
                                      "Continue with Google",
                                      style: TextStyle(
                                          color: Color(0xFF1A1A1A),
                                          fontSize: 15,
                                          fontWeight: FontWeight.w600),
                                    ),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.white,
                                      foregroundColor: Colors.black87,
                                      elevation: 1, // subtle depth
                                      shadowColor: Colors.black.withOpacity(0.2),
                                      shape: const StadiumBorder(),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ).animate(delay: 200.ms).fadeIn(duration: 600.ms).slideY(begin: 0.1, curve: Curves.easeOut),
                        ),

                        // ── Spacer (push link down with consistent padding) ─
                        const Spacer(),

                        // ── Register link — always stays above safe area ────
                        Padding(
                          padding: const EdgeInsets.only(bottom: 24),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                "Don't have an account?  ",
                                style: TextStyle(color: Colors.grey[600], fontSize: 15),
                              ),
                              GestureDetector(
                                onTap: () => Navigator.push(context,
                                    MaterialPageRoute(builder: (_) => const SignupScreen())),
                                child: const Text(
                                  "Create one",
                                  style: TextStyle(
                                    color: Color(0xFF2D6A1E),
                                    fontWeight: FontWeight.bold,
                                    fontSize: 15,
                                  ),
                                ),
                              ),
                            ],
                          ).animate(delay: 600.ms).fadeIn(duration: 500.ms).slideY(begin: 0.1),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
        ],
      ),
    );
  }

  Widget _buildField({
    required TextEditingController controller,
    required String label,
    TextInputType keyboardType = TextInputType.text,
    bool obscureText = false,
    IconData? suffixIcon,
    VoidCallback? onSuffixTap,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFF4FAF2),
        borderRadius: BorderRadius.circular(30),
      ),
      child: TextField(
        controller: controller,
        keyboardType: keyboardType,
        obscureText: obscureText,
        style: const TextStyle(fontSize: 15, color: Color(0xFF1A1A1A)),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: TextStyle(color: Colors.grey[500], fontSize: 13),
          floatingLabelStyle: const TextStyle(color: Color(0xFF2D6A1E), fontSize: 12),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(30),
            borderSide: BorderSide.none,
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(30),
            borderSide: const BorderSide(color: Color(0xFF2D6A1E), width: 1.5),
          ),
          contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 18),
          suffixIcon: suffixIcon != null
              ? Padding(
                  padding: const EdgeInsets.only(right: 8.0),
                  child: GestureDetector(
                    onTap: onSuffixTap,
                    child: Icon(suffixIcon, color: Colors.grey[400], size: 22),
                  ),
                )
              : null,
        ),
      ),
    );
  }
}

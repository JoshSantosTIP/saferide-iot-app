import 'package:flutter/material.dart';
import '../../services/auth_service.dart';

class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final AuthService _authService = AuthService();

  bool _isLoading = false;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  String? _errorMessage;

  String _getFriendlyErrorMessage(String error) {
    if (error.contains('email-already-in-use')) {
      return "An account already exists for this email address.";
    } else if (error.contains('invalid-email')) {
      return "Please enter a valid email address.";
    } else if (error.contains('weak-password')) {
      return "Your password is too weak. Please use a stronger one.";
    } else if (error.contains('network-request-failed')) {
      return "Network error. Please check your internet connection.";
    }
    // Fallback: strip ugly firebase codes
    return error.replaceAll(RegExp(r'\[.*?\]\s*'), '').replaceFirst("Exception: ", "").trim();
  }

  Future<void> _handleSignup() async {
    final name = _nameController.text.trim();
    final email = _emailController.text.trim();
    final pwd = _passwordController.text.trim();
    final confirmPwd = _confirmPasswordController.text.trim();

    if (name.isEmpty || email.isEmpty || pwd.isEmpty || confirmPwd.isEmpty) {
      setState(() => _errorMessage = "Please fill in all fields");
      return;
    }
    if (pwd != confirmPwd) {
      setState(() => _errorMessage = "Passwords do not match");
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final profile = await _authService.signUpWithEmail(email, pwd, name: name);
      if (profile != null && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Account created! Please sign in.')),
        );
        Navigator.pop(context);
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: DecoratedBox(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFFFFFFFF), Color(0xFFDFF0D8)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SafeArea(
          child: LayoutBuilder(
            builder: (context, constraints) {
              return Stack(
                children: [
                  // ── Scrollable content ─────────────────────────────────
                  SingleChildScrollView(
                    child: ConstrainedBox(
                      constraints: BoxConstraints(minHeight: constraints.maxHeight),
                      child: IntrinsicHeight(
                        child: Column(
                          children: [
                            // Top spacer
                            const Spacer(),

                            // ── Logo ───────────────────────────────────────
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 24),
                              child: Image.asset(
                                'assets/images/logo.png',
                                height: 130,
                                fit: BoxFit.contain,
                              ),
                            ),

                            const SizedBox(height: 24),

                            // ── White card ─────────────────────────────────
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 24),
                              child: Container(
                                padding: const EdgeInsets.fromLTRB(24, 24, 24, 24),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(28),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.07),
                                      blurRadius: 28,
                                      offset: const Offset(0, 8),
                                    ),
                                  ],
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.stretch,
                                  children: [
                                    const Text(
                                      "Create Account",
                                      style: TextStyle(
                                        fontSize: 20,
                                        fontWeight: FontWeight.bold,
                                        color: Color(0xFF1A1A1A),
                                      ),
                                      textAlign: TextAlign.center,
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      "Sign up to track jeepneys near you",
                                      style: TextStyle(
                                          fontSize: 13, color: Colors.grey[500]),
                                      textAlign: TextAlign.center,
                                    ),
                                    const SizedBox(height: 20),

                                    // Error banner
                                    if (_errorMessage != null) ...[
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 14, vertical: 11),
                                        decoration: BoxDecoration(
                                          color: Colors.red.shade50,
                                          borderRadius: BorderRadius.circular(12),
                                          border: Border.all(color: Colors.red.shade200),
                                        ),
                                        child: Text(
                                          _errorMessage!,
                                          style: TextStyle(
                                              color: Colors.red.shade700, fontSize: 13),
                                        ),
                                      ),
                                      const SizedBox(height: 14),
                                    ],

                                    _buildField(
                                      controller: _nameController,
                                      label: "Full Name",
                                      suffixIcon: Icons.person_outline,
                                      textCapitalization: TextCapitalization.words,
                                    ),
                                    const SizedBox(height: 12),
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
                                      onSuffixTap: () => setState(
                                          () => _obscurePassword = !_obscurePassword),
                                    ),
                                    const SizedBox(height: 12),
                                    _buildField(
                                      controller: _confirmPasswordController,
                                      label: "Confirm Password",
                                      obscureText: _obscureConfirmPassword,
                                      suffixIcon: _obscureConfirmPassword
                                          ? Icons.visibility_off_outlined
                                          : Icons.visibility_outlined,
                                      onSuffixTap: () => setState(() =>
                                          _obscureConfirmPassword = !_obscureConfirmPassword),
                                    ),

                                    const SizedBox(height: 22),

                                    SizedBox(
                                      height: 52,
                                      child: ElevatedButton(
                                        onPressed: _isLoading ? null : _handleSignup,
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: const Color(0xFF2D6A1E),
                                          foregroundColor: Colors.white,
                                          elevation: 3,
                                          shadowColor:
                                              const Color(0xFF2D6A1E).withOpacity(0.35),
                                          shape: RoundedRectangleBorder(
                                              borderRadius: BorderRadius.circular(30)),
                                        ),
                                        child: _isLoading
                                            ? const SizedBox(
                                                width: 20,
                                                height: 20,
                                                child: CircularProgressIndicator(
                                                    color: Colors.white, strokeWidth: 2.5),
                                              )
                                            : const Text(
                                                "Create Account",
                                                style: TextStyle(
                                                    fontSize: 16,
                                                    fontWeight: FontWeight.bold,
                                                    letterSpacing: 0.3),
                                              ),
                                      ),
                                    ),

                                    const SizedBox(height: 12),

                                    Text(
                                      "Operators need to contact admin after sign up for role assignment.",
                                      style: TextStyle(
                                          fontSize: 11, color: Colors.grey[400]),
                                      textAlign: TextAlign.center,
                                    ),
                                  ],
                                ),
                              ),
                            ),

                            // Bottom spacer
                            const Spacer(),

                            // ── Sign in link — safe distance from bottom ────
                            Padding(
                              padding: const EdgeInsets.only(bottom: 20),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    "Already have an account?  ",
                                    style: TextStyle(color: Colors.grey[600], fontSize: 14),
                                  ),
                                  GestureDetector(
                                    onTap: () => Navigator.pop(context),
                                    child: const Text(
                                      "Sign In",
                                      style: TextStyle(
                                        color: Color(0xFF2D6A1E),
                                        fontWeight: FontWeight.bold,
                                        fontSize: 14,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),

                  // ── Back button pinned top-left ─────────────────────────
                  Positioned(
                    top: 4,
                    left: 4,
                    child: Material(
                      color: Colors.white.withOpacity(0.6),
                      shape: const CircleBorder(),
                      child: IconButton(
                        icon: const Icon(Icons.arrow_back,
                            color: Color(0xFF1A1A1A), size: 22),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        ),
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
    TextCapitalization textCapitalization = TextCapitalization.none,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFF4FAF2),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFD8EDD3), width: 1.2),
      ),
      child: TextField(
        controller: controller,
        keyboardType: keyboardType,
        obscureText: obscureText,
        textCapitalization: textCapitalization,
        style: const TextStyle(fontSize: 14.5, color: Color(0xFF1A1A1A)),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: TextStyle(color: Colors.grey[500], fontSize: 13),
          floatingLabelStyle:
              const TextStyle(color: Color(0xFF2D6A1E), fontSize: 12),
          border: InputBorder.none,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 18, vertical: 15),
          suffixIcon: suffixIcon != null
              ? GestureDetector(
                  onTap: onSuffixTap,
                  child:
                      Icon(suffixIcon, color: Colors.grey[400], size: 20),
                )
              : null,
        ),
      ),
    );
  }
}

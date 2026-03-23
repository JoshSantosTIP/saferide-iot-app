import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/auth_service.dart';
import '../models/user_profile.dart';
import 'login_screen.dart';

class UserSettingsScreen extends StatefulWidget {
  final UserProfile? userProfile;
  final bool isTab; // Added to handle tab usage vs standalone
  
  const UserSettingsScreen({super.key, this.userProfile, this.isTab = false});

  @override
  State<UserSettingsScreen> createState() => _UserSettingsScreenState();
}

class _UserSettingsScreenState extends State<UserSettingsScreen> {
  final AuthService _authService = AuthService();

  // Toggles
  bool _notificationsEnabled = true;
  bool _locationEnabled = true;
  bool _nearbyAlertsEnabled = true;
  bool _crowdAlertEnabled = false;
  bool _darkMapEnabled = false;
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    final profile = widget.userProfile;
    final email = FirebaseAuth.instance.currentUser?.email ?? '';

    return Scaffold(
      backgroundColor: const Color(0xFFF9FBF9), // Match the extremely light background
      body: Stack(
        children: [
          SafeArea(
            bottom: false,
            // If it's a tab, we already have a global safe area and logo above, just add normal padding.
            // If it's NOT a tab, add standard top padding for the back button and header.
            child: SingleChildScrollView(
              padding: EdgeInsets.fromLTRB(24, widget.isTab ? 20 : 16, 24, 120),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                   // Standalone App Bar / Back Button
                  if (!widget.isTab) ...[
                    GestureDetector(
                      onTap: () => Navigator.pop(context),
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.black.withOpacity(0.05)),
                        ),
                        child: const Icon(Icons.arrow_back_rounded, color: Color(0xFF18331A)),
                      ),
                    ),
                    const SizedBox(height: 24),
                  ],

                  // ── Header Profile Info ──────────────────────────────────────
                  Row(
                    children: [
                      Container(
                        width: 72,
                        height: 72,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: const Color(0xFFEFF7EA),
                          border: Border.all(color: const Color(0xFF2D6A1E), width: 2),
                        ),
                        child: ClipOval(
                          child: profile?.profilePictureUrl != null
                              ? Image.network(profile!.profilePictureUrl!, fit: BoxFit.cover)
                              : const Icon(Icons.person, color: Color(0xFF2D6A1E), size: 36),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              profile?.name ?? 'Account Info',
                              style: const TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.w900,
                                color: Color(0xFF101828),
                                letterSpacing: -0.5,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              email,
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey[600],
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: const Color(0xFF2D6A1E).withOpacity(0.1),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                profile?.isOperator == true ? 'Operator' : 'Passenger',
                                style: const TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF2D6A1E),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ).animate().fadeIn(duration: 600.ms).slideX(begin: -0.1, curve: Curves.easeOutCubic),
                  const SizedBox(height: 36),

                  // ── Settings Content ──────────────────────────────────────────
                  _sectionHeader("Preferences").animate(delay: 200.ms).fadeIn(),
                  const SizedBox(height: 12),
                  _settingsCard([
                    _toggleTile(
                      icon: Icons.notifications_active_outlined,
                      title: "Push Notifications",
                      value: _notificationsEnabled,
                      onChanged: (v) => setState(() => _notificationsEnabled = v),
                    ),
                    _divider(),
                    _toggleTile(
                      icon: Icons.location_on_outlined,
                      title: "Share Location",
                      value: _locationEnabled,
                      onChanged: (v) => setState(() => _locationEnabled = v),
                    ),
                  ]).animate(delay: 300.ms).fadeIn(duration: 500.ms).slideY(begin: 0.1, curve: Curves.easeOutCubic),
                  
                  const SizedBox(height: 24),
                  _sectionHeader("Alerts & Map").animate(delay: 400.ms).fadeIn(),
                  const SizedBox(height: 12),
                  _settingsCard([
                    _toggleTile(
                      icon: Icons.near_me_outlined,
                      title: "Nearby Jeepney Alerts",
                      value: _nearbyAlertsEnabled,
                      onChanged: (v) => setState(() => _nearbyAlertsEnabled = v),
                    ),
                    _divider(),
                    _toggleTile(
                      icon: Icons.warning_amber_rounded,
                      title: "Crowd Capacity Alerts",
                      value: _crowdAlertEnabled,
                      onChanged: (v) => setState(() => _crowdAlertEnabled = v),
                    ),
                    _divider(),
                    _toggleTile(
                      icon: Icons.map_outlined,
                      title: "Dark Map Interface",
                      value: _darkMapEnabled,
                      onChanged: (v) => setState(() => _darkMapEnabled = v),
                    ),
                  ]).animate(delay: 500.ms).fadeIn(duration: 500.ms).slideY(begin: 0.1, curve: Curves.easeOutCubic),

                  const SizedBox(height: 24),
                  _sectionHeader("General").animate(delay: 600.ms).fadeIn(),
                  const SizedBox(height: 12),
                  _settingsCard([
                    _actionTile(
                      icon: Icons.info_outline,
                      title: "App Version",
                      trailingText: "v1.0.0",
                    ),
                    _divider(),
                    _actionTile(
                      icon: Icons.logout_rounded,
                      title: "Sign Out",
                      iconColor: Colors.red,
                      titleColor: Colors.red,
                      onTap: () => _confirmLogout(context),
                    ),
                  ]).animate(delay: 700.ms).fadeIn(duration: 500.ms).slideY(begin: 0.1, curve: Curves.easeOutCubic),
                ],
              ),
            ),
          ),

          // ── Loading overlay ──────────────────────────────────────────────────
          if (_isLoading)
            Container(
              color: Colors.black.withOpacity(0.4),
              child: const Center(
                child: Card(
                  elevation: 8,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.all(Radius.circular(20)),
                  ),
                  child: Padding(
                    padding: EdgeInsets.symmetric(horizontal: 32, vertical: 28),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        CircularProgressIndicator(color: Color(0xFF2D6A1E)),
                        SizedBox(height: 16),
                        Text(
                          "Signing out…",
                          style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _sectionHeader(String label) {
    return Padding(
      padding: const EdgeInsets.only(left: 4),
      child: Text(
        label.toUpperCase(),
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w800,
          color: Colors.grey[500],
          letterSpacing: 1.2,
        ),
      ),
    );
  }

  Widget _settingsCard(List<Widget> children) {
    return Container(
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
      child: Column(children: children),
    );
  }

  Widget _toggleTile({
    required IconData icon,
    required String title,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: const Color(0xFFF3FBF5),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: const Color(0xFF2D6A1E), size: 20),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              title,
              style: const TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 15,
                color: Color(0xFF111827),
              ),
            ),
          ),
          Switch.adaptive(
            value: value,
            onChanged: onChanged,
            activeColor: const Color(0xFF2D6A1E),
          ),
        ],
      ),
    );
  }

  Widget _actionTile({
    required IconData icon,
    required String title,
    Color? iconColor,
    Color? titleColor,
    String? trailingText,
    VoidCallback? onTap,
  }) {
    final effectiveIconColor = iconColor ?? const Color(0xFF2D6A1E);
    final bgColor = iconColor != null ? iconColor.withOpacity(0.1) : const Color(0xFFF3FBF5);
    
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(24),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: bgColor,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: effectiveIconColor, size: 20),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                title,
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 15,
                  color: titleColor ?? const Color(0xFF111827),
                ),
              ),
            ),
            if (trailingText != null)
              Text(
                trailingText,
                style: TextStyle(color: Colors.grey[400], fontSize: 13, fontWeight: FontWeight.w600),
              )
            else
              const Icon(Icons.chevron_right_rounded, color: Colors.grey, size: 22),
          ],
        ),
      ),
    );
  }

  Widget _divider() {
    return Divider(
      height: 1,
      thickness: 1,
      indent: 64,
      endIndent: 20,
      color: Colors.black.withOpacity(0.05),
    );
  }

  void _confirmLogout(BuildContext context) {
    showDialog(
      context: context,
      builder: (dialogCtx) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
        backgroundColor: Colors.white,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 32, 24, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.logout_rounded, color: Colors.redAccent, size: 36),
              ),
              const SizedBox(height: 24),
              const Text(
                "Sign Out",
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w900,
                  color: Color(0xFF111827),
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                "Are you sure you want to securely wrap up and sign out from your account?",
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 14, color: Colors.grey[600], height: 1.4),
              ),
              const SizedBox(height: 32),
              Row(
                children: [
                  Expanded(
                    child: TextButton(
                      onPressed: () => Navigator.pop(dialogCtx),
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      ),
                      child: Text("Cancel",
                          style: TextStyle(color: Colors.grey[700], fontWeight: FontWeight.bold, fontSize: 16)),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () async {
                        Navigator.pop(dialogCtx);
                        if (mounted) setState(() => _isLoading = true);
                        try {
                          await _authService.signOut().timeout(const Duration(seconds: 5));
                        } catch (_) {}
                        if (mounted) setState(() => _isLoading = false);
                        if (context.mounted) {
                          Navigator.of(context).pushAndRemoveUntil(
                            MaterialPageRoute(builder: (_) => const LoginScreen()),
                            (_) => false,
                          );
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.redAccent,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      ),
                      child: const Text("Sign Out", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

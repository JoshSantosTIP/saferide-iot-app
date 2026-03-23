import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../models/user_profile.dart';
import '../../services/auth_service.dart';
import 'passenger_map_screen.dart';
import 'passenger_nearby_screen.dart';
import '../user_settings_screen.dart';
import '../../widgets/chatbot_widget.dart'; // Add Chatbot widget

class PassengerMainScreen extends StatefulWidget {
  const PassengerMainScreen({super.key});

  @override
  State<PassengerMainScreen> createState() => _PassengerMainScreenState();
}

class _PassengerMainScreenState extends State<PassengerMainScreen> {
  int _currentIndex = 1; // 0=Account, 1=Home(Map), 2=Nearby
  final PageController _pageController = PageController(initialPage: 1);

  UserProfile? _userProfile;
  final AuthService _authService = AuthService();
  bool _isLoadingProfile = true;

  @override
  void initState() {
    super.initState();
    _loadUserProfile();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _loadUserProfile() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid != null) {
      final profile = await _authService.getUserProfile(uid);
      if (mounted) {
        setState(() {
          _userProfile = profile;
          _isLoadingProfile = false;
        });
      }
    } else {
      if (mounted) {
        setState(() {
          _isLoadingProfile = false;
        });
      }
    }
  }

  void _onPageChanged(int index) {
    setState(() {
      _currentIndex = index;
    });
  }

  void _onNavTapped(int index) {
    if ((index - _currentIndex).abs() > 1) {
      // Direct jump to avoid "crossing over" intermediate screens
      _pageController.jumpToPage(index);
    } else {
      _pageController.animateToPage(
        index,
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeOutCubic,
      );
    }
  }

  Widget _buildPage(int index) {
    switch (index) {
      case 0:
        return UserSettingsScreen(userProfile: _userProfile, isTab: true);
      case 1:
        return const PassengerMapScreen();
      case 2:
        return const PassengerNearbyScreen();
      default:
        return const SizedBox.shrink();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9FBF9), // Extremely light background
      floatingActionButton: const ChatbotFab(), // Globally visible across all tabs!
      body: Column(
        children: [
          // ── Global Top Logo (Always visible overlying the tabs) ───────
          SafeArea(
            bottom: false,
            child: Padding(
              padding: const EdgeInsets.only(left: 24, right: 24, top: 16, bottom: 8),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        )
                      ],
                    ),
                    child: const Icon(Icons.directions_transit_filled_rounded, color: Color(0xFF2D6A1E), size: 18),
                  ),
                  const SizedBox(width: 8),
                  const Text(
                    "PARAGO",
                    style: TextStyle(
                      color: Color(0xFF18331A),
                      fontSize: 16,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 2.0,
                    ),
                  ),
                ],
              ),
            ),
          ),
          
          // ── The Swipeable Views ─────────────────────────────────────────
          Expanded(
            child: AnimatedBuilder(
              animation: _pageController,
              builder: (context, child) {
                return PageView.builder(
                  controller: _pageController,
                  onPageChanged: _onPageChanged,
                  physics: const BouncingScrollPhysics(),
                  itemCount: 3,
                  itemBuilder: (context, index) {
                    // Animation logic
                    double value = (_currentIndex - index).abs().toDouble(); // Default based on stored index
                    
                    if (_pageController.hasClients && _pageController.positions.length == 1) {
                      try {
                        value = (_pageController.page! - index).abs();
                      } catch (_) {
                        // Fallback to default if page property access still fails
                      }
                    }

                    // Clamp and invert (0.0 = active, 1.0 = fully "deloaded")
                    value = (1 - (value * 0.4)).clamp(0.0, 1.0);
                    
                    final double scale = 0.92 + (value * 0.08); // 0.92 to 1.0
                    final double opacity = 0.4 + (value * 0.6); // 0.4 to 1.0
                    final double yOffset = (1 - value) * 15;   // 15px rise effect

                    return Opacity(
                      opacity: opacity,
                      child: Transform.translate(
                        offset: Offset(0, yOffset),
                        child: Transform.scale(
                          scale: scale,
                          child: _buildPage(index),
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
      // Use floating bottom navigation bar
      bottomNavigationBar: SafeArea(
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(40),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.08),
                blurRadius: 15,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildNavItem(0, Icons.person_rounded, "Account"),
                _buildNavItem(1, Icons.map_rounded, "Home", isCircle: true),
                _buildNavItem(2, Icons.directions_bus_rounded, "Nearby"),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(int index, IconData icon, String label, {bool isCircle = false}) {
    final bool isActive = _currentIndex == index;
    final Color activeColor = const Color(0xFF2D6A1E); // Our brand Mint/Green
    final Color inactiveColor = Colors.grey[400]!;

    return GestureDetector(
      onTap: () => _onNavTapped(index),
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOutCubic,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (isCircle)
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: isActive ? activeColor : Colors.transparent,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  icon,
                  color: isActive ? Colors.white : inactiveColor,
                  size: 26,
                ),
              )
            else
              Container(
                padding: const EdgeInsets.all(8),
                child: Icon(
                  icon,
                  color: isActive ? activeColor : inactiveColor,
                  size: 26,
                ),
              ),
            const SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(
                color: isActive ? activeColor : inactiveColor,
                fontSize: 11,
                fontWeight: isActive ? FontWeight.bold : FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}


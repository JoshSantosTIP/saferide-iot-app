import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'login_screen.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({Key? key}) : super(key: key);

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  final List<Map<String, dynamic>> _pages = [
    {
      'title': 'Welcome to ParaGo',
      'description': 'Your intelligent companion for safe and efficient jeepney rides.',
      'icon': Icons.directions_bus_rounded,
    },
    {
      'title': 'Real-Time Tracking',
      'description': 'Know exactly where your ride is and when it will arrive at your stop.',
      'icon': Icons.map_rounded,
    },
    {
      'title': 'Safety First',
      'description': 'Get instant alerts about vehicle capacity limits to ensure a comfortable journey.',
      'icon': Icons.verified_user_rounded,
    },
  ];

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
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
            child: Column(
              children: [
                // Skip button at top right
                Align(
                  alignment: Alignment.topRight,
                  child: Padding(
                    padding: const EdgeInsets.only(top: 16.0, right: 16.0),
                    child: TextButton(
                      onPressed: _goToLogin,
                      child: const Text(
                        'Skip',
                        style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                ),
            
            // Carousel
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                onPageChanged: (index) {
                  setState(() => _currentPage = index);
                },
                itemCount: _pages.length,
                itemBuilder: (context, index) {
                  return _buildPage(_pages[index]);
                },
              ),
            ),
            
            // Indicators
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(
                _pages.length,
                (index) => AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  margin: const EdgeInsets.symmetric(horizontal: 4.0),
                  height: 8.0,
                  width: _currentPage == index ? 24.0 : 8.0,
                  decoration: BoxDecoration(
                    color: _currentPage == index ? const Color(0xFF2D6A1E) : Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(4.0),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 32),
            
            // Get Started Button
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
              child: ElevatedButton(
                onPressed: () {
                  if (_currentPage == _pages.length - 1) {
                    _goToLogin();
                  } else {
                    _pageController.nextPage(
                      duration: const Duration(milliseconds: 300),
                      curve: Curves.easeInOut,
                    );
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF2D6A1E),
                  foregroundColor: Colors.white,
                  minimumSize: const Size(double.infinity, 56),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  elevation: 0,
                ),
                child: Text(
                  _currentPage == _pages.length - 1 ? "Get Started" : "Next",
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
      ],
    ),
  );
}

  Widget _buildPage(Map<String, dynamic> page) {
    return Padding(
      padding: const EdgeInsets.all(40.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(32),
            decoration: const BoxDecoration(
              color: Color(0xFFEFF7EA),
              shape: BoxShape.circle,
            ),
            child: Icon(
              page['icon'],
              size: 100,
              color: const Color(0xFF2D6A1E),
            ),
          ).animate().scale(delay: 200.ms, duration: 500.ms, curve: Curves.easeOutBack),
          const SizedBox(height: 48),
          Text(
            page['title'],
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1A1A1A),
            ),
          ).animate().fadeIn(delay: 400.ms).slideY(begin: 0.2, end: 0),
          const SizedBox(height: 16),
          Text(
            page['description'],
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey.shade600,
              height: 1.5,
            ),
          ).animate().fadeIn(delay: 600.ms).slideY(begin: 0.2, end: 0),
        ],
      ),
    );
  }

  void _goToLogin() {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => const LoginScreen()),
    );
  }
}

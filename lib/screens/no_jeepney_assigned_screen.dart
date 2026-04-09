import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'login_screen.dart';

// Operator color system (matches DashboardScreen - green palette)
const _kBg = Color(0xFFF2F7F2);
const _kSurface = Color(0xFFFFFFFF);
const _kBorder = Color(0xFFE4EDE4);
const _kAmber = Color(0xFF2D6A1E);    // primary green
const _kRed = Color(0xFFD32F2F);
const _kTextPrimary = Color(0xFF1B3B18);
const _kTextSecondary = Color(0xFF6B8A65);

class NoJeepneyAssignedScreen extends StatelessWidget {
  final String userEmail;
  const NoJeepneyAssignedScreen({super.key, required this.userEmail});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _kBg,
      body: Stack(
        children: [
          // Grid background
          CustomPaint(painter: _GridPainter(), size: Size.infinite),

          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Top bar
                  Row(
                    children: [
                      Container(
                        width: 10, height: 10,
                        decoration: const BoxDecoration(
                          color: _kRed, shape: BoxShape.circle,
                        ),
                      ).animate()
                       .scaleXY(end: 1.6, duration: 900.ms),
                      const SizedBox(width: 8),
                      const Text(
                        'ACCESS RESTRICTED',
                        style: TextStyle(
                          fontSize: 11,
                          color: _kRed,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 2.5,
                        ),
                      ),
                    ],
                  ).animate().fadeIn(delay: 100.ms, duration: 500.ms),

                  const Spacer(),

                  // Error code visual
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: _kRed.withOpacity(0.06),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: _kRed.withOpacity(0.25)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.directions_bus_filled_rounded, color: _kRed, size: 28),
                            const SizedBox(width: 12),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: const [
                                Text(
                                  'ERR_NO_VEHICLE',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w900,
                                    color: _kRed,
                                    fontFamily: 'monospace',
                                    letterSpacing: 1,
                                  ),
                                ),
                                Text(
                                  'Vehicle not assigned to operator',
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: _kTextSecondary,
                                    letterSpacing: 0.5,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),
                        Container(
                          height: 1,
                          color: _kRed.withOpacity(0.15),
                        ),
                        const SizedBox(height: 20),
                        _infoRow('USER', userEmail),
                        const SizedBox(height: 10),
                        _infoRow('STATUS', 'UNASSIGNED'),
                        const SizedBox(height: 10),
                        _infoRow('ACTION', 'Contact administrator'),
                      ],
                    ),
                  ).animate().fadeIn(delay: 200.ms, duration: 500.ms)
                   .slideY(begin: 0.1, curve: Curves.easeOutCubic),

                  const SizedBox(height: 24),

                  // Main message
                  const Text(
                    'No vehicle\nassigned.',
                    style: TextStyle(
                      fontSize: 40,
                      fontWeight: FontWeight.w900,
                      color: _kTextPrimary,
                      height: 1.1,
                      letterSpacing: -0.5,
                    ),
                  ).animate().fadeIn(delay: 300.ms, duration: 500.ms)
                   .slideY(begin: 0.1, curve: Curves.easeOutCubic),

                  const SizedBox(height: 16),
                  const Text(
                    'Your operator account does not have a jeepney assigned to it. Please contact your fleet administrator to get a vehicle assigned before you can access the dispatch dashboard.',
                    style: TextStyle(
                      fontSize: 14,
                      color: _kTextSecondary,
                      height: 1.6,
                    ),
                  ).animate().fadeIn(delay: 400.ms, duration: 500.ms),

                  const SizedBox(height: 36),

                  // Back to login
                  GestureDetector(
                    onTap: () {
                      Navigator.of(context).pushAndRemoveUntil(
                        MaterialPageRoute(builder: (_) => const LoginScreen()),
                        (_) => false,
                      );
                    },
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      decoration: BoxDecoration(
                        color: _kSurface,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: _kBorder),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: const [
                          Icon(Icons.arrow_back_rounded, color: _kTextSecondary, size: 16),
                          SizedBox(width: 10),
                          Text(
                            'BACK TO LOGIN',
                            style: TextStyle(
                              color: _kTextSecondary,
                              fontWeight: FontWeight.w700,
                              fontSize: 13,
                              letterSpacing: 1.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ).animate().fadeIn(delay: 500.ms, duration: 500.ms),

                  const SizedBox(height: 12),

                  // Contact admin
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [_kAmber.withOpacity(0.15), _kAmber.withOpacity(0.05)],
                      ),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: _kAmber.withOpacity(0.35)),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: const [
                        Icon(Icons.admin_panel_settings_rounded, color: _kAmber, size: 16),
                        SizedBox(width: 10),
                        Text(
                          'CONTACT ADMINISTRATOR',
                          style: TextStyle(
                            color: _kAmber,
                            fontWeight: FontWeight.w800,
                            fontSize: 12,
                            letterSpacing: 1.5,
                          ),
                        ),
                      ],
                    ),
                  ).animate().fadeIn(delay: 600.ms, duration: 500.ms),

                  const Spacer(),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _infoRow(String key, String value) {
    return Row(
      children: [
        SizedBox(
          width: 72,
          child: Text(
            key,
            style: const TextStyle(
              fontSize: 10,
              color: _kTextSecondary,
              letterSpacing: 1.5,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        const Text('·  ', style: TextStyle(color: _kBorder)),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(
              fontSize: 12,
              color: _kTextPrimary,
              fontFamily: 'monospace',
              fontWeight: FontWeight.w600,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}

class _GridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFFE8F5E3)
      ..strokeWidth = 0.7;
    const spacing = 36.0;
    for (double x = 0; x < size.width; x += spacing) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }
    for (double y = 0; y < size.height; y += spacing) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter old) => false;
}

import 'dart:async';
import 'dart:math';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:latlong2/latlong.dart';
import '../models/jeepney_data.dart';
import '../models/user_profile.dart';
import '../services/jeepney_service.dart';
import '../services/auth_service.dart';
import '../widgets/chatbot_widget.dart';
import 'login_screen.dart';

// ── Brand tokens (matches passenger green palette) ────────────────────────────
const _kBg        = Color(0xFFF9FBF9);
const _kSurface   = Color(0xFFFFFFFF);
const _kBorder    = Color(0xFFE8F5E3);
const _kPrimary   = Color(0xFF2D6A1E);  // deep brand green
const _kGreen     = Color(0xFF438A31);  // signal green
const _kRed       = Color(0xFFD32F2F);
const _kTextPrimary   = Color(0xFF111827);
const _kTextSecondary = Color(0xFF6B8A65);

// ── Shell ─────────────────────────────────────────────────────────────────────
class DashboardScreen extends StatefulWidget {
  final String jeepId;
  const DashboardScreen({super.key, required this.jeepId});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen>
    with TickerProviderStateMixin {
  int _currentIndex = 1; // 0=Settings, 1=Dashboard, 2=Audit Logs
  late final PageController _pageController;

  UserProfile? _userProfile;
  final AuthService _authService = AuthService();
  bool _isLoadingProfile = true;

  @override
  void initState() {
    super.initState();
    _pageController = PageController(initialPage: 1);
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
      if (mounted) setState(() { _userProfile = profile; _isLoadingProfile = false; });
    } else {
      if (mounted) setState(() => _isLoadingProfile = false);
    }
  }

  void _onNavTapped(int index) {
    if ((index - _currentIndex).abs() > 1) {
      _pageController.jumpToPage(index);
    } else {
      _pageController.animateToPage(index,
          duration: const Duration(milliseconds: 380),
          curve: Curves.easeOutCubic);
    }
  }

  Widget _buildPage(int index) {
    switch (index) {
      case 0: return _OperatorSettingsTab(
          userProfile: _userProfile,
          isLoading: _isLoadingProfile,
          jeepId: widget.jeepId,
        );
      case 1: return _OperatorDashTab(jeepId: widget.jeepId);
      case 2: return _OperatorAuditTab(jeepId: widget.jeepId);
      case 3: return _OperatorAnalyticsTab(jeepId: widget.jeepId);
      default: return const SizedBox.shrink();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _kBg,
      floatingActionButton: _buildAiFab(),
      body: Column(
        children: [
          // ── Persistent header ────────────────────────────────────────────
          SafeArea(
            bottom: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 14, 20, 8),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: _kPrimary.withOpacity(0.12),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: const Icon(Icons.directions_transit_filled_rounded,
                        color: _kPrimary, size: 18),
                  ),
                  const SizedBox(width: 10),
                  const Text(
                    'PARAGO',
                    style: TextStyle(
                      color: _kTextPrimary,
                      fontSize: 16,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 2.4,
                    ),
                  ),
                  const Spacer(),
                  // Operator badge
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: _kPrimary.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _LiveDot(),
                        const SizedBox(width: 5),
                        const Text(
                          'OPERATOR',
                          style: TextStyle(
                            color: _kPrimary,
                            fontSize: 10,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 1.2,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          // ── Swipeable pages ──────────────────────────────────────────────
          Expanded(
            child: AnimatedBuilder(
              animation: _pageController,
              builder: (context, child) {
                return PageView.builder(
                  controller: _pageController,
                  onPageChanged: (i) => setState(() => _currentIndex = i),
                  physics: const BouncingScrollPhysics(),
                  itemCount: 4,
                  itemBuilder: (context, index) {
                    double value = (_currentIndex - index).abs().toDouble();
                    if (_pageController.hasClients &&
                        _pageController.positions.length == 1) {
                      try { value = (_pageController.page! - index).abs(); } catch (_) {}
                    }
                    value = (1 - (value * 0.4)).clamp(0.0, 1.0);
                    return Opacity(
                      opacity: (0.4 + value * 0.6).clamp(0.0, 1.0),
                      child: Transform.translate(
                        offset: Offset(0, (1 - value) * 12),
                        child: Transform.scale(
                          scale: 0.93 + value * 0.07,
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

      // ── Floating bottom nav ──────────────────────────────────────────────
      bottomNavigationBar: SafeArea(
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(40),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.08),
                blurRadius: 16,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildNavItem(0, Icons.settings_rounded, 'Settings'),
                _buildNavItem(1, Icons.dashboard_rounded, 'Dashboard', isCenter: true),
                _buildNavItem(2, Icons.history_rounded, 'Audit Logs'),
                _buildNavItem(3, Icons.insights_rounded, 'Analytics'),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(int index, IconData icon, String label,
      {bool isCenter = false}) {
    final isActive = _currentIndex == index;
    return GestureDetector(
      onTap: () => _onNavTapped(index),
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOutCubic,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (isCenter)
              AnimatedContainer(
                duration: const Duration(milliseconds: 220),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: isActive ? _kPrimary : Colors.transparent,
                  shape: BoxShape.circle,
                ),
                child: Icon(icon,
                    color: isActive ? Colors.white : Colors.grey[400],
                    size: 26),
              )
            else
              Padding(
                padding: const EdgeInsets.all(8),
                child: Icon(icon,
                    color: isActive ? _kPrimary : Colors.grey[400], size: 24),
              ),
            const SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(
                color: isActive ? _kPrimary : Colors.grey[400],
                fontSize: 10,
                fontWeight: isActive ? FontWeight.w800 : FontWeight.w600,
                letterSpacing: 0.3,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAiFab() {
    return FloatingActionButton(
      heroTag: 'chatbot_fab',
      backgroundColor: _kPrimary,
      shape: const CircleBorder(),
      tooltip: 'SafeRide Assistant',
      onPressed: () {
        showModalBottomSheet(
          context: context,
          isScrollControlled: true,
          backgroundColor: Colors.transparent,
          builder: (ctx) => const ChatbotFabSheet(),
        );
      },
      child: const Icon(Icons.support_agent_rounded, color: Colors.white, size: 26),
    );
  }
}

// ── Live indicator dot ────────────────────────────────────────────────────────
class _LiveDot extends StatefulWidget {
  @override
  State<_LiveDot> createState() => _LiveDotState();
}
class _LiveDotState extends State<_LiveDot> with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 1400))
      ..repeat(reverse: true);
  }
  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }
  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _ctrl,
      builder: (_, __) => Container(
        width: 7, height: 7,
        decoration: BoxDecoration(
          color: _kGreen.withOpacity(0.5 + 0.5 * _ctrl.value),
          shape: BoxShape.circle,
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// TAB 1 — DASHBOARD (Live telemetry)
// ─────────────────────────────────────────────────────────────────────────────
class _OperatorDashTab extends StatefulWidget {
  final String jeepId;
  const _OperatorDashTab({required this.jeepId});
  @override
  State<_OperatorDashTab> createState() => _OperatorDashTabState();
}

class _OperatorDashTabState extends State<_OperatorDashTab>
    with TickerProviderStateMixin {
  final JeepneyService _service = JeepneyService();
  late Stream<JeepneyData> _jeepStream;
  final MapController _mapController = MapController();
  late AnimationController _pulseCtrl;
  List<Map<String, dynamic>> _alerts = [];
  late StreamSubscription _alertSub;
  bool _showMap = true;

  // Boarding detection
  // Location name for map display
  String _locationName = '';

  @override
  void initState() {
    super.initState();
    _jeepStream = _service.streamJeepneyData(widget.jeepId);
    _service.initializeNotifications();
    _pulseCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 1800))
      ..repeat();
    _alertSub = _service.streamAlerts(widget.jeepId).listen((alerts) {
      if (mounted) setState(() => _alerts = alerts);
    });
  }

  @override
  void dispose() {
    _alertSub.cancel();
    _pulseCtrl.dispose();
    super.dispose();
  }

  void _animatedMapMove(LatLng dest, double zoom) {
    final latT = Tween<double>(begin: _mapController.camera.center.latitude, end: dest.latitude);
    final lngT = Tween<double>(begin: _mapController.camera.center.longitude, end: dest.longitude);
    final ctrl = AnimationController(duration: const Duration(milliseconds: 900), vsync: this);
    final anim = CurvedAnimation(parent: ctrl, curve: Curves.fastOutSlowIn);
    ctrl.addListener(() => _mapController.move(LatLng(latT.evaluate(anim), lngT.evaluate(anim)), zoom));
    anim.addStatusListener((s) {
      if (s == AnimationStatus.completed || s == AnimationStatus.dismissed) ctrl.dispose();
    });
    ctrl.forward();
  }

  String _timeAgo(int ts) {
    final d = DateTime.now().difference(DateTime.fromMillisecondsSinceEpoch(ts));
    if (d.inSeconds < 60) return '${d.inSeconds}s ago';
    if (d.inMinutes < 60) return '${d.inMinutes}m ago';
    return '${d.inHours}h ago';
  }

  Color _alertColor(String type) {
    switch (type) {
      case 'stop_request': return _kPrimary;
      case 'emergency': return _kRed;
      case 'overloading': return const Color(0xFF3B82F6);
      default: return _kTextSecondary;
    }
  }

  IconData _alertIcon(String type) {
    switch (type) {
      case 'stop_request': return Icons.pan_tool_rounded;
      case 'emergency': return Icons.warning_rounded;
      case 'overloading': return Icons.groups_rounded;
      default: return Icons.notifications_rounded;
    }
  }

  String _alertLabel(String type) {
    switch (type) {
      case 'stop_request': return 'STOP REQ';
      case 'emergency': return 'EMERGENCY';
      case 'overloading': return 'OVERLOAD';
      default: return 'ALERT';
    }
  }

  String _formatTs(int ts) {
    final d = DateTime.fromMillisecondsSinceEpoch(ts);
    return '${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}:${d.second.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<JeepneyData>(
      stream: _jeepStream,
      builder: (ctx, snap) {
        if (!snap.hasData) return _buildLoading();
        final data = snap.data!;
        _service.checkSystemAlerts(data);
        return _buildBody(data);
      },
    );
  }

  Widget _buildLoading() => Center(
    child: Column(mainAxisSize: MainAxisSize.min, children: [
      SizedBox(width: 36, height: 36,
          child: CircularProgressIndicator(color: _kPrimary, strokeWidth: 2)),
      const SizedBox(height: 14),
      const Text('CONNECTING…',
          style: TextStyle(color: _kTextSecondary, fontSize: 11,
              letterSpacing: 2, fontWeight: FontWeight.w700)),
    ]),
  );

  Widget _buildBody(JeepneyData data) {
    final fillPct = (data.weightLoadPercentage / 100.0).clamp(0.0, 1.0);

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 90),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Status banner ──────────────────────────────────────────────
          _buildStatusBanner(data),
          const SizedBox(height: 12),

          // ── Gauge row ─────────────────────────────────────────────────
          Row(children: [
            Expanded(child: _buildWeightGauge(data.currentWeight, data.maxWeightCapacity, fillPct)),
            const SizedBox(width: 8),
            Expanded(child: Column(children: [
              _buildStatCard(
                label: 'PASSENGERS',
                icon: Icons.event_seat_rounded,
                value: '${data.passengerCount}',
                sub: '/ ${data.maxSeatCapacity}',
                color: data.passengerCount >= data.maxSeatCapacity ? _kRed
                    : (data.passengerCount / data.maxSeatCapacity > 0.7 ? _kPrimary : _kGreen),
              ),
              const SizedBox(height: 8),
              _buildStatCard(
                label: 'VELOCITY',
                icon: Icons.speed_rounded,
                value: data.speed.toStringAsFixed(0),
                sub: ' km/h',
                color: _kPrimary,
              ),
            ])),
          ]),
          const SizedBox(height: 12),

          // ── Map ───────────────────────────────────────────────────────
          _buildMapSection(data),
          const SizedBox(height: 12),

          // ── Passenger alerts ──────────────────────────────────────────
          if (_alerts.isNotEmpty) ...[
            _sectionLabel('PASSENGER SIGNALS', Icons.cell_tower_rounded),
            const SizedBox(height: 8),
            ..._alerts.map((a) => _buildAlertCard(a)),
          ],
        ].animate(interval: 40.ms)
            .fadeIn(duration: 380.ms, curve: Curves.easeOutCubic)
            .slideY(begin: 0.04, duration: 380.ms, curve: Curves.easeOutCubic),
      ),
    );
  }

  Widget _buildStatusBanner(JeepneyData data) {
    List<Widget> banners = [];

    if (data.currentWeight > data.maxWeightCapacity) {
      banners.add(_buildGradientBanner(_kRed, const Color(0xFFDC2626), 'WEIGHT LIMIT EXCEEDED', Icons.warning_rounded));
    }
    if (data.passengerCount >= data.maxSeatCapacity) {
      banners.add(_buildGradientBanner(const Color(0xFFF59E0B), const Color(0xFFD97706), 'NO MORE AVAILABLE SEATS', Icons.event_seat_rounded));
    }

    if (banners.isEmpty) {
      banners.add(_buildGradientBanner(_kGreen, const Color(0xFF15803D), 'ALL SYSTEMS NOMINAL', Icons.verified_rounded));
    }

    return Column(
      children: banners.map((b) => Padding(padding: const EdgeInsets.only(bottom: 8.0), child: b)).toList(),
    );
  }

  Widget _buildGradientBanner(Color color1, Color color2, String label, IconData icon) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 380),
      curve: Curves.easeOutCubic,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [color1, color2],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(color: color1.withOpacity(0.35), blurRadius: 12, offset: const Offset(0, 4)),
        ],
      ),
      child: Row(children: [
        Icon(icon, color: Colors.white, size: 18),
        const SizedBox(width: 12),
        Expanded(child: Text(label,
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w800,
                color: Colors.white, letterSpacing: 1.2))),
         Container(width: 8, height: 8,
             decoration: BoxDecoration(color: Colors.white.withOpacity(0.9), shape: BoxShape.circle)),
      ]),
    );
  }

  Widget _buildWeightGauge(double weight, double max, double fillPct) {
    final isHigh  = fillPct > 0.85;
    final color   = isHigh ? _kRed : (fillPct > 0.6 ? _kPrimary : _kGreen);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.black.withOpacity(0.03)),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 20, offset: const Offset(0, 8))],
      ),
      child: Column(children: [
        _sectionLabel('PAYLOAD', Icons.scale_rounded),
        const SizedBox(height: 14),
        TweenAnimationBuilder<double>(
          tween: Tween<double>(begin: 0, end: fillPct),
          duration: const Duration(milliseconds: 600),
          curve: Curves.easeOutCubic,
          builder: (_, v, __) => SizedBox(
            width: 100, height: 60,
            child: CustomPaint(
              painter: _ArcGaugePainter(percent: v, color: color),
              child: Center(child: Padding(
                padding: const EdgeInsets.only(top: 12),
                child: Text('${(v * 100).toStringAsFixed(0)}%',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900,
                        color: color, fontFamily: 'monospace')),
              )),
            ),
          ),
        ),
        const SizedBox(height: 8),
        Text('${weight.toStringAsFixed(0)} / ${max.toStringAsFixed(0)} kg',
            style: const TextStyle(fontSize: 11, color: _kTextSecondary, fontFamily: 'monospace')),
        const SizedBox(height: 8),
        _buildLinearBar(fillPct, color),
      ]),
    );
  }

  Widget _buildLinearBar(double fill, Color color) => Stack(children: [
    Container(height: 6,
        decoration: BoxDecoration(color: Colors.grey.withOpacity(0.15), borderRadius: BorderRadius.circular(4))),
    AnimatedFractionallySizedBox(
      duration: const Duration(milliseconds: 600), curve: Curves.easeOutCubic,
      widthFactor: fill,
      child: Container(height: 6,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(4),
            gradient: LinearGradient(colors: [color.withOpacity(0.5), color]),
            boxShadow: [BoxShadow(color: color.withOpacity(0.4), blurRadius: 4, offset: const Offset(0, 2))],
          )),
    ),
  ]);

  Widget _buildStatCard({required String label, required IconData icon,
      required String value, required String sub, required Color color}) {
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.black.withOpacity(0.03)),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 20, offset: const Offset(0, 8))],
      ),
      child: Row(children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [color.withOpacity(0.15), color.withOpacity(0.05)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: color, size: 18),
        ),
        const SizedBox(width: 12),
        Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(label, style: const TextStyle(fontSize: 9, color: _kTextSecondary,
              letterSpacing: 1.5, fontWeight: FontWeight.w700)),
          const SizedBox(height: 2),
          RichText(text: TextSpan(children: [
            WidgetSpan(child: TweenAnimationBuilder<double>(
              tween: Tween<double>(begin: 0, end: double.tryParse(value) ?? 0),
              duration: const Duration(milliseconds: 600),
              curve: Curves.easeOutCubic,
              builder: (_, v, __) => Text(
                value.contains('.') ? v.toStringAsFixed(0) : v.toInt().toString(),
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900,
                    color: color, fontFamily: 'monospace'),
              ),
            )),
            TextSpan(text: sub,
                style: const TextStyle(fontSize: 11, color: _kTextSecondary, fontFamily: 'monospace')),
          ])),
        ]),
      ]),
    );
  }

  Widget _buildMapSection(JeepneyData data) {
    return Column(children: [
      Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: Colors.black.withOpacity(0.03)),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 20, offset: const Offset(0, 8))],
        ),
        child: Column(children: [
          GestureDetector(
            onTap: () => setState(() => _showMap = !_showMap),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [_kGreen.withOpacity(0.15), _kGreen.withOpacity(0.03)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: _showMap
                    ? const BorderRadius.vertical(top: Radius.circular(23))
                    : BorderRadius.circular(23),
              ),
              child: Row(children: [
                _sectionLabel('LIVE LOCATION', Icons.radar_rounded),
                const Spacer(),
                Icon(_showMap ? Icons.keyboard_arrow_up_rounded : Icons.keyboard_arrow_down_rounded,
                    color: _kPrimary, size: 20),
              ]),
            ),
          ),
          if (_showMap)
            ClipRRect(
              borderRadius: const BorderRadius.vertical(bottom: Radius.circular(23)),
              child: SizedBox(
                height: 180,
                child: Stack(children: [
                  FlutterMap(
                    mapController: _mapController,
                    options: MapOptions(
                      initialCenter: LatLng(data.latitude, data.longitude),
                      initialZoom: 16.0,
                    ),
                    children: [
                      TileLayer(urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png'),
                      MarkerLayer(markers: [
                        Marker(
                          point: LatLng(data.latitude, data.longitude),
                          width: 50, height: 50,
                          child: Stack(alignment: Alignment.center, children: [
                            AnimatedBuilder(
                              animation: _pulseCtrl,
                              builder: (_, __) => Container(
                                width: 38 + (10 * _pulseCtrl.value),
                                height: 38 + (10 * _pulseCtrl.value),
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: _kGreen.withOpacity(0.18 * (1 - _pulseCtrl.value)),
                                ),
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.all(6),
                              decoration: BoxDecoration(
                                color: _kGreen, shape: BoxShape.circle,
                                boxShadow: [BoxShadow(color: _kGreen.withOpacity(0.45), blurRadius: 7)],
                              ),
                              child: const Icon(Icons.directions_bus_rounded, color: Colors.white, size: 15),
                            ),
                          ]),
                        ),
                      ]),
                    ],
                  ),
                  Positioned(bottom: 12, right: 12,
                    child: GestureDetector(
                      onTap: () => _animatedMapMove(LatLng(data.latitude, data.longitude), 16.0),
                      child: Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 8, offset: const Offset(0, 2))],
                        ),
                        child: const Icon(Icons.my_location_rounded, color: _kGreen, size: 18),
                      ),
                    )),
                ]),
              ),
            ),
        ]),
      ),
      // ── Location name label below map ──────────────────────────────────
      if (_locationName.isNotEmpty && _showMap)
        Padding(
          padding: const EdgeInsets.only(top: 6),
          child: Row(children: [
            const Icon(Icons.location_on_rounded, color: _kPrimary, size: 14),
            const SizedBox(width: 5),
            Expanded(
              child: Text(_locationName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 12, color: _kTextSecondary,
                      fontWeight: FontWeight.w600)),
            ),
          ]),
        ),
    ]);
  }

  Widget _buildAlertCard(Map<String, dynamic> alert) {
    final type    = alert['type'] as String? ?? 'unknown';
    final message = alert['message'] as String? ?? 'Alert';
    final name    = alert['passengerName'] as String? ?? 'Passenger';
    final ts      = alert['timestamp'] as int? ?? 0;
    final id      = alert['id'] as String? ?? '';
    final color   = _alertColor(type);

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: _kSurface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.3)),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 8)],
      ),
      child: Row(children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(10)),
          child: Icon(_alertIcon(type), color: color, size: 16),
        ),
        const SizedBox(width: 10),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(4)),
              child: Text(_alertLabel(type),
                  style: TextStyle(color: color, fontSize: 9, fontWeight: FontWeight.w900, letterSpacing: 1.2)),
            ),
            const SizedBox(width: 6),
            Text(_timeAgo(ts), style: const TextStyle(color: _kTextSecondary, fontSize: 10)),
          ]),
          const SizedBox(height: 3),
          Text(message, style: const TextStyle(color: _kTextPrimary, fontWeight: FontWeight.w600, fontSize: 13)),
          Text('— $name', style: const TextStyle(color: _kTextSecondary, fontSize: 11)),
        ])),
        IconButton(
          icon: const Icon(Icons.check_rounded, color: _kGreen, size: 20),
          onPressed: () => _service.dismissAlert(widget.jeepId, id),
          splashRadius: 18,
        ),
      ]),
    ).animate(key: ValueKey(id))
        .slideX(begin: 0.12, end: 0, duration: 320.ms, curve: Curves.easeOutCubic)
        .fadeIn();
  }

  Widget _sectionLabel(String label, IconData icon) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      Icon(icon, color: _kPrimary, size: 13),
      const SizedBox(width: 6),
      Text(label, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w800,
          color: _kPrimary, letterSpacing: 2.0)),
    ],
  );
}

// ─────────────────────────────────────────────────────────────────────────────
// TAB 2 — AUDIT LOGS (Boarding Events)
// ─────────────────────────────────────────────────────────────────────────────
class _OperatorAuditTab extends StatefulWidget {
  final String jeepId;
  const _OperatorAuditTab({required this.jeepId});
  @override
  State<_OperatorAuditTab> createState() => _OperatorAuditTabState();
}

class _OperatorAuditTabState extends State<_OperatorAuditTab> {
  final JeepneyService _service = JeepneyService();
  List<Map<String, dynamic>> _boardingLogs = [];
  List<Map<String, dynamic>> _systemAlerts = [];
  bool _loadingBoarding = true;
  bool _loadingAlerts = true;

  late StreamSubscription _boardingSub;
  late StreamSubscription _alertSub;

  int _viewIndex = 0; // 0 = Boarding, 1 = System Alerts
  String _boardingFilter = 'all'; // all | boarded | alighted

  @override
  void initState() {
    super.initState();
    _boardingSub = _service.streamBoardingLogs(widget.jeepId).listen((logs) {
      if (mounted) setState(() { _boardingLogs = logs; _loadingBoarding = false; });
    });
    _alertSub = _service.streamSystemAlerts(widget.jeepId).listen((alerts) {
      if (mounted) setState(() { _systemAlerts = alerts; _loadingAlerts = false; });
    });
  }

  @override
  void dispose() {
    _boardingSub.cancel();
    _alertSub.cancel();
    super.dispose();
  }

  List<Map<String, dynamic>> get _filteredBoarding {
    if (_boardingFilter == 'all') return _boardingLogs;
    if (_boardingFilter == 'boarded') return _boardingLogs.where((l) => (l['delta'] as int? ?? 0) > 0).toList();
    return _boardingLogs.where((l) => (l['delta'] as int? ?? 0) < 0).toList();
  }

  String _formatFull(int ts) {
    final d = DateTime.fromMillisecondsSinceEpoch(ts);
    final months = ['Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec'];
    final h = d.hour.toString().padLeft(2, '0');
    final m = d.minute.toString().padLeft(2, '0');
    final s = d.second.toString().padLeft(2, '0');
    return '${months[d.month - 1]} ${d.day}  ·  $h:$m:$s';
  }

  @override
  Widget build(BuildContext context) {
    return Column(children: [
      // ── View Toggle ────────────────────────────────────────────────────────
      Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
        child: Container(
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: Colors.black.withOpacity(0.04),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Row(
            children: [
              Expanded(child: _buildTabView(0, 'Boarding Logs', Icons.people_rounded)),
              Expanded(child: _buildTabView(1, 'System Alerts', Icons.warning_rounded)),
            ],
          ),
        ),
      ),

      // ── Header & Filters (Boarding Only) ──────────────────────────────
      if (_viewIndex == 0) ...[
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
          child: Row(children: [
            _filterChip('all', 'All'),
            _filterChip('boarded', 'Boarded'),
            _filterChip('alighted', 'Alighted'),
          ]),
        ),
      ],
      if (_viewIndex == 1) const SizedBox(height: 12),

      // ── List ───────────────────────────────────────────────────────────
      Expanded(
        child: _viewIndex == 0 ? _buildBoardingView() : _buildAlertsView(),
      ),
    ]);
  }

  Widget _buildTabView(int index, String label, IconData icon) {
    final isActive = _viewIndex == index;
    return GestureDetector(
      onTap: () => setState(() => _viewIndex = index),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: isActive ? Colors.white : Colors.transparent,
          borderRadius: BorderRadius.circular(16),
          boxShadow: isActive ? [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 4)] : [],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 14, color: isActive ? _kPrimary : Colors.grey[500]),
            const SizedBox(width: 6),
            Text(label, style: TextStyle(
              fontSize: 12,
              fontWeight: isActive ? FontWeight.w800 : FontWeight.w600,
              color: isActive ? _kPrimary : Colors.grey[500],
            )),
          ],
        ),
      ),
    );
  }

  Widget _filterChip(String value, String label) {
    final isActive = _boardingFilter == value;
    return GestureDetector(
      onTap: () => setState(() => _boardingFilter = value),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        margin: const EdgeInsets.only(right: 8),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
        decoration: BoxDecoration(
          color: isActive ? _kPrimary : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: isActive ? _kPrimary : _kBorder, width: 1.5),
          boxShadow: isActive ? [BoxShadow(color: _kPrimary.withOpacity(0.2), blurRadius: 8, offset: const Offset(0, 3))] : [],
        ),
        child: Text(label, style: TextStyle(
          fontSize: 12, fontWeight: FontWeight.w700,
          color: isActive ? Colors.white : _kTextSecondary, letterSpacing: 0.2,
        )),
      ),
    );
  }

  Widget _buildBoardingView() {
    if (_loadingBoarding) return const Center(child: CircularProgressIndicator(color: _kPrimary, strokeWidth: 2));
    final filtered = _filteredBoarding;
    if (filtered.isEmpty) return _buildEmpty('No boarding events yet', Icons.transfer_within_a_station_rounded);
    
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 90),
      itemCount: filtered.length,
      itemBuilder: (_, i) => _buildBoardingCard(filtered[i], i),
    );
  }

  Widget _buildAlertsView() {
    if (_loadingAlerts) return const Center(child: CircularProgressIndicator(color: _kPrimary, strokeWidth: 2));
    if (_systemAlerts.isEmpty) return _buildEmpty('No system alerts', Icons.check_circle_outline_rounded);

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 90),
      itemCount: _systemAlerts.length,
      itemBuilder: (_, i) => _buildSystemAlertCard(_systemAlerts[i], i),
    );
  }

  Widget _buildBoardingCard(Map<String, dynamic> log, int index) {
    final delta    = log['delta'] as int? ?? 0;
    final count    = log['passenger_count'] as int? ?? 0;
    final ts       = log['timestamp'] as int? ?? 0;
    final location = log['location_name'] as String? ?? 'Unknown';
    final lat      = (log['latitude'] as num?)?.toDouble() ?? 0;
    final lng      = (log['longitude'] as num?)?.toDouble() ?? 0;

    final isBoard  = delta > 0;
    final color    = isBoard ? _kGreen : const Color(0xFFF59E0B);
    final icon     = isBoard ? Icons.login_rounded : Icons.logout_rounded;
    final label    = isBoard ? '+$delta boarded' : '${delta.abs()} alighted';
    final tag      = isBoard ? 'BOARD' : 'ALIGHT';

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.black.withOpacity(0.03)),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 20, offset: const Offset(0, 8))],
      ),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [color.withOpacity(0.15), color.withOpacity(0.05)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Icon(icon, color: color, size: 20),
        ),
        const SizedBox(width: 14),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Text(label, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: _kTextPrimary)),
            const Spacer(),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
              child: Text(tag, style: TextStyle(fontSize: 9, fontWeight: FontWeight.w900, color: color, letterSpacing: 1.0)),
            ),
          ]),
          const SizedBox(height: 6),
          Text('$count passengers on board', style: TextStyle(fontSize: 12, color: Colors.grey[500], fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          Row(children: [
            Icon(Icons.location_on_rounded, size: 14, color: color.withOpacity(0.8)),
            const SizedBox(width: 6),
            Expanded(child: Text(location, maxLines: 1, overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 12, color: _kTextSecondary, fontWeight: FontWeight.w600))),
          ]),
          const SizedBox(height: 6),
          Row(children: [
            const Icon(Icons.access_time_rounded, size: 12, color: _kTextSecondary),
            const SizedBox(width: 4),
            Text(_formatFull(ts), style: const TextStyle(fontSize: 11, color: _kTextSecondary)),
            const Spacer(),
            Text('${lat.toStringAsFixed(4)}, ${lng.toStringAsFixed(4)}',
                style: TextStyle(fontSize: 10, color: Colors.grey[400], fontFamily: 'monospace')),
          ]),
        ])),
      ]),
    ).animate(delay: (index.clamp(0, 15) * 30).ms)
        .fadeIn(duration: 350.ms, curve: Curves.easeOutCubic)
        .slideY(begin: 0.04, duration: 350.ms, curve: Curves.easeOutCubic);
  }

  Widget _buildSystemAlertCard(Map<String, dynamic> alert, int index) {
    final type     = alert['type'] as String? ?? 'unknown';
    final message  = alert['message'] as String? ?? 'Alert';
    final ts       = alert['timestamp'] as int? ?? 0;
    final location = alert['location_name'] as String? ?? 'Unknown';

    final isOverload = type == 'weight_overload';
    final color      = isOverload ? _kRed : const Color(0xFFF59E0B);
    final icon       = isOverload ? Icons.scale_rounded : Icons.event_seat_rounded;
    final label      = isOverload ? 'Weight Exceeded' : 'Seats Full';
    final tag        = isOverload ? 'OVERLOAD' : 'FULL';

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.black.withOpacity(0.03)),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 20, offset: const Offset(0, 8))],
      ),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [color.withOpacity(0.18), color.withOpacity(0.05)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Icon(icon, color: color, size: 20),
        ),
        const SizedBox(width: 14),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Text(label, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: _kTextPrimary)),
            const Spacer(),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
              child: Text(tag, style: TextStyle(fontSize: 9, fontWeight: FontWeight.w900, color: color, letterSpacing: 1.0)),
            ),
          ]),
          const SizedBox(height: 6),
          Text(message, style: const TextStyle(fontSize: 12, color: _kTextPrimary, fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          Row(children: [
            Icon(Icons.location_on_rounded, size: 14, color: color.withOpacity(0.8)),
            const SizedBox(width: 6),
            Expanded(child: Text(location, maxLines: 1, overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 12, color: _kTextSecondary, fontWeight: FontWeight.w600))),
          ]),
          const SizedBox(height: 6),
          Row(children: [
            const Icon(Icons.access_time_rounded, size: 12, color: _kTextSecondary),
            const SizedBox(width: 4),
            Text(_formatFull(ts), style: const TextStyle(fontSize: 11, color: _kTextSecondary)),
          ]),
        ])),
      ]),
    ).animate(delay: (index.clamp(0, 15) * 30).ms)
        .fadeIn(duration: 350.ms, curve: Curves.easeOutCubic)
        .slideY(begin: 0.04, duration: 350.ms, curve: Curves.easeOutCubic);
  }

  Widget _buildEmpty(String title, IconData icon) {
    return Center(
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        Container(
          padding: const EdgeInsets.all(22),
          decoration: BoxDecoration(
            color: Colors.grey.withOpacity(0.08),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: Colors.grey[400], size: 38),
        ),
        const SizedBox(height: 16),
        Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: _kTextPrimary)),
      ]),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// TAB 0 — SETTINGS
// ─────────────────────────────────────────────────────────────────────────────
class _OperatorSettingsTab extends StatefulWidget {
  final UserProfile? userProfile;
  final bool isLoading;
  final String jeepId;
  const _OperatorSettingsTab({this.userProfile, required this.isLoading, required this.jeepId});
  @override
  State<_OperatorSettingsTab> createState() => _OperatorSettingsTabState();
}

class _OperatorSettingsTabState extends State<_OperatorSettingsTab> {
  bool _soundAlerts   = true;
  bool _autoRecenter  = true;
  bool _showEta       = false;
  bool _overloadBanner = true;
  bool _isSigningOut  = false;

  @override
  Widget build(BuildContext context) {
    final profile = widget.userProfile;
    final email = FirebaseAuth.instance.currentUser?.email ?? '';

    return Stack(children: [
      SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 100),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          // ── Profile header ───────────────────────────────────────────
          widget.isLoading
              ? const Center(child: CircularProgressIndicator(color: _kPrimary))
              : Row(children: [
                  Container(
                    width: 68, height: 68,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: const Color(0xFFEFF7EA),
                      border: Border.all(color: _kPrimary, width: 2),
                    ),
                    child: ClipOval(child: profile?.profilePictureUrl != null
                        ? Image.network(profile!.profilePictureUrl!, fit: BoxFit.cover)
                        : const Icon(Icons.person_rounded, color: _kPrimary, size: 34)),
                  ),
                  const SizedBox(width: 16),
                  Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(profile?.name ?? 'Operator',
                        style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900,
                            color: _kTextPrimary, letterSpacing: -0.4)),
                    const SizedBox(height: 3),
                    Text(email, style: TextStyle(fontSize: 13, color: Colors.grey[500], fontWeight: FontWeight.w500)),
                    const SizedBox(height: 6),
                    Row(children: [
                      _chip('Operator', _kPrimary),
                      const SizedBox(width: 6),
                      _chip(widget.jeepId.toUpperCase().replaceAll('_', '-'), _kGreen),
                    ]),
                  ])),
                ]).animate().fadeIn(duration: 500.ms).slideX(begin: -0.08, curve: Curves.easeOutCubic),
          const SizedBox(height: 28),

          // ── Alerts & Display ────────────────────────────────────────
          _sectionHeader('Alerts & Display'),
          const SizedBox(height: 10),
          _settingsCard([
            _toggleTile(
              icon: Icons.volume_up_rounded,
              title: 'Sound Alerts',
              subtitle: 'Play audio on passenger signals',
              value: _soundAlerts,
              onChanged: (v) => setState(() => _soundAlerts = v),
            ),
            _divider(),
            _toggleTile(
              icon: Icons.warning_amber_rounded,
              title: 'Overload Banner',
              subtitle: 'Show warning when weight exceeded',
              value: _overloadBanner,
              onChanged: (v) => setState(() => _overloadBanner = v),
            ),
          ]).animate(delay: 150.ms).fadeIn(duration: 420.ms).slideY(begin: 0.08, curve: Curves.easeOutCubic),
          const SizedBox(height: 20),

          // ── Navigation ──────────────────────────────────────────────
          _sectionHeader('Navigation'),
          const SizedBox(height: 10),
          _settingsCard([
            _toggleTile(
              icon: Icons.my_location_rounded,
              title: 'Auto-Recenter Map',
              subtitle: 'Keep map centered on vehicle',
              value: _autoRecenter,
              onChanged: (v) => setState(() => _autoRecenter = v),
            ),
            _divider(),
            _toggleTile(
              icon: Icons.timer_outlined,
              title: 'Show ETA Overlay',
              subtitle: 'Display time estimate on map',
              value: _showEta,
              onChanged: (v) => setState(() => _showEta = v),
            ),
          ]).animate(delay: 250.ms).fadeIn(duration: 420.ms).slideY(begin: 0.08, curve: Curves.easeOutCubic),
          const SizedBox(height: 20),

          // ── General ─────────────────────────────────────────────────
          _sectionHeader('General'),
          const SizedBox(height: 10),
          _settingsCard([
            _actionTile(
              icon: Icons.info_outline_rounded,
              title: 'App Version',
              trailing: 'v1.0.0',
            ),
            _divider(),
            _actionTile(
              icon: Icons.logout_rounded,
              title: 'End Shift & Sign Out',
              iconColor: _kRed,
              titleColor: _kRed,
              onTap: () => _confirmLogout(context),
            ),
          ]).animate(delay: 350.ms).fadeIn(duration: 420.ms).slideY(begin: 0.08, curve: Curves.easeOutCubic),
        ]),
      ),

      // Loading overlay for sign-out
      if (_isSigningOut)
        Container(
          color: Colors.black.withOpacity(0.35),
          child: Center(child: Container(
            padding: const EdgeInsets.all(28),
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(24)),
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              const CircularProgressIndicator(color: _kPrimary),
              const SizedBox(height: 16),
              const Text('Ending shift…', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
            ]),
          )),
        ),
    ]);
  }

  Widget _chip(String label, Color color) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
    decoration: BoxDecoration(
      color: color.withOpacity(0.1),
      borderRadius: BorderRadius.circular(8),
    ),
    child: Text(label,
        style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: color)),
  );

  Widget _sectionHeader(String label) => Padding(
    padding: const EdgeInsets.only(left: 4),
    child: Text(label.toUpperCase(),
        style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800,
            color: Colors.grey[400], letterSpacing: 1.3)),
  );

  Widget _settingsCard(List<Widget> children) => Container(
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(22),
      border: Border.all(color: Colors.black.withOpacity(0.04), width: 1.5),
      boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.025), blurRadius: 14, offset: const Offset(0, 6))],
    ),
    child: Column(children: children),
  );

  Widget _toggleTile({required IconData icon, required String title,
      String? subtitle, required bool value, required ValueChanged<bool> onChanged}) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
      child: Row(children: [
        Container(
          padding: const EdgeInsets.all(9),
          decoration: BoxDecoration(
            color: const Color(0xFFF3FBF5), borderRadius: BorderRadius.circular(11)),
          child: Icon(icon, color: _kPrimary, size: 19),
        ),
        const SizedBox(width: 14),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(title, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15, color: _kTextPrimary)),
          if (subtitle != null) ...[
            const SizedBox(height: 1),
            Text(subtitle, style: TextStyle(fontSize: 12, color: Colors.grey[400])),
          ],
        ])),
        Switch.adaptive(value: value, onChanged: onChanged, activeColor: _kPrimary),
      ]),
    );
  }

  Widget _actionTile({required IconData icon, required String title,
      Color? iconColor, Color? titleColor, String? trailing, VoidCallback? onTap}) {
    final ic = iconColor ?? _kPrimary;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(22),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
        child: Row(children: [
          Container(
            padding: const EdgeInsets.all(9),
            decoration: BoxDecoration(
              color: ic.withOpacity(0.1), borderRadius: BorderRadius.circular(11)),
            child: Icon(icon, color: ic, size: 19),
          ),
          const SizedBox(width: 14),
          Expanded(child: Text(title,
              style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15,
                  color: titleColor ?? _kTextPrimary))),
          if (trailing != null)
            Text(trailing, style: TextStyle(color: Colors.grey[400], fontSize: 13, fontWeight: FontWeight.w600))
          else
            const Icon(Icons.chevron_right_rounded, color: Colors.grey, size: 22),
        ]),
      ),
    );
  }

  Widget _divider() => Divider(height: 1, thickness: 1, indent: 62, endIndent: 18,
      color: Colors.black.withOpacity(0.05));

  void _confirmLogout(BuildContext context) {
    showDialog(
      context: context,
      builder: (dCtx) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
        backgroundColor: Colors.white,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 32, 24, 24),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(color: _kRed.withOpacity(0.08), shape: BoxShape.circle),
              child: const Icon(Icons.logout_rounded, color: _kRed, size: 34),
            ),
            const SizedBox(height: 20),
            const Text('End Shift',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900,
                    color: _kTextPrimary, letterSpacing: -0.4)),
            const SizedBox(height: 10),
            Text('Sign out and end your active shift?',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 14, color: Colors.grey[500], height: 1.4)),
            const SizedBox(height: 28),
            Row(children: [
              Expanded(child: TextButton(
                onPressed: () => Navigator.pop(dCtx),
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
                child: Text('Cancel', style: TextStyle(color: Colors.grey[600], fontWeight: FontWeight.bold, fontSize: 15)),
              )),
              const SizedBox(width: 10),
              Expanded(child: ElevatedButton(
                onPressed: () async {
                  Navigator.pop(dCtx);
                  if (mounted) setState(() => _isSigningOut = true);
                  try {
                    await AuthService().signOut().timeout(const Duration(seconds: 6));
                  } catch (_) {}
                  if (!mounted) return;
                  setState(() => _isSigningOut = false);
                  if (context.mounted) {
                    Navigator.of(context).pushAndRemoveUntil(
                      MaterialPageRoute(builder: (_) => const LoginScreen()),
                      (_) => false,
                    );
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: _kRed,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
                child: const Text('Sign Out', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
              )),
            ]),
          ]),
        ),
      ),
    );
  }
}

// ── Arc Gauge Painter ─────────────────────────────────────────────────────────
class _ArcGaugePainter extends CustomPainter {
  final double percent;
  final Color color;
  _ArcGaugePainter({required this.percent, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final c = Offset(size.width / 2, size.height * 0.9);
    final r = size.width * 0.44;
    const start = pi;
    const total = pi;
    const stroke = 9.0;
    canvas.drawArc(Rect.fromCircle(center: c, radius: r), start, total, false,
        Paint()..color = const Color(0xFFD0F0D8)..style = PaintingStyle.stroke
            ..strokeWidth = stroke..strokeCap = StrokeCap.round);
    if (percent > 0) {
      canvas.drawArc(Rect.fromCircle(center: c, radius: r), start, total * percent, false,
          Paint()..color = color..style = PaintingStyle.stroke
              ..strokeWidth = stroke..strokeCap = StrokeCap.round);
    }
  }

  @override
  bool shouldRepaint(_ArcGaugePainter old) => old.percent != percent || old.color != color;
}

// ── ANALYTICS TAB ─────────────────────────────────────────────────────────────
class _OperatorAnalyticsTab extends StatefulWidget {
  final String jeepId;
  const _OperatorAnalyticsTab({Key? key, required this.jeepId}) : super(key: key);

  @override
  State<_OperatorAnalyticsTab> createState() => _OperatorAnalyticsTabState();
}

class _OperatorAnalyticsTabState extends State<_OperatorAnalyticsTab> {
  final JeepneyService _service = JeepneyService();
  bool _isLoading = true;

  List<Map<String, dynamic>> _alerts = [];
  List<Map<String, dynamic>> _boardingLogs = [];
  Map<int, int> _hourlyBoarding = {};
  List<MapEntry<String, int>> _topLocations = [];

  final MapController _mapController = MapController();

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final logs = await _service.fetchHistoricalBoardingLogs(widget.jeepId);
    final alerts = await _service.fetchHistoricalAlerts(widget.jeepId);

    Map<int, int> hourly = {};
    for (int i = 0; i < 24; i++) hourly[i] = 0;
    Map<String, int> locCounts = {};

    for (var log in logs) {
      final delta = log['delta'] as int? ?? 0;
      if (delta > 0) {
        final d = DateTime.fromMillisecondsSinceEpoch(log['timestamp'] as int? ?? 0);
        hourly[d.hour] = (hourly[d.hour] ?? 0) + delta;

        final loc = log['location_name'] as String? ?? 'Unknown';
        if (loc != 'Unknown') {
          locCounts[loc] = (locCounts[loc] ?? 0) + delta;
        }
      }
    }

    var sortedLocs = locCounts.entries.toList()..sort((a, b) => b.value.compareTo(a.value));

    if (mounted) {
      setState(() {
        _alerts = alerts;
        _boardingLogs = logs;
        _hourlyBoarding = hourly;
        _topLocations = sortedLocs.take(4).toList();
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator(color: _kPrimary, strokeWidth: 2));
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 90),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header
          const Padding(
            padding: EdgeInsets.only(left: 8, bottom: 16),
            child: Text('Data & Trends', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: _kTextPrimary)),
          ),

          // Peak Hours Chart
          _buildChartCard(),
          const SizedBox(height: 16),

          // Top Routes
          _buildTopRoutesCard(),
          const SizedBox(height: 16),

          // Hotspot Map
          _buildHotspotMapCard(),
        ],
      ).animate().fadeIn(duration: 400.ms, curve: Curves.easeOutCubic).slideY(begin: 0.04),
    );
  }

  Widget _buildChartCard() {
    double maxY = _hourlyBoarding.values.isEmpty ? 10.0 : _hourlyBoarding.values.reduce(max).toDouble();
    if (maxY < 5) maxY = 5;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.black.withOpacity(0.03)),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 20, offset: const Offset(0, 8))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                gradient: LinearGradient(colors: [_kGreen.withOpacity(0.15), _kGreen.withOpacity(0.05)]),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.bar_chart_rounded, color: _kGreen, size: 20),
            ),
            const SizedBox(width: 12),
            const Text('Peak Boarding Hours', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: _kTextPrimary)),
          ]),
          const SizedBox(height: 24),
          SizedBox(
            height: 160,
            child: BarChart(
              BarChartData(
                alignment: BarChartAlignment.spaceAround,
                maxY: maxY * 1.2,
                barTouchData: BarTouchData(enabled: false),
                titlesData: FlTitlesData(
                  show: true,
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (value, meta) {
                        if (value % 4 != 0) return const SizedBox.shrink();
                        return Padding(
                          padding: const EdgeInsets.only(top: 8.0),
                          child: Text('${value.toInt()}:00', style: const TextStyle(color: _kTextSecondary, fontSize: 10, fontWeight: FontWeight.bold)),
                        );
                      },
                      reservedSize: 28,
                    ),
                  ),
                  leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                ),
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  horizontalInterval: maxY / 2,
                  getDrawingHorizontalLine: (value) => FlLine(color: _kBorder, strokeWidth: 1, dashArray: [5, 5]),
                ),
                borderData: FlBorderData(show: false),
                barGroups: _hourlyBoarding.entries.map((e) {
                  return BarChartGroupData(
                    x: e.key,
                    barRods: [
                      BarChartRodData(
                        toY: e.value.toDouble(),
                        color: _kGreen,
                        width: 8,
                        borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
                        backDrawRodData: BackgroundBarChartRodData(
                          show: true,
                          toY: maxY * 1.2,
                          color: _kBorder.withOpacity(0.5),
                        ),
                      )
                    ],
                  );
                }).toList(),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTopRoutesCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.black.withOpacity(0.03)),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 20, offset: const Offset(0, 8))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                gradient: LinearGradient(colors: [_kPrimary.withOpacity(0.15), _kPrimary.withOpacity(0.05)]),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.route_rounded, color: _kPrimary, size: 20),
            ),
            const SizedBox(width: 12),
            const Text('Highest Traffic Zones', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: _kTextPrimary)),
          ]),
          const SizedBox(height: 16),
          if (_topLocations.isEmpty)
            const Padding(padding: EdgeInsets.all(16), child: Center(child: Text('Not enough data yet.', style: TextStyle(color: _kTextSecondary, fontSize: 12))))
          else
            ..._topLocations.asMap().entries.map((entry) {
              final i = entry.key;
              final mapEntry = entry.value;
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Row(
                  children: [
                    Text('#${i + 1}', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w900, color: _kTextSecondary)),
                    const SizedBox(width: 12),
                    Expanded(child: Text(mapEntry.key, maxLines: 1, overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: _kTextPrimary))),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(color: _kPrimary.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
                      child: Text('${mapEntry.value} pax', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: _kPrimary)),
                    )
                  ],
                ),
              );
            }).toList()
        ],
      ),
    );
  }

  Widget _buildHotspotMapCard() {
    double? initialLat;
    double? initialLng;

    if (_boardingLogs.isNotEmpty) {
      initialLat = (_boardingLogs.first['latitude'] as num?)?.toDouble();
      initialLng = (_boardingLogs.first['longitude'] as num?)?.toDouble();
    }

    List<Marker> buildMapMarkers(bool showStats) {
      return _boardingLogs.where((log) => (log['delta'] as num? ?? 0) != 0).map((log) {
        final lat = (log['latitude'] as num?)?.toDouble() ?? 0;
        final lng = (log['longitude'] as num?)?.toDouble() ?? 0;
        final delta = log['delta'] as num? ?? 0;
        final isBoarding = delta > 0;
        final color = isBoarding ? Colors.green : Colors.amber;
        final size = isBoarding ? 55.0 : 45.0; // Noticeably larger
        return Marker(
          point: LatLng(lat, lng),
          width: size, height: size,
          child: Container(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: color.withOpacity(0.4), // Transparent core
              border: Border.all(color: color.withOpacity(1.0), width: 3.5), // Thick visible border
              boxShadow: [
                BoxShadow(
                  color: color.withOpacity(0.7),
                  blurRadius: 18,
                  spreadRadius: 4,
                )
              ]
            ),
            child: Center(
              child: showStats
                  ? Text('${isBoarding ? '+' : ''}$delta', 
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 16, 
                          shadows: [Shadow(color: Colors.black87, blurRadius: 6)]))
                  : Container(
                      width: 10, height: 10,
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.9),
                        shape: BoxShape.circle,
                        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.3), blurRadius: 4)]
                      ),
                    ),
            ),
          ),
        );
      }).toList();
    }

    final normalMarkers = buildMapMarkers(false);
    final fullscreenMarkers = buildMapMarkers(true);

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.black.withOpacity(0.03)),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 20, offset: const Offset(0, 8))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  gradient: LinearGradient(colors: [_kGreen.withOpacity(0.15), _kGreen.withOpacity(0.05)]),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.compare_arrows_rounded, color: _kGreen, size: 20),
              ),
              const SizedBox(width: 12),
              const Text('Passenger Flow Map', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: _kTextPrimary)),
              const Spacer(),
              IconButton(
                icon: const Icon(Icons.fullscreen_rounded, color: _kTextSecondary),
                onPressed: () {
                  if (initialLat == null || initialLng == null) return;
                  showDialog(
                    context: context,
                    builder: (ctx) => Dialog.fullscreen(
                      child: Stack(
                        children: [
                          FlutterMap(
                            options: MapOptions(
                              initialCenter: LatLng(initialLat!, initialLng!),
                              initialZoom: 14.5,
                              interactionOptions: const InteractionOptions(flags: InteractiveFlag.all),
                            ),
                            children: [
                              TileLayer(urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png'),
                              MarkerLayer(markers: fullscreenMarkers),
                            ],
                          ),
                          Positioned(
                            top: 40, right: 16,
                            child: FloatingActionButton.small(
                              backgroundColor: Colors.white,
                              child: const Icon(Icons.close_rounded, color: Colors.black),
                              onPressed: () => Navigator.pop(ctx),
                            ),
                          ),
                          Positioned(
                            top: 40, left: 16,
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(20),
                                boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 10)],
                              ),
                              child: const Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.circle, color: Colors.green, size: 12),
                                  SizedBox(width: 4), Text('Boarding', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                                  SizedBox(width: 12),
                                  Icon(Icons.circle, color: Colors.amber, size: 12),
                                  SizedBox(width: 4), Text('Alighting', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ]),
          ),
          if (initialLat == null || initialLng == null)
            const Padding(padding: EdgeInsets.all(24), child: Center(child: Text('No boarding data recorded.', style: TextStyle(color: _kTextSecondary, fontSize: 12))))
          else
            ClipRRect(
              borderRadius: const BorderRadius.vertical(bottom: Radius.circular(23)),
              child: SizedBox(
                height: 200,
                child: IgnorePointer( // Map only interactive when expanded via fullscreen button
                  child: FlutterMap(
                    mapController: _mapController,
                    options: MapOptions(
                      initialCenter: LatLng(initialLat, initialLng),
                      initialZoom: 14.0,
                    ),
                    children: [
                      TileLayer(urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png'),
                      MarkerLayer(markers: normalMarkers),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

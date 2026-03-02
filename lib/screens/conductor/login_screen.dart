import 'package:flutter/material.dart';
import '../../services/jeepney_service.dart';
import '../dashboard_screen.dart';

class ConductorLoginScreen extends StatefulWidget {
  const ConductorLoginScreen({super.key});

  @override
  State<ConductorLoginScreen> createState() => _ConductorLoginScreenState();
}

class _ConductorLoginScreenState extends State<ConductorLoginScreen> {
  final TextEditingController _idController = TextEditingController();
  final JeepneyService _service = JeepneyService();
  bool _isLoading = false;
  String? _errorText;

  // For simulation, let's suggest "jeep_001"
  @override
  void initState() {
    super.initState();
    _idController.text = ""; // Start empty
  }

  Future<void> _handleLogin() async {
    final id = _idController.text.trim();
    if (id.isEmpty) {
      setState(() => _errorText = "Please enter an ID");
      return;
    }

    setState(() {
      _isLoading = true;
      _errorText = null;
    });

    try {
      // Check if jeep exists in Firebase
      final exists = await _service.checkJeepExists(id);

      if (!mounted) return;

      if (exists) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => DashboardScreen(jeepId: id)),
        );
      } else {
        setState(() => _errorText = "Jeep ID not found in database.");
      }
    } catch (e) {
      setState(() => _errorText = "Connection Error: $e");
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text(
          "Conductor Login",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Icon(
              Icons.directions_bus_filled,
              size: 64,
              color: Color(0xFF0056D2),
            ),
            const SizedBox(height: 24),
            const Text(
              "Track Ejeeps for safer travel",
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1A1A1A),
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              "Enter your vehicle ID to start monitoring",
              style: TextStyle(fontSize: 14, color: Colors.grey[600]),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            TextField(
              controller: _idController,
              decoration: InputDecoration(
                labelText: "Type ejeep id...",
                hintText: "e.g. jeep_001",
                errorText: _errorText,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                filled: true,
                fillColor: Colors.grey[50],
                prefixIcon: const Icon(Icons.search),
              ),
              onSubmitted: (_) => _handleLogin(),
            ),
            const SizedBox(height: 24),
            SizedBox(
              height: 50,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _handleLogin,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF0056D2),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 2,
                ),
                child: _isLoading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            Colors.white,
                          ),
                        ),
                      )
                    : const Text(
                        "View your Ejeep Details",
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

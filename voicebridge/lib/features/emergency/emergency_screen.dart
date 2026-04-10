import 'dart:async';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:geolocator/geolocator.dart';
import '../../services/firestore_service.dart';

// ────────────────────────────── constants ──────────────────────────────

const _kEmergencyRed = Color(0xFF930009);
const _kWhite = Colors.white;

// ─────────────────────────── data model ───────────────────────────────

class EmergencyType {
  final String label;
  final IconData icon;
  final String semanticLabel;

  const EmergencyType({
    required this.label,
    required this.icon,
    required this.semanticLabel,
  });
}

const _kEmergencyTypes = [
  EmergencyType(
    label: 'Medical',
    icon: Icons.medical_services,
    semanticLabel: 'Medical emergency',
  ),
  EmergencyType(
    label: 'Fire',
    icon: Icons.local_fire_department,
    semanticLabel: 'Fire emergency',
  ),
  EmergencyType(
    label: 'Danger',
    icon: Icons.warning_rounded,
    semanticLabel: 'Danger emergency',
  ),
];

// ─────────────────────── EmergencyScreen ──────────────────────────────

class EmergencyScreen extends StatefulWidget {
  const EmergencyScreen({super.key});

  @override
  State<EmergencyScreen> createState() => _EmergencyScreenState();
}

class _EmergencyScreenState extends State<EmergencyScreen>
    with TickerProviderStateMixin {
  int _selectedIndex = 0; // Medical pre-selected for speed
  bool _showCountdown = false;
  int _countdown = 3;
  Timer? _countdownTimer;

  // Pulse animation for the big SOS button
  late AnimationController _pulseCtrl;
  late Animation<double> _pulseAnim;

  String _userName = 'Guest User';
  String _userAddress = 'Fetching location...';

  @override
  void initState() {
    super.initState();
    _loadProfileAndLocation();
    _pulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);
    _pulseAnim = Tween<double>(
      begin: 1.0,
      end: 1.08,
    ).animate(CurvedAnimation(parent: _pulseCtrl, curve: Curves.easeInOut));
  }

  Future<void> _loadProfileAndLocation() async {
    try {
      final profile = await FirestoreService.instance.getProfile();
      if (profile != null && mounted) {
        setState(() {
          _userName = profile.fullName.isNotEmpty
              ? profile.fullName
              : _userName;
          _userAddress = profile.homeAddress.isNotEmpty
              ? profile.homeAddress
              : 'Unknown Location';
        });
      }

      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (serviceEnabled) {
        LocationPermission permission = await Geolocator.checkPermission();
        if (permission == LocationPermission.denied) {
          permission = await Geolocator.requestPermission();
        }
        if (permission == LocationPermission.whileInUse ||
            permission == LocationPermission.always) {
          Position position = await Geolocator.getCurrentPosition(
            locationSettings: const LocationSettings(
              timeLimit: Duration(seconds: 4),
            ),
          );
          if (mounted) {
            setState(() {
              _userAddress =
                  'Lat: ${position.latitude.toStringAsFixed(4)}, Lng: ${position.longitude.toStringAsFixed(4)}';
            });
          }
        }
      }
    } catch (e) {
      debugPrint('Error loading profile or location: $e');
    }
  }

  @override
  void dispose() {
    _pulseCtrl.dispose();
    _countdownTimer?.cancel();
    super.dispose();
  }

  // ── countdown logic ──

  void _startCountdown() {
    setState(() {
      _showCountdown = true;
      _countdown = 3;
    });
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) return;
      setState(() => _countdown--);
      if (_countdown <= 0) {
        timer.cancel();
        _launchEmergencyCall();
      }
    });
  }

  void _cancelCountdown() {
    _countdownTimer?.cancel();
    setState(() {
      _showCountdown = false;
      _countdown = 3;
    });
  }

  void _launchEmergencyCall() {
    if (!mounted) return;
    setState(() => _showCountdown = false);
    final emergencyType = _kEmergencyTypes[_selectedIndex].label;
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => _EmergencyLiveCallScreen(
          userName: _userName,
          userAddress: _userAddress,
          emergencyType: emergencyType,
        ),
      ),
    );
  }

  // ── build ──

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _kEmergencyRed,
      body: Stack(
        children: [
          // Subtle radial glow decorations
          _buildBackgroundDecorations(),

          // Main content
          SafeArea(
            child: Column(
              children: [
                _buildHeader(context),
                Expanded(child: _buildMainContent()),
                _buildFooterInfo(),
              ],
            ),
          ),

          // Countdown overlay
          if (_showCountdown) _buildCountdownOverlay(),
        ],
      ),
    );
  }

  // ── header ──

  Widget _buildHeader(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      child: Row(
        children: [
          Semantics(
            label: 'Cancel and return to home',
            button: true,
            child: GestureDetector(
              onTap: () => context.go('/'),
              child: Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.close, color: _kWhite, size: 24),
              ),
            ),
          ),
          const Expanded(
            child: Text(
              'VoiceBridge',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: _kWhite,
                fontSize: 24,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          // Spacer to balance close button
          const SizedBox(width: 48),
        ],
      ),
    );
  }

  // ── main content ──

  Widget _buildMainContent() {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        children: [
          const SizedBox(height: 8),

          // Title + instruction
          const Text(
            'Emergency call',
            style: TextStyle(
              color: _kWhite,
              fontSize: 40,
              fontWeight: FontWeight.w800,
              height: 1.1,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 12),
          Text(
            'Select the type of emergency, then press Call.',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.8),
              fontSize: 18,
              height: 1.4,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 40),

          // Emergency type buttons
          Row(
            children: List.generate(_kEmergencyTypes.length, (i) {
              return Expanded(
                child: Padding(
                  padding: EdgeInsets.only(
                    right: i < _kEmergencyTypes.length - 1 ? 12 : 0,
                  ),
                  child: _EmergencyTypeButton(
                    type: _kEmergencyTypes[i],
                    isSelected: _selectedIndex == i,
                    onTap: () => setState(() => _selectedIndex = i),
                  ),
                ),
              );
            }),
          ),
          const SizedBox(height: 48),

          // Pulsing SOS button
          ScaleTransition(
            scale: _pulseAnim,
            child: Stack(
              alignment: Alignment.center,
              children: [
                // Ping ring
                Container(
                  width: 260,
                  height: 260,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white.withValues(alpha: 0.08),
                  ),
                ),
                // SOS button
                Semantics(
                  label: 'Call Emergency Services',
                  button: true,
                  child: GestureDetector(
                    onTap: _startCountdown,
                    child: Container(
                      width: 220,
                      height: 220,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: _kWhite,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.3),
                            blurRadius: 40,
                            spreadRadius: 8,
                          ),
                        ],
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(
                            Icons.emergency,
                            color: _kEmergencyRed,
                            size: 72,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Call Emergency\nServices',
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              color: _kEmergencyRed,
                              fontSize: 16,
                              fontWeight: FontWeight.w800,
                              height: 1.3,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 48),
        ],
      ),
    );
  }

  // ── footer info panel ──

  Widget _buildFooterInfo() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 0, 24, 32),
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(32),
          border: Border.all(
            color: Colors.white.withValues(alpha: 0.2),
            width: 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Icon(Icons.auto_awesome, color: _kWhite, size: 28),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'AI will say: "$_userName at $_userAddress — ${_kEmergencyTypes[_selectedIndex].label} emergency"',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.9),
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 4,
                    children: [
                      _Chip(label: 'Auto Voice-to-Dispatch'),
                      _Chip(label: 'GPS Pin Sent'),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── countdown overlay ──

  Widget _buildCountdownOverlay() {
    return Positioned.fill(
      child: Container(
        color: Colors.black.withValues(alpha: 0.85),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              _countdown > 0 ? '$_countdown' : '...',
              style: const TextStyle(
                color: _kWhite,
                fontSize: 120,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Calling Emergency Services...',
              style: TextStyle(
                color: _kWhite,
                fontSize: 22,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 48),
            Semantics(
              label: 'Cancel emergency call',
              button: true,
              child: TextButton(
                onPressed: _cancelCountdown,
                style: TextButton.styleFrom(
                  backgroundColor: Colors.white.withValues(alpha: 0.15),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 48,
                    vertical: 18,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(32),
                  ),
                ),
                child: const Text(
                  'Cancel',
                  style: TextStyle(
                    color: _kWhite,
                    fontSize: 20,
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

  // ── background decorations ──

  Widget _buildBackgroundDecorations() {
    return Positioned.fill(
      child: IgnorePointer(
        child: Stack(
          children: [
            Positioned(
              top: -100,
              right: -100,
              child: Container(
                width: 400,
                height: 400,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withValues(alpha: 0.04),
                ),
              ),
            ),
            Positioned(
              bottom: -100,
              left: -100,
              child: Container(
                width: 400,
                height: 400,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withValues(alpha: 0.04),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────── Emergency Type Button ─────────────────────────

class _EmergencyTypeButton extends StatelessWidget {
  final EmergencyType type;
  final bool isSelected;
  final VoidCallback onTap;

  const _EmergencyTypeButton({
    required this.type,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: '${type.semanticLabel}${isSelected ? ', selected' : ''}',
      button: true,
      selected: isSelected,
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOut,
          padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 8),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: isSelected ? 0.2 : 0.1),
            borderRadius: BorderRadius.circular(28),
            border: Border.all(
              color: isSelected ? _kWhite : Colors.transparent,
              width: 2.5,
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 80,
                height: 80,
                decoration: const BoxDecoration(
                  color: _kWhite,
                  shape: BoxShape.circle,
                ),
                child: Icon(type.icon, color: _kEmergencyRed, size: 40),
              ),
              const SizedBox(height: 12),
              Text(
                type.label,
                style: const TextStyle(
                  color: _kWhite,
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────── Small chip widget ─────────────────────────

class _Chip extends StatelessWidget {
  final String label;
  const _Chip({required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: Colors.white.withValues(alpha: 0.7),
          fontSize: 11,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.8,
        ),
      ),
    );
  }
}

// ──────────────────── Emergency Live Call Screen ───────────────────────

class _EmergencyLiveCallScreen extends StatefulWidget {
  final String userName;
  final String userAddress;
  final String emergencyType;

  const _EmergencyLiveCallScreen({
    required this.userName,
    required this.userAddress,
    required this.emergencyType,
  });

  @override
  State<_EmergencyLiveCallScreen> createState() =>
      _EmergencyLiveCallScreenState();
}

class _EmergencyLiveCallScreenState extends State<_EmergencyLiveCallScreen> {
  final ScrollController _scrollCtrl = ScrollController();
  int _seconds = 0;
  Timer? _callTimer;
  bool _aiSpeaking = true;
  final List<Map<String, String>> _messages = [];

  @override
  void initState() {
    super.initState();
    _callTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() => _seconds++);
    });
    // Simulate AI opening line after 1 second
    Timer(const Duration(seconds: 1), () {
      if (!mounted) return;
      setState(() {
        _messages.add({
          'speaker': 'AI',
          'text':
              'Hello, this is an emergency. My name is ${widget.userName}. I am calling on behalf of a non-verbal person at ${widget.userAddress}. This is a ${widget.emergencyType} emergency. Please send help immediately.',
        });
        _aiSpeaking = false;
      });
      _scrollToBottom();
    });
  }

  @override
  void dispose() {
    _callTimer?.cancel();
    _scrollCtrl.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollCtrl.hasClients) {
        _scrollCtrl.animateTo(
          _scrollCtrl.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  String get _formattedTime {
    final m = (_seconds ~/ 60).toString().padLeft(2, '0');
    final s = (_seconds % 60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  void _endCall() {
    _callTimer?.cancel();
    // Go back to home
    Navigator.of(context).popUntil((route) => route.isFirst);
    GoRouter.of(context).go('/');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _kEmergencyRed,
      body: SafeArea(
        child: Column(
          children: [
            // ── top bar ──────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Timer
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.timer, color: _kWhite, size: 16),
                        const SizedBox(width: 8),
                        Text(
                          _formattedTime,
                          style: const TextStyle(
                            color: _kWhite,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                  // "Live" badge
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Row(
                      children: [
                        Icon(Icons.circle, color: _kWhite, size: 8),
                        SizedBox(width: 8),
                        Text(
                          'LIVE',
                          style: TextStyle(
                            color: _kWhite,
                            fontSize: 14,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 1.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // ── title ──────────────────────────────────────────
            const Text(
              'Emergency Call',
              style: TextStyle(
                color: _kWhite,
                fontSize: 22,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'AI is handling this call autonomously',
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.75),
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 24),

            // ── transcript panel ──────────────────────────────
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(32),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.2),
                    ),
                  ),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          const Icon(
                            Icons.record_voice_over,
                            color: _kWhite,
                            size: 16,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'LIVE TRANSCRIPT',
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.7),
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 1.5,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Expanded(
                        child: _messages.isEmpty
                            ? Center(
                                child: Text(
                                  'Connecting...',
                                  style: TextStyle(
                                    color: Colors.white.withValues(alpha: 0.5),
                                    fontSize: 18,
                                  ),
                                ),
                              )
                            : ListView.builder(
                                controller: _scrollCtrl,
                                itemCount: _messages.length,
                                itemBuilder: (context, index) {
                                  final msg = _messages[index];
                                  return Padding(
                                    padding: const EdgeInsets.only(bottom: 20),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          children: [
                                            Icon(
                                              Icons.smart_toy,
                                              color: Colors.white.withValues(
                                                alpha: 0.6,
                                              ),
                                              size: 14,
                                            ),
                                            const SizedBox(width: 6),
                                            Text(
                                              'AI ASSISTANT',
                                              style: TextStyle(
                                                color: Colors.white.withValues(
                                                  alpha: 0.6,
                                                ),
                                                fontSize: 12,
                                                fontWeight: FontWeight.w700,
                                                letterSpacing: 0.5,
                                              ),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 8),
                                        Container(
                                          padding: const EdgeInsets.all(16),
                                          decoration: BoxDecoration(
                                            color: Colors.white.withValues(
                                              alpha: 0.15,
                                            ),
                                            borderRadius: BorderRadius.circular(
                                              20,
                                            ),
                                          ),
                                          child: Text(
                                            msg['text'] ?? '',
                                            style: const TextStyle(
                                              color: _kWhite,
                                              fontSize: 18,
                                              fontWeight: FontWeight.w500,
                                              height: 1.5,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  );
                                },
                              ),
                      ),
                      // AI speaking indicator
                      if (_aiSpeaking) ...[
                        const SizedBox(height: 12),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            ...List.generate(
                              5,
                              (i) => Container(
                                margin: const EdgeInsets.symmetric(
                                  horizontal: 3,
                                ),
                                width: 4,
                                height: i % 2 == 0 ? 12 : 20,
                                decoration: BoxDecoration(
                                  color: Colors.white.withValues(alpha: 0.7),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Text(
                              'AI SPEAKING...',
                              style: TextStyle(
                                color: Colors.white.withValues(alpha: 0.7),
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 1.5,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),

            // ── end call button ───────────────────────────────
            Padding(
              padding: const EdgeInsets.all(24),
              child: Semantics(
                label: 'End emergency call',
                button: true,
                child: SizedBox(
                  width: double.infinity,
                  height: 72,
                  child: ElevatedButton.icon(
                    onPressed: _endCall,
                    icon: const Icon(Icons.call_end, color: _kWhite, size: 28),
                    label: const Text(
                      'End Call',
                      style: TextStyle(
                        color: _kWhite,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white.withValues(alpha: 0.2),
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(36),
                        side: const BorderSide(color: _kWhite, width: 2),
                      ),
                    ),
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

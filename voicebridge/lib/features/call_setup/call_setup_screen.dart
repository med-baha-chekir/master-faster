import 'package:flutter/material.dart';
import 'package:flutter_contacts/flutter_contacts.dart';
import 'package:go_router/go_router.dart';

import '../../models/user_profile.dart';
import '../../services/firestore_service.dart';

// ─── Scenario metadata ────────────────────────────────────────────────────────
IconData _iconForScenario(String scenario) {
  final s = scenario.toLowerCase();
  if (s.contains('food') || s.contains('order') || s.contains('restaurant')) {
    return Icons.restaurant;
  } else if (s.contains('delivery') || s.contains('courier')) {
    return Icons.local_shipping;
  } else if (s.contains('info')) {
    return Icons.info;
  } else if (s.contains('appointment') || s.contains('book')) {
    return Icons.event;
  } else if (s.contains('report') || s.contains('problem')) {
    return Icons.report_problem;
  } else if (s.contains('support') || s.contains('customer')) {
    return Icons.support_agent;
  }
  return Icons.phone;
}

// ─── Screen ───────────────────────────────────────────────────────────────────
class CallSetupScreen extends StatefulWidget {
  final String? scenario;

  const CallSetupScreen({super.key, this.scenario});

  @override
  State<CallSetupScreen> createState() => _CallSetupScreenState();
}

class _CallSetupScreenState extends State<CallSetupScreen> {
  // Profile loading
  UserProfile? _profile;
  bool _isLoading = true;

  // Phone field (cosmetic only)
  final TextEditingController _phoneCtrl = TextEditingController();
  String _countryCode = '+216';

  // Language selection
  String _selectedLang = 'fr';

  static const _purple = Color(0xFF534AB7);
  static const _lightPurple = Color(0xFFEEEDFE);

  static const _languages = [
    {'code': 'fr', 'label': 'Français'},
    {'code': 'ar', 'label': 'العربية'},
    {'code': 'en', 'label': 'English'},
  ];

  static const _countryCodes = ['+216', '+33', '+1', '+44', '+212'];

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    try {
      final profile = await FirestoreService.instance.getProfile();
      if (mounted) {
        setState(() {
          _profile = profile;
          _isLoading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _pickContact() async {
    try {
      final granted = await FlutterContacts.requestPermission();
      if (!granted) return;
      final contact = await FlutterContacts.openExternalPick();
      if (contact == null) return;
      final phones = contact.phones;
      if (phones.isNotEmpty && mounted) {
        setState(() => _phoneCtrl.text = phones.first.number);
      }
    } catch (e) {
      debugPrint('Contact picker error: $e');
    }
  }

  void _startCall() {
    final scenario = widget.scenario ?? 'Contact';
    final userName = _profile?.fullName ?? 'Utilisateur';
    final userAddress = _profile?.homeAddress ?? 'Adresse inconnue';

    context.push('/live', extra: {
      'scenario': scenario,
      'userName': userName,
      'userAddress': userAddress,
      'language': _selectedLang,
    });
  }

  String get _previewText {
    final name = _profile?.fullName ?? '…';
    final scenario = (widget.scenario ?? 'vous aider').toLowerCase();
    return 'Bonjour, je m\'appelle Sarra et j\'appelle au nom de $name. '
        'Je souhaite $scenario. Est-ce que c\'est possible ?';
  }

  @override
  void dispose() {
    _phoneCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final scenario = widget.scenario ?? 'Contact';

    return Scaffold(
      backgroundColor: const Color(0xFFF7F9FE),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF7F9FE),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: _purple),
          onPressed: () => context.pop(),
        ),
        title: const Text(
          'Préparer l\'appel',
          style: TextStyle(
            color: _purple,
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // ── 1. Scenario card ─────────────────────────────────────────────
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: _purple,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      _iconForScenario(scenario),
                      color: Colors.white,
                      size: 28,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Text(
                      scenario,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // ── 2. Phone number (cosmetic) ────────────────────────────────────
            const Text(
              'Numéro à appeler',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: Color(0xFF3F484D),
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                // Country code dropdown
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    border: Border.all(color: Colors.grey.shade300),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: _countryCode,
                      items: _countryCodes
                          .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                          .toList(),
                      onChanged: (v) => setState(() => _countryCode = v!),
                      style: const TextStyle(
                        fontSize: 16,
                        color: Colors.black87,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                // Phone number input
                Expanded(
                  child: TextField(
                    controller: _phoneCtrl,
                    keyboardType: TextInputType.phone,
                    decoration: InputDecoration(
                      hintText: '22 000 000',
                      filled: true,
                      fillColor: Colors.white,
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 14),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide:
                            BorderSide(color: Colors.grey.shade300),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide:
                            BorderSide(color: Colors.grey.shade300),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                // Contact picker button
                IconButton(
                  onPressed: _pickContact,
                  tooltip: 'Choose from contacts',
                  style: IconButton.styleFrom(
                    backgroundColor: _lightPurple,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  icon: const Icon(Icons.contacts, color: _purple),
                ),
              ],
            ),
            const SizedBox(height: 6),
            const Text(
              'Le numéro est affiché à titre indicatif',
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
            const SizedBox(height: 24),

            // ── 3. Sarra preview ──────────────────────────────────────────────
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: _lightPurple,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.record_voice_over, color: _purple, size: 20),
                      SizedBox(width: 8),
                      Text(
                        'Ce que Sarra va dire',
                        style: TextStyle(
                          color: _purple,
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  _isLoading
                      ? const Center(
                          child: CircularProgressIndicator(color: _purple),
                        )
                      : Text(
                          _previewText,
                          style: const TextStyle(
                            color: _purple,
                            fontStyle: FontStyle.italic,
                            fontSize: 15,
                            height: 1.5,
                          ),
                        ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // ── 4. Language selector ──────────────────────────────────────────
            const Text(
              'Langue de l\'appel',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: Color(0xFF3F484D),
              ),
            ),
            const SizedBox(height: 10),
            Row(
              children: _languages.map((lang) {
                final isSelected = _selectedLang == lang['code'];
                return Expanded(
                  child: Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: GestureDetector(
                      onTap: () =>
                          setState(() => _selectedLang = lang['code']!),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        decoration: BoxDecoration(
                          color: isSelected ? _purple : Colors.white,
                          border: Border.all(color: _purple, width: 2),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          lang['label']!,
                          style: TextStyle(
                            color: isSelected ? Colors.white : _purple,
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 24),

            // ── 5. Simulation info banner ─────────────────────────────────────
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFFE8F4FD),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.info_outline,
                      color: Color(0xFF1565C0), size: 20),
                  SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Mode prototype : cet appel est simulé par l\'IA. '
                      'Aucun vrai appel téléphonique n\'est effectué.',
                      style: TextStyle(
                        fontSize: 12,
                        color: Color(0xFF1565C0),
                        height: 1.4,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),

            // ── 6. Start button ───────────────────────────────────────────────
            SizedBox(
              height: 64,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _startCall,
                style: ElevatedButton.styleFrom(
                  backgroundColor: _purple,
                  disabledBackgroundColor: Colors.grey.shade300,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  elevation: 2,
                ),
                child: _isLoading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.smart_toy, color: Colors.white, size: 24),
                          SizedBox(width: 12),
                          Text(
                            'Démarrer l\'appel simulé',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
              ),
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }
}

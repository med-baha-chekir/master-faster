import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../models/user_profile.dart';
import '../../services/firestore_service.dart';

// ─────────────────────── colour tokens ────────────────────────────────
const _kPrimary = Color(0xFF004D64);
const _kSurface = Color(0xFFF7F9FE);
const _kCard = Color(0xFFF1F4F8);
const _kOnSurface = Color(0xFF181C1F);
const _kOnSurfaceVariant = Color(0xFF3F484D);
const _kOutline = Color(0xFF70787E);
const _kIconBg = Color(0xFFBEE9FF);

// ─────────────────────── helpers ──────────────────────────────────────
String _fmtDate(DateTime d) {
  const months = [
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'May',
    'Jun',
    'Jul',
    'Aug',
    'Sep',
    'Oct',
    'Nov',
    'Dec',
  ];
  return '${months[d.month - 1]} ${d.day}, ${d.year}';
}

// ═════════════════════════ SettingsScreen ═════════════════════════════
class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _loading = true;
  String _appVersion = '';

  // Controllers
  final _fullNameCtrl = TextEditingController();
  final _addressCtrl = TextEditingController();
  final _secAddressCtrl = TextEditingController();
  final _ecNameCtrl = TextEditingController();
  final _ecPhoneCtrl = TextEditingController();
  final _medNoteCtrl = TextEditingController();

  DateTime _dob = DateTime(1990, 1, 1);

  // Preference state
  String _language = 'English';
  String _aiVoice = 'neutral';
  String _speakingStyle = 'formal';
  bool _alwaysShowCustomReply = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _fullNameCtrl.dispose();
    _addressCtrl.dispose();
    _secAddressCtrl.dispose();
    _ecNameCtrl.dispose();
    _ecPhoneCtrl.dispose();
    _medNoteCtrl.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    // Fetch package info (with web fallback)
    String version = '1.0.0';
    try {
      final info = await PackageInfo.fromPlatform();
      version = '${info.version} (${info.buildNumber})';
    } catch (_) {
      version = '1.0.0';
    }

    // Load profile from Firestore (falls back to default if not yet created)
    final profile =
        await FirestoreService.instance.getProfile() ??
        UserProfile(
          id: FirestoreService.userId,
          fullName: '',
          homeAddress: '',
          dateOfBirth: DateTime(1990, 1, 1),
          preferredLanguage: 'English',
          emergencyContactName: '',
          emergencyContactPhone: '',
          aiVoicePreference: 'neutral',
          speakingStyle: 'formal',
        );

    if (!mounted) return;
    setState(() {
      _appVersion = version;
      _fullNameCtrl.text = profile.fullName;
      _addressCtrl.text = profile.homeAddress;
      _secAddressCtrl.text = profile.secondaryAddress ?? '';
      _ecNameCtrl.text = profile.emergencyContactName;
      _ecPhoneCtrl.text = profile.emergencyContactPhone;
      _medNoteCtrl.text = profile.medicalNote ?? '';
      _dob = profile.dateOfBirth;
      _language = profile.preferredLanguage;
      _aiVoice = profile.aiVoicePreference;
      _speakingStyle = profile.speakingStyle;
      _loading = false;
    });
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _dob,
      firstDate: DateTime(1920),
      lastDate: DateTime.now(),
      builder: (ctx, child) => Theme(
        data: Theme.of(
          ctx,
        ).copyWith(colorScheme: const ColorScheme.light(primary: _kPrimary)),
        child: child!,
      ),
    );
    if (picked != null) setState(() => _dob = picked);
  }

  Future<void> _save() async {
    final profile = UserProfile(
      id: FirestoreService.userId,
      fullName: _fullNameCtrl.text.trim(),
      homeAddress: _addressCtrl.text.trim(),
      secondaryAddress: _secAddressCtrl.text.trim().isEmpty
          ? null
          : _secAddressCtrl.text.trim(),
      dateOfBirth: _dob,
      preferredLanguage: _language,
      emergencyContactName: _ecNameCtrl.text.trim(),
      emergencyContactPhone: _ecPhoneCtrl.text.trim(),
      medicalNote: _medNoteCtrl.text.trim().isEmpty
          ? null
          : _medNoteCtrl.text.trim(),
      aiVoicePreference: _aiVoice,
      speakingStyle: _speakingStyle,
    );

    try {
      await FirestoreService.instance.saveProfile(profile);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Settings saved', style: TextStyle(fontSize: 16)),
          duration: Duration(seconds: 2),
          backgroundColor: Color(0xFF004D64),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Save failed: $e'), backgroundColor: Colors.red),
      );
    }
  }

  Future<void> _openPrivacyPolicy() async {
    final uri = Uri.parse('https://voicebridge.app/privacy');
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not open privacy policy')),
        );
      }
    }
  }

  void _showAboutDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
        title: const Text(
          'About VoiceBridge',
          style: TextStyle(
            fontWeight: FontWeight.w800,
            fontSize: 20,
            color: _kPrimary,
          ),
        ),
        content: const Text(
          'VoiceBridge gives non-verbal individuals an independent voice for '
          'everyday phone calls — using AI to speak on their behalf with '
          'dignity, clarity, and full personalisation.\n\n'
          'Built with care for accessibility, privacy, and inclusion.',
          style: TextStyle(
            fontSize: 16,
            height: 1.6,
            color: _kOnSurfaceVariant,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text(
              'Close',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: _kPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── build ────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _kSurface,
      appBar: _buildAppBar(),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: _kPrimary))
          : _buildBody(),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: _kSurface,
      elevation: 0,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back, color: _kPrimary),
        onPressed: () => context.go('/'),
        tooltip: 'Back',
      ),
      title: const Text(
        'Settings',
        style: TextStyle(
          color: _kPrimary,
          fontSize: 22,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }

  Widget _buildBody() {
    return Stack(
      children: [
        ListView(
          padding: const EdgeInsets.fromLTRB(24, 8, 24, 120),
          children: [
            _SectionHeader(label: 'Profile'),
            _buildProfileSection(),
            const SizedBox(height: 32),
            _SectionHeader(label: 'Call Preferences'),
            _buildPreferencesSection(),
            const SizedBox(height: 32),
            _SectionHeader(label: 'About'),
            _buildAboutSection(),
          ],
        ),
        // Fixed bottom save button
        Positioned(left: 0, right: 0, bottom: 0, child: _buildSaveButton()),
      ],
    );
  }

  // ── Profile section ─────────────────────────────────────────────────

  Widget _buildProfileSection() {
    return Container(
      decoration: BoxDecoration(
        color: _kCard,
        borderRadius: BorderRadius.circular(28),
      ),
      child: Column(
        children: [
          _SettingsTextField(
            icon: Icons.person_outline,
            label: 'Full name',
            controller: _fullNameCtrl,
            isFirst: true,
          ),
          _divider(),
          _DateField(
            icon: Icons.calendar_today_outlined,
            label: 'Date of birth',
            value: _fmtDate(_dob),
            onTap: _pickDate,
          ),
          _divider(),
          _SettingsTextField(
            icon: Icons.location_on_outlined,
            label: 'Home address',
            controller: _addressCtrl,
          ),
          _divider(),
          _SettingsTextField(
            icon: Icons.add_location_alt_outlined,
            label: 'Secondary address (optional)',
            controller: _secAddressCtrl,
          ),
          _divider(),
          _SettingsTextField(
            icon: Icons.contact_emergency_outlined,
            label: 'Emergency contact name',
            controller: _ecNameCtrl,
          ),
          _divider(),
          _SettingsTextField(
            icon: Icons.phone_outlined,
            label: 'Emergency contact phone',
            controller: _ecPhoneCtrl,
            keyboardType: TextInputType.phone,
          ),
          _divider(),
          _SettingsTextField(
            icon: Icons.medical_information_outlined,
            label: 'Medical / disability note',
            controller: _medNoteCtrl,
            maxLines: 3,
            isLast: true,
          ),
        ],
      ),
    );
  }

  // ── Preferences section ─────────────────────────────────────────────

  Widget _buildPreferencesSection() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: _kCard,
        borderRadius: BorderRadius.circular(28),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SegmentedRow<String>(
            icon: Icons.language,
            label: 'Preferred language',
            options: const ['Arabic', 'French', 'English'],
            selected: _language,
            onChanged: (v) => setState(() => _language = v),
          ),
          const SizedBox(height: 24),
          _SegmentedRow<String>(
            icon: Icons.record_voice_over_outlined,
            label: 'AI voice',
            options: const ['male', 'female', 'neutral'],
            displayLabels: const ['Male', 'Female', 'Neutral'],
            selected: _aiVoice,
            onChanged: (v) => setState(() => _aiVoice = v),
          ),
          const SizedBox(height: 24),
          _SegmentedRow<String>(
            icon: Icons.chat_bubble_outline,
            label: 'Speaking style',
            options: const ['formal', 'casual'],
            displayLabels: const ['Formal', 'Casual'],
            selected: _speakingStyle,
            onChanged: (v) => setState(() => _speakingStyle = v),
          ),
          const SizedBox(height: 24),
          _divider(),
          const SizedBox(height: 24),
          // Toggle row
          Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: _kIconBg,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(
                  Icons.keyboard_alt_outlined,
                  color: _kPrimary,
                  size: 22,
                ),
              ),
              const SizedBox(width: 16),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Always show custom reply',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: _kOnSurface,
                      ),
                    ),
                    Text(
                      'Show free-text input during every call',
                      style: TextStyle(fontSize: 14, color: _kOnSurfaceVariant),
                    ),
                  ],
                ),
              ),
              Semantics(
                label: 'Always show custom reply option during calls',
                toggled: _alwaysShowCustomReply,
                child: Switch(
                  value: _alwaysShowCustomReply,
                  onChanged: (v) => setState(() => _alwaysShowCustomReply = v),
                  activeColor: _kPrimary,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ── About section ───────────────────────────────────────────────────

  Widget _buildAboutSection() {
    return Container(
      decoration: BoxDecoration(
        color: _kCard,
        borderRadius: BorderRadius.circular(28),
      ),
      child: Column(
        children: [
          // Version
          _AboutRow(
            label: 'App version',
            trailing: Text(
              _appVersion.isEmpty ? '—' : _appVersion,
              style: const TextStyle(
                fontSize: 15,
                color: _kOutline,
                fontWeight: FontWeight.w500,
                fontFamily: 'monospace',
              ),
            ),
            isFirst: true,
          ),
          _divider(),
          // Privacy policy
          Semantics(
            label: 'Privacy Policy — opens in browser',
            button: true,
            child: _AboutRow(
              label: 'Privacy policy',
              trailing: const Icon(
                Icons.open_in_new,
                color: _kOutline,
                size: 20,
              ),
              onTap: _openPrivacyPolicy,
            ),
          ),
          _divider(),
          // About VoiceBridge
          Semantics(
            label: 'About VoiceBridge',
            button: true,
            child: _AboutRow(
              label: 'About VoiceBridge',
              trailing: const Icon(
                Icons.info_outline,
                color: _kOutline,
                size: 20,
              ),
              onTap: _showAboutDialog,
              isLast: true,
            ),
          ),
        ],
      ),
    );
  }

  // ── Save button ─────────────────────────────────────────────────────

  Widget _buildSaveButton() {
    return Container(
      color: _kSurface,
      padding: const EdgeInsets.fromLTRB(24, 12, 24, 32),
      child: Semantics(
        label: 'Save changes',
        button: true,
        child: SizedBox(
          height: 64,
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: _save,
            icon: const Icon(
              Icons.check_circle_outline,
              color: Colors.white,
              size: 24,
            ),
            label: const Text(
              'Save changes',
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: _kPrimary,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(32),
              ),
              elevation: 4,
              shadowColor: _kPrimary.withValues(alpha: 0.4),
            ),
          ),
        ),
      ),
    );
  }

  // ── util ─────────────────────────────────────────────────────────────

  Widget _divider() => const Divider(
    height: 0,
    thickness: 0.5,
    indent: 24,
    endIndent: 24,
    color: Color(0xFFE0E3E7),
  );
}

// ═══════════════════════ Sub-widgets ══════════════════════════════════

class _SectionHeader extends StatelessWidget {
  final String label;
  const _SectionHeader({required this.label});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Text(
        label,
        style: const TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.w700,
          color: _kOnSurfaceVariant,
        ),
      ),
    );
  }
}

// ── Editable text field row ───────────────────────────────────────────

class _SettingsTextField extends StatelessWidget {
  final IconData icon;
  final String label;
  final TextEditingController controller;
  final TextInputType keyboardType;
  final int maxLines;
  final bool isFirst;
  final bool isLast;

  const _SettingsTextField({
    required this.icon,
    required this.label,
    required this.controller,
    this.keyboardType = TextInputType.text,
    this.maxLines = 1,
    this.isFirst = false,
    this.isLast = false,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
      child: Row(
        crossAxisAlignment: maxLines > 1
            ? CrossAxisAlignment.start
            : CrossAxisAlignment.center,
        children: [
          Padding(
            padding: EdgeInsets.only(top: maxLines > 1 ? 14 : 0),
            child: Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: _kIconBg,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(icon, color: _kPrimary, size: 22),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Semantics(
              label: label,
              textField: true,
              child: TextField(
                controller: controller,
                keyboardType: keyboardType,
                maxLines: maxLines,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w500,
                  color: _kOnSurface,
                ),
                decoration: InputDecoration(
                  labelText: label,
                  labelStyle: const TextStyle(
                    fontSize: 14,
                    color: _kOnSurfaceVariant,
                  ),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(vertical: 16),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Date picker row ───────────────────────────────────────────────────

class _DateField extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final VoidCallback onTap;

  const _DateField({
    required this.icon,
    required this.label,
    required this.value,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: '$label: $value',
      button: true,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: _kIconBg,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(icon, color: _kPrimary, size: 22),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label,
                      style: const TextStyle(
                        fontSize: 14,
                        color: _kOnSurfaceVariant,
                      ),
                    ),
                    Text(
                      value,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w500,
                        color: _kOnSurface,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right, color: _kOutline),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Segmented control row ─────────────────────────────────────────────

class _SegmentedRow<T> extends StatelessWidget {
  final IconData icon;
  final String label;
  final List<T> options;
  final List<String>? displayLabels;
  final T selected;
  final ValueChanged<T> onChanged;

  const _SegmentedRow({
    required this.icon,
    required this.label,
    required this.options,
    this.displayLabels,
    required this.selected,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: _kIconBg,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(icon, color: _kPrimary, size: 22),
            ),
            const SizedBox(width: 16),
            Text(
              label,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: _kOnSurface,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: List.generate(options.length, (i) {
            final opt = options[i];
            final lbl = displayLabels?[i] ?? opt.toString();
            final isSelected = opt == selected;
            return Expanded(
              child: Padding(
                padding: EdgeInsets.only(right: i < options.length - 1 ? 8 : 0),
                child: Semantics(
                  label: '$label: $lbl${isSelected ? ', selected' : ''}',
                  button: true,
                  selected: isSelected,
                  child: GestureDetector(
                    onTap: () => onChanged(opt),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 180),
                      height: 48,
                      decoration: BoxDecoration(
                        color: isSelected ? _kPrimary : Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: isSelected
                              ? _kPrimary
                              : const Color(0xFFBFC8CD),
                          width: 1.5,
                        ),
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        lbl,
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: isSelected ? Colors.white : _kOnSurfaceVariant,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            );
          }),
        ),
      ],
    );
  }
}

// ── About row ─────────────────────────────────────────────────────────

class _AboutRow extends StatelessWidget {
  final String label;
  final Widget trailing;
  final VoidCallback? onTap;
  final bool isFirst;
  final bool isLast;

  const _AboutRow({
    required this.label,
    required this.trailing,
    this.onTap,
    this.isFirst = false,
    this.isLast = false,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.vertical(
          top: isFirst ? const Radius.circular(28) : Radius.zero,
          bottom: isLast ? const Radius.circular(28) : Radius.zero,
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  label,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w500,
                    color: _kOnSurface,
                  ),
                ),
              ),
              trailing,
            ],
          ),
        ),
      ),
    );
  }
}

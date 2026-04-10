import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../models/user_profile.dart';
import 'widgets/step_identity.dart';
import 'widgets/step_language.dart';
import 'widgets/step_emergency.dart';
import 'widgets/step_voice_style.dart';
import 'widgets/onboarding_footer.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentStep = 0;
  final int _totalSteps = 7;
  bool _isSaving = false;

  // Form Controllers
  final TextEditingController _nameController = TextEditingController();
  DateTime _dateOfBirth = DateTime.now().subtract(
    const Duration(days: 365 * 30),
  );
  final TextEditingController _homeAddressController = TextEditingController();
  final TextEditingController _secondaryAddressController =
      TextEditingController();
  String _preferredLanguage = 'English';
  final TextEditingController _emergencyNameController =
      TextEditingController();
  final TextEditingController _emergencyPhoneController =
      TextEditingController();
  final TextEditingController _medicalNoteController = TextEditingController();
  String _aiVoice = 'neutral';
  String _aiStyle = 'casual';

  @override
  void dispose() {
    _pageController.dispose();
    _nameController.dispose();
    _homeAddressController.dispose();
    _secondaryAddressController.dispose();
    _emergencyNameController.dispose();
    _emergencyPhoneController.dispose();
    _medicalNoteController.dispose();
    super.dispose();
  }

  void _nextStep() {
    if (_currentStep < _totalSteps - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    } else {
      _completeSetup();
    }
  }

  void _prevStep() {
    if (_currentStep > 0) {
      _pageController.previousPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  void _skipStep() {
    // Fill with default values and move to next step
    switch (_currentStep) {
      case 0:
        if (_nameController.text.isEmpty) {
          _nameController.text = "Guest User";
        }
        break;
      case 1:
        if (_homeAddressController.text.isEmpty) {
          _homeAddressController.text = "123 Main St, City";
        }
        break;
      case 2:
        _preferredLanguage = 'English';
        break;
      case 3:
        if (_emergencyNameController.text.isEmpty) {
          _emergencyNameController.text = "Default Contact";
        }
        if (_emergencyPhoneController.text.isEmpty) {
          _emergencyPhoneController.text = "911";
        }
        break;
      case 4:
        break; // Optional medical note skipped
      case 5:
        _aiVoice = 'neutral';
        break;
      case 6:
        _aiStyle = 'casual';
        break;
    }
    setState(() {});
    _nextStep();
  }

  Future<void> _completeSetup() async {
    setState(() {
      _isSaving = true;
    });

    try {
      final uid =
          FirebaseAuth.instance.currentUser?.uid ?? 'mock_uid_prototype_123';

      final profile = UserProfile(
        id: uid,
        fullName: _nameController.text.isNotEmpty
            ? _nameController.text
            : "Guest User",
        homeAddress: _homeAddressController.text.isNotEmpty
            ? _homeAddressController.text
            : "Not provided",
        secondaryAddress: _secondaryAddressController.text.isEmpty
            ? null
            : _secondaryAddressController.text,
        dateOfBirth: _dateOfBirth,
        preferredLanguage: _preferredLanguage,
        emergencyContactName: _emergencyNameController.text.isNotEmpty
            ? _emergencyNameController.text
            : "Not provided",
        emergencyContactPhone: _emergencyPhoneController.text.isNotEmpty
            ? _emergencyPhoneController.text
            : "Not provided",
        medicalNote: _medicalNoteController.text.isEmpty
            ? null
            : _medicalNoteController.text,
        aiVoicePreference: _aiVoice,
        speakingStyle: _aiStyle,
      );

      await FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .set(profile.toMap());

      if (mounted) {
        context.go('/');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Failed to save profile: $e')));
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  Widget _buildStepContent() {
    switch (_currentStep) {
      case 0:
        return Step1FullNameDob(
          nameController: _nameController,
          selectedDate: _dateOfBirth,
          onDateChanged: (date) => setState(() => _dateOfBirth = date),
        );
      case 1:
        return Step2Address(
          homeAddressController: _homeAddressController,
          secondaryAddressController: _secondaryAddressController,
        );
      case 2:
        return Step3Language(
          selectedLanguage: _preferredLanguage,
          onLanguageChanged: (lang) =>
              setState(() => _preferredLanguage = lang),
        );
      case 3:
        return Step4EmergencyContact(
          nameController: _emergencyNameController,
          phoneController: _emergencyPhoneController,
        );
      case 4:
        return Step5MedicalNote(medicalNoteController: _medicalNoteController);
      case 5:
        return Step6Voice(
          selectedVoice: _aiVoice,
          onVoiceChanged: (voice) => setState(() => _aiVoice = voice),
        );
      case 6:
        return Step7Style(
          selectedStyle: _aiStyle,
          onStyleChanged: (style) => setState(() => _aiStyle = style),
        );
      default:
        return const SizedBox.shrink();
    }
  }

  @override
  Widget build(BuildContext context) {
    // Determine layout direction based on selected language
    final textDirection = _preferredLanguage == 'Arabic'
        ? TextDirection.rtl
        : TextDirection.ltr;

    return Directionality(
      textDirection: textDirection,
      child: Scaffold(
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          leading: _currentStep > 0
              ? IconButton(
                  icon: const Icon(Icons.arrow_back),
                  color: Theme.of(context).colorScheme.primary,
                  onPressed: _prevStep,
                  tooltip: 'Go back',
                )
              : null,
          title: Text(
            'VoiceBridge',
            style: TextStyle(
              color: Theme.of(context).colorScheme.primary,
              fontWeight: FontWeight.bold,
            ),
          ),
          actions: [
            TextButton(
              onPressed: _isSaving ? null : _skipStep,
              child: Text(
                'Skip',
                style: TextStyle(color: Colors.grey[700], fontSize: 16),
              ),
            ),
          ],
        ),
        body: _isSaving
            ? const Center(child: CircularProgressIndicator())
            : SafeArea(
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 800),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24.0,
                        vertical: 16.0,
                      ),
                      child: Column(
                        children: [
                          Row(
                            children: [
                              Text(
                                'Step ${_currentStep + 1} of $_totalSteps',
                                style: TextStyle(
                                  color: Theme.of(context).colorScheme.primary,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 1.2,
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: LinearProgressIndicator(
                                  value: (_currentStep + 1) / _totalSteps,
                                  backgroundColor: Theme.of(
                                    context,
                                  ).colorScheme.surfaceContainerHighest,
                                  color: Theme.of(context).colorScheme.primary,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 32),
                          Expanded(
                            child: PageView.builder(
                              controller: _pageController,
                              physics:
                                  const NeverScrollableScrollPhysics(), // Disable swipe
                              itemCount: _totalSteps,
                              onPageChanged: (index) {
                                setState(() {
                                  _currentStep = index;
                                });
                              },
                              itemBuilder: (context, index) {
                                return SingleChildScrollView(
                                  child: _buildStepContent(),
                                );
                              },
                            ),
                          ),
                          OnboardingFooter(
                            onBack: _prevStep,
                            onNext: _nextStep,
                            isFirstStep: _currentStep == 0,
                            isLastStep: _currentStep == _totalSteps - 1,
                          ),
                          const SizedBox(height: 16),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
      ),
    );
  }
}

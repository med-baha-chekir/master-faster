import 'package:flutter/material.dart';

class OnboardingFooter extends StatelessWidget {
  final VoidCallback? onBack;
  final VoidCallback onNext;
  final bool isLastStep;
  final bool isFirstStep;

  const OnboardingFooter({
    super.key,
    this.onBack,
    required this.onNext,
    this.isLastStep = false,
    this.isFirstStep = false,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 16.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          if (!isFirstStep)
            Semantics(
              label: 'Go back to the previous step',
              button: true,
              child: TextButton.icon(
                onPressed: onBack,
                icon: const Icon(Icons.arrow_back),
                label: const Text('Back'),
                style: TextButton.styleFrom(minimumSize: const Size(56, 56)),
              ),
            )
          else
            const SizedBox.shrink(),
          Semantics(
            label: isLastStep
                ? 'Complete setup and save profile'
                : 'Continue to the next step',
            button: true,
            child: FilledButton.icon(
              onPressed: onNext,
              icon: Icon(isLastStep ? Icons.check : Icons.arrow_forward),
              label: Text(
                isLastStep ? 'Complete Setup' : 'Next',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              style: FilledButton.styleFrom(
                minimumSize: const Size(120, 56), // Minimum 56x56 tap target
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(100),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

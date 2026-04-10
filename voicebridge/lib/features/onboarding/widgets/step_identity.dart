import 'package:flutter/material.dart';

class Step1FullNameDob extends StatelessWidget {
  final TextEditingController nameController;
  final DateTime selectedDate;
  final ValueChanged<DateTime> onDateChanged;

  const Step1FullNameDob({
    super.key,
    required this.nameController,
    required this.selectedDate,
    required this.onDateChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Create your unique identity.',
          style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        Text(
          'We use these details to personalize your AI voice and ensure help is ready if you need it.',
          style: TextStyle(fontSize: 18, color: Colors.grey[700]),
        ),
        const SizedBox(height: 32),
        Semantics(
          label: 'Full Name input field',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Full Name',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: nameController,
                style: const TextStyle(fontSize: 18),
                decoration: InputDecoration(
                  hintText: 'e.g., Sarah Chen',
                  filled: true,
                  fillColor: Theme.of(
                    context,
                  ).colorScheme.surfaceContainerHighest,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(24),
                    borderSide: BorderSide.none,
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 20,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
        Semantics(
          label: 'Date of Birth selector',
          button: true,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Date of Birth',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              const SizedBox(height: 8),
              InkWell(
                onTap: () async {
                  final picked = await showDatePicker(
                    context: context,
                    initialDate: selectedDate,
                    firstDate: DateTime(1900),
                    lastDate: DateTime.now(),
                  );
                  if (picked != null) {
                    onDateChanged(picked);
                  }
                },
                borderRadius: BorderRadius.circular(24),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 20,
                  ),
                  decoration: BoxDecoration(
                    color: Theme.of(
                      context,
                    ).colorScheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(24),
                  ),
                  child: Text(
                    "${selectedDate.year}-${selectedDate.month.toString().padLeft(2, '0')}-${selectedDate.day.toString().padLeft(2, '0')}",
                    style: const TextStyle(fontSize: 18),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class Step2Address extends StatelessWidget {
  final TextEditingController homeAddressController;
  final TextEditingController secondaryAddressController;

  const Step2Address({
    super.key,
    required this.homeAddressController,
    required this.secondaryAddressController,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Where do you live?',
          style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        Text(
          'Used for emergencies and home deliveries.',
          style: TextStyle(fontSize: 18, color: Colors.grey[700]),
        ),
        const SizedBox(height: 32),
        Semantics(
          label: 'Home Address input field',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Home Address',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: homeAddressController,
                maxLines: 3,
                style: const TextStyle(fontSize: 18),
                decoration: InputDecoration(
                  hintText: 'Street, Apartment, City, Postal Code',
                  filled: true,
                  fillColor: Theme.of(
                    context,
                  ).colorScheme.surfaceContainerHighest,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(24),
                    borderSide: BorderSide.none,
                  ),
                  contentPadding: const EdgeInsets.all(24),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
        Semantics(
          label: 'Secondary Address Optional input field',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Secondary / Delivery Address (Optional)',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: secondaryAddressController,
                maxLines: 2,
                style: const TextStyle(fontSize: 18),
                decoration: InputDecoration(
                  hintText: 'e.g., Work Address',
                  filled: true,
                  fillColor: Theme.of(
                    context,
                  ).colorScheme.surfaceContainerHighest,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(24),
                    borderSide: BorderSide.none,
                  ),
                  contentPadding: const EdgeInsets.all(24),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

import 'package:flutter/material.dart';

class Step6Voice extends StatelessWidget {
  final String selectedVoice;
  final ValueChanged<String> onVoiceChanged;

  const Step6Voice({
    super.key,
    required this.selectedVoice,
    required this.onVoiceChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'AI Voice Preference',
          style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        Text(
          'How do you want your AI assistant to sound?',
          style: TextStyle(fontSize: 18, color: Colors.grey[700]),
        ),
        const SizedBox(height: 32),
        Column(
          children: ['male', 'female', 'neutral'].map((voice) {
            final isSelected = selectedVoice == voice;
            final labelText = voice[0].toUpperCase() + voice.substring(1);

            return Padding(
              padding: const EdgeInsets.only(bottom: 16.0),
              child: Semantics(
                button: true,
                selected: isSelected,
                label: 'Select $labelText AI voice',
                child: InkWell(
                  onTap: () => onVoiceChanged(voice),
                  borderRadius: BorderRadius.circular(24),
                  child: Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? Theme.of(context).colorScheme.primaryContainer
                          : Theme.of(
                              context,
                            ).colorScheme.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(
                        color: isSelected
                            ? Theme.of(context).colorScheme.primary
                            : Colors.transparent,
                        width: 2,
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.record_voice_over,
                          color: isSelected
                              ? Theme.of(context).colorScheme.onPrimaryContainer
                              : null,
                          size: 32,
                        ),
                        const SizedBox(width: 16),
                        Text(
                          labelText,
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: isSelected
                                ? Theme.of(
                                    context,
                                  ).colorScheme.onPrimaryContainer
                                : null,
                          ),
                        ),
                        const Spacer(),
                        if (isSelected)
                          Icon(
                            Icons.check_circle,
                            color: Theme.of(context).colorScheme.primary,
                            size: 32,
                          ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }
}

class Step7Style extends StatelessWidget {
  final String selectedStyle;
  final ValueChanged<String> onStyleChanged;

  const Step7Style({
    super.key,
    required this.selectedStyle,
    required this.onStyleChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Speaking Style',
          style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        Text(
          'How should the AI communicate with others?',
          style: TextStyle(fontSize: 18, color: Colors.grey[700]),
        ),
        const SizedBox(height: 32),
        Column(
          children: ['formal', 'casual'].map((style) {
            final isSelected = selectedStyle == style;
            final labelText = style[0].toUpperCase() + style.substring(1);

            return Padding(
              padding: const EdgeInsets.only(bottom: 16.0),
              child: Semantics(
                button: true,
                selected: isSelected,
                label: 'Select $labelText speaking style',
                child: InkWell(
                  onTap: () => onStyleChanged(style),
                  borderRadius: BorderRadius.circular(24),
                  child: Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? Theme.of(context).colorScheme.primaryContainer
                          : Theme.of(
                              context,
                            ).colorScheme.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(
                        color: isSelected
                            ? Theme.of(context).colorScheme.primary
                            : Colors.transparent,
                        width: 2,
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          style == 'formal'
                              ? Icons.business_center
                              : Icons.chat_bubble_outline,
                          color: isSelected
                              ? Theme.of(context).colorScheme.onPrimaryContainer
                              : null,
                          size: 32,
                        ),
                        const SizedBox(width: 16),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              labelText,
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: isSelected
                                    ? Theme.of(
                                        context,
                                      ).colorScheme.onPrimaryContainer
                                    : null,
                              ),
                            ),
                            Text(
                              style == 'formal'
                                  ? 'Polite and professional'
                                  : 'Friendly and relaxed',
                              style: TextStyle(
                                fontSize: 14,
                                color: isSelected
                                    ? Theme.of(
                                        context,
                                      ).colorScheme.onPrimaryContainer
                                    : Colors.grey[700],
                              ),
                            ),
                          ],
                        ),
                        const Spacer(),
                        if (isSelected)
                          Icon(
                            Icons.check_circle,
                            color: Theme.of(context).colorScheme.primary,
                            size: 32,
                          ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }
}

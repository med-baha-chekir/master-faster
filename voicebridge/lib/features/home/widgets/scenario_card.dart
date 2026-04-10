import 'package:flutter/material.dart';

class ScenarioCard extends StatefulWidget {
  final String title;
  final String description;
  final IconData icon;
  final VoidCallback onTap;
  final Color iconBackgroundColor;
  final Color iconColor;

  const ScenarioCard({
    super.key,
    required this.title,
    required this.description,
    required this.icon,
    required this.onTap,
    required this.iconBackgroundColor,
    required this.iconColor,
  });

  @override
  State<ScenarioCard> createState() => _ScenarioCardState();
}

class _ScenarioCardState extends State<ScenarioCard> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    // We recreate the "group hover" styling using a MouseRegion and InkWell combined.
    // When hovered, the card background becomes primaryContainer, and elements turn white / light blue.
    return Semantics(
      button: true,
      label: 'Scenario: ${widget.title}',
      hint: widget.description,
      child: MouseRegion(
        onEnter: (_) => setState(() => _isHovered = true),
        onExit: (_) => setState(() => _isHovered = false),
        child: Material(
          color: _isHovered
              ? colorScheme.primaryContainer
              : theme.cardColor, // fallback to cardColor which should be white
          borderRadius: BorderRadius.circular(24.0),
          elevation: _isHovered ? 4.0 : 0.5, // slight shadow normally
          child: InkWell(
            onTap: widget.onTap,
            borderRadius: BorderRadius.circular(24.0),
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.max,
                children: [
                  Container(
                    padding: const EdgeInsets.all(16.0),
                    decoration: BoxDecoration(
                      color: _isHovered
                          ? colorScheme.onPrimaryContainer
                          : widget.iconBackgroundColor,
                      borderRadius: BorderRadius.circular(16.0),
                    ),
                    child: Icon(
                      widget.icon,
                      color: _isHovered
                          ? colorScheme.primaryContainer
                          : widget.iconColor,
                      size: 32.0,
                    ),
                  ),
                  const Spacer(),
                  Text(
                    widget.title,
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: _isHovered
                          ? colorScheme.onPrimary
                          : colorScheme.onSurface,
                    ),
                  ),
                  const SizedBox(height: 8.0),
                  Text(
                    widget.description,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: _isHovered
                          ? colorScheme.onPrimaryContainer
                          : colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

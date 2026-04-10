import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'widgets/scenario_card.dart';

// Colors from Stitch prototype
const _primaryContainer = Color(0xFF006684);
const _secondaryContainer = Color(0xFF9DEEED);
const _onSecondaryContainer = Color(0xFF0B6E6E);
const _primaryFixed = Color(0xFFBEE9FF);
const _onPrimaryFixedVariant = Color(0xFF004D64);
const _secondaryFixed = Color(0xFFA0F0F0);
const _onSecondaryFixedVariant = Color(0xFF004F4F);
const _errorContainer = Color(0xFFFFDAD6);
const _onErrorContainer = Color(0xFF93000A);
const _primaryFixedDim = Color(0xFF87D0F2);
const _surfaceContainerLowest = Color(0xFFFFFFFF);
const _onSurface = Color(0xFF181C1F);
const _onSurfaceVariant = Color(0xFF3F484D);

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final TextEditingController _customScenarioController =
      TextEditingController();

  void _navigateToSetup(BuildContext context, String scenario) {
    context.push('/setup', extra: scenario);
  }

  @override
  void dispose() {
    _customScenarioController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark
          ? const Color(0xFF181C1F)
          : const Color(0xFFF7F9FE),
      appBar: AppBar(
        backgroundColor: isDark
            ? const Color(0xFF181C1F)
            : const Color(0xFFF7F9FE),
        elevation: 0,
        title: Text(
          'VoiceBridge',
          style: TextStyle(
            color: isDark ? const Color(0xFF4FD8EB) : const Color(0xFF006684),
            fontWeight: FontWeight.bold,
            fontFamily:
                'Plus Jakarta Sans', // matching prototype font if available
          ),
        ),
        leading: Semantics(
          label: 'Back',
          button: true,
          child: IconButton(
            icon: Icon(
              Icons.arrow_back,
              color: isDark ? const Color(0xFF4FD8EB) : const Color(0xFF006684),
            ),
            onPressed: () {
              if (context.canPop()) context.pop();
            },
          ),
        ),
        actions: [
          Semantics(
            label: 'Profile',
            button: true,
            child: IconButton(
              icon: Icon(
                Icons.account_circle,
                color: isDark
                    ? const Color(0xFF4FD8EB)
                    : const Color(0xFF006684),
              ),
              onPressed: () {
                // Future profile navigation
              },
            ),
          ),
        ],
      ),
      body: Stack(
        children: [
          // Main content
          SingleChildScrollView(
            padding: const EdgeInsets.only(
              left: 24.0,
              right: 24.0,
              top: 24.0,
              bottom: 200.0,
            ), // space for bottom nav
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Hero Section
                Text(
                  'What can I speak\nfor you today?',
                  style: theme.textTheme.displaySmall?.copyWith(
                    fontWeight: FontWeight.w800,
                    color: isDark ? Colors.white : _onSurface,
                    height: 1.2,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'Choose a pre-built scenario or describe exactly what you need. We\'ll handle the call.',
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: isDark ? Colors.white70 : _onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 32),

                // Scenario Bento Grid
                LayoutBuilder(
                  builder: (context, constraints) {
                    final isWide = constraints.maxWidth > 600;
                    return GridView.count(
                      crossAxisCount: isWide ? 3 : 2,
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      mainAxisSpacing: 16,
                      crossAxisSpacing: 16,
                      childAspectRatio: isWide
                          ? 0.8
                          : 0.55, // Adjust for mobile so text fits
                      children: [
                        ScenarioCard(
                          title: 'Order food',
                          description: 'Pizza, takeout, or reservations.',
                          icon: Icons.restaurant,
                          iconBackgroundColor: _secondaryContainer,
                          iconColor: _onSecondaryContainer,
                          onTap: () => _navigateToSetup(context, 'Order food'),
                        ),
                        ScenarioCard(
                          title: 'Request delivery',
                          description: 'Courier and parcel tracking.',
                          icon: Icons.local_shipping,
                          iconBackgroundColor: _primaryFixed,
                          iconColor: _onPrimaryFixedVariant,
                          onTap: () =>
                              _navigateToSetup(context, 'Request delivery'),
                        ),
                        ScenarioCard(
                          title: 'Ask for info',
                          description: 'Hours, pricing, or inquiries.',
                          icon: Icons.info,
                          iconBackgroundColor: _secondaryFixed,
                          iconColor: _onSecondaryFixedVariant,
                          onTap: () =>
                              _navigateToSetup(context, 'Ask for info'),
                        ),
                        ScenarioCard(
                          title: 'Book appointment',
                          description: 'Doctor, salon, or visits.',
                          icon: Icons.event,
                          iconBackgroundColor: _secondaryContainer,
                          iconColor: _onSecondaryContainer,
                          onTap: () =>
                              _navigateToSetup(context, 'Book appointment'),
                        ),
                        ScenarioCard(
                          title: 'Report a problem',
                          description: 'Utilities, outages, damages.',
                          icon: Icons.report_problem,
                          iconBackgroundColor: _errorContainer,
                          iconColor: _onErrorContainer,
                          onTap: () =>
                              _navigateToSetup(context, 'Report a problem'),
                        ),
                        ScenarioCard(
                          title: 'Customer support',
                          description: 'Talk to a human via AI.',
                          icon: Icons.support_agent,
                          iconBackgroundColor: _primaryFixedDim,
                          iconColor: _onPrimaryFixedVariant,
                          onTap: () =>
                              _navigateToSetup(context, 'Customer support'),
                        ),
                      ],
                    );
                  },
                ),
                const SizedBox(height: 32),

                // Custom Scenario Input
                Container(
                  padding: const EdgeInsets.all(24.0),
                  decoration: BoxDecoration(
                    color: isDark
                        ? const Color(0xFF2D3134)
                        : const Color(0xFFF1F4F8), // surface-container-low
                    borderRadius: BorderRadius.circular(32.0),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Custom Scenario',
                        style: theme.textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: isDark ? Colors.white : _onSurface,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Container(
                        decoration: BoxDecoration(
                          color: isDark
                              ? const Color(0xFF181C1F)
                              : _surfaceContainerLowest,
                          borderRadius: BorderRadius.circular(32.0),
                          boxShadow: const [
                            BoxShadow(
                              color: Colors.black12,
                              blurRadius: 4,
                              offset: Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Row(
                          children: [
                            const Padding(
                              padding: EdgeInsets.only(left: 20.0, right: 8.0),
                              child: Icon(Icons.keyboard, color: Colors.grey),
                            ),
                            Expanded(
                              child: Semantics(
                                textField: true,
                                label: 'Custom scenario text field',
                                child: TextField(
                                  controller: _customScenarioController,
                                  decoration: const InputDecoration(
                                    border: InputBorder.none,
                                    hintText: 'Describe a custom scenario...',
                                    hintStyle: TextStyle(color: Colors.grey),
                                    contentPadding: EdgeInsets.symmetric(
                                      vertical: 20.0,
                                    ),
                                  ),
                                  onSubmitted: (val) {
                                    if (val.trim().isNotEmpty) {
                                      _navigateToSetup(context, val.trim());
                                    }
                                  },
                                ),
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8.0,
                              ),
                              child: ElevatedButton(
                                onPressed: () {
                                  if (_customScenarioController.text
                                      .trim()
                                      .isNotEmpty) {
                                    _navigateToSetup(
                                      context,
                                      _customScenarioController.text.trim(),
                                    );
                                  }
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: _primaryContainer,
                                  foregroundColor: Colors.white,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(24.0),
                                  ),
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 24.0,
                                    vertical: 16.0,
                                  ),
                                ),
                                child: const Text(
                                  'Start Call',
                                  style: TextStyle(fontWeight: FontWeight.bold),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Bottom Navigation Shell Layer
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Floating SOS Button (overlaps the nav bar)
                Semantics(
                  button: true,
                  label: 'Emergency SOS',
                  hint: 'Double tap to open emergency screen immediately',
                  child: GestureDetector(
                    onTap: () => context.push('/emergency'),
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFF930009), Color(0xFFBA1A1A)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(24.0),
                        boxShadow: const [
                          BoxShadow(
                            color: Colors.black26,
                            blurRadius: 16,
                            offset: Offset(0, 8),
                          ),
                        ],
                      ),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 32.0,
                        vertical: 16.0,
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.emergency, color: Colors.white, size: 32),
                          SizedBox(width: 12),
                          Text(
                            'SOS EMERGENCY',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 1.2,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

                // Slight overlap mapping via transform or just space
                const SizedBox(height: 16),

                // Bottom Nav Bar
                Container(
                  padding: const EdgeInsets.only(
                    top: 12,
                    bottom: 24,
                    left: 16,
                    right: 16,
                  ),
                  decoration: BoxDecoration(
                    color: isDark
                        ? const Color(0xCC181C1F)
                        : const Color(0xCCF7F9FE),
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(24.0),
                    ),
                    boxShadow: const [
                      BoxShadow(
                        color: Colors.black12,
                        blurRadius: 10,
                        offset: Offset(0, -4),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _buildNavItem(
                        Icons.home,
                        'Home',
                        isActive: true,
                        isDark: isDark,
                      ),
                      _buildNavItem(
                        Icons.history,
                        'History',
                        isDark: isDark,
                        onTap: () => context.push('/history'),
                      ),
                      _buildNavItem(
                        Icons.emergency,
                        'SOS',
                        isDark: isDark,
                        onTap: () => context.push('/emergency'),
                      ),
                      _buildNavItem(
                        Icons.settings,
                        'Settings',
                        isDark: isDark,
                        onTap: () => context.push('/settings'),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNavItem(
    IconData icon,
    String label, {
    bool isActive = false,
    VoidCallback? onTap,
    required bool isDark,
  }) {
    final activeBg = isDark ? const Color(0xFF004D64) : const Color(0xFF006684);
    final activeColor = Colors.white;
    final inactiveColor = isDark
        ? const Color(0xFFC4C7CF)
        : const Color(0xFF44474E);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16.0),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 8.0),
        decoration: BoxDecoration(
          color: isActive ? activeBg : Colors.transparent,
          borderRadius: BorderRadius.circular(16.0),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: isActive ? activeColor : inactiveColor, size: 28),
            const SizedBox(height: 4),
            Text(
              label.toUpperCase(),
              style: TextStyle(
                color: isActive ? activeColor : inactiveColor,
                fontSize: 10,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.0,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

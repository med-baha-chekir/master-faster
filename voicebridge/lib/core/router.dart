import 'package:go_router/go_router.dart';
import '../features/home/home_screen.dart';
import '../features/onboarding/onboarding_screen.dart';
import '../features/call_setup/call_setup_screen.dart';
import '../features/live_call/live_call_screen.dart';
import '../features/post_call/post_call_summary_screen.dart';
import '../features/emergency/emergency_screen.dart';
import '../features/history/call_history_screen.dart';
import '../features/settings/settings_screen.dart';
import '../models/transcript_line.dart';

final appRouter = GoRouter(
  initialLocation: '/onboarding',
  routes: [
    GoRoute(
      path: '/',
      name: 'home',
      builder: (context, state) => const HomeScreen(),
    ),
    GoRoute(
      path: '/onboarding',
      name: 'onboarding',
      builder: (context, state) => const OnboardingScreen(),
    ),
    GoRoute(
      path: '/setup',
      name: 'call_setup',
      builder: (context, state) {
        final scenario = state.extra as String?;
        return CallSetupScreen(scenario: scenario);
      },
    ),
    GoRoute(
      path: '/live',
      name: 'live_call',
      builder: (context, state) {
        final args = state.extra as Map<String, dynamic>? ?? {};
        return LiveCallScreen(
          scenario: args['scenario'] as String?,
          userName: args['userName'] as String?,
          userAddress: args['userAddress'] as String?,
          language: args['language'] as String? ?? 'fr',
        );
      },
    ),
    GoRoute(
      path: '/summary',
      name: 'post_call',
      builder: (context, state) {
        final args = state.extra as Map<String, dynamic>? ?? {};
        return PostCallSummaryScreen(
          transcript: args['transcript'] as List<TranscriptLine>?,
          scenario: args['scenario'] as String?,
          summary: args['summary'] as String?,
          duration: args['callDuration'] as int?,
        );
      },
    ),
    GoRoute(
      path: '/emergency',
      name: 'emergency',
      builder: (context, state) => const EmergencyScreen(),
    ),
    GoRoute(
      path: '/history',
      name: 'history',
      builder: (context, state) => const CallHistoryScreen(),
    ),
    GoRoute(
      path: '/settings',
      name: 'settings',
      builder: (context, state) => const SettingsScreen(),
    ),
  ],
);

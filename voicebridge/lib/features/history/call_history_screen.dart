import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../models/call_record.dart';
import '../../services/firestore_service.dart';

// ─────────────────── scenario icon helpers ────────────────────────────

IconData _scenarioIcon(String key) {
  switch (key) {
    case 'restaurant':
      return Icons.restaurant;
    case 'medical_services':
      return Icons.medical_services;
    case 'shopping_basket':
      return Icons.shopping_basket;
    case 'local_taxi':
      return Icons.local_taxi;
    case 'settings_phone':
      return Icons.settings_phone;
    default:
      return Icons.phone;
  }
}

Color _scenarioIconBg(String key) {
  switch (key) {
    case 'restaurant':
      return const Color(0xFF9DEEED);
    case 'medical_services':
      return const Color(0xFFBEE9FF);
    case 'shopping_basket':
      return const Color(0xFF84D4D3);
    case 'local_taxi':
      return const Color(0xFFFFDAD5);
    default:
      return const Color(0xFFE0E3E7);
  }
}

Color _scenarioIconFg(String key) {
  switch (key) {
    case 'restaurant':
      return const Color(0xFF0B6E6E);
    case 'medical_services':
      return const Color(0xFF004D64);
    case 'shopping_basket':
      return const Color(0xFF004F4F);
    case 'local_taxi':
      return const Color(0xFF410002);
    default:
      return const Color(0xFF3F484D);
  }
}

// ─────────────────── date formatting helpers ──────────────────────────

String _formatDateTime(DateTime dt) {
  const weekdays = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
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
  final wd = weekdays[dt.weekday - 1];
  final mo = months[dt.month - 1];
  final hh = dt.hour.toString().padLeft(2, '0');
  final mm = dt.minute.toString().padLeft(2, '0');
  return '$wd ${dt.day} $mo, $hh:$mm';
}

String _formatDuration(Duration d) {
  final m = d.inMinutes.toString().padLeft(2, '0');
  final s = (d.inSeconds % 60).toString().padLeft(2, '0');
  return '$m:$s';
}

String _groupLabel(DateTime dt) {
  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);
  final yesterday = today.subtract(const Duration(days: 1));
  final day = DateTime(dt.year, dt.month, dt.day);
  if (day == today) return 'Today';
  if (day == yesterday) return 'Yesterday';
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
  return '${['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'][dt.weekday - 1]} ${dt.day} ${months[dt.month - 1]}';
}

// ─────────────────── CallHistoryScreen ───────────────────────────────

class CallHistoryScreen extends StatelessWidget {
  const CallHistoryScreen({super.key});

  void _openSummary(BuildContext context, CallRecord record) {
    context.push(
      '/summary',
      extra: {
        'transcript': null,
        'scenario': record.scenarioName,
        'summary': record.fullSummary,
        'callDuration': record.duration.inSeconds,
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F9FE),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF7F9FE),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF006684)),
          onPressed: () => context.go('/'),
          tooltip: 'Back to Home',
        ),
        title: const Text(
          'VoiceBridge',
          style: TextStyle(
            color: Color(0xFF006684),
            fontSize: 22,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
      body: StreamBuilder<List<CallRecord>>(
        stream: FirestoreService.instance.callsStream(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(color: Color(0xFF006684)),
            );
          }
          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.cloud_off,
                      size: 64,
                      color: Color(0xFF70787E),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Could not load history\n${snapshot.error}',
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 16,
                        color: Color(0xFF3F484D),
                      ),
                    ),
                  ],
                ),
              ),
            );
          }

          final records = snapshot.data ?? [];

          if (records.isEmpty) {
            return _buildEmptyState();
          }

          return _buildList(context, records);
        },
      ),
    );
  }

  // ── empty state ──────────────────────────────────────────────────────

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 48),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 96,
              height: 96,
              decoration: BoxDecoration(
                color: const Color(0xFFE0E3E7),
                borderRadius: BorderRadius.circular(28),
              ),
              child: const Icon(
                Icons.history,
                size: 48,
                color: Color(0xFF70787E),
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'No calls yet',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w800,
                color: Color(0xFF181C1F),
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              'Your call history will appear here.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16,
                color: Color(0xFF3F484D),
                height: 1.5,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── grouped list ─────────────────────────────────────────────────────

  Widget _buildList(BuildContext context, List<CallRecord> records) {
    // Group by date label
    final Map<String, List<CallRecord>> groups = {};
    for (final r in records) {
      final label = _groupLabel(r.timestamp);
      groups.putIfAbsent(label, () => []).add(r);
    }

    return ListView(
      padding: const EdgeInsets.fromLTRB(24, 8, 24, 40),
      children: [
        const Text(
          'Call History',
          style: TextStyle(
            fontSize: 32,
            fontWeight: FontWeight.w800,
            color: Color(0xFF004D64),
            height: 1.2,
          ),
        ),
        const SizedBox(height: 6),
        const Text(
          'Review your previous voice-assisted conversations.',
          style: TextStyle(
            fontSize: 15,
            color: Color(0xFF3F484D),
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 28),
        for (final entry in groups.entries) ...[
          _buildGroupHeader(entry.key),
          const SizedBox(height: 12),
          ...entry.value.map(
            (r) => Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: _CallRecordCard(
                record: r,
                onTap: () => _openSummary(context, r),
              ),
            ),
          ),
          const SizedBox(height: 16),
        ],
      ],
    );
  }

  Widget _buildGroupHeader(String label) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          decoration: BoxDecoration(
            color: const Color(0xFFE0E3E7),
            borderRadius: BorderRadius.circular(24),
          ),
          child: Text(
            label.toUpperCase(),
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: Color(0xFF3F484D),
              letterSpacing: 1.2,
            ),
          ),
        ),
        const SizedBox(width: 12),
        const Expanded(
          child: Divider(height: 1, thickness: 0.5, color: Color(0xFFE5E8ED)),
        ),
      ],
    );
  }
}

// ─────────────────── _CallRecordCard ──────────────────────────────────

class _CallRecordCard extends StatelessWidget {
  final CallRecord record;
  final VoidCallback onTap;

  const _CallRecordCard({required this.record, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label:
          '${record.scenarioName}, ${_formatDuration(record.duration)}, '
          '${_formatDateTime(record.timestamp)}. ${record.summaryExcerpt}',
      button: true,
      child: Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(24),
          child: Container(
            constraints: const BoxConstraints(minHeight: 56),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 24,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                children: [
                  // Scenario icon
                  Container(
                    width: 64,
                    height: 64,
                    decoration: BoxDecoration(
                      color: _scenarioIconBg(record.scenarioIcon),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Icon(
                      _scenarioIcon(record.scenarioIcon),
                      color: _scenarioIconFg(record.scenarioIcon),
                      size: 32,
                    ),
                  ),
                  const SizedBox(width: 20),

                  // Text content
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Text(
                                record.scenarioName,
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w700,
                                  color: Color(0xFF004D64),
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            Text(
                              '${record.timestamp.hour.toString().padLeft(2, '0')}:${record.timestamp.minute.toString().padLeft(2, '0')}',
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF70787E),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            const Icon(
                              Icons.call,
                              size: 12,
                              color: Color(0xFF70787E),
                            ),
                            const SizedBox(width: 4),
                            Text(
                              record.scenarioName,
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w500,
                                color: Color(0xFF70787E),
                              ),
                            ),
                            const SizedBox(width: 6),
                            Container(
                              width: 4,
                              height: 4,
                              decoration: const BoxDecoration(
                                color: Color(0xFFBFC8CD),
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 6),
                            const Icon(
                              Icons.schedule,
                              size: 12,
                              color: Color(0xFF70787E),
                            ),
                            const SizedBox(width: 4),
                            Text(
                              _formatDuration(record.duration),
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w500,
                                color: Color(0xFF70787E),
                              ),
                            ),
                            if (record.isSimulated) ...[  
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFE0E3E7),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: const Text(
                                  'Simulé',
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF3F484D),
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          '"${record.summaryExcerpt}"',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 13,
                            fontStyle: FontStyle.italic,
                            color: Color(0xFF3F484D),
                            height: 1.4,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  const Icon(
                    Icons.chevron_right,
                    color: Color(0xFFBEE9FF),
                    size: 24,
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

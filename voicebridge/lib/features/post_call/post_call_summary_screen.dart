import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../models/call_record.dart';
import '../../models/transcript_line.dart';
import '../../services/firestore_service.dart';

// ─── Scenario icon helper (shared with history) ───────────────────────────────
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

String _iconKeyForScenario(String scenario) {
  final s = scenario.toLowerCase();
  if (s.contains('food') || s.contains('order') || s.contains('restaurant')) {
    return 'restaurant';
  } else if (s.contains('delivery') || s.contains('shipping')) {
    return 'local_taxi';
  } else if (s.contains('appointment') || s.contains('book')) {
    return 'medical_services';
  } else if (s.contains('grocery') || s.contains('shopping')) {
    return 'shopping_basket';
  }
  return 'phone';
}

// ─── Duration formatter ───────────────────────────────────────────────────────
String _formatDuration(int seconds) {
  final m = seconds ~/ 60;
  final s = seconds % 60;
  if (m == 0) return '$s sec';
  if (s == 0) return '$m min';
  return '$m min $s sec';
}

// ─── Action line extractor ────────────────────────────────────────────────────
List<String> _extractActions(String summary) {
  return summary
      .split('\n')
      .where((l) => l.trim().toLowerCase().startsWith('action:'))
      .map((l) => l.replaceFirst(RegExp(r'action:\s*', caseSensitive: false), '').trim())
      .where((l) => l.isNotEmpty)
      .toList();
}

String _summaryWithoutActions(String summary) {
  return summary
      .split('\n')
      .where((l) => !l.trim().toLowerCase().startsWith('action:'))
      .join('\n')
      .trim();
}

// ─── PostCallSummaryScreen ────────────────────────────────────────────────────
class PostCallSummaryScreen extends StatefulWidget {
  final List<TranscriptLine>? transcript;
  final String? scenario;
  final String? summary;
  final int? duration;

  const PostCallSummaryScreen({
    super.key,
    this.transcript,
    this.scenario,
    this.summary,
    this.duration,
  });

  @override
  State<PostCallSummaryScreen> createState() => _PostCallSummaryScreenState();
}

class _PostCallSummaryScreenState extends State<PostCallSummaryScreen> {
  bool _saving = false;
  bool _transcriptExpanded = false;

  static const _purple = Color(0xFF534AB7);
  static const _lightPurple = Color(0xFFEEEDFE);

  String get _scenario => widget.scenario ?? 'Appel';
  String get _summary => widget.summary ?? 'Appel terminé.';
  int get _durationSecs => widget.duration ?? 0;
  List<TranscriptLine> get _transcript => widget.transcript ?? [];

  // ── Derived
  List<String> get _actions => _extractActions(_summary);
  String get _cleanSummary => _summaryWithoutActions(_summary);

  String get _summaryExcerpt {
    final text = _cleanSummary;
    return text.length > 100 ? '${text.substring(0, 97)}...' : text;
  }

  Future<void> _save() async {
    if (_saving) return;
    setState(() => _saving = true);
    try {
      final record = CallRecord(
        id: '',
        timestamp: DateTime.now(),
        scenarioIcon: _iconKeyForScenario(_scenario),
        scenarioName: _scenario,
        phoneNumberCalled: 'Agent IA',
        duration: Duration(seconds: _durationSecs),
        summaryExcerpt: _summaryExcerpt,
        fullSummary: _summary,
        isSimulated: true,
      );
      await FirestoreService.instance.saveCall(record);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Appel sauvegardé dans l\'historique'),
          backgroundColor: Color(0xFF004D64),
          duration: Duration(seconds: 2),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erreur: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
    if (mounted) context.go('/');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F9FE),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF7F9FE),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: _purple),
          onPressed: () => context.go('/'),
        ),
        title: const Text(
          'VoiceBridge',
          style: TextStyle(
            color: _purple,
            fontSize: 22,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // ── Success banner ────────────────────────────────────────────────
            Container(
              height: 140,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [_purple, Color(0xFF3B33A0)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(24),
              ),
              child: const Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.check_circle, color: Colors.white, size: 52),
                  SizedBox(height: 10),
                  Text(
                    'Appel terminé',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // ── Section 1: Call info card ─────────────────────────────────────
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 20,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: _lightPurple,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Icon(
                      _iconForScenario(_scenario),
                      color: _purple,
                      size: 28,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _scenario,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF181C1F),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Durée : ${_formatDuration(_durationSecs)}',
                          style: const TextStyle(
                            fontSize: 14,
                            color: Color(0xFF3F484D),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: const Color(0xFFE0E3E7),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: const Text(
                      'Appel simulé',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF3F484D),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // ── Section 2: Summary card ───────────────────────────────────────
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.04),
                    blurRadius: 16,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 4,
                        height: 22,
                        decoration: BoxDecoration(
                          color: _purple,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                      const SizedBox(width: 10),
                      const Text(
                        'Résumé de l\'appel',
                        style: TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF181C1F),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF7F9FE),
                      borderRadius: BorderRadius.circular(14),
                      border: Border(
                        left: BorderSide(color: _purple.withValues(alpha: 0.4), width: 3),
                      ),
                    ),
                    child: Text(
                      _cleanSummary,
                      style: const TextStyle(
                        fontSize: 15,
                        color: Color(0xFF3F484D),
                        height: 1.6,
                      ),
                    ),
                  ),
                  // Actions list
                  if (_actions.isNotEmpty) ...[
                    const SizedBox(height: 16),
                    const Text(
                      'Actions',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF181C1F),
                      ),
                    ),
                    const SizedBox(height: 8),
                    ..._actions.map(
                      (action) => Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Icon(Icons.check_circle,
                                color: Colors.green, size: 20),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                action,
                                style: const TextStyle(
                                  fontSize: 14,
                                  color: Color(0xFF3F484D),
                                  height: 1.4,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 20),

            // ── Section 3: Transcript accordion ──────────────────────────────
            if (_transcript.isNotEmpty)
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.04),
                      blurRadius: 16,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    InkWell(
                      onTap: () => setState(
                          () => _transcriptExpanded = !_transcriptExpanded),
                      borderRadius: BorderRadius.circular(20),
                      child: Padding(
                        padding: const EdgeInsets.all(20),
                        child: Row(
                          children: [
                            const Icon(Icons.chat_bubble_outline,
                                color: _purple, size: 20),
                            const SizedBox(width: 10),
                            const Expanded(
                              child: Text(
                                'Voir la transcription complète',
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.bold,
                                  color: _purple,
                                ),
                              ),
                            ),
                            Icon(
                              _transcriptExpanded
                                  ? Icons.expand_less
                                  : Icons.expand_more,
                              color: _purple,
                            ),
                          ],
                        ),
                      ),
                    ),
                    if (_transcriptExpanded) ...[
                      const Divider(height: 1, thickness: 0.5),
                      Padding(
                        padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
                        child: Column(
                          children: _transcript.map((line) {
                            final isAgent = line.speaker == 'agent';
                            return Padding(
                              padding: const EdgeInsets.only(bottom: 12),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 8, vertical: 3),
                                    decoration: BoxDecoration(
                                      color: isAgent ? _lightPurple : const Color(0xFFE0E3E7),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Text(
                                      isAgent ? 'Sarra' : 'Caller',
                                      style: TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.bold,
                                        color: isAgent ? _purple : const Color(0xFF3F484D),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Text(
                                      line.text,
                                      style: TextStyle(
                                        fontSize: 14,
                                        color: isAgent ? _purple : const Color(0xFF3F484D),
                                        height: 1.5,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            );
                          }).toList(),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            const SizedBox(height: 28),

            // ── Section 4: Action buttons ─────────────────────────────────────
            SizedBox(
              height: 60,
              child: ElevatedButton.icon(
                onPressed: _saving ? null : _save,
                icon: _saving
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: Colors.white),
                      )
                    : const Icon(Icons.save, color: Colors.white),
                label: Text(
                  _saving ? 'Sauvegarde...' : 'Sauvegarder',
                  style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: _purple,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  elevation: 2,
                ),
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              height: 60,
              child: OutlinedButton.icon(
                onPressed: () => context.go('/'),
                icon: const Icon(Icons.add_call, color: _purple),
                label: const Text(
                  'Nouvel appel',
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                    color: _purple,
                  ),
                ),
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: _purple, width: 2),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 32),

            // ── Safety notice ─────────────────────────────────────────────────
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFFFFDAD6),
                borderRadius: BorderRadius.circular(14),
              ),
              child: const Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.report_problem,
                      color: Color(0xFF93000A), size: 22),
                  SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Cet appel était entièrement simulé par l\'IA. '
                      'Aucune vraie communication téléphonique n\'a eu lieu.',
                      style: TextStyle(
                        fontSize: 13,
                        color: Color(0xFF93000A),
                        height: 1.4,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

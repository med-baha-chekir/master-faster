import 'dart:async';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../models/transcript_line.dart';
import '../../services/simulated_call_service.dart';
import '../../services/tts_service.dart';
import '../../exceptions/simulated_call_exception.dart';

class LiveCallScreen extends StatefulWidget {
  final String? scenario;
  final String? userName;
  final String? userAddress;
  final String language;

  const LiveCallScreen({
    super.key,
    this.scenario,
    this.userName,
    this.userAddress,
    this.language = 'fr',
  });

  @override
  State<LiveCallScreen> createState() => _LiveCallScreenState();
}

class _LiveCallScreenState extends State<LiveCallScreen> {
  final ScrollController _scrollController = ScrollController();
  final SimulatedCallService _callService = SimulatedCallService();
  final TTSService _ttsService = TTSService();

  List<TranscriptLine> transcript = [];
  List<String> responseCards = [];
  
  bool isAgentSpeaking = false;
  bool isCallerSpeaking = false;
  bool isLoading = true;
  bool isCallEnded = false;
  
  String loadingMessage = 'Démarrage de l\'appel...';
  String? activeCallSessionId;
  
  Timer? callTimer;
  int callSeconds = 0;

  @override
  void initState() {
    super.initState();
    callTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!isCallEnded) {
        setState(() => callSeconds++);
      }
    });

    _initCall();
  }

  Future<void> _initCall() async {
    try {
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(FirebaseAuth.instance.currentUser?.uid)
          .get();

      String finalUserName = 'Utilisateur';
      String finalUserAddress = 'Adresse non renseignée';

      if (doc.exists) {
        final data = doc.data()!;
        finalUserName = data['fullName'] as String? ?? 'Utilisateur';
        finalUserAddress = data['homeAddress'] as String? ?? 'Adresse non renseignée';
      }

      if (widget.userName != null && widget.userName != 'Utilisateur') {
        finalUserName = widget.userName!;
      }
      if (widget.userAddress != null && widget.userAddress != 'Adresse inconnue') {
        finalUserAddress = widget.userAddress!;
      }

      // ── Step 1: Start call — get agentLine, receiverFirstReply, cards ──────
      final result = await _callService.startCall(
        scenario: widget.scenario ?? 'Contact',
        userName: finalUserName,
        userAddress: finalUserAddress,
        language: widget.language,
      );

      if (!mounted) return;

      // ── Step 2: Add agentLine to transcript and hide loading overlay ────────
      setState(() {
        activeCallSessionId = result.sessionId;
        transcript.add(TranscriptLine(
          speaker: 'agent',
          text: result.agentLine,
          timestamp: DateTime.now(),
        ));
        isLoading = false;
        isAgentSpeaking = true;
      });

      _scrollToBottom();

      // ── Step 3: Play agentLine with agent TTS voice ─────────────────────────
      final agentVoiceId = dotenv.env['ELEVENLABS_AGENT_VOICE_ID'];
      await _ttsService.speak(result.agentLine,
          language: widget.language, voiceId: agentVoiceId);

      if (!mounted || isCallEnded) return;

      setState(() => isAgentSpeaking = false);
      await Future.delayed(const Duration(milliseconds: 400));
      if (!mounted || isCallEnded) return;

      // ── Step 4: Add receiverFirstReply to transcript ────────────────────────
      setState(() {
        isCallerSpeaking = true;
        transcript.add(TranscriptLine(
          speaker: 'caller',
          text: result.receiverFirstReply,
          timestamp: DateTime.now(),
        ));
      });

      _scrollToBottom();

      // ── Step 5: Play receiverFirstReply with caller TTS voice ───────────────
      final callerVoiceId = dotenv.env['ELEVENLABS_CALLER_VOICE_ID'];
      await _ttsService.speak(result.receiverFirstReply,
          language: widget.language, voiceId: callerVoiceId);

      if (!mounted || isCallEnded) return;

      // ── Step 6: Show response cards — user is ready to tap ──────────────────
      setState(() {
        isCallerSpeaking = false;
        responseCards = result.responseCards;
      });

    } on SimulatedCallException catch (e) {
      if (!mounted) return;
      _showErrorDialog(e.message);
    } catch (e) {
      if (!mounted) return;
      _showErrorDialog(e.toString());
    }
  }

  Future<void> _onCardTapped(String cardText) async {
    if (isCallEnded || isLoading) return;

    setState(() {
      responseCards = [];
      isAgentSpeaking = true;
    });

    try {
      final result = await _callService.sendUserChoice(cardText);
      if (!mounted || isCallEnded) return;

      if (result.agentSentence.isNotEmpty) {
        setState(() {
          transcript.add(
            TranscriptLine(
              speaker: 'agent',
              text: result.agentSentence,
              timestamp: DateTime.now(),
            ),
          );
        });
        
        _scrollToBottom();

        String? agentVoiceId = dotenv.env['ELEVENLABS_AGENT_VOICE_ID'];
        await _ttsService.speak(result.agentSentence, language: widget.language, voiceId: agentVoiceId);
      }

      if (!mounted || isCallEnded) return;

      setState(() {
        isAgentSpeaking = false;
      });

      await Future.delayed(const Duration(milliseconds: 300));
      if (!mounted || isCallEnded) return;

      setState(() {
        isCallerSpeaking = true;
        transcript.add(
          TranscriptLine(
            speaker: 'caller',
            text: result.callerReply,
            timestamp: DateTime.now(),
          ),
        );
      });
      
      _scrollToBottom();

      String? callerVoiceId = dotenv.env['ELEVENLABS_CALLER_VOICE_ID'];
      await _ttsService.speak(result.callerReply, language: widget.language, voiceId: callerVoiceId);

      if (!mounted || isCallEnded) return;

      setState(() {
        isCallerSpeaking = false;
      });

      if (result.callComplete) {
        await Future.delayed(const Duration(seconds: 1));
        if (mounted) {
          _endCall();
        }
      } else {
        setState(() {
          responseCards = result.responseCards;
        });
      }
      
    } on SimulatedCallException catch (e) {
      if (!mounted) return;
      _showErrorDialog(e.message);
      setState(() {
        isAgentSpeaking = false;
        responseCards = ['Bonjour', 'Allô ?', 'Oui ?'];
      });
    } catch (e) {
      if (!mounted) return;
      _showErrorDialog('Erreur inattendue: $e');
      setState(() {
        isAgentSpeaking = false;
        responseCards = ['Bonjour', 'Allô ?', 'Oui ?'];
      });
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _endCall() async {
    callTimer?.cancel();
    setState(() {
      isCallEnded = true;
    });

    try {
      final summary = await _callService.getCallSummary();
      await _callService.endCall();
      
      if (!mounted) return;
      
      context.pushReplacement(
        '/summary',
        extra: {
          'transcript': transcript,
          'summary': summary,
          'callDuration': callSeconds,
          'scenario': widget.scenario,
        },
      );
    } catch (e) {
      if (!mounted) return;
      context.pushReplacement(
        '/summary',
        extra: {
          'transcript': transcript,
          'summary': 'Appel terminé.',
          'callDuration': callSeconds,
          'scenario': widget.scenario,
        },
      );
    }
  }

  void _showErrorDialog(String msg) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('Erreur'),
        content: Text(msg),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              if (mounted) context.pop();
            },
            child: const Text('Retour'),
          ),
        ],
      ),
    );
  }

  void _showCustomReplySheet() {
    final TextEditingController fieldCtrl = TextEditingController();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
      ),
      builder: (context) {
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
            left: 24,
            right: 24,
            top: 24,
          ),
          child: SafeArea(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'Réponse personnalisée',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF004D64),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: fieldCtrl,
                  autofocus: true,
                  decoration: InputDecoration(
                    hintText: 'Tapez votre message...',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  onSubmitted: (val) {
                    Navigator.pop(context);
                    if (val.trim().isNotEmpty) {
                      _onCardTapped(val.trim());
                    }
                  },
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF006684),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(28),
                      ),
                    ),
                    onPressed: () {
                      final val = fieldCtrl.text;
                      Navigator.pop(context);
                      if (val.trim().isNotEmpty) {
                        _onCardTapped(val.trim());
                      }
                    },
                    child: const Text(
                      'Envoyer',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
              ],
            ),
          ),
        );
      },
    );
  }

  String get _formattedTime {
    final minutes = (callSeconds / 60).floor().toString().padLeft(2, '0');
    final seconds = (callSeconds % 60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }

  @override
  void dispose() {
    callTimer?.cancel();
    _scrollController.dispose();
    _ttsService.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F9FE),
      appBar: AppBar(
        automaticallyImplyLeading: false,
        backgroundColor: const Color(0xFFF1F4F8),
        elevation: 0,
        title: Row(
          children: [
            Text(
              _formattedTime,
              style: const TextStyle(
                color: Color(0xFF006684),
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const Spacer(),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Text(
                'Appel simulé',
                style: TextStyle(
                  color: Colors.black87,
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const Spacer(),
          ],
        ),
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 16),
            constraints: const BoxConstraints(minWidth: 56, minHeight: 56),
            child: Semantics(
              label: 'End call',
              button: true,
              child: ElevatedButton(
                onPressed: _endCall,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFBA1A1A),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  elevation: 0,
                ),
                child: const Icon(Icons.call_end, color: Colors.white, size: 24),
              ),
            ),
          ),
        ],
      ),
      body: Stack(
        children: [
          Column(
            children: [
              // Transcript panel (upper 55%)
              Expanded(
                flex: 55,
                child: ListView.builder(
                  controller: _scrollController,
                  padding: const EdgeInsets.all(24.0),
                  itemCount: transcript.length,
                  itemBuilder: (context, index) {
                    final line = transcript[index];
                    final isAI = line.speaker == 'agent';

                    return Padding(
                      padding: const EdgeInsets.only(bottom: 24.0),
                      child: Column(
                        crossAxisAlignment: isAI
                            ? CrossAxisAlignment.start
                            : CrossAxisAlignment.end,
                        children: [
                          Text(
                            isAI ? 'Sarra:' : 'Correspondant:',
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF3F484D),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: isAI
                                  ? const Color(0xFFE8DEF8) // Purple-ish
                                  : const Color(0xFFE0E3E7), // Gray
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Column(
                              crossAxisAlignment: isAI 
                                ? CrossAxisAlignment.start 
                                : CrossAxisAlignment.end,
                              children: [
                                Text(
                                  line.text,
                                  style: const TextStyle(
                                    fontSize: 18,
                                    color: Color(0xFF181C1F),
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  '${line.timestamp.hour.toString().padLeft(2, '0')}:${line.timestamp.minute.toString().padLeft(2, '0')}',
                                  style: const TextStyle(
                                    fontSize: 10,
                                    color: Colors.black54,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),

              // Speaking indicator (between transcript and cards)
              if (isAgentSpeaking || isCallerSpeaking)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 16.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        width: 12,
                        height: 12,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: isAgentSpeaking 
                            ? Colors.purple 
                            : Colors.grey,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        isAgentSpeaking ? 'Sarra parle...' : 'Correspondant parle...',
                        style: TextStyle(
                          color: isAgentSpeaking ? Colors.purple : Colors.grey.shade700,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),

              // Response cards panel (lower 40%)
              if (responseCards.isNotEmpty && !isAgentSpeaking && !isCallerSpeaking)
                Expanded(
                  flex: 40,
                  child: Container(
                    padding: const EdgeInsets.all(24),
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.only(
                        topLeft: Radius.circular(32),
                        topRight: Radius.circular(32),
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black12,
                          blurRadius: 10,
                          offset: Offset(0, -2),
                        )
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const Text(
                          'Votre réponse:',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: Colors.black54,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Expanded(
                          child: ListView.separated(
                            itemCount: responseCards.length,
                            separatorBuilder: (context, index) => const SizedBox(height: 12),
                            itemBuilder: (context, index) {
                              final card = responseCards[index];
                              return InkWell(
                                onTap: () => _onCardTapped(card),
                                borderRadius: BorderRadius.circular(16),
                                child: Container(
                                  constraints: const BoxConstraints(minHeight: 64),
                                  padding: const EdgeInsets.all(16),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(16),
                                    border: Border.all(
                                      color: Colors.purple.shade200,
                                      width: 2,
                                    ),
                                  ),
                                  alignment: Alignment.center,
                                  child: Text(
                                    card,
                                    textAlign: TextAlign.center,
                                    style: const TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.black87,
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                        TextButton(
                          onPressed: _showCustomReplySheet,
                          child: const Text(
                            'Répondre autrement',
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.purple,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),

          // Loading overlay
          if (isLoading)
            Container(
              color: Colors.black54,
              child: Center(
                child: Card(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(32.0),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const CircularProgressIndicator(),
                        const SizedBox(height: 24),
                        Text(
                          loadingMessage,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

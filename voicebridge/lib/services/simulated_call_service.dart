import 'dart:async';
import 'dart:convert';
import 'dart:io';


import 'package:http/http.dart' as http;
import '../core/api_client.dart';

import '../exceptions/simulated_call_exception.dart';
import '../models/simulated_call_result.dart';

class SimulatedCallService {
  final String _baseUrl = baseUrl;
  String? _currentSessionId;
  
  String? get currentSessionId => _currentSessionId;

  Future<SimulatedCallStartResult> startCall({
    required String scenario,
    required String userName,
    required String userAddress,
    String language = 'fr',
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/simulate-call-start'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'scenario': scenario,
          'userName': userName,
          'userAddress': userAddress,
          'language': language,
        }),
      ).timeout(const Duration(seconds: 15));
      
      if (response.statusCode != 200) {
        throw SimulatedCallException('Failed to start call');
      }
      
      final data = jsonDecode(response.body);
      _currentSessionId = data['sessionId'] as String;

      return SimulatedCallStartResult(
        sessionId: _currentSessionId!,
        agentLine: data['agentLine'] as String,
        receiverFirstReply: data['receiverFirstReply'] as String,
        responseCards: (data['responseCards'] as List).cast<String>(),
      );
    } on SocketException {
      throw SimulatedCallException('Pas de connexion internet');
    } on TimeoutException {
      throw SimulatedCallException('Le serveur ne répond pas');
    }
  }

  Future<SimulatedCallTurnResult> sendUserChoice(
    String userChoice
  ) async {
    if (_currentSessionId == null) {
      throw SimulatedCallException('No active call session');
    }
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/simulate-caller-response'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'sessionId': _currentSessionId,
          'userChoice': userChoice,
        }),
      ).timeout(const Duration(seconds: 20));
      
      final data = jsonDecode(response.body);
      return SimulatedCallTurnResult(
        agentSentence: data['agentSentence'] as String,
        callerReply: data['callerReply'] as String,
        responseCards: (data['responseCards'] as List)
          .cast<String>(),
        callComplete: data['callComplete'] as bool,
        turn: data['turn'] as int,
      );
    } on SocketException {
      throw SimulatedCallException('Pas de connexion internet');
    } on TimeoutException {
      throw SimulatedCallException('Réponse trop lente');
    }
  }

  Future<List<Map<String, String>>> endCall() async {
    if (_currentSessionId == null) return [];
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/simulate-call-end'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'sessionId': _currentSessionId}),
      );
      final data = jsonDecode(response.body);
      _currentSessionId = null;
      return (data['transcript'] as List)
        .map((e) => Map<String, String>.from(e as Map))
        .toList();
    } catch (_) {
      _currentSessionId = null;
      return [];
    }
  }

  Future<String> getCallSummary() async {
    if (_currentSessionId == null) return 'Appel terminé.';
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/simulate-summary'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'sessionId': _currentSessionId}),
      );
      final data = jsonDecode(response.body);
      return data['summary'] as String;
    } catch (_) {
      return 'Appel terminé.';
    }
  }
}

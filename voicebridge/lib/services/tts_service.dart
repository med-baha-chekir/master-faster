import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import '../core/api_client.dart';
import 'audio_player_interface.dart';
import 'audio_player_stub.dart'
    if (dart.library.html) 'audio_player_web.dart'
    if (dart.library.io) 'audio_player_mobile.dart';

class TTSService {
  PlatformAudioPlayer? _player;

  Future<void> speak(String text, {String language = 'fr', String? voiceId}) async {
    try {
      // Call backend /speak endpoint
      final response = await http.post(
        Uri.parse('$baseUrl/speak'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'text': text, 
          'language': language,
          if (voiceId != null) 'voiceId': voiceId,
        }),
      );
      if (response.statusCode != 200) throw Exception('TTS failed');

      // Play the audio bytes using the platform-specific player
      _player ??= getPlatformAudioPlayer();
      await _player!.playAudioBytes(response.bodyBytes);

    } catch (e) {
      debugPrint('TTS error: $e');
      // Fail silently — call continues without audio
    }
  }

  Future<void> stopSpeaking() async {
    await _player?.stop();
    _player?.dispose();
    _player = null;
  }

  void dispose() {
    _player?.dispose();
    _player = null;
  }
}

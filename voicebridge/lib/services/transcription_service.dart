import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

class TranscriptionService {
  WebSocketChannel? _channel;
  StreamController<String>? _transcriptController;

  Stream<String> startStreaming(Stream<Uint8List> audioStream) {
    _transcriptController = StreamController<String>.broadcast();

    final wsUrl = Uri.parse(
      'wss://api.deepgram.com/v1/listen'
      '?model=nova-3'
      '&language=fr'
      '&encoding=linear16'
      '&sample_rate=16000'
      '&punctuate=true'
      '&smart_format=true'
      '&interim_results=false'
      '&endpointing=500',
    );

    _channel = WebSocketChannel.connect(
      wsUrl,
      protocols: ['token', dotenv.env['DEEPGRAM_API_KEY']!],
    );

    // Send audio chunks to Deepgram
    audioStream.listen(
      (audioChunk) => _channel?.sink.add(audioChunk),
      onDone: () => _channel?.sink.close(),
    );

    // Listen to transcript results
    _channel!.stream.listen(
      (message) {
        try {
          final json = jsonDecode(message as String);
          final transcript =
              json['channel']?['alternatives']?[0]?['transcript'] as String?;
          if (transcript != null && transcript.trim().isNotEmpty) {
            _transcriptController?.add(transcript.trim());
          }
        } catch (e) {
          debugPrint('Deepgram parse error: $e');
        }
      },
      onError: (error) {
        debugPrint('Deepgram WebSocket error: $error');
        // Retry with nova-2-phonecall fallback
        _retryWithFallback(audioStream);
      },
      onDone: () => _transcriptController?.close(),
    );

    return _transcriptController!.stream;
  }

  void _retryWithFallback(Stream<Uint8List> audioStream) {
    debugPrint('Retrying with nova-2-phonecall fallback');
    final fallbackUrl = Uri.parse(
      'wss://api.deepgram.com/v1/listen'
      '?model=nova-2-phonecall'
      '&language=fr'
      '&encoding=linear16'
      '&sample_rate=16000'
      '&punctuate=true'
      '&interim_results=false',
    );
    _channel = WebSocketChannel.connect(
      fallbackUrl,
      protocols: ['token', dotenv.env['DEEPGRAM_API_KEY']!],
    );
    audioStream.listen((chunk) => _channel?.sink.add(chunk));
    _channel!.stream.listen((message) {
      try {
        final json = jsonDecode(message as String);
        final transcript =
            json['channel']?['alternatives']?[0]?['transcript'] as String?;
        if (transcript != null && transcript.trim().isNotEmpty) {
          _transcriptController?.add(transcript.trim());
        }
      } catch (_) {}
    });
  }

  Future<void> stopStreaming() async {
    await _channel?.sink.close();
    await _transcriptController?.close();
    _channel = null;
    _transcriptController = null;
  }
}

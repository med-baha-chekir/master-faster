// ignore: avoid_web_libraries_in_flutter
import 'dart:html' as html;
import 'dart:async';
import 'dart:convert';
import 'audio_player_interface.dart';

class WebAudioPlayer implements PlatformAudioPlayer {
  html.AudioElement? _audio;

  @override
  Future<void> playAudioBytes(List<int> bytes) async {
    final completer = Completer<void>();
    final base64String = base64Encode(bytes);
    final dataUri = 'data:audio/mpeg;base64,$base64String';
    
    _audio?.pause();
    _audio?.remove();
    
    _audio = html.AudioElement(dataUri);
    
    _audio!.onEnded.listen((_) {
      if (!completer.isCompleted) completer.complete();
    });
    
    _audio!.onError.listen((_) {
      if (!completer.isCompleted) completer.completeError('Audio playback error');
    });
    
    _audio!.play();
    return completer.future;
  }

  @override
  Future<void> stop() async {
    _audio?.pause();
    _audio?.remove();
    _audio = null;
  }

  @override
  void dispose() {
    stop();
  }
}

PlatformAudioPlayer getPlatformAudioPlayer() => WebAudioPlayer();

import 'dart:io';
import 'package:just_audio/just_audio.dart';
import 'package:path_provider/path_provider.dart';
import 'audio_player_interface.dart';

class MobileAudioPlayer implements PlatformAudioPlayer {
  AudioPlayer? _player;

  @override
  Future<void> playAudioBytes(List<int> bytes) async {
    final dir = await getTemporaryDirectory();
    final file = File('${dir.path}/tts_output.mp3');
    await file.writeAsBytes(bytes);

    _player ??= AudioPlayer();
    await _player!.setFilePath(file.path);
    await _player!.play();

    await _player!.processingStateStream.firstWhere(
      (state) => state == ProcessingState.completed,
    );
  }

  @override
  Future<void> stop() async {
    await _player?.stop();
  }

  @override
  void dispose() {
    _player?.dispose();
    _player = null;
  }
}

PlatformAudioPlayer getPlatformAudioPlayer() => MobileAudioPlayer();

import 'dart:async';
import 'dart:typed_data';
import 'package:record/record.dart';
import 'package:permission_handler/permission_handler.dart';

class MicrophoneService {
  final _recorder = AudioRecorder();
  StreamController<Uint8List>? _audioController;

  Future<bool> requestPermission() async {
    final status = await Permission.microphone.request();
    return status == PermissionStatus.granted;
  }

  Future<Stream<Uint8List>> startRecording() async {
    _audioController = StreamController<Uint8List>();
    await _recorder
        .startStream(
          const RecordConfig(
            encoder: AudioEncoder.pcm16bits,
            sampleRate: 16000,
            numChannels: 1,
          ),
        )
        .then((stream) {
          stream.listen(
            (data) => _audioController?.add(data),
            onError: (e) => _audioController?.addError(e),
            onDone: () => _audioController?.close(),
          );
        });
    return _audioController!.stream;
  }

  Future<void> stopRecording() async {
    await _recorder.stop();
    await _audioController?.close();
    _audioController = null;
  }

  void dispose() {
    _recorder.dispose();
    _audioController?.close();
  }
}

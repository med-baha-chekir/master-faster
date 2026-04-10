import 'audio_player_interface.dart';

PlatformAudioPlayer getPlatformAudioPlayer() => throw UnsupportedError('Cannot create an audio player without dart:html or dart:io');

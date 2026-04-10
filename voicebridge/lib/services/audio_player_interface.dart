abstract class PlatformAudioPlayer {
  Future<void> playAudioBytes(List<int> bytes);
  Future<void> stop();
  void dispose();
}

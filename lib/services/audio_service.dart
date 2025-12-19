import 'package:audioplayers/audioplayers.dart';

class AudioService {
  final AudioPlayer _player = AudioPlayer();

  /// 🔊 Play audio from assets
  Future<void> playAsset(String assetPath) async {
    try {
      await _player.stop();

      // Remove "assets/" because AssetSource already points to assets folder
      final cleanPath = assetPath.replaceFirst('assets/', '');

      await _player.play(AssetSource(cleanPath));
    } catch (e) {
      print("Audio error: $e");
    }
  }

  /// 🔊 Play audio if JSON has audio path
  Future<void> playFromJson(dynamic audio) async {
    if (audio == null) return;

    if (audio is String) {
      await playAsset(audio);
    }
  }
}

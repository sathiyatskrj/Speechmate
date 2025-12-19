import 'package:audioplayers/audioplayers.dart';

class AudioService {
  final AudioPlayer _player = AudioPlayer();

  /// Play audio directly from asset path
  Future<void> playAsset(String assetPath) async {
    await _player.stop();
    await _player.play(AssetSource(
      assetPath.replaceFirst('assets/', ''),
    ));
  }

  /// ✅ NEW METHOD – plays audio from JSON value
  /// JSON format:
  /// "audio": "assets/audio/numbers/one.mp3"
  Future<void> playFromJson(dynamic audio) async {
    if (audio == null) return;

    if (audio is String) {
      await playAsset(audio);
    }
  }
}

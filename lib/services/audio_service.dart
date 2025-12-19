import 'package:audioplayers/audioplayers.dart';

class AudioService {
  final AudioPlayer _player = AudioPlayer();

  /// Plays audio using category + file
  /// Example: { category: "words", file: "tree.mp3" }
  Future<void> play(Map<String, dynamic> audio) async {
    final String category = audio['category'];
    final String file = audio['file'];

    final String path = 'assets/audio/$category/$file';

    await _player.stop();
    await _player.play(AssetSource(path.replaceFirst('assets/', '')));
  }

  /// Plays audio directly from full asset path
  /// Example: assets/audio/phrases/good_morning.mp3
  Future<void> playAsset(String assetPath) async {
    await _player.stop();
    await _player.play(
      AssetSource(assetPath.replaceFirst('assets/', '')),
    );
  }
}

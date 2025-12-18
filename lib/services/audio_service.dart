import 'package:audioplayers/audioplayers.dart';

class AudioService {
  final AudioPlayer _player = AudioPlayer();

  Future<void> play({
    required String category,
    required String file,
  }) async {
    try {
      await _player.stop();
      await _player.play(
        AssetSource('audio/$category/$file.mp3'),
      );
    } catch (e) {
      print('Audio not found: $category/$file');
    }
  }
}

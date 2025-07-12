import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';

class AlarmService {
  final AudioPlayer _audioPlayer = AudioPlayer();

  Future<void> playAlarm(String ringtone) async {
    try {
      await _audioPlayer.setReleaseMode(ReleaseMode.loop);
      await _audioPlayer.play(AssetSource(ringtone.replaceFirst('assets/', '')));
    } catch (e) {
      debugPrint('Error playing alarm: $e');
    }
  }

  Future<void> stopAlarm() async {
    await _audioPlayer.stop();
  }

  void dispose() {
    _audioPlayer.dispose();
  }
}
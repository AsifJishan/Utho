import 'package:audioplayers/audioplayers.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AlarmService {
  final AudioPlayer _audioPlayer = AudioPlayer();
  static const String _ringtoneKey = 'selected_ringtone';
  static const String _alarmStateKey = 'alarm_is_set';

  Future<void> playAlarm(String ringtonePath) async {
    Source source;
    if (ringtonePath.startsWith('/')) {
      source = DeviceFileSource(ringtonePath);
    } else {
      source = AssetSource(ringtonePath.replaceFirst('assets/', ''));
    }
    await _audioPlayer.play(source);
  }

  Future<void> stopAlarm() async {
    await _audioPlayer.stop();
  }

  Future<void> saveRingtone(String ringtonePath) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_ringtoneKey, ringtonePath);
  }

  Future<String?> loadRingtone() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_ringtoneKey);
  }

  Future<void> saveAlarmState(bool isSet) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_alarmStateKey, isSet);
  }

  Future<bool> loadAlarmState() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_alarmStateKey) ?? false;
  }

  void dispose() {
    _audioPlayer.dispose();
  }
}
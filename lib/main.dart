import 'package:flutter/material.dart';
import 'package:audioplayers/audioplayers.dart';
import 'dart:async';
import 'dart:io';
import 'package:permission_handler/permission_handler.dart';

void main() {
  runApp(const AlarmClockApp());
}

class AlarmClockApp extends StatelessWidget {
  const AlarmClockApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Utho',
      theme: ThemeData.dark(
        useMaterial3: true,
      ).copyWith(
        colorScheme: const ColorScheme.dark(
          primary: Colors.white,
          secondary: Colors.grey,
          surface: Colors.black,
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.black,
          foregroundColor: Colors.white,
        ),
      ),
      home: const AlarmClockScreen(),
    );
  }
}

class AlarmClockScreen extends StatefulWidget {
  const AlarmClockScreen({super.key});

  @override
  State<AlarmClockScreen> createState() => _AlarmClockScreenState();
}

class _AlarmClockScreenState extends State<AlarmClockScreen> {
  final AudioPlayer _audioPlayer = AudioPlayer();
  Timer? _timer;
  TimeOfDay? _selectedTime;
  bool _isAlarmSet = false;
  bool _isAlarmRinging = false;
  String _currentTime = '';
  String _selectedRingtone = 'assets/audios/alarm_tone_1.mp3';
  
  final List<String> _ringtones = [
    'assets/audios/alarm_tone_1.mp3',
    'assets/audios/alarm_tone_2.mp3',
    'assets/audios/alarm_tone_3.mp3',
  ];

  @override
  void initState() {
    super.initState();
    _updateCurrentTime();
    _startTimeUpdate();
    _requestPermissions();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _audioPlayer.dispose();
    super.dispose();
  }

  void _requestPermissions() async {
    if (Platform.isAndroid) {
      await Permission.notification.request();
    }
  }

  void _startTimeUpdate() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      _updateCurrentTime();
      _checkAlarm();
    });
  }

  void _updateCurrentTime() {
    final now = DateTime.now();
    setState(() {
      _currentTime = '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}:${now.second.toString().padLeft(2, '0')}';
    });
  }

  void _checkAlarm() {
    if (_isAlarmSet && _selectedTime != null && !_isAlarmRinging) {
      final now = DateTime.now();
      if (now.hour == _selectedTime!.hour && now.minute == _selectedTime!.minute) {
        _triggerAlarm();
      }
    }
  }

  void _triggerAlarm() {
    setState(() {
      _isAlarmRinging = true;
    });
    _playAlarm();
    _showAlarmDialog();
  }

  void _playAlarm() async {
    try {
      await _audioPlayer.setReleaseMode(ReleaseMode.loop);
      await _audioPlayer.play(AssetSource(_selectedRingtone.replaceFirst('assets/', '')));
    } catch (e) {
      print('Error playing alarm: $e');
    }
  }

  void _stopAlarm() async {
    await _audioPlayer.stop();
    setState(() {
      _isAlarmRinging = false;
      _isAlarmSet = false;
      _selectedTime = null;
    });
  }

  void _showAlarmDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Alarm!'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.alarm, size: 64, color: Colors.red),
              const SizedBox(height: 16),
              Text(
                'Alarm time: ${_selectedTime!.format(context)}',
                style: const TextStyle(fontSize: 18),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                _stopAlarm();
                Navigator.of(context).pop();
              },
              child: const Text('Stop Alarm'),
            ),
          ],
        );
      },
    );
  }

  void _selectTime() async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
    );
    if (picked != null) {
      setState(() {
        _selectedTime = picked;
      });
    }
  }

  void _setAlarm() {
    if (_selectedTime != null) {
      setState(() {
        _isAlarmSet = true;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Alarm set for ${_selectedTime!.format(context)}'),
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  void _cancelAlarm() {
    setState(() {
      _isAlarmSet = false;
      _selectedTime = null;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Alarm cancelled'),
        duration: Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Utho - Alarm Clock'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Current Time Display - change to black and white
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.grey.shade900,
                borderRadius: BorderRadius.circular(15),
                border: Border.all(color: Colors.grey.shade700),
              ),
              child: Column(
                children: [
                  const Text(
                    'Current Time',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w500),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    _currentTime,
                    style: const TextStyle(
                      fontSize: 36,
                      fontWeight: FontWeight.bold,
                      fontFamily: 'monospace',
                    ),
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 40),
            
            // Alarm Settings - change to black and white
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.grey.shade800,
                borderRadius: BorderRadius.circular(15),
                border: Border.all(color: Colors.grey.shade600),
              ),
              child: Column(
                children: [
                  const Text(
                    'Alarm Settings',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w500),
                  ),
                  const SizedBox(height: 15),
                  
                  // Selected Time Display
                  if (_selectedTime != null)
                    Text(
                      'Selected Time: ${_selectedTime!.format(context)}',
                      style: const TextStyle(fontSize: 16),
                    ),
                  
                  const SizedBox(height: 15),
                  
                  // Buttons
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      ElevatedButton.icon(
                        onPressed: _selectTime,
                        icon: const Icon(Icons.access_time),
                        label: const Text('Set Time'),
                      ),
                      if (_selectedTime != null && !_isAlarmSet)
                        ElevatedButton.icon(
                          onPressed: _setAlarm,
                          icon: const Icon(Icons.alarm_add),
                          label: const Text('Set Alarm'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green,
                            foregroundColor: Colors.white,
                          ),
                        ),
                      if (_isAlarmSet)
                        ElevatedButton.icon(
                          onPressed: _cancelAlarm,
                          icon: const Icon(Icons.alarm_off),
                          label: const Text('Cancel'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.red,
                            foregroundColor: Colors.white,
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 30),
            
            // Ringtone Selection - change to black and white
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.grey.shade700,
                borderRadius: BorderRadius.circular(15),
                border: Border.all(color: Colors.grey.shade500),
              ),
              child: Column(
                children: [
                  const Text(
                    'Ringtone',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w500),
                  ),
                  const SizedBox(height: 15),
                  DropdownButton<String>(
                    value: _selectedRingtone,
                    isExpanded: true,
                    items: _ringtones.map((String ringtone) {
                      return DropdownMenuItem<String>(
                        value: ringtone,
                        child: Text('Alarm Tone ${_ringtones.indexOf(ringtone) + 1}'),
                      );
                    }).toList(),
                    onChanged: (String? newValue) {
                      if (newValue != null) {
                        setState(() {
                          _selectedRingtone = newValue;
                        });
                      }
                    },
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 30),
            
            // Status Indicator - change to black and white
            if (_isAlarmSet)
              Container(
                padding: const EdgeInsets.all(15),
                decoration: BoxDecoration(
                  color: Colors.grey.shade800,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.white),
                ),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.alarm_on, color: Colors.white),
                    SizedBox(width: 10),
                    Text(
                      'Alarm Active',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}

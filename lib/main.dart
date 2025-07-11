import 'package:flutter/material.dart';
import 'package:audioplayers/audioplayers.dart';
import 'dart:async';
import 'dart:io';
import 'package:permission_handler/permission_handler.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:math';

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
  
  // Quiz system variables
  int _correctAnswers = 0;
  int _totalQuestions = 0;
  final int _requiredCorrectAnswers = 3;
  bool _isLoadingQuiz = false;
  
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
      debugPrint('Error playing alarm: $e');
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
    setState(() {
      _isLoadingQuiz = true;
      _correctAnswers = 0;
      _totalQuestions = 0;
    });
    
    _fetchAndShowNextQuestion();
  }

  Future<void> _fetchAndShowNextQuestion() async {
    setState(() {
      _isLoadingQuiz = true;
    });

    try {
      debugPrint('Attempting to fetch question from API...');
      
      // Generate random Surah selection (1-114 are valid Surah numbers)
      final random = Random();
      final List<int> randomSurahs = [];
      
      // Generate 5 random unique Surah numbers
      while (randomSurahs.length < 5) {
        int surahNumber = random.nextInt(114) + 1; // 1-114
        if (!randomSurahs.contains(surahNumber)) {
          randomSurahs.add(surahNumber);
        }
      }
      
      // Convert to comma-separated string
      final surahSelection = randomSurahs.join(',');
      
      debugPrint('Using random Surahs: $surahSelection');
      
      // Use the correct API endpoint with random Surah selection
      final response = await http.get(
        Uri.parse('https://quran.zakiego.com/api/guessSurah?select=$surahSelection&amount=3'),
        headers: {
          'Accept': 'application/json',
          'Content-Type': 'application/json',
          'User-Agent': 'Flutter App',
        },
      ).timeout(const Duration(seconds: 10));
      
      debugPrint('Response status: ${response.statusCode}');
      debugPrint('Response body: ${response.body}');
      
      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);
        setState(() {
          _isLoadingQuiz = false;
        });
        
        // Handle the correct API response structure
        if (responseData['message'] == 'success' && responseData['data'] != null) {
          final questions = responseData['data'] as List;
          if (questions.isNotEmpty) {
            // Pick a random question from the returned array
            final randomQuestion = questions[random.nextInt(questions.length)];
            _showQuizDialog(randomQuestion);
          } else {
            debugPrint('No questions in API response');
            _showErrorDialog();
          }
        } else {
          debugPrint('API response format error: $responseData');
          _showErrorDialog();
        }
        return;
      } else {
        debugPrint('API returned status code: ${response.statusCode}');
        _showErrorDialog();
      }
    } catch (e) {
      debugPrint('Error fetching quiz question: $e');
      _showErrorDialog();
    }
  }

  void _showQuizDialog(Map<String, dynamic> questionData) {
    // Extract the question and options from the API response
    final String question = questionData['question'];
    final List<dynamic> optionsData = questionData['options'];
    
    // Find the correct answer and create options list
    String correctAnswer = '';
    List<String> options = [];
    
    for (var option in optionsData) {
      final String text = option['text'];
      final int value = option['value'];
      options.add(text);
      
      if (value == 1) {
        correctAnswer = text;
      }
    }
    
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: Colors.grey.shade900,
          title: Column(
            children: [
              const Icon(Icons.quiz, size: 48, color: Colors.white),
              const SizedBox(height: 10),
              const Text(
                'Quiz Progress',
                style: TextStyle(color: Colors.white, fontSize: 18),
              ),
              const SizedBox(height: 5),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'Correct: $_correctAnswers/$_requiredCorrectAnswers',
                    style: const TextStyle(color: Colors.green, fontSize: 16),
                  ),
                  const SizedBox(width: 15),
                  Text(
                    'Total: $_totalQuestions',
                    style: const TextStyle(color: Colors.white, fontSize: 16),
                  ),
                ],
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Which Surah is this verse from?',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 15),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey.shade800,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.grey.shade600),
                ),
                child: Text(
                  question,
                  style: const TextStyle(
                    fontSize: 16,
                    color: Colors.white,
                    fontFamily: 'serif',
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
              const SizedBox(height: 20),
              ...options.map((option) => Container(
                width: double.infinity,
                margin: const EdgeInsets.only(bottom: 8),
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                    _handleQuizAnswer(option, correctAnswer);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.grey.shade700,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  child: Text(
                    option,
                    style: const TextStyle(fontSize: 14),
                  ),
                ),
              )).toList(),
            ],
          ),
        );
      },
    );
  }

  void _handleQuizAnswer(String selectedAnswer, String correctAnswer) {
    _totalQuestions++;
    bool isCorrect = selectedAnswer == correctAnswer;
    
    if (isCorrect) {
      _correctAnswers++;
    }
    
    _showAnswerFeedback(isCorrect);
    
    // Check if user has achieved the required correct answers
    if (_correctAnswers >= _requiredCorrectAnswers) {
      Timer(const Duration(seconds: 1), () {
        _stopAlarm();
        _showSuccessDialog();
      });
    } else {
      // Continue with next question after showing feedback
      Timer(const Duration(seconds: 1), () {
        _fetchAndShowNextQuestion();
      });
    }
  }

  void _showAnswerFeedback(bool isCorrect) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: isCorrect ? Colors.green.shade800 : Colors.red.shade800,
          title: Column(
            children: [
              Icon(
                isCorrect ? Icons.check_circle : Icons.cancel,
                size: 64,
                color: Colors.white,
              ),
              const SizedBox(height: 10),
              Text(
                isCorrect ? 'Correct!' : 'Wrong Answer!',
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Progress: $_correctAnswers/$_requiredCorrectAnswers correct',
                style: const TextStyle(
                  fontSize: 16,
                  color: Colors.white,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 5),
              Text(
                'Total questions: $_totalQuestions',
                style: const TextStyle(
                  fontSize: 14,
                  color: Colors.white70,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        );
      },
    );
    
    Timer(const Duration(seconds: 1), () {
      Navigator.of(context).pop();
    });
  }

  void _showSuccessDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: Colors.green.shade800,
          title: const Column(
            children: [
              Icon(Icons.celebration, size: 64, color: Colors.white),
              SizedBox(height: 10),
              Text(
                'Congratulations!',
                style: TextStyle(color: Colors.white),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'You got $_correctAnswers correct answers!',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 10),
              Text(
                'Total questions answered: $_totalQuestions',
                style: const TextStyle(
                  fontSize: 16,
                  color: Colors.white70,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 10),
              const Text(
                'Alarm has been turned off!',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.white,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text(
                'OK',
                style: TextStyle(color: Colors.white),
              ),
            ),
          ],
        );
      },
    );
  }

  void _showErrorDialog() {
    setState(() {
      _isLoadingQuiz = false;
    });
    
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: Colors.red.shade800,
          title: const Icon(Icons.error, size: 64, color: Colors.white),
          content: const Text(
            'Failed to load quiz question from API.\nThe API might be down or changed.\n\nCheck the debug console for more details.',
            style: TextStyle(color: Colors.white),
            textAlign: TextAlign.center,
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                _stopAlarm();
              },
              child: const Text(
                'Turn Off Alarm',
                style: TextStyle(color: Colors.white),
              ),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                _fetchAndShowNextQuestion();
              },
              child: const Text(
                'Try Again',
                style: TextStyle(color: Colors.white),
              ),
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

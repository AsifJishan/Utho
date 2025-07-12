import 'package:flutter/material.dart';
import 'dart:async';
import 'dart:io';
import 'package:permission_handler/permission_handler.dart';
import '../models/alarm_model.dart';
import '../models/quiz_model.dart';
import '../services/alarm_service.dart';
import '../services/quiz_service.dart';

class AlarmViewModel extends ChangeNotifier {
  final AlarmService _alarmService = AlarmService();
  final QuizService _quizService = QuizService();
  
  Timer? _timer;
  
  // State
  AlarmModel _alarmModel = AlarmModel(
    isAlarmSet: false,
    isAlarmRinging: false,
    selectedRingtone: 'assets/audios/alarm_tone_1.mp3',
    currentTime: '',
  );
  
  QuizModel _quizModel = QuizModel(
    correctAnswers: 0,
    totalQuestions: 0,
    requiredCorrectAnswers: 3,
    isLoadingQuiz: false,
  );

  final List<String> _ringtones = [
    'assets/audios/alarm_tone_1.mp3',
    'assets/audios/alarm_tone_2.mp3',
    'assets/audios/alarm_tone_3.mp3',
  ];

  // Getters
  AlarmModel get alarmModel => _alarmModel;
  QuizModel get quizModel => _quizModel;
  List<String> get ringtones => _ringtones;

  // Constructor
  AlarmViewModel() {
    _initialize();
  }

  void _initialize() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _updateCurrentTime();
      _startTimeUpdate();
      _requestPermissions();
    });
  }

  void _requestPermissions() async {
    if (Platform.isAndroid) {
      await Permission.notification.request();
    }
  }

  // OPTIMIZATION: Removed the broad post-frame callback from the timer loop.
  void _startTimeUpdate() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      _updateCurrentTime();
      _checkAlarm();
    });
  }

  void _updateCurrentTime() {
    final now = DateTime.now();
    final timeString = '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}:${now.second.toString().padLeft(2, '0')}';
    
    _alarmModel = _alarmModel.copyWith(currentTime: timeString);
    notifyListeners();
  }

  // OPTIMIZATION: Added a targeted post-frame callback only for the alarm trigger.
  void _checkAlarm() {
    if (_alarmModel.isAlarmSet && _alarmModel.selectedTime != null && !_alarmModel.isAlarmRinging) {
      final now = DateTime.now();
      if (now.hour == _alarmModel.selectedTime!.hour && now.minute == _alarmModel.selectedTime!.minute) {
        // This is the infrequent event that needs to be deferred.
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (hasListeners) {
            triggerAlarm();
          }
        });
      }
    }
  }

  void selectTime(TimeOfDay time) {
    _alarmModel = _alarmModel.copyWith(selectedTime: time);
    notifyListeners();
  }

  void setAlarm() {
    if (_alarmModel.selectedTime != null) {
      _alarmModel = _alarmModel.copyWith(isAlarmSet: true);
      notifyListeners();
    }
  }

  void cancelAlarm() {
    _alarmModel = _alarmModel.copyWith(
      isAlarmSet: false,
      selectedTime: null,
    );
    notifyListeners();
  }

  void selectRingtone(String ringtone) {
    _alarmModel = _alarmModel.copyWith(selectedRingtone: ringtone);
    notifyListeners();
  }

  void triggerAlarm() {
    if (_alarmModel.isAlarmRinging) return;

    _alarmModel = _alarmModel.copyWith(isAlarmRinging: true);
    _alarmService.playAlarm(_alarmModel.selectedRingtone);
    _resetQuizState();
    notifyListeners();
  }

  void _resetQuizState() {
    _quizModel = _quizModel.copyWith(
      correctAnswers: 0,
      totalQuestions: 0,
    );
  }

  Future<QuizQuestion> fetchQuizQuestion() async {
    _quizModel = _quizModel.copyWith(isLoadingQuiz: true);
    await Future.microtask(() => notifyListeners());
    
    try {
      final question = await _quizService.fetchQuizQuestion();
      _quizModel = _quizModel.copyWith(isLoadingQuiz: false);
      notifyListeners();
      return question;
    } catch (e) {
      _quizModel = _quizModel.copyWith(isLoadingQuiz: false);
      notifyListeners();
      rethrow;
    }
  }

  void handleQuizAnswer(bool isCorrect) {
    final newTotalQuestions = _quizModel.totalQuestions + 1;
    final newCorrectAnswers = isCorrect ? _quizModel.correctAnswers + 1 : _quizModel.correctAnswers;
    
    _quizModel = _quizModel.copyWith(
      totalQuestions: newTotalQuestions,
      correctAnswers: newCorrectAnswers,
    );
    notifyListeners();
  }

  bool get isQuizCompleted => _quizModel.correctAnswers >= _quizModel.requiredCorrectAnswers;

  Future<void> stopAlarm() async {
    await _alarmService.stopAlarm();
    _alarmModel = _alarmModel.copyWith(
      isAlarmRinging: false,
      isAlarmSet: false,
      selectedTime: null,
    );
    notifyListeners();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _alarmService.dispose();
    super.dispose();
  }
}
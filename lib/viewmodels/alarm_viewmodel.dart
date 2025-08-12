import 'dart:async';
import 'dart:io';
import 'package:audioplayers/audioplayers.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:awesome_notifications/awesome_notifications.dart';
import 'package:flutter/scheduler.dart';
import '../models/alarm_model.dart';
import '../models/quiz_model.dart';
import '../services/alarm_service.dart';
import '../services/quiz_service.dart'; // Import the QuizService
import 'package:utho/widgets/quiz_dialog.dart';
import 'package:utho/utils/app_router.dart';

class AlarmViewModel extends ChangeNotifier {
  final AlarmService _alarmService = AlarmService();
  final QuizService _quizService = QuizService(); // Add an instance of QuizService

  // Make _audioPlayer a class field
  final AudioPlayer _audioPlayer = AudioPlayer();
  Timer? _timer;
  Timer? _linuxAlarmTimer; // Linux fallback timer

  // State
  AlarmModel _alarmModel = AlarmModel(
    isAlarmSet: false,
    isAlarmRinging: false,
    selectedRingtone: 'assets/audios/alarm_tone_1.mp3',
    currentTime: '',
  );

  // This field is reassigned with copyWith, so it cannot be final.
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

  // Add this getter
  bool get isQuizCompleted => _quizModel.correctAnswers >= _quizModel.requiredCorrectAnswers;

  // Constructor
  AlarmViewModel() {
    _initialize();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _linuxAlarmTimer?.cancel();
    super.dispose();
  }

  void _initialize() async {
    // Load the saved ringtone
    final savedRingtone = await _alarmService.loadRingtone();
    if (savedRingtone != null) {
      _alarmModel = _alarmModel.copyWith(selectedRingtone: savedRingtone);
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _updateCurrentTime();
      _startTimeUpdate();
      _requestPermissions();
      notifyListeners(); // Update UI after loading
    });
  }

  void _requestPermissions() async {
    if (Platform.isAndroid) {
      await Permission.notification.request();
    }
  }

  Future<void> requestBatteryOptimizationExemption() async {
    if (Platform.isAndroid) {
      // We just launch an intent via platform channel not yet implemented; placeholder log.
      debugPrint('[ALARM] Ask user to disable battery optimization manually.');
    }
  }

  // OPTIMIZATION: Removed the broad post-frame callback from the timer loop.
  void _startTimeUpdate() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      _updateCurrentTime();
      // _checkAlarm(); // REMOVE THIS LINE
    });
  }

  void _updateCurrentTime() {
    final now = DateTime.now();
    final timeString = '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}:${now.second.toString().padLeft(2, '0')}';
    _alarmModel = _alarmModel.copyWith(currentTime: timeString);
    _safeNotify();
  }

  // REMOVE THIS ENTIRE METHOD
  /*
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
  */

  void selectTime(TimeOfDay time) {
    _alarmModel = _alarmModel.copyWith(selectedTime: time);
    _safeNotify();
  }

  void selectRingtone(String ringtone) {
    _alarmModel = _alarmModel.copyWith(selectedRingtone: ringtone);
    _alarmService.saveRingtone(ringtone);
    _safeNotify();
  }

  Future<void> selectRingtoneFromFile() async {
    // Request permission first
    var status = await Permission.audio.request();
    if (status.isGranted) {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.audio,
      );

      if (result != null && result.files.single.path != null) {
        String filePath = result.files.single.path!;
        _alarmModel = _alarmModel.copyWith(selectedRingtone: filePath);
        _alarmService.saveRingtone(filePath); // Save the custom path
        _safeNotify();
      }
    } else {
      // Handle the case where permission is denied
      // The print statement was removed to fix the lint warning.
    }
  }

  // REMOVE legacy setAlarm in favor of _scheduleAlarm via public scheduleAlarm() wrapper
  void setAlarm() {
    // Deprecated: keep empty to avoid duplicate scheduling. Use scheduleAlarm() instead.
    scheduleAlarm();
  }

  Future<void> scheduleAlarm() async {
    if (Platform.isLinux) {
      // Linux fallback: schedule via Dart Timer
      _linuxAlarmTimer?.cancel();
      if (_alarmModel.selectedTime == null) return;
      final now = DateTime.now();
      var target = DateTime(now.year, now.month, now.day, _alarmModel.selectedTime!.hour, _alarmModel.selectedTime!.minute);
      if (target.isBefore(now)) target = target.add(const Duration(days: 1));
      final diff = target.difference(now);
      debugPrint('[ALARM][LINUX] Scheduling local timer in ${diff.inSeconds}s for ${target.toIso8601String()}');
      _linuxAlarmTimer = Timer(diff, () {
        debugPrint('[ALARM][LINUX] Firing alarm');
        triggerAlarm();
        final ctx = AppRouter.navigatorKey.currentContext;
        if (ctx != null) {
          showDialog(
            context: ctx,
            barrierDismissible: false,
            builder: (_) => QuizDialog(viewModel: this),
          );
        }
      });
      _alarmModel = _alarmModel.copyWith(isAlarmSet: true);
      _safeNotify();
      return;
    }
    await _scheduleAlarm();
    _alarmModel = _alarmModel.copyWith(isAlarmSet: true);
    _safeNotify();
  }

  Future<bool> _canScheduleExact() async {
    const channelName = 'exact_alarm';
    const channel = MethodChannel(channelName);
    try {
      final can = await channel.invokeMethod<bool>('canScheduleExactAlarms');
      return can ?? true;
    } catch (_) {
      return true;
    }
  }

  void cancelAlarm() {
    if (Platform.isLinux) {
      _linuxAlarmTimer?.cancel();
    }
    AwesomeNotifications().cancel(10);
    _alarmModel = _alarmModel.copyWith(isAlarmSet: false, isAlarmRinging: false);
    _audioPlayer.stop();
    _safeNotify();
  }

  // ADD THIS METHOD
  Future<void> _saveAlarmState() async {
    // This assumes your AlarmService has a method to save the boolean state.
    // If not, you would add it there.
    await _alarmService.saveAlarmState(_alarmModel.isAlarmSet);
  }

  void toggleAlarm(bool isSet) {
    _alarmModel = _alarmModel.copyWith(isAlarmSet: isSet);
    _saveAlarmState();

    // Call _scheduleAlarm or cancel it when the toggle is flipped
    if (isSet) {
      _scheduleAlarm();
    } else {
      AwesomeNotifications().cancel(10);
    }

    _safeNotify();
  }

  // ADD THIS METHOD
  Future<QuizQuestion> fetchQuizQuestion() async {
    _quizModel = _quizModel.copyWith(isLoadingQuiz: true);
    _safeNotify();
    try {
      final question = await _quizService.fetchQuizQuestion();
      _quizModel = _quizModel.copyWith(isLoadingQuiz: false);
      _safeNotify();
      return question;
    } catch (e) {
      _quizModel = _quizModel.copyWith(isLoadingQuiz: false);
      _safeNotify();
      rethrow;
    }
  }

  // ADD THIS METHOD
  void handleQuizAnswer(bool isCorrect) {
    int newCorrectAnswers = _quizModel.correctAnswers;
    if (isCorrect) {
      newCorrectAnswers++;
    }
    _quizModel = _quizModel.copyWith(
      correctAnswers: newCorrectAnswers,
      totalQuestions: _quizModel.totalQuestions + 1,
    );

    if (isQuizCompleted) {
      stopAlarm();
    }
    _safeNotify();
  }

  void triggerAlarm() {
    _alarmModel = _alarmModel.copyWith(isAlarmRinging: true);
    _alarmService.playAlarm(_alarmModel.selectedRingtone);
    _safeNotify();
  }

  void stopAlarm() {
    _alarmService.stopAlarm();
    _alarmModel = _alarmModel.copyWith(isAlarmRinging: false, isAlarmSet: false);
    AwesomeNotifications().cancel(10);
    _safeNotify();
  }

  Future<void> _scheduleAlarm() async {
    if (_alarmModel.selectedTime == null) return;

    final canExact = await _canScheduleExact();

    await AwesomeNotifications().cancel(10);

    final timeZone = await AwesomeNotifications().getLocalTimeZoneIdentifier();
    final now = DateTime.now();
    final target = DateTime(now.year, now.month, now.day, _alarmModel.selectedTime!.hour, _alarmModel.selectedTime!.minute);
    final scheduled = target.isBefore(now) ? target.add(const Duration(days: 1)) : target;
    final diffMs = scheduled.difference(now).inMilliseconds;

    debugPrint('[ALARM] Scheduling id=10 at ${scheduled.toIso8601String()} (in ${diffMs/1000}s) tz=$timeZone exact=$canExact');

    await AwesomeNotifications().createNotification(
      content: NotificationContent(
        id: 10,
        channelKey: 'alarm_channel',
        title: 'Utho!',
        body: 'Time to wake up!',
        payload: {'uuid': 'alarm_payload'},
        category: NotificationCategory.Alarm,
        wakeUpScreen: true,
        fullScreenIntent: true,
        autoDismissible: false,
        locked: true,
        criticalAlert: true,
        notificationLayout: NotificationLayout.Default,
      ),
      schedule: NotificationCalendar(
        year: scheduled.year,
        month: scheduled.month,
        day: scheduled.day,
        hour: scheduled.hour,
        minute: scheduled.minute,
        second: 0,
        millisecond: 0,
        timeZone: timeZone,
        repeats: false,
        allowWhileIdle: true,
        preciseAlarm: canExact,
      ),
      actionButtons: [
        NotificationActionButton(
          key: 'DISMISS',
          label: 'Dismiss',
          actionType: ActionType.DismissAction,
          isDangerousOption: true,
        )
      ],
    );
  }

  void _safeNotify() {
    if (!hasListeners) return;
    final phase = SchedulerBinding.instance.schedulerPhase;
    if (phase == SchedulerPhase.idle || phase == SchedulerPhase.postFrameCallbacks) {
      notifyListeners();
    } else {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (hasListeners) notifyListeners();
      });
    }
  }
}
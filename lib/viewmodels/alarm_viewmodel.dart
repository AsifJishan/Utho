import 'dart:async';
import 'dart:io';
import 'package:audioplayers/audioplayers.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:awesome_notifications/awesome_notifications.dart';
import 'package:flutter/scheduler.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/alarm_model.dart';
import '../models/quiz_model.dart';
import '../services/alarm_service.dart';
import '../services/quiz_service.dart';
import 'package:utho/widgets/quiz_dialog.dart';
import 'package:utho/utils/app_router.dart';

class AlarmViewModel extends ChangeNotifier {
  final AlarmService _alarmService = AlarmService();
  final QuizService _quizService = QuizService();
  final AudioPlayer _audioPlayer = AudioPlayer();
  Timer? _timer;
  Timer? _linuxAlarmTimer; // Linux fallback timer

  AlarmModel _alarmModel = AlarmModel(
    isAlarmSet: false,
    isAlarmRinging: false,
    selectedRingtone: null,
    currentTime: '',
  );

  QuizModel _quizModel = QuizModel(
    correctAnswers: 0,
    totalQuestions: 0,
    requiredCorrectAnswers: 3,
    isLoadingQuiz: false,
  );

  bool _hafidhMode = false;

  final List<int> _restrictedSurahs = [1, 93, 94, 95, 96, 97, 98, 99, 100, 101, 102, 103, 104, 105, 106, 107, 108, 109, 110, 111, 112, 113, 114];

  AlarmModel get alarmModel => _alarmModel;
  QuizModel get quizModel => _quizModel;
  bool get hafidhMode => _hafidhMode;

  bool get isQuizCompleted => _quizModel.correctAnswers >= _quizModel.requiredCorrectAnswers;

  void toggleHafidhMode() async {
    _hafidhMode = !_hafidhMode;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('hafidhMode', _hafidhMode);
    notifyListeners();
  }

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
    final savedRingtone = await _alarmService.loadRingtone();
    if (savedRingtone != null) {
      _alarmModel = _alarmModel.copyWith(selectedRingtone: savedRingtone);
    }

    final prefs = await SharedPreferences.getInstance();
    _hafidhMode = prefs.getBool('hafidhMode') ?? false;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _updateCurrentTime();
      _startTimeUpdate();
      _requestPermissions();
      notifyListeners();
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

  void _startTimeUpdate() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      _updateCurrentTime();
    });
  }

  void _updateCurrentTime() {
    final now = DateTime.now();
    final timeString = '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}:${now.second.toString().padLeft(2, '0')}';
    _alarmModel = _alarmModel.copyWith(currentTime: timeString);
    _safeNotify();
  }

  void selectTime(TimeOfDay time) {
    _alarmModel = _alarmModel.copyWith(selectedTime: time);
    _safeNotify();
  }

  void setAlarm() {
    scheduleAlarm();
  }

  Future<void> scheduleAlarm() async {
    // Reset quiz state for new alarm
    _quizModel = QuizModel(
      correctAnswers: 0,
      totalQuestions: 0,
      requiredCorrectAnswers: 3,
      isLoadingQuiz: false,
    );

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

  Future<void> _saveAlarmState() async {
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

  Future<QuizQuestion> fetchQuizQuestion() async {
    _quizModel = _quizModel.copyWith(isLoadingQuiz: true);
    _safeNotify();
    try {
      final question = await _quizService.fetchQuizQuestion(_hafidhMode ? null : _restrictedSurahs);
      _quizModel = _quizModel.copyWith(isLoadingQuiz: false);
      _safeNotify();
      return question;
    } catch (e) {
      _quizModel = _quizModel.copyWith(isLoadingQuiz: false);
      _safeNotify();
      rethrow;
    }
  }

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
    if (_alarmModel.selectedRingtone != null) {
      _alarmService.playAlarm(_alarmModel.selectedRingtone!);
    }
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

  Future<void> selectRingtoneFromFile() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.audio,
    );
    if (result != null && result.files.single.path != null) {
      final picked = result.files.single;
      final appDocs = await getApplicationDocumentsDirectory();
      final tonesDir = Directory(p.join(appDocs.path, 'tones'));
      await tonesDir.create(recursive: true);
      // Sanitize filename to avoid issues
      final safeName = picked.name.replaceAll(RegExp(r'[^a-zA-Z0-9._-]'), '_');
      final filename = '${DateTime.now().millisecondsSinceEpoch}_$safeName';
      final destPath = p.join(tonesDir.path, filename);
      // Copy the file to app storage
      await File(picked.path!).copy(destPath);
      // Update the model with the copied path and display name
      _alarmModel = _alarmModel.copyWith(
        selectedRingtone: destPath,
        toneName: picked.name, // Store the original name for UI
      );
      _alarmService.saveRingtone(destPath); // Save the copied path
      _safeNotify();
    }
  }
}
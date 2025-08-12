import 'package:awesome_notifications/awesome_notifications.dart';
import 'package:flutter/material.dart';
import 'package:utho/utils/app_router.dart';
import 'package:utho/utils/service_locator.dart';
import 'package:utho/viewmodels/alarm_viewmodel.dart';
import 'package:utho/widgets/quiz_dialog.dart';

class NotificationController {
  /// Use this method to detect when a new notification or a schedule is created
  @pragma("vm:entry-point")
  static Future<void> onNotificationCreatedMethod(
      ReceivedNotification receivedNotification) async {
    // Removed immediate trigger to avoid early playback when a scheduled notification is merely created.
  }

  /// Use this method to detect every time that a new notification is displayed
  @pragma("vm:entry-point")
  static Future<void> onNotificationDisplayedMethod(
      ReceivedNotification receivedNotification) async {
    if (receivedNotification.payload?['uuid'] == 'alarm_payload') {
      final viewModel = locator<AlarmViewModel>();
      if (!viewModel.alarmModel.isAlarmRinging) {
        viewModel.triggerAlarm();
      }
      final context = AppRouter.navigatorKey.currentContext;
      if (context != null) {
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (_) => QuizDialog(viewModel: viewModel),
        );
      }
    }
  }

  /// Use this method to detect if the user dismissed a notification
  @pragma("vm:entry-point")
  static Future<void> onDismissActionReceivedMethod(
      ReceivedAction receivedAction) async {
    // Your code goes here
  }

  /// Use this method to detect when the user taps on a notification or action button
  @pragma("vm:entry-point")
  static Future<void> onActionReceivedMethod(
      ReceivedAction receivedAction) async {
    // Your code goes here
  }
}
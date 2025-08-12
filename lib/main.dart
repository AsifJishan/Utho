import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:utho/controllers/notification_controller.dart';
import 'package:utho/utils/app_router.dart';
import 'package:utho/utils/service_locator.dart'; // Import the locator
import 'package:utho/viewmodels/alarm_viewmodel.dart';
import 'package:utho/views/alarm_clock_view.dart';
import 'package:awesome_notifications/awesome_notifications.dart';

void main() async {
  // This line is required to ensure that plugin services are initialized
  // before the app is run.
  WidgetsFlutterBinding.ensureInitialized();
  setupLocator(); // Initialize the service locator

  // Initialize awesome_notifications
  await AwesomeNotifications().initialize(
    // Set the icon to null to use the default app icon
    null,
    [
      NotificationChannel(
        channelKey: 'alarm_channel',
        channelName: 'Alarm Notifications',
        channelDescription: 'Notification channel for alarms',
        defaultColor: const Color(0xFF9D50DD),
        ledColor: Colors.white,
        importance: NotificationImportance.Max,
        channelShowBadge: true,
        playSound: true,
        enableVibration: true,
        // ADD THIS LINE to give the alarm higher priority
        criticalAlerts: true,
        soundSource: 'resource://raw/alarm_tone_1',
      )
    ],
    debug: true,
  );

  // Set the listener here, after initialization
  AwesomeNotifications().setListeners(
      onActionReceivedMethod: NotificationController.onActionReceivedMethod,
      onNotificationCreatedMethod:
          NotificationController.onNotificationCreatedMethod,
      onNotificationDisplayedMethod:
          NotificationController.onNotificationDisplayedMethod,
      onDismissActionReceivedMethod:
          NotificationController.onDismissActionReceivedMethod);

  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  @override
  void initState() {
    super.initState();

    // Request all necessary permissions when the app starts.
    AwesomeNotifications().requestPermissionToSendNotifications(
      channelKey: 'alarm_channel', // Request for the specific channel
      permissions: [
        NotificationPermission.Alert,
        NotificationPermission.Sound,
        NotificationPermission.Badge,
        NotificationPermission.Vibration,
        NotificationPermission.FullScreenIntent,
        // Add these for reliability
        NotificationPermission.CriticalAlert,
      ],
    ).then((isAllowed) {
      if (!isAllowed) {
        // Consider showing a dialog explaining why the permissions are needed
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      // Use the instance from the service locator
      create: (context) => locator<AlarmViewModel>(),
      child: MaterialApp(
        // Add the navigatorKey
        navigatorKey: AppRouter.navigatorKey,
        title: 'Utho',
        theme: ThemeData.dark(useMaterial3: true).copyWith(
          colorScheme: ColorScheme.fromSeed(
              seedColor: Colors.deepPurple, brightness: Brightness.dark),
        ),
        home: const AlarmClockView(),
      ),
    );
  }
}

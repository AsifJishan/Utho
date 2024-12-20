import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize notifications
  var initializationSettingsAndroid = AndroidInitializationSettings('@mipmap/ic_launcher');
  var initializationSettings = InitializationSettings(android: initializationSettingsAndroid);
  await flutterLocalNotificationsPlugin.initialize(initializationSettings);

  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: AlarmScreen(),
    );
  }
}

Future<void> scheduleAlarm(DateTime scheduledTime) async {
  var androidDetails = AndroidNotificationDetails(
    'alarm_channel',
    'Alarm Notifications',
    'This channel is for alarm notifications',
    importance: Importance.max,
    priority: Priority.high,
    sound: RawResourceAndroidNotificationSound('alarm_tone'), // Add your tone in android/res/raw folder
  );
  var notificationDetails = NotificationDetails(android: androidDetails);

  await flutterLocalNotificationsPlugin.zonedSchedule(
    0,
    'Alarm',
    'Answer the question to turn off!',
    scheduledTime,
    notificationDetails,
    androidAllowWhileIdle: true,
    uiLocalNotificationDateInterpretation:
        UILocalNotificationDateInterpretation.absoluteTime,
  );
}

class AlarmScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Alarm App'),
      ),
      body: Center(
        child: ElevatedButton(
          onPressed: () {
            DateTime now = DateTime.now();
            scheduleAlarm(now.add(Duration(seconds: 10))); // Set alarm for 10 seconds later
          },
          child: Text('Set Alarm'),
        ),
      ),
    );
  }
}
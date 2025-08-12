// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:utho/main.dart';

void main() {
  // This setup is needed to mock the platform channels used by plugins like awesome_notifications
  setUpAll(() {
    TestWidgetsFlutterBinding.ensureInitialized();
    const MethodChannel channel = MethodChannel('awesome_notifications');
    
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(channel, (MethodCall methodCall) async {
      // Mock all expected calls from the plugin
      switch (methodCall.method) {
        case 'initialize':
          return true;
        case 'isNotificationAllowed':
          return true;
        case 'requestPermissionToSendNotifications':
          return true;
        case 'createNotification':
          return true;
        case 'cancel':
          return true;
        default:
          return null;
      }
    });
  });

  tearDownAll(() {
    const MethodChannel channel = MethodChannel('awesome_notifications');
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(channel, null);
  });

  testWidgets('Alarm Clock UI smoke test', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    // The widget name is MyApp, not AlarmClockApp.
    await tester.pumpWidget(const MyApp());

    // Verify that the app bar title is displayed.
    expect(find.text('Utho - Alarm Clock'), findsOneWidget);

    // Verify that the "Set Alarm" button is present
    expect(find.text('Set Alarm'), findsOneWidget);

    // Verify that the "Alarm List" button is present
    expect(find.text('Alarm List'), findsOneWidget);

    // Verify that the "Settings" button is present
    expect(find.text('Settings'), findsOneWidget);

    // Verify that the bottom navigation bar is present
    expect(find.byType(BottomNavigationBar), findsOneWidget);

    // Verify that the initial selected label of the bottom navigation bar is "Alarm"
    final BottomNavigationBar bottomNavBar = tester.widget(find.byType(BottomNavigationBar));
    expect(bottomNavBar.currentIndex, 0);
  });
}

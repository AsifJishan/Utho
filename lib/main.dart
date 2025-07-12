import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'viewmodels/alarm_viewmodel.dart';
import 'views/alarm_clock_view.dart';

void main() {
  runApp(const AlarmClockApp());
}

class AlarmClockApp extends StatelessWidget {
  const AlarmClockApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (context) => AlarmViewModel(),
      child: MaterialApp(
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
        home: const AlarmClockView(),
      ),
    );
  }
}

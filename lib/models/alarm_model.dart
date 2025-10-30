import 'package:flutter/material.dart';

class AlarmModel {
  final TimeOfDay? selectedTime;
  final bool isAlarmSet;
  final bool isAlarmRinging;
  final String? selectedRingtone;
  final String currentTime;
  final String? toneName;

  AlarmModel({
    this.selectedTime,
    required this.isAlarmSet,
    required this.isAlarmRinging,
    this.selectedRingtone,
    required this.currentTime,
    this.toneName,
  });

  AlarmModel copyWith({
    TimeOfDay? selectedTime,
    bool? isAlarmSet,
    bool? isAlarmRinging,
    String? selectedRingtone,
    String? currentTime,
    String? toneName,
  }) {
    return AlarmModel(
      selectedTime: selectedTime ?? this.selectedTime,
      isAlarmSet: isAlarmSet ?? this.isAlarmSet,
      isAlarmRinging: isAlarmRinging ?? this.isAlarmRinging,
      selectedRingtone: selectedRingtone ?? this.selectedRingtone,
      currentTime: currentTime ?? this.currentTime,
      toneName: toneName ?? this.toneName,
    );
  }
}
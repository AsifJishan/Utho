import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../viewmodels/alarm_viewmodel.dart';

class AlarmClockView extends StatefulWidget {
  const AlarmClockView({super.key});

  @override
  State<AlarmClockView> createState() => _AlarmClockViewState();
}

class _AlarmClockViewState extends State<AlarmClockView> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Utho - Alarm Clock'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: Consumer<AlarmViewModel>(
        builder: (context, viewModel, child) {
          return Padding(
            padding: const EdgeInsets.all(16.0),
            // Wrapped the Column in a SingleChildScrollView to prevent overflow
            child: SingleChildScrollView(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _buildCurrentTimeDisplay(viewModel),
                  const SizedBox(height: 40),
                  _buildAlarmSettings(context, viewModel),
                  const SizedBox(height: 30),
                  _buildRingtoneSelection(viewModel),
                  const SizedBox(height: 30),
                  if (viewModel.alarmModel.isAlarmSet)
                    _buildAlarmStatus(),
                  const SizedBox(height: 30),
                  _buildHafidhModeToggle(viewModel),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildCurrentTimeDisplay(AlarmViewModel viewModel) {
    return Container(
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
            viewModel.alarmModel.currentTime,
            style: const TextStyle(
              fontSize: 36,
              fontWeight: FontWeight.bold,
              fontFamily: 'monospace',
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAlarmSettings(BuildContext context, AlarmViewModel viewModel) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.grey.shade800,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: Colors.grey.shade600),
      ),
      child: Column(
        children: [
          if (viewModel.alarmModel.selectedTime != null)
            Text(
              'Selected Time: ${viewModel.alarmModel.selectedTime!.format(context)}',
              style: const TextStyle(fontSize: 16),
            ),
          
          const SizedBox(height: 15),
          
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              ElevatedButton.icon(
                onPressed: () => _selectTime(context, viewModel),
                icon: const Icon(Icons.access_time),
                label: const Text('Set Time'),
              ),
              if (viewModel.alarmModel.selectedTime != null && !viewModel.alarmModel.isAlarmSet)
                ElevatedButton.icon(
                  onPressed: () => _setAlarm(context, viewModel),
                  icon: const Icon(Icons.alarm_add),
                  label: const Text('Set Alarm'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                  ),
                ),
              if (viewModel.alarmModel.isAlarmSet)
                ElevatedButton.icon(
                  onPressed: () => _cancelAlarm(context, viewModel),
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
    );
  }

  Widget _buildRingtoneSelection(AlarmViewModel viewModel) {
    return Column(
      children: [
        Text(viewModel.alarmModel.toneName ?? 'No audio selected'),
        const SizedBox(height: 10),
        ElevatedButton(
          onPressed: () => viewModel.selectRingtoneFromFile(),
          child: const Text('Pick Audio File'),
        ),
      ],
    );
  }

  Widget _buildAlarmStatus() {
    return Container(
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
    );
  }

  Widget _buildHafidhModeToggle(AlarmViewModel viewModel) {
    return SwitchListTile(
      title: const Text('Hafidh Mode'),
      subtitle: const Text('Enable to access all surahs'),
      value: viewModel.hafidhMode,
      onChanged: (value) => viewModel.toggleHafidhMode(),
    );
  }

  void _selectTime(BuildContext context, AlarmViewModel viewModel) async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
    );
    if (picked != null) {
      viewModel.selectTime(picked);
    }
  }

  void _setAlarm(BuildContext context, AlarmViewModel viewModel) {
    viewModel.scheduleAlarm();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Alarm set for ${viewModel.alarmModel.selectedTime!.format(context)}'),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _cancelAlarm(BuildContext context, AlarmViewModel viewModel) {
    viewModel.cancelAlarm();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Alarm cancelled'),
        duration: Duration(seconds: 2),
      ),
    );
  }
}
import 'package:get_it/get_it.dart';
import 'package:utho/viewmodels/alarm_viewmodel.dart';

final GetIt locator = GetIt.instance;

void setupLocator() {
  locator.registerSingleton<AlarmViewModel>(AlarmViewModel());
}
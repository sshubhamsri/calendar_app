import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:home_widget/home_widget.dart';
import 'package:workmanager/workmanager.dart';

import 'app.dart';
import 'core/constants/app_constants.dart';

// Background task name for Android WorkManager
const _widgetRefreshTask = 'widgetRefresh';

@pragma('vm:entry-point')
void callbackDispatcher() {
  Workmanager().executeTask((taskName, inputData) async {
    // Background tasks run in isolate — only use SharedPreferences
    // The native widget reads SharedPreferences directly,
    // so no Flutter-side work is needed here beyond triggering an update.
    return Future.value(true);
  });
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await _initHive();
  await _initHomeWidget();
  await _initWorkManager();

  runApp(const ProviderScope(child: CalendarApp()));
}

Future<void> _initHive() async {
  await Hive.initFlutter();
  await Future.wait([
    Hive.openBox(AppConstants.eventsBoxName),
    Hive.openBox(AppConstants.weatherBoxName),
    Hive.openBox(AppConstants.settingsBoxName),
  ]);
}

Future<void> _initHomeWidget() async {
  HomeWidget.setAppGroupId('group.com.naehas.calendar_app');
}

Future<void> _initWorkManager() async {
  await Workmanager().initialize(callbackDispatcher);
  await Workmanager().registerPeriodicTask(
    _widgetRefreshTask,
    _widgetRefreshTask,
    frequency: const Duration(minutes: 15),
    constraints: Constraints(networkType: NetworkType.connected),
    existingWorkPolicy: ExistingWorkPolicy.keep,
  );
}

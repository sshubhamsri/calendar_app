import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:home_widget/home_widget.dart';
import 'package:workmanager/workmanager.dart';

import 'app.dart';
import 'core/constants/app_constants.dart';

const _widgetRefreshTask = 'widgetRefresh';

@pragma('vm:entry-point')
void callbackDispatcher() {
  Workmanager().executeTask((taskName, inputData) async {
    return true;
  });
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await _initHive();
  _initHomeWidget();
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

void _initHomeWidget() {
  HomeWidget.setAppGroupId('group.com.naehas.calendar_app');
}

Future<void> _initWorkManager() async {
  await Workmanager().initialize(callbackDispatcher);
  await Workmanager().registerPeriodicTask(
    _widgetRefreshTask,
    _widgetRefreshTask,
    frequency: const Duration(minutes: 15),
    constraints: Constraints(networkType: NetworkType.connected),
    existingWorkPolicy: ExistingPeriodicWorkPolicy.keep,
  );
}

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../calendar/domain/providers/calendar_provider.dart';
import '../../../weather/domain/providers/weather_provider.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  final _cityController = TextEditingController();

  @override
  void initState() {
    super.initState();
    final city = ref.read(weatherSettingsProvider).city;
    _cityController.text = city;
  }

  @override
  void dispose() {
    _cityController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final sourcesAsync = ref.watch(calendarSourcesProvider);
    final weatherSettings = ref.watch(weatherSettingsProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        children: [
          // --- Calendars section ---
          _SectionHeader(title: 'CALENDARS'),
          sourcesAsync.when(
            data: (sources) => Column(
              children: sources.map((source) {
                return                   SwitchListTile(
                  value: source.isSelected,
                  activeThumbColor: source.color,
                  onChanged: (_) => ref
                      .read(calendarSourcesProvider.notifier)
                      .toggleSource(source.id),
                  title: Text(source.name,
                      style:
                          const TextStyle(color: AppColors.textPrimary)),
                  subtitle: source.isReadOnly
                      ? const Text('Read only',
                          style: TextStyle(
                              color: AppColors.textMuted, fontSize: 11))
                      : null,
                  secondary: Container(
                    width: 14,
                    height: 14,
                    decoration: BoxDecoration(
                      color: source.color,
                      shape: BoxShape.circle,
                    ),
                  ),
                );
              }).toList(),
            ),
            loading: () => const Center(
                child: Padding(
              padding: EdgeInsets.all(16),
              child: CircularProgressIndicator(),
            )),
            error: (e, _) => Padding(
              padding: const EdgeInsets.all(16),
              child: Text('Failed to load calendars: $e',
                  style:
                      const TextStyle(color: AppColors.textSecondary)),
            ),
          ),

          const Divider(color: AppColors.divider, height: 32),

          // --- Weather section ---
          _SectionHeader(title: 'WEATHER'),

          // Auto location toggle
          SwitchListTile(
            title: const Text('Auto-detect location',
                style: TextStyle(color: AppColors.textPrimary)),
            subtitle: const Text(
              'Uses your location for accurate weather',
              style: TextStyle(
                  color: AppColors.textMuted, fontSize: 11),
            ),
            value: weatherSettings.useAutoLocation,
            activeThumbColor: AppColors.accent,
            onChanged: (enabled) async {
              if (enabled) {
                final ok = await ref
                    .read(weatherSettingsProvider.notifier)
                    .enableAutoLocation();
                if (!ok && context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Location permission denied'),
                    ),
                  );
                }
              } else {
                await ref
                    .read(weatherSettingsProvider.notifier)
                    .disableAutoLocation();
              }
            },
          ),

          // Manual city input (shown when auto is off)
          if (!weatherSettings.useAutoLocation)
            Padding(
              padding: const EdgeInsets.symmetric(
                  horizontal: 16, vertical: 8),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _cityController,
                      style: const TextStyle(
                          color: AppColors.textPrimary),
                      decoration: const InputDecoration(
                        labelText: 'City name',
                        hintText: 'e.g. Mumbai',
                        hintStyle:
                            TextStyle(color: AppColors.textMuted),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.accent),
                    onPressed: () async {
                      final city = _cityController.text.trim();
                      if (city.isEmpty) return;
                      await ref
                          .read(weatherSettingsProvider.notifier)
                          .setCity(city);
                      if (context.mounted) {
                        ScaffoldMessenger.of(context)
                            .showSnackBar(SnackBar(
                          content: Text('Weather set to $city'),
                        ));
                      }
                    },
                    child: const Text('Set'),
                  ),
                ],
              ),
            ),

          const SizedBox(height: 32),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 6),
      child: Text(
        title,
        style: const TextStyle(
          color: AppColors.weekNumberColor,
          fontSize: 11,
          fontWeight: FontWeight.w600,
          letterSpacing: 1.2,
        ),
      ),
    );
  }
}

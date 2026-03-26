import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_theme.dart';
import '../../domain/providers/calendar_provider.dart';

class PermissionScreen extends ConsumerWidget {
  const PermissionScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final permState = ref.watch(calendarPermissionProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.calendar_month_outlined,
                size: 72,
                color: AppColors.accent,
              ),
              const SizedBox(height: 32),
              const Text(
                'Calendar Access',
                style: TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 24,
                  fontWeight: FontWeight.w700,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              const Text(
                'This app needs access to your calendars to show your events. '
                'Your data stays on your device.',
                style: TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 15,
                  height: 1.6,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 48),
              permState.when(
                data: (granted) {
                  if (granted) {
                    // Auto-navigate if already granted
                    WidgetsBinding.instance.addPostFrameCallback(
                      (_) => context.go('/'),
                    );
                    return const SizedBox.shrink();
                  }
                  return _GrantButton(
                    onTap: () async {
                      await ref
                          .read(calendarPermissionProvider.notifier)
                          .request();
                      final newState =
                          ref.read(calendarPermissionProvider);
                      if (newState.valueOrNull == true &&
                          context.mounted) {
                        context.go('/');
                      }
                    },
                  );
                },
                loading: () =>
                    const CircularProgressIndicator(color: AppColors.accent),
                error: (e, st) => _GrantButton(
                  onTap: () => ref
                      .read(calendarPermissionProvider.notifier)
                      .request(),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _GrantButton extends StatelessWidget {
  const _GrantButton({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: FilledButton.icon(
        onPressed: onTap,
        icon: const Icon(Icons.check_circle_outline),
        label: const Text('Allow Calendar Access'),
        style: FilledButton.styleFrom(
          backgroundColor: AppColors.accent,
          padding: const EdgeInsets.symmetric(vertical: 16),
          textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      ),
    );
  }
}

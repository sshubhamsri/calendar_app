import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';

class WeekNumberColumn extends StatelessWidget {
  const WeekNumberColumn({super.key, required this.weekNumbers});

  final List<int> weekNumbers;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Space aligning with the day-header row
        const SizedBox(height: 28),
        ...weekNumbers.map(
          (w) => Expanded(
            child: Center(
              child: Text(
                '$w',
                style: const TextStyle(
                  fontSize: 10,
                  color: AppColors.weekNumberColor,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

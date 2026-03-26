import 'package:flutter/material.dart';
import '../../../config/theme/app_colors.dart';

enum TimeRange {
  oneHour('1H', Duration(hours: 1)),
  sixHours('6H', Duration(hours: 6)),
  oneDay('24H', Duration(hours: 24)),
  sevenDays('7D', Duration(days: 7)),
  thirtyDays('30D', Duration(days: 30));

  final String label;
  final Duration duration;
  const TimeRange(this.label, this.duration);
}

class TimeRangeSelector extends StatelessWidget {
  final TimeRange selected;
  final ValueChanged<TimeRange> onChanged;

  const TimeRangeSelector({
    super.key,
    required this.selected,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: TimeRange.values.map((range) {
        final isSelected = range == selected;
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4),
          child: GestureDetector(
            onTap: () => onChanged(range),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: isSelected
                    ? AppColors.primary.withValues(alpha: 0.15)
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(6),
                border: Border.all(
                  color: isSelected ? AppColors.primary : AppColors.border,
                  width: isSelected ? 1.5 : 0.5,
                ),
              ),
              child: Text(
                range.label,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                  color: isSelected
                      ? AppColors.primary
                      : AppColors.textSecondary,
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}

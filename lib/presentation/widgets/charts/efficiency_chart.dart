import 'dart:math' as math;

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../config/theme/app_colors.dart';
import '../../../config/theme/app_spacing.dart';
import '../../../core/extensions/double_ext.dart';
import '../../../data/models/miner_snapshot.dart';
import 'time_range_selector.dart';

class EfficiencyChart extends StatelessWidget {
  final List<MinerSnapshot> snapshots;
  final TimeRange timeRange;

  const EfficiencyChart({
    super.key,
    required this.snapshots,
    this.timeRange = TimeRange.oneDay,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.cardDark,
        borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
        border: Border.all(color: AppColors.border, width: 0.5),
      ),
      padding: const EdgeInsets.all(AppSpacing.cardPadding),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Text(
                'Efficiency',
                style: TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              SizedBox(width: 8),
              Text(
                '(lower is better)',
                style: TextStyle(
                  color: AppColors.textMuted,
                  fontSize: 11,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          if (snapshots.isEmpty || !snapshots.any((s) => s.efficiency != null))
            const SizedBox(
              height: 200,
              child: Center(
                child: Text(
                  'No data',
                  style: TextStyle(
                    color: AppColors.textMuted,
                    fontSize: 14,
                  ),
                ),
              ),
            )
          else
            SizedBox(
              height: 200,
              child: LineChart(_buildChartData()),
            ),
        ],
      ),
    );
  }

  LineChartData _buildChartData() {
    final spots = <FlSpot>[];
    final startTime = snapshots.first.timestamp.millisecondsSinceEpoch.toDouble();
    final effValues = <double>[];

    for (int i = 0; i < snapshots.length; i++) {
      final eff = snapshots[i].efficiency;
      if (eff == null) continue;
      final x = (snapshots[i].timestamp.millisecondsSinceEpoch.toDouble() - startTime) / 1000;
      spots.add(FlSpot(x, eff));
      effValues.add(eff);
    }

    final minVal = effValues.reduce(math.min);
    final maxVal = effValues.reduce(math.max);
    final range = maxVal - minVal;
    final padding = range > 0 ? range * 0.1 : 1.0;
    final minY = (minVal - padding).clamp(0, double.infinity).toDouble();
    final maxY = maxVal + padding;
    final yInterval = (maxY - minY) / 4;

    return LineChartData(
      minY: minY,
      maxY: maxY,
      gridData: FlGridData(
        show: true,
        drawVerticalLine: false,
        horizontalInterval: yInterval > 0 ? yInterval : 1,
        getDrawingHorizontalLine: (value) => FlLine(
          color: AppColors.border.withValues(alpha: 0.3),
          strokeWidth: 0.5,
        ),
      ),
      titlesData: FlTitlesData(
        topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        leftTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            reservedSize: 52,
            interval: yInterval > 0 ? yInterval : 1,
            getTitlesWidget: (value, meta) {
              if (value == meta.min || value == meta.max) {
                return const SizedBox.shrink();
              }
              return Padding(
                padding: const EdgeInsets.only(right: 4),
                child: Text(
                  value.toEfficiencyString(),
                  style: const TextStyle(
                    color: AppColors.textMuted,
                    fontSize: 10,
                  ),
                  textAlign: TextAlign.right,
                ),
              );
            },
          ),
        ),
        bottomTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            reservedSize: 24,
            interval: _bottomInterval(spots),
            getTitlesWidget: (value, meta) {
              if (value == meta.min || value == meta.max) {
                return const SizedBox.shrink();
              }
              final ts = DateTime.fromMillisecondsSinceEpoch(
                (startTime + value * 1000).toInt(),
              );
              final label = timeRange.duration.inHours <= 24
                  ? DateFormat('HH:mm').format(ts)
                  : DateFormat('MM/dd').format(ts);
              return Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(
                  label,
                  style: const TextStyle(
                    color: AppColors.textMuted,
                    fontSize: 10,
                  ),
                ),
              );
            },
          ),
        ),
      ),
      borderData: FlBorderData(show: false),
      lineTouchData: LineTouchData(
        touchTooltipData: LineTouchTooltipData(
          getTooltipColor: (_) => AppColors.elevatedDark,
          tooltipBorder: const BorderSide(color: AppColors.border, width: 0.5),
          tooltipRoundedRadius: 8,
          getTooltipItems: (touchedSpots) {
            return touchedSpots.map((spot) {
              final ts = DateTime.fromMillisecondsSinceEpoch(
                (startTime + spot.x * 1000).toInt(),
              );
              return LineTooltipItem(
                '${spot.y.toEfficiencyString()}\n${DateFormat('HH:mm:ss').format(ts)}',
                const TextStyle(
                  color: AppColors.chartEfficiency,
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              );
            }).toList();
          },
        ),
        handleBuiltInTouches: true,
      ),
      lineBarsData: [
        LineChartBarData(
          spots: spots,
          isCurved: true,
          curveSmoothness: 0.3,
          color: AppColors.chartEfficiency,
          barWidth: 2.0,
          isStrokeCapRound: true,
          dotData: const FlDotData(show: false),
          belowBarData: BarAreaData(
            show: true,
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                AppColors.chartEfficiency.withValues(alpha: 0.2),
                AppColors.chartEfficiency.withValues(alpha: 0.0),
              ],
            ),
          ),
        ),
      ],
    );
  }

  double _bottomInterval(List<FlSpot> spots) {
    if (spots.length < 2) return 1;
    final totalSeconds = spots.last.x - spots.first.x;
    return totalSeconds / 5;
  }
}

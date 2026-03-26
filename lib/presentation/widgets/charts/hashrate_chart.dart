import 'dart:math' as math;

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../config/theme/app_colors.dart';
import '../../../config/theme/app_spacing.dart';
import '../../../core/extensions/double_ext.dart';
import '../../../data/models/miner_snapshot.dart';
import 'time_range_selector.dart';

class HashrateChart extends StatelessWidget {
  final List<MinerSnapshot> snapshots;
  final TimeRange timeRange;

  const HashrateChart({
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
          _buildHeader(),
          const SizedBox(height: AppSpacing.md),
          if (snapshots.isEmpty)
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

  Widget _buildHeader() {
    if (snapshots.isEmpty) {
      return const Text(
        'Hashrate',
        style: TextStyle(
          color: AppColors.textPrimary,
          fontSize: 16,
          fontWeight: FontWeight.w600,
        ),
      );
    }

    final values = snapshots.map((s) => s.hashrate).toList();
    final minVal = values.reduce(math.min);
    final maxVal = values.reduce(math.max);
    final avgVal = values.reduce((a, b) => a + b) / values.length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Hashrate',
          style: TextStyle(
            color: AppColors.textPrimary,
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: AppSpacing.xs),
        Row(
          children: [
            _statLabel('Min', minVal.toHashrateString()),
            const SizedBox(width: AppSpacing.lg),
            _statLabel('Avg', avgVal.toHashrateString()),
            const SizedBox(width: AppSpacing.lg),
            _statLabel('Max', maxVal.toHashrateString()),
          ],
        ),
      ],
    );
  }

  Widget _statLabel(String label, String value) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          '$label: ',
          style: const TextStyle(
            color: AppColors.textMuted,
            fontSize: 11,
          ),
        ),
        Text(
          value,
          style: const TextStyle(
            color: AppColors.textSecondary,
            fontSize: 11,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  LineChartData _buildChartData() {
    final spots = <FlSpot>[];
    final startTime = snapshots.first.timestamp.millisecondsSinceEpoch.toDouble();

    for (int i = 0; i < snapshots.length; i++) {
      final x = (snapshots[i].timestamp.millisecondsSinceEpoch.toDouble() - startTime) / 1000;
      spots.add(FlSpot(x, snapshots[i].hashrate));
    }

    final values = snapshots.map((s) => s.hashrate).toList();
    final minY = values.reduce(math.min) * 0.95;
    final maxY = values.reduce(math.max) * 1.05;

    return LineChartData(
      minY: minY,
      maxY: maxY,
      gridData: FlGridData(
        show: true,
        drawVerticalLine: false,
        horizontalInterval: (maxY - minY) / 4,
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
            reservedSize: 60,
            interval: (maxY - minY) / 4,
            getTitlesWidget: (value, meta) {
              if (value == meta.min || value == meta.max) {
                return const SizedBox.shrink();
              }
              return Padding(
                padding: const EdgeInsets.only(right: 4),
                child: Text(
                  value.toHashrateString(),
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
              final label = _formatTimeLabel(ts);
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
                '${spot.y.toHashrateString()}\n${DateFormat('HH:mm:ss').format(ts)}',
                const TextStyle(
                  color: AppColors.chartHashrate,
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
          color: AppColors.chartHashrate,
          barWidth: 2.0,
          isStrokeCapRound: true,
          dotData: const FlDotData(show: false),
          belowBarData: BarAreaData(
            show: true,
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                AppColors.chartHashrate.withValues(alpha: 0.25),
                AppColors.chartHashrate.withValues(alpha: 0.0),
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

  String _formatTimeLabel(DateTime ts) {
    if (timeRange.duration.inHours <= 24) {
      return DateFormat('HH:mm').format(ts);
    }
    return DateFormat('MM/dd').format(ts);
  }
}

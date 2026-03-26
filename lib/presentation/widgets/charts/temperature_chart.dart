import 'dart:math' as math;

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../config/theme/app_colors.dart';
import '../../../config/theme/app_spacing.dart';
import '../../../core/extensions/double_ext.dart';
import '../../../data/models/miner_snapshot.dart';
import 'time_range_selector.dart';

class TemperatureChart extends StatelessWidget {
  final List<MinerSnapshot> snapshots;
  final TimeRange timeRange;

  static const double _warningThreshold = 80.0;
  static const double _criticalThreshold = 90.0;

  const TemperatureChart({
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
          const SizedBox(height: AppSpacing.sm),
          _buildLegend(),
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
    return const Text(
      'Temperature',
      style: TextStyle(
        color: AppColors.textPrimary,
        fontSize: 16,
        fontWeight: FontWeight.w600,
      ),
    );
  }

  Widget _buildLegend() {
    return Row(
      children: [
        _legendDot(AppColors.chartTemp, 'ASIC'),
        const SizedBox(width: AppSpacing.md),
        _legendDot(AppColors.chartFan, 'VR'),
        const SizedBox(width: AppSpacing.md),
        _legendDot(const Color(0xFFD29922), '80C warn'),
        const SizedBox(width: AppSpacing.md),
        _legendDot(AppColors.error, '90C crit'),
      ],
    );
  }

  Widget _legendDot(Color color, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 4),
        Text(
          label,
          style: const TextStyle(
            color: AppColors.textMuted,
            fontSize: 10,
          ),
        ),
      ],
    );
  }

  LineChartData _buildChartData() {
    final asicSpots = <FlSpot>[];
    final vrSpots = <FlSpot>[];
    final startTime = snapshots.first.timestamp.millisecondsSinceEpoch.toDouble();

    double allMin = double.infinity;
    double allMax = double.negativeInfinity;

    for (int i = 0; i < snapshots.length; i++) {
      final x = (snapshots[i].timestamp.millisecondsSinceEpoch.toDouble() - startTime) / 1000;
      final asic = snapshots[i].asicTemp;
      final vr = snapshots[i].vrTemp;

      if (asic != null) {
        asicSpots.add(FlSpot(x, asic));
        allMin = math.min(allMin, asic);
        allMax = math.max(allMax, asic);
      }
      if (vr != null) {
        vrSpots.add(FlSpot(x, vr));
        allMin = math.min(allMin, vr);
        allMax = math.max(allMax, vr);
      }
    }

    // Ensure threshold lines are visible
    allMax = math.max(allMax, _criticalThreshold + 5);
    if (allMin.isInfinite) allMin = 0;
    if (allMax.isInfinite) allMax = 100;
    final minY = (allMin - 5).clamp(0, double.infinity).toDouble();
    final maxY = allMax + 5;

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
      extraLinesData: ExtraLinesData(
        horizontalLines: [
          HorizontalLine(
            y: _warningThreshold,
            color: const Color(0xFFD29922).withValues(alpha: 0.6),
            strokeWidth: 1,
            dashArray: [6, 4],
            label: HorizontalLineLabel(
              show: true,
              alignment: Alignment.topRight,
              padding: const EdgeInsets.only(right: 4, bottom: 2),
              style: const TextStyle(
                color: Color(0xFFD29922),
                fontSize: 9,
                fontWeight: FontWeight.w500,
              ),
              labelResolver: (_) => '80C',
            ),
          ),
          HorizontalLine(
            y: _criticalThreshold,
            color: AppColors.error.withValues(alpha: 0.6),
            strokeWidth: 1,
            dashArray: [6, 4],
            label: HorizontalLineLabel(
              show: true,
              alignment: Alignment.topRight,
              padding: const EdgeInsets.only(right: 4, bottom: 2),
              style: const TextStyle(
                color: AppColors.error,
                fontSize: 9,
                fontWeight: FontWeight.w500,
              ),
              labelResolver: (_) => '90C',
            ),
          ),
        ],
      ),
      titlesData: FlTitlesData(
        topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        leftTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            reservedSize: 40,
            interval: (maxY - minY) / 4,
            getTitlesWidget: (value, meta) {
              if (value == meta.min || value == meta.max) {
                return const SizedBox.shrink();
              }
              return Padding(
                padding: const EdgeInsets.only(right: 4),
                child: Text(
                  '${value.toInt()}C',
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
            interval: _bottomInterval(asicSpots.isNotEmpty ? asicSpots : vrSpots),
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
              final isAsic = spot.barIndex == 0;
              final label = isAsic ? 'ASIC' : 'VR';
              final color = isAsic ? AppColors.chartTemp : AppColors.chartFan;
              return LineTooltipItem(
                '$label: ${spot.y.toTempString()}',
                TextStyle(
                  color: color,
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
        if (asicSpots.isNotEmpty)
          LineChartBarData(
            spots: asicSpots,
            isCurved: true,
            curveSmoothness: 0.3,
            color: AppColors.chartTemp,
            barWidth: 2.0,
            isStrokeCapRound: true,
            dotData: const FlDotData(show: false),
            belowBarData: BarAreaData(
              show: true,
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  AppColors.chartTemp.withValues(alpha: 0.15),
                  AppColors.chartTemp.withValues(alpha: 0.0),
                ],
              ),
            ),
          ),
        if (vrSpots.isNotEmpty)
          LineChartBarData(
            spots: vrSpots,
            isCurved: true,
            curveSmoothness: 0.3,
            color: AppColors.chartFan,
            barWidth: 2.0,
            isStrokeCapRound: true,
            dotData: const FlDotData(show: false),
            belowBarData: BarAreaData(show: false),
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

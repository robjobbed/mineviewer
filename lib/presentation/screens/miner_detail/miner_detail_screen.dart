import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../config/theme/app_colors.dart';
import '../../../config/theme/app_spacing.dart';
import '../../../core/extensions/double_ext.dart';
import '../../../providers/miners/snapshot_history_provider.dart';
import '../../../utils/formatters.dart';
import '../../providers/miners_provider.dart';
import '../../widgets/charts/efficiency_chart.dart';
import '../../widgets/charts/hashrate_chart.dart';
import '../../widgets/charts/power_chart.dart';
import '../../widgets/charts/temperature_chart.dart';
import '../../widgets/charts/time_range_selector.dart';
import '../../widgets/miner_actions.dart';
import '../../widgets/overclock_controls.dart';
import '../../widgets/pool_config_card.dart';
import '../../widgets/stat_card.dart';
import '../../widgets/status_indicator.dart';

class MinerDetailScreen extends ConsumerStatefulWidget {
  final String minerId;

  const MinerDetailScreen({super.key, required this.minerId});

  @override
  ConsumerState<MinerDetailScreen> createState() => _MinerDetailScreenState();
}

class _MinerDetailScreenState extends ConsumerState<MinerDetailScreen> {
  TimeRange _selectedRange = TimeRange.oneHour;

  @override
  Widget build(BuildContext context) {
    final miner = ref.watch(minerByIdProvider(widget.minerId));
    final snapshot = ref.watch(minerLatestSnapshotProvider(widget.minerId));

    if (miner == null) {
      return Scaffold(
        appBar: AppBar(),
        body: const Center(
          child: Text(
            'Miner not found',
            style: TextStyle(color: AppColors.textSecondary),
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            StatusIndicator(status: miner.status, size: 8),
            const SizedBox(width: AppSpacing.sm),
            Flexible(
              child: Text(
                miner.name,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
            ),
          ],
        ),
      ),
      body: snapshot == null
          ? _buildLoadingState()
          : _buildContent(context, ref, miner, snapshot),
    );
  }

  Widget _buildLoadingState() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: 32,
            height: 32,
            child: CircularProgressIndicator(
              strokeWidth: 2.5,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          const Text(
            'Connecting to miner...',
            style: TextStyle(
              color: AppColors.textSecondary,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContent(
    BuildContext context,
    WidgetRef ref,
    dynamic miner,
    dynamic snapshot,
  ) {
    // Watch chart history based on selected time range
    final chartHistory = ref.watch(
      minerHistoryProvider((
        minerId: widget.minerId,
        range: _selectedRange.duration,
      )),
    );

    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSpacing.screenPadding),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 1. Stats grid (live data)
          _buildStatsGrid(snapshot),

          const SizedBox(height: AppSpacing.xl),

          // 2. Time range selector + Charts
          TimeRangeSelector(
            selected: _selectedRange,
            onChanged: (range) {
              setState(() => _selectedRange = range);
            },
          ),

          const SizedBox(height: AppSpacing.lg),

          _SectionHeader(title: 'CHARTS'),
          const SizedBox(height: AppSpacing.sm),

          HashrateChart(
            snapshots: chartHistory,
            timeRange: _selectedRange,
          ),
          const SizedBox(height: AppSpacing.md),

          TemperatureChart(
            snapshots: chartHistory,
            timeRange: _selectedRange,
          ),
          const SizedBox(height: AppSpacing.md),

          PowerChart(
            snapshots: chartHistory,
            timeRange: _selectedRange,
          ),
          const SizedBox(height: AppSpacing.md),

          EfficiencyChart(
            snapshots: chartHistory,
            timeRange: _selectedRange,
          ),

          const SizedBox(height: AppSpacing.xl),

          // 3. Pool Configuration
          _SectionHeader(title: 'POOL CONFIGURATION'),
          const SizedBox(height: AppSpacing.sm),
          PoolConfigCard(miner: miner, snapshot: snapshot),

          const SizedBox(height: AppSpacing.xl),

          // 4. Overclock Controls
          _SectionHeader(title: 'OVERCLOCK'),
          const SizedBox(height: AppSpacing.sm),
          OverclockControls(miner: miner, snapshot: snapshot),

          const SizedBox(height: AppSpacing.xl),

          // 5. Actions
          _SectionHeader(title: 'ACTIONS'),
          const SizedBox(height: AppSpacing.sm),
          MinerActions(miner: miner),

          const SizedBox(height: AppSpacing.xxl),
        ],
      ),
    );
  }

  Widget _buildStatsGrid(dynamic snapshot) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final crossAxisCount = constraints.maxWidth > 500 ? 4 : 2;
        return GridView.count(
          crossAxisCount: crossAxisCount,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: AppSpacing.sm,
          crossAxisSpacing: AppSpacing.sm,
          childAspectRatio: 1.6,
          children: [
            StatCard(
              label: 'Hashrate',
              value: _extractHashrateValue(snapshot.hashrate),
              unit: _extractHashrateUnit(snapshot.hashrate),
              icon: Icons.speed_rounded,
              valueColor: AppColors.chartHashrate,
            ),
            StatCard(
              label: 'ASIC Temp',
              value: snapshot.asicTemp?.toStringAsFixed(1) ?? '--',
              unit: 'C',
              icon: Icons.thermostat_rounded,
              valueColor: _tempColor(snapshot.asicTemp),
            ),
            StatCard(
              label: 'VR Temp',
              value: snapshot.vrTemp?.toStringAsFixed(1) ?? '--',
              unit: 'C',
              icon: Icons.thermostat_rounded,
              valueColor: _tempColor(snapshot.vrTemp),
            ),
            StatCard(
              label: 'Power',
              value: _extractPowerValue(snapshot.power),
              unit: _extractPowerUnit(snapshot.power),
              icon: Icons.bolt_rounded,
              valueColor: AppColors.chartPower,
            ),
            StatCard(
              label: 'Fan',
              value: snapshot.fanRpm?.toString() ?? '--',
              unit: 'RPM',
              icon: Icons.air_rounded,
              valueColor: AppColors.chartFan,
            ),
            StatCard(
              label: 'Efficiency',
              value: snapshot.efficiency?.toStringAsFixed(1) ?? '--',
              unit: 'J/TH',
              icon: Icons.eco_rounded,
              valueColor: AppColors.chartEfficiency,
            ),
            StatCard(
              label: 'Accepted',
              value: snapshot.acceptedShares?.toString() ?? '--',
              unit: 'shares',
              icon: Icons.check_circle_outline_rounded,
              valueColor: AppColors.online,
            ),
            StatCard(
              label: 'Uptime',
              value: snapshot.uptimeSeconds != null
                  ? Formatters.uptime(snapshot.uptimeSeconds!)
                  : '--',
              icon: Icons.timer_rounded,
            ),
          ],
        );
      },
    );
  }

  // -- Helpers for splitting formatted strings into value + unit --

  String _extractHashrateValue(double hashrate) {
    final full = hashrate.toHashrateString();
    return full.split(' ').first;
  }

  String _extractHashrateUnit(double hashrate) {
    final full = hashrate.toHashrateString();
    final parts = full.split(' ');
    return parts.length > 1 ? parts.last : '';
  }

  String _extractPowerValue(double? power) {
    if (power == null) return '--';
    final full = power.toPowerString();
    return full.split(' ').first;
  }

  String _extractPowerUnit(double? power) {
    if (power == null) return '';
    final full = power.toPowerString();
    final parts = full.split(' ');
    return parts.length > 1 ? parts.last : '';
  }

  Color _tempColor(double? temp) {
    if (temp == null) return AppColors.textPrimary;
    if (temp >= 80) return AppColors.error;
    if (temp >= 65) return AppColors.warning;
    return AppColors.chartTemp;
  }
}

// ---------------------------------------------------------------------------
// Section header
// ---------------------------------------------------------------------------

class _SectionHeader extends StatelessWidget {
  final String title;
  const _SectionHeader({required this.title});

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 11,
        fontWeight: FontWeight.w600,
        color: AppColors.textMuted,
        letterSpacing: 1.0,
      ),
    );
  }
}

import 'package:flutter/material.dart';

import '../../../config/theme/app_colors.dart';
import '../../../config/theme/app_spacing.dart';
import '../../../core/extensions/double_ext.dart';
import '../../../data/models/miner.dart';
import '../../../data/models/miner_snapshot.dart';
import '../../../data/models/miner_status.dart';

class FleetTicker extends StatefulWidget {
  final List<Miner> miners;
  final Map<String, MinerSnapshot> snapshots;

  const FleetTicker({
    super.key,
    required this.miners,
    required this.snapshots,
  });

  @override
  State<FleetTicker> createState() => _FleetTickerState();
}

class _FleetTickerState extends State<FleetTicker>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final ScrollController _scrollController;
  double _maxScrollExtent = 0;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 30),
    )..addListener(_onTick);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _maxScrollExtent = _scrollController.position.maxScrollExtent;
        if (_maxScrollExtent > 0) {
          _controller.repeat();
        }
      }
    });
  }

  void _onTick() {
    if (!_scrollController.hasClients || _maxScrollExtent <= 0) return;
    final offset = _controller.value * _maxScrollExtent;
    _scrollController.jumpTo(offset);
  }

  @override
  void didUpdateWidget(covariant FleetTicker oldWidget) {
    super.didUpdateWidget(oldWidget);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _maxScrollExtent = _scrollController.position.maxScrollExtent;
        if (_maxScrollExtent > 0 && !_controller.isAnimating) {
          _controller.repeat();
        }
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final stats = _computeStats();

    return Container(
      height: 30,
      width: double.infinity,
      color: AppColors.elevatedDark,
      child: SingleChildScrollView(
        controller: _scrollController,
        scrollDirection: Axis.horizontal,
        physics: const NeverScrollableScrollPhysics(),
        child: Row(
          children: [
            // Duplicate content for seamless looping
            ..._buildTickerItems(stats),
            const SizedBox(width: AppSpacing.xxl),
            ..._buildTickerItems(stats),
          ],
        ),
      ),
    );
  }

  List<Widget> _buildTickerItems(_FleetStats stats) {
    return [
      const SizedBox(width: AppSpacing.lg),
      _TickerItem(label: 'Shares', value: _formatInt(stats.totalShares)),
      _dot(),
      _TickerItem(
        label: 'Avg Temp',
        value: stats.avgTemp > 0 ? '${stats.avgTemp.toStringAsFixed(1)}C' : '--',
        valueColor: _tempColor(stats.avgTemp),
      ),
      _dot(),
      _TickerItem(
        label: 'Avg Eff',
        value: stats.avgEfficiency > 0
            ? '${stats.avgEfficiency.toStringAsFixed(1)} W/THs'
            : '--',
      ),
      _dot(),
      _TickerItem(
        label: 'Total Power',
        value: stats.totalPower.toPowerString(),
        valueColor: AppColors.chartPower,
      ),
      _dot(),
      _TickerItem(
        label: 'Total Hashrate',
        value: stats.totalHashrate.toHashrateString(),
        valueColor: AppColors.primary,
      ),
      _dot(),
      _TickerItem(
        label: 'Online',
        value: '${stats.onlineCount}/${widget.miners.length}',
        valueColor: stats.onlineCount == widget.miners.length
            ? AppColors.online
            : AppColors.warning,
      ),
      const SizedBox(width: AppSpacing.lg),
    ];
  }

  Widget _dot() {
    return const Padding(
      padding: EdgeInsets.symmetric(horizontal: AppSpacing.md),
      child: Text(
        '\u2022',
        style: TextStyle(
          fontSize: 8,
          color: AppColors.primary,
        ),
      ),
    );
  }

  Color _tempColor(double temp) {
    if (temp <= 0) return AppColors.textMuted;
    if (temp > 80) return AppColors.error;
    if (temp >= 60) return AppColors.warning;
    return AppColors.online;
  }

  _FleetStats _computeStats() {
    double totalHashrate = 0;
    double totalPower = 0;
    double totalTemp = 0;
    double totalEfficiency = 0;
    int totalShares = 0;
    int tempCount = 0;
    int efficiencyCount = 0;
    int onlineCount = 0;

    for (final miner in widget.miners) {
      if (miner.status == MinerStatus.online) onlineCount++;
      final snap = widget.snapshots[miner.id];
      if (snap == null) continue;

      totalHashrate += snap.hashrate;
      totalPower += snap.power ?? 0;
      totalShares += snap.acceptedShares ?? 0;

      if (snap.asicTemp != null && snap.asicTemp! > 0) {
        totalTemp += snap.asicTemp!;
        tempCount++;
      }
      if (snap.efficiency != null && snap.efficiency! > 0) {
        totalEfficiency += snap.efficiency!;
        efficiencyCount++;
      }
    }

    return _FleetStats(
      totalHashrate: totalHashrate,
      totalPower: totalPower,
      totalShares: totalShares,
      avgTemp: tempCount > 0 ? totalTemp / tempCount : 0,
      avgEfficiency: efficiencyCount > 0 ? totalEfficiency / efficiencyCount : 0,
      onlineCount: onlineCount,
    );
  }

  String _formatInt(int value) {
    if (value <= 0) return '0';
    final str = value.toString();
    final buf = StringBuffer();
    for (int i = 0; i < str.length; i++) {
      if (i > 0 && (str.length - i) % 3 == 0) buf.write(',');
      buf.write(str[i]);
    }
    return buf.toString();
  }
}

class _FleetStats {
  final double totalHashrate;
  final double totalPower;
  final int totalShares;
  final double avgTemp;
  final double avgEfficiency;
  final int onlineCount;

  const _FleetStats({
    required this.totalHashrate,
    required this.totalPower,
    required this.totalShares,
    required this.avgTemp,
    required this.avgEfficiency,
    required this.onlineCount,
  });
}

class _TickerItem extends StatelessWidget {
  final String label;
  final String value;
  final Color valueColor;

  const _TickerItem({
    required this.label,
    required this.value,
    this.valueColor = AppColors.textPrimary,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          '$label: ',
          style: const TextStyle(
            fontSize: 11,
            color: AppColors.textSecondary,
            fontWeight: FontWeight.w400,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: 11,
            color: valueColor,
            fontWeight: FontWeight.w600,
            fontFeatures: const [FontFeature.tabularFigures()],
          ),
        ),
      ],
    );
  }
}

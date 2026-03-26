import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../config/router/route_names.dart';
import '../../../config/theme/app_colors.dart';
import '../../../config/theme/app_spacing.dart';
import '../../../core/extensions/double_ext.dart';
import '../../../data/models/miner.dart';
import '../../../data/models/miner_snapshot.dart';
import '../../../data/models/miner_status.dart';

class RichMinerCard extends StatelessWidget {
  final Miner miner;
  final MinerSnapshot? snapshot;

  const RichMinerCard({
    super.key,
    required this.miner,
    this.snapshot,
  });

  Color get _statusColor => switch (miner.status) {
        MinerStatus.online => AppColors.online,
        MinerStatus.offline => AppColors.textMuted,
        MinerStatus.warning => AppColors.warning,
        MinerStatus.error => AppColors.error,
      };

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.cardDark,
      borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
      child: InkWell(
        borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
        onTap: () => context.goNamed(
          RouteNames.minerDetail,
          pathParameters: {'id': miner.id},
        ),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
            border: Border.all(color: AppColors.border, width: 0.5),
          ),
          child: IntrinsicHeight(
            child: Row(
              children: [
                // Colored left border
                Container(
                  width: 3,
                  decoration: BoxDecoration(
                    color: _statusColor,
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(AppSpacing.cardRadius),
                      bottomLeft: Radius.circular(AppSpacing.cardRadius),
                    ),
                  ),
                ),
                // Card content
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.all(AppSpacing.cardPadding),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildTopRow(),
                        const SizedBox(height: AppSpacing.xs),
                        _buildSecondRow(),
                        const SizedBox(height: AppSpacing.md),
                        _buildStatsGrid(),
                        const SizedBox(height: AppSpacing.md),
                        _buildBottomRow(),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Top row: status dot + name + pool badge + uptime
  // ---------------------------------------------------------------------------

  Widget _buildTopRow() {
    final isSolo = snapshot?.poolUrl?.contains('solo') ?? false;
    final uptimeStr = _formatUptime(snapshot?.uptimeSeconds);

    return Row(
      children: [
        // Status dot
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            color: _statusColor,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: _statusColor.withValues(alpha: 0.4),
                blurRadius: 4,
                spreadRadius: 1,
              ),
            ],
          ),
        ),
        const SizedBox(width: AppSpacing.sm),
        // Miner name
        Expanded(
          child: Text(
            miner.name,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        // Pool type badge
        Container(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.sm,
            vertical: 2,
          ),
          decoration: BoxDecoration(
            color: isSolo
                ? AppColors.online.withValues(alpha: 0.12)
                : const Color(0xFF58A6FF).withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(AppSpacing.chipRadius),
          ),
          child: Text(
            isSolo ? 'Solo Mining' : 'Pool',
            style: TextStyle(
              fontSize: 9,
              fontWeight: FontWeight.w600,
              color: isSolo ? AppColors.online : const Color(0xFF58A6FF),
              letterSpacing: 0.3,
            ),
          ),
        ),
        if (uptimeStr != null) ...[
          const SizedBox(width: AppSpacing.sm),
          Text(
            uptimeStr,
            style: const TextStyle(
              fontSize: 10,
              color: AppColors.textMuted,
              fontFeatures: [FontFeature.tabularFigures()],
            ),
          ),
        ],
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // Second row: model + IP
  // ---------------------------------------------------------------------------

  Widget _buildSecondRow() {
    return Row(
      children: [
        if (miner.model != null) ...[
          Text(
            miner.model!,
            style: const TextStyle(
              fontSize: 12,
              color: AppColors.textSecondary,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(width: AppSpacing.md),
        ],
        Text(
          miner.ipAddress,
          style: const TextStyle(
            fontSize: 11,
            color: AppColors.textMuted,
            fontFeatures: [FontFeature.tabularFigures()],
          ),
        ),
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // Stats grid (2x3)
  // ---------------------------------------------------------------------------

  Widget _buildStatsGrid() {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _StatCell(
                label: 'Real Hashrate',
                value: snapshot != null
                    ? snapshot!.hashrate.toHashrateString()
                    : '--',
                valueColor: AppColors.online,
                large: true,
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: _StatCell(
                label: 'Chip Temperature',
                value: snapshot?.asicTemp != null
                    ? '${snapshot!.asicTemp!.toStringAsFixed(1)}C'
                    : '--',
                valueColor: _tempColor(snapshot?.asicTemp),
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: _StatCell(
                label: 'VR Temp',
                value: snapshot?.vrTemp != null
                    ? '${snapshot!.vrTemp!.toStringAsFixed(1)}C'
                    : '--',
                valueColor: _tempColor(snapshot?.vrTemp),
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.sm),
        Row(
          children: [
            Expanded(
              child: _StatCell(
                label: 'Efficiency',
                value: _computeEfficiency(),
                unit: 'W/THs',
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: _StatCell(
                label: 'Best/Session',
                value: _formatBestDiff(),
                valueColor: AppColors.primary,
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: _StatCell(
                label: 'Power',
                value: snapshot?.power != null
                    ? snapshot!.power!.toPowerString()
                    : '--',
                valueColor: AppColors.chartPower,
              ),
            ),
          ],
        ),
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // Bottom row: pool status
  // ---------------------------------------------------------------------------

  Widget _buildBottomRow() {
    // Consider pool alive if we have a recent snapshot and miner is online
    final poolAlive = miner.status == MinerStatus.online && snapshot != null;

    return Row(
      children: [
        Icon(
          poolAlive ? Icons.check_circle_rounded : Icons.cancel_rounded,
          size: 14,
          color: poolAlive ? AppColors.online : AppColors.textMuted,
        ),
        const SizedBox(width: AppSpacing.xs),
        Text(
          poolAlive ? 'Pool: Alive' : 'Pool: --',
          style: TextStyle(
            fontSize: 11,
            color: poolAlive ? AppColors.online : AppColors.textMuted,
            fontWeight: FontWeight.w500,
          ),
        ),
        const Spacer(),
        const Icon(
          Icons.chevron_right_rounded,
          size: 16,
          color: AppColors.textMuted,
        ),
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // Helpers
  // ---------------------------------------------------------------------------

  Color _tempColor(double? temp) {
    if (temp == null) return AppColors.textMuted;
    if (temp > 80) return AppColors.error;
    if (temp >= 60) return AppColors.warning;
    return AppColors.online;
  }

  String? _formatUptime(int? seconds) {
    if (seconds == null || seconds <= 0) return null;
    final days = seconds ~/ 86400;
    final hours = (seconds % 86400) ~/ 3600;
    if (days > 0) return '${days}d ${hours}h';
    final mins = (seconds % 3600) ~/ 60;
    return '${hours}h ${mins}m';
  }

  String _computeEfficiency() {
    if (snapshot == null) return '--';
    // Prefer the snapshot's own efficiency value
    if (snapshot!.efficiency != null && snapshot!.efficiency! > 0) {
      return snapshot!.efficiency!.toStringAsFixed(1);
    }
    // Fallback: calculate from power / hashrate (W per TH/s)
    final power = snapshot!.power;
    final hashrate = snapshot!.hashrate;
    if (power != null && power > 0 && hashrate > 0) {
      final hashrateTHs = hashrate / 1e12;
      if (hashrateTHs > 0) {
        return (power / hashrateTHs).toStringAsFixed(1);
      }
    }
    return '--';
  }

  String _formatBestDiff() {
    final diff = snapshot?.difficulty;
    if (diff == null || diff <= 0) return '--';
    if (diff >= 1e9) return '${(diff / 1e9).toStringAsFixed(1)}G';
    if (diff >= 1e6) return '${(diff / 1e6).toStringAsFixed(1)}M';
    if (diff >= 1e3) return '${(diff / 1e3).toStringAsFixed(1)}K';
    return diff.toStringAsFixed(0);
  }
}

// ---------------------------------------------------------------------------
// Stat cell used in the 2x3 grid
// ---------------------------------------------------------------------------

class _StatCell extends StatelessWidget {
  final String label;
  final String value;
  final String? unit;
  final Color valueColor;
  final bool large;

  const _StatCell({
    required this.label,
    required this.value,
    this.unit,
    this.valueColor = AppColors.textPrimary,
    this.large = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: AppSpacing.xs + 2,
      ),
      decoration: BoxDecoration(
        color: AppColors.surfaceDark,
        borderRadius: BorderRadius.circular(AppSpacing.chipRadius),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 9,
              fontWeight: FontWeight.w600,
              color: AppColors.textMuted,
              letterSpacing: 0.3,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 2),
          Row(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Flexible(
                child: Text(
                  value,
                  style: TextStyle(
                    fontSize: large ? 15 : 13,
                    fontWeight: FontWeight.w700,
                    color: valueColor,
                    fontFeatures: const [FontFeature.tabularFigures()],
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (unit != null) ...[
                const SizedBox(width: 2),
                Text(
                  unit!,
                  style: const TextStyle(
                    fontSize: 9,
                    color: AppColors.textMuted,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../config/router/route_names.dart';
import '../../../config/theme/app_colors.dart';
import '../../../config/theme/app_spacing.dart';
import '../../../data/models/alert_event.dart';
import '../../../data/models/alert_rule.dart';
import '../../providers/alerts_provider.dart';
import '../../providers/miners_provider.dart';
import '../../widgets/empty_state.dart';

class AlertsScreen extends ConsumerWidget {
  const AlertsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Activate alert evaluation whenever this screen is visible
    ref.watch(alertEvaluationProvider);

    final events = ref.watch(alertEventsProvider);
    final rules = ref.watch(alertRulesProvider);
    final miners = ref.watch(minersProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Alerts',
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
        actions: [
          if (events.isNotEmpty)
            PopupMenuButton<String>(
              icon: const Icon(Icons.more_vert_rounded),
              onSelected: (value) {
                if (value == 'clear') {
                  ref.read(alertEventsProvider.notifier).clearAll();
                }
              },
              itemBuilder: (_) => [
                const PopupMenuItem(
                  value: 'clear',
                  child: Text('Clear All'),
                ),
              ],
            ),
          IconButton(
            icon: const Icon(Icons.tune_rounded),
            tooltip: 'Alert Rules',
            onPressed: () => context.goNamed(RouteNames.alertRules),
          ),
        ],
      ),
      body: events.isEmpty
          ? const EmptyState(
              icon: Icons.notifications_none_rounded,
              title: 'No alerts yet',
              subtitle:
                  'Configure alert rules to get notified when\nyour miners need attention.',
            )
          : ListView.builder(
              padding: const EdgeInsets.symmetric(
                vertical: AppSpacing.sm,
                horizontal: AppSpacing.screenPadding,
              ),
              itemCount: events.length,
              itemBuilder: (context, index) {
                final event = events[index];
                final rule = rules
                    .where((r) => r.id == event.ruleId)
                    .firstOrNull;
                final miner = miners
                    .where((m) => m.id == event.minerId)
                    .firstOrNull;

                return _AlertEventTile(
                  event: event,
                  rule: rule,
                  minerName: miner?.name ?? event.minerId,
                  onAcknowledge: () {
                    ref
                        .read(alertEventsProvider.notifier)
                        .acknowledgeEvent(index);
                  },
                );
              },
            ),
    );
  }
}

class _AlertEventTile extends StatelessWidget {
  final AlertEvent event;
  final AlertRule? rule;
  final String minerName;
  final VoidCallback onAcknowledge;

  const _AlertEventTile({
    required this.event,
    required this.rule,
    required this.minerName,
    required this.onAcknowledge,
  });

  @override
  Widget build(BuildContext context) {
    final metric = rule?.metric;
    final iconData = _metricIcon(metric);
    final iconColor = _metricColor(metric);
    final dimmed = event.acknowledged;

    final thresholdText = rule != null
        ? '${_formatNumber(event.actualValue)}${rule!.metric.unit}'
            ' (threshold: ${rule!.condition.displayName.toLowerCase()}'
            ' ${_formatNumber(rule!.threshold)}${rule!.metric.unit})'
        : '${_formatNumber(event.actualValue)}';

    final timeAgo = _relativeTime(event.triggeredAt);

    return Opacity(
      opacity: dimmed ? 0.45 : 1.0,
      child: Card(
        color: AppColors.cardDark,
        margin: const EdgeInsets.only(bottom: AppSpacing.sm),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
          side: BorderSide(
            color: dimmed ? AppColors.border : iconColor.withValues(alpha: 0.3),
            width: 0.5,
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.cardPadding),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: iconColor.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(AppSpacing.chipRadius),
                ),
                child: Icon(iconData, color: iconColor, size: 20),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            metric?.displayName ?? 'Alert',
                            style:
                                Theme.of(context).textTheme.bodyLarge?.copyWith(
                                      color: AppColors.textPrimary,
                                      fontWeight: FontWeight.w600,
                                    ),
                          ),
                        ),
                        Text(
                          timeAgo,
                          style:
                              Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: AppColors.textMuted,
                                  ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      minerName,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: AppColors.textSecondary,
                          ),
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      thresholdText,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: AppColors.textSecondary,
                          ),
                    ),
                  ],
                ),
              ),
              if (!event.acknowledged)
                IconButton(
                  icon: const Icon(
                    Icons.check_circle_outline_rounded,
                    size: 20,
                  ),
                  color: AppColors.textMuted,
                  tooltip: 'Acknowledge',
                  onPressed: onAcknowledge,
                  constraints: const BoxConstraints(
                    minWidth: 36,
                    minHeight: 36,
                  ),
                  padding: EdgeInsets.zero,
                ),
            ],
          ),
        ),
      ),
    );
  }

  IconData _metricIcon(AlertMetric? metric) {
    if (metric == null) return Icons.warning_amber_rounded;
    return switch (metric) {
      AlertMetric.asicTemp ||
      AlertMetric.vrTemp ||
      AlertMetric.ambientTemp =>
        Icons.thermostat_rounded,
      AlertMetric.hashrate || AlertMetric.hashrateDrop => Icons.speed_rounded,
      AlertMetric.power => Icons.bolt_rounded,
      AlertMetric.efficiency => Icons.eco_rounded,
      AlertMetric.fanSpeed => Icons.air_rounded,
      AlertMetric.offline => Icons.cloud_off_rounded,
      AlertMetric.rejectedShares => Icons.error_outline_rounded,
    };
  }

  Color _metricColor(AlertMetric? metric) {
    if (metric == null) return AppColors.warning;
    return switch (metric) {
      AlertMetric.asicTemp ||
      AlertMetric.vrTemp ||
      AlertMetric.ambientTemp =>
        AppColors.chartTemp,
      AlertMetric.hashrate || AlertMetric.hashrateDrop => AppColors.chartHashrate,
      AlertMetric.power => AppColors.chartPower,
      AlertMetric.efficiency => AppColors.chartEfficiency,
      AlertMetric.fanSpeed => AppColors.chartFan,
      AlertMetric.offline => AppColors.offline,
      AlertMetric.rejectedShares => AppColors.error,
    };
  }

  String _formatNumber(double value) {
    if (value == value.roundToDouble()) {
      return value.toInt().toString();
    }
    return value.toStringAsFixed(1);
  }

  String _relativeTime(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inSeconds < 60) return 'just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    return '${diff.inDays}d ago';
  }
}

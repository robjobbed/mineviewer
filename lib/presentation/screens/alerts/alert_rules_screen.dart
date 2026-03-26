import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../config/theme/app_colors.dart';
import '../../../config/theme/app_spacing.dart';
import '../../../data/models/alert_rule.dart';
import '../../providers/alerts_provider.dart';
import '../../providers/miners_provider.dart';

class AlertRulesScreen extends ConsumerWidget {
  const AlertRulesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final rules = ref.watch(alertRulesProvider);
    final miners = ref.watch(minersProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Alert Rules',
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddRuleSheet(context, ref),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.black,
        child: const Icon(Icons.add_rounded),
      ),
      body: rules.isEmpty
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.xxl),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.tune_rounded,
                      size: 64,
                      color: AppColors.textMuted,
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    Text(
                      'No alert rules',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            color: AppColors.textPrimary,
                          ),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    Text(
                      'Tap + to create your first alert rule.',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: AppColors.textSecondary,
                          ),
                    ),
                  ],
                ),
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.symmetric(
                vertical: AppSpacing.sm,
                horizontal: AppSpacing.screenPadding,
              ),
              itemCount: rules.length,
              itemBuilder: (context, index) {
                final rule = rules[index];
                final miner = rule.minerId != null
                    ? miners.where((m) => m.id == rule.minerId).firstOrNull
                    : null;
                final minerLabel =
                    rule.minerId == null ? 'All Miners' : (miner?.name ?? rule.minerId!);

                return Dismissible(
                  key: ValueKey(rule.id),
                  direction: DismissDirection.endToStart,
                  background: Container(
                    alignment: Alignment.centerRight,
                    padding: const EdgeInsets.only(right: AppSpacing.xl),
                    margin: const EdgeInsets.only(bottom: AppSpacing.sm),
                    decoration: BoxDecoration(
                      color: AppColors.error.withValues(alpha: 0.2),
                      borderRadius:
                          BorderRadius.circular(AppSpacing.cardRadius),
                    ),
                    child: const Icon(
                      Icons.delete_rounded,
                      color: AppColors.error,
                    ),
                  ),
                  onDismissed: (_) {
                    ref.read(alertRulesProvider.notifier).removeRule(rule.id);
                  },
                  child: _RuleTile(
                    rule: rule,
                    minerLabel: minerLabel,
                    onToggle: () {
                      ref
                          .read(alertRulesProvider.notifier)
                          .toggleRule(rule.id);
                    },
                  ),
                );
              },
            ),
    );
  }

  void _showAddRuleSheet(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surfaceDark,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (_) => _AddRuleSheet(ref: ref),
    );
  }
}

// ---------------------------------------------------------------------------
// Rule Tile
// ---------------------------------------------------------------------------

class _RuleTile extends StatelessWidget {
  final AlertRule rule;
  final String minerLabel;
  final VoidCallback onToggle;

  const _RuleTile({
    required this.rule,
    required this.minerLabel,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    final conditionText =
        '${rule.metric.displayName} ${rule.condition.displayName.toLowerCase()}'
        ' ${_formatThreshold(rule.threshold)}${rule.metric.unit}';

    final durationText = rule.durationSeconds > 0
        ? ' for ${rule.durationSeconds}s'
        : '';

    return Card(
      color: AppColors.cardDark,
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
        side: const BorderSide(color: AppColors.border, width: 0.5),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.cardPadding,
          vertical: AppSpacing.md,
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: _metricColor(rule.metric).withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(AppSpacing.chipRadius),
              ),
              child: Icon(
                _metricIcon(rule.metric),
                color: _metricColor(rule.metric),
                size: 20,
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '$conditionText$durationText',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: AppColors.textPrimary,
                          fontWeight: FontWeight.w500,
                        ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    minerLabel,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppColors.textSecondary,
                        ),
                  ),
                ],
              ),
            ),
            Switch.adaptive(
              value: rule.enabled,
              onChanged: (_) => onToggle(),
              activeColor: AppColors.primary,
            ),
          ],
        ),
      ),
    );
  }

  IconData _metricIcon(AlertMetric metric) {
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

  Color _metricColor(AlertMetric metric) {
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

  String _formatThreshold(double value) {
    if (value == value.roundToDouble()) {
      return value.toInt().toString();
    }
    return value.toStringAsFixed(1);
  }
}

// ---------------------------------------------------------------------------
// Add Rule Bottom Sheet
// ---------------------------------------------------------------------------

class _AddRuleSheet extends ConsumerStatefulWidget {
  final WidgetRef ref;
  const _AddRuleSheet({required this.ref});

  @override
  ConsumerState<_AddRuleSheet> createState() => _AddRuleSheetState();
}

class _AddRuleSheetState extends ConsumerState<_AddRuleSheet> {
  String? _selectedMinerId; // null = All Miners
  AlertMetric _selectedMetric = AlertMetric.asicTemp;
  AlertCondition _selectedCondition = AlertCondition.above;
  final _thresholdController = TextEditingController();
  final _durationController = TextEditingController();

  @override
  void dispose() {
    _thresholdController.dispose();
    _durationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final miners = ref.watch(minersProvider);
    final bottomInset = MediaQuery.viewInsetsOf(context).bottom;

    return Padding(
      padding: EdgeInsets.only(
        left: AppSpacing.screenPadding,
        right: AppSpacing.screenPadding,
        top: AppSpacing.xl,
        bottom: bottomInset + AppSpacing.xl,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Handle bar
          Center(
            child: Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.textMuted,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.xl),
          Text(
            'Add Alert Rule',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.w700,
                ),
          ),
          const SizedBox(height: AppSpacing.xl),

          // Miner dropdown
          _DropdownField<String?>(
            label: 'Miner',
            value: _selectedMinerId,
            items: [
              const DropdownMenuItem(value: null, child: Text('All Miners')),
              ...miners.map((m) => DropdownMenuItem(
                    value: m.id,
                    child: Text(m.name),
                  )),
            ],
            onChanged: (v) => setState(() => _selectedMinerId = v),
          ),
          const SizedBox(height: AppSpacing.md),

          // Metric dropdown
          _DropdownField<AlertMetric>(
            label: 'Metric',
            value: _selectedMetric,
            items: AlertMetric.values
                .map((m) => DropdownMenuItem(
                      value: m,
                      child: Text(m.displayName),
                    ))
                .toList(),
            onChanged: (v) {
              if (v != null) setState(() => _selectedMetric = v);
            },
          ),
          const SizedBox(height: AppSpacing.md),

          // Condition dropdown
          _DropdownField<AlertCondition>(
            label: 'Condition',
            value: _selectedCondition,
            items: AlertCondition.values
                .map((c) => DropdownMenuItem(
                      value: c,
                      child: Text(c.displayName),
                    ))
                .toList(),
            onChanged: (v) {
              if (v != null) setState(() => _selectedCondition = v);
            },
          ),
          const SizedBox(height: AppSpacing.md),

          // Threshold
          _LabeledTextField(
            label: 'Threshold (${_selectedMetric.unit})',
            controller: _thresholdController,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
          ),
          const SizedBox(height: AppSpacing.md),

          // Duration (optional)
          _LabeledTextField(
            label: 'Sustained for (seconds, optional)',
            controller: _durationController,
            keyboardType: TextInputType.number,
          ),
          const SizedBox(height: AppSpacing.xl),

          // Save button
          FilledButton(
            onPressed: _save,
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.black,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppSpacing.chipRadius),
              ),
            ),
            child: const Text(
              'Save Rule',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }

  void _save() {
    final threshold = double.tryParse(_thresholdController.text.trim());
    if (threshold == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Enter a valid threshold number')),
      );
      return;
    }

    final duration = int.tryParse(_durationController.text.trim()) ?? 0;

    final rule = AlertRule(
      id: '', // Will be assigned by notifier
      minerId: _selectedMinerId,
      metric: _selectedMetric,
      condition: _selectedCondition,
      threshold: threshold,
      durationSeconds: duration,
    );

    widget.ref.read(alertRulesProvider.notifier).addRule(rule);
    Navigator.of(context).pop();
  }
}

// ---------------------------------------------------------------------------
// Reusable form widgets
// ---------------------------------------------------------------------------

class _DropdownField<T> extends StatelessWidget {
  final String label;
  final T value;
  final List<DropdownMenuItem<T>> items;
  final ValueChanged<T?> onChanged;

  const _DropdownField({
    required this.label,
    required this.value,
    required this.items,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: AppColors.textSecondary,
                fontWeight: FontWeight.w500,
              ),
        ),
        const SizedBox(height: AppSpacing.xs),
        DropdownButtonFormField<T>(
          value: value,
          items: items,
          onChanged: onChanged,
          dropdownColor: AppColors.elevatedDark,
          decoration: InputDecoration(
            filled: true,
            fillColor: AppColors.cardDark,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppSpacing.chipRadius),
              borderSide: const BorderSide(color: AppColors.border),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppSpacing.chipRadius),
              borderSide: const BorderSide(color: AppColors.border),
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.md,
              vertical: AppSpacing.md,
            ),
          ),
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: AppColors.textPrimary,
              ),
        ),
      ],
    );
  }
}

class _LabeledTextField extends StatelessWidget {
  final String label;
  final TextEditingController controller;
  final TextInputType? keyboardType;

  const _LabeledTextField({
    required this.label,
    required this.controller,
    this.keyboardType,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: AppColors.textSecondary,
                fontWeight: FontWeight.w500,
              ),
        ),
        const SizedBox(height: AppSpacing.xs),
        TextField(
          controller: controller,
          keyboardType: keyboardType,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: AppColors.textPrimary,
              ),
          decoration: InputDecoration(
            filled: true,
            fillColor: AppColors.cardDark,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppSpacing.chipRadius),
              borderSide: const BorderSide(color: AppColors.border),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppSpacing.chipRadius),
              borderSide: const BorderSide(color: AppColors.border),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppSpacing.chipRadius),
              borderSide: const BorderSide(color: AppColors.primary),
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.md,
              vertical: AppSpacing.md,
            ),
          ),
        ),
      ],
    );
  }
}

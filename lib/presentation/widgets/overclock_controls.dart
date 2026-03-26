import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../config/theme/app_colors.dart';
import '../../config/theme/app_spacing.dart';
import '../../data/models/miner.dart';
import '../../data/models/miner_config.dart';
import '../../data/models/miner_snapshot.dart';
import '../../drivers/driver_registry.dart';
import '../../drivers/miner_driver.dart';

/// Dynamic overclock control panel.
///
/// Inspects [DriverRegistry] capabilities for the given [Miner.type] and
/// renders only the sliders that the driver advertises.
class OverclockControls extends ConsumerStatefulWidget {
  final Miner miner;
  final MinerSnapshot snapshot;

  const OverclockControls({
    super.key,
    required this.miner,
    required this.snapshot,
  });

  @override
  ConsumerState<OverclockControls> createState() => _OverclockControlsState();
}

class _OverclockControlsState extends ConsumerState<OverclockControls> {
  late final MinerDriver _driver;

  // Slider state
  double _frequency = 400;
  double _voltage = 1200;
  double _hashrateTarget = 50;
  double _powerTarget = 1000;
  double _fanSpeed = 100;
  bool _autoFan = true;

  bool _applying = false;

  @override
  void initState() {
    super.initState();
    _driver = DriverRegistry.getDriver(widget.miner.type);
    _initFromSnapshot();
  }

  @override
  void didUpdateWidget(covariant OverclockControls oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.snapshot != widget.snapshot) {
      _initFromSnapshot();
    }
  }

  void _initFromSnapshot() {
    final s = widget.snapshot;
    // Best-effort: use snapshot values as starting points when available.
    if (s.fanSpeedPct != null) {
      _fanSpeed = s.fanSpeedPct!.toDouble().clamp(0, 100);
    }
  }

  Set<OverclockCapability> get _caps => _driver.overclockCapabilities;

  @override
  Widget build(BuildContext context) {
    if (_caps.isEmpty) {
      return _buildEmptyCard();
    }

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: AppColors.cardDark,
        borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
        border: Border.all(color: AppColors.border, width: 0.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Safety banner
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.cardPadding,
              vertical: AppSpacing.md,
            ),
            decoration: BoxDecoration(
              color: AppColors.warning.withValues(alpha: 0.10),
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(AppSpacing.cardRadius),
                topRight: Radius.circular(AppSpacing.cardRadius),
              ),
            ),
            child: Row(
              children: [
                const Icon(Icons.warning_amber_rounded,
                    size: 16, color: AppColors.warning),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Text(
                    'Overclocking can damage your hardware. Use at your own risk.',
                    style: TextStyle(
                      fontSize: 12,
                      color: AppColors.warning,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),

          Padding(
            padding: const EdgeInsets.all(AppSpacing.cardPadding),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (_caps.contains(OverclockCapability.frequency))
                  _SliderGroup(
                    label: 'Frequency',
                    value: _frequency,
                    min: 100,
                    max: 600,
                    divisions: 50,
                    unit: 'MHz',
                    activeColor: AppColors.primary,
                    onChanged: (v) => setState(() => _frequency = v),
                    onApply: () => _applyConfig(
                      MinerConfig(frequency: _frequency.round()),
                    ),
                    isApplying: _applying,
                  ),
                if (_caps.contains(OverclockCapability.voltage)) ...[
                  const SizedBox(height: AppSpacing.lg),
                  _SliderGroup(
                    label: 'Core Voltage',
                    value: _voltage,
                    min: 1000,
                    max: 1300,
                    divisions: 30,
                    unit: 'mV',
                    activeColor: AppColors.chartPower,
                    onChanged: (v) => setState(() => _voltage = v),
                    onApply: () => _applyConfig(
                      MinerConfig(coreVoltage: _voltage.round()),
                    ),
                    isApplying: _applying,
                  ),
                ],
                if (_caps.contains(OverclockCapability.hashrateTarget)) ...[
                  const SizedBox(height: AppSpacing.lg),
                  _SliderGroup(
                    label: 'Hashrate Target',
                    value: _hashrateTarget,
                    min: 10,
                    max: 200,
                    divisions: 38,
                    unit: 'TH/s',
                    activeColor: AppColors.chartHashrate,
                    onChanged: (v) => setState(() => _hashrateTarget = v),
                    onApply: () => _applyConfig(
                      MinerConfig(hashrateTarget: _hashrateTarget),
                    ),
                    isApplying: _applying,
                  ),
                ],
                if (_caps.contains(OverclockCapability.powerTarget)) ...[
                  const SizedBox(height: AppSpacing.lg),
                  _SliderGroup(
                    label: 'Power Target',
                    value: _powerTarget,
                    min: 100,
                    max: 5000,
                    divisions: 49,
                    unit: 'W',
                    activeColor: AppColors.chartPower,
                    onChanged: (v) => setState(() => _powerTarget = v),
                    onApply: () => _applyConfig(
                      MinerConfig(powerTarget: _powerTarget),
                    ),
                    isApplying: _applying,
                  ),
                ],
                if (_caps.contains(OverclockCapability.fanSpeed)) ...[
                  const SizedBox(height: AppSpacing.lg),
                  _FanSliderGroup(
                    fanSpeed: _fanSpeed,
                    autoFan: _autoFan,
                    activeColor: AppColors.chartFan,
                    onFanChanged: (v) => setState(() => _fanSpeed = v),
                    onAutoFanChanged: (v) =>
                        setState(() => _autoFan = v ?? false),
                    onApply: () => _applyConfig(
                      MinerConfig(
                        fanSpeedPct: _autoFan ? null : _fanSpeed.round(),
                        autoFan: _autoFan,
                      ),
                    ),
                    isApplying: _applying,
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.cardPadding),
      decoration: BoxDecoration(
        color: AppColors.cardDark,
        borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
        border: Border.all(color: AppColors.border, width: 0.5),
      ),
      child: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: AppSpacing.lg),
          child: Text(
            'No overclock controls available for this miner type.',
            style: TextStyle(
              color: AppColors.textSecondary,
              fontSize: 13,
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _applyConfig(MinerConfig config) async {
    setState(() => _applying = true);
    try {
      final result = await _driver.applyConfig(
        widget.miner.ipAddress,
        config,
        port: widget.miner.port,
      );
      if (!mounted) return;
      result.when(
        success: (_) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Configuration applied'),
              behavior: SnackBarBehavior.floating,
              backgroundColor: AppColors.online,
            ),
          );
        },
        failure: (msg, _) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed: $msg'),
              behavior: SnackBarBehavior.floating,
              backgroundColor: AppColors.error,
            ),
          );
        },
      );
    } finally {
      if (mounted) setState(() => _applying = false);
    }
  }
}

// ---------------------------------------------------------------------------
// Generic slider group
// ---------------------------------------------------------------------------

class _SliderGroup extends StatelessWidget {
  final String label;
  final double value;
  final double min;
  final double max;
  final int divisions;
  final String unit;
  final Color activeColor;
  final ValueChanged<double> onChanged;
  final VoidCallback onApply;
  final bool isApplying;

  const _SliderGroup({
    required this.label,
    required this.value,
    required this.min,
    required this.max,
    required this.divisions,
    required this.unit,
    required this.activeColor,
    required this.onChanged,
    required this.onApply,
    required this.isApplying,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
            Text(
              '${value.round()} $unit',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                fontFamily: 'monospace',
                color: activeColor,
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.xs),
        Row(
          children: [
            Text(
              '${min.round()}',
              style: const TextStyle(
                  fontSize: 10, color: AppColors.textMuted),
            ),
            Expanded(
              child: SliderTheme(
                data: SliderThemeData(
                  activeTrackColor: activeColor,
                  inactiveTrackColor: activeColor.withValues(alpha: 0.15),
                  thumbColor: activeColor,
                  overlayColor: activeColor.withValues(alpha: 0.12),
                  trackHeight: 3,
                  thumbShape:
                      const RoundSliderThumbShape(enabledThumbRadius: 7),
                ),
                child: Slider(
                  value: value,
                  min: min,
                  max: max,
                  divisions: divisions,
                  onChanged: onChanged,
                ),
              ),
            ),
            Text(
              '${max.round()}',
              style: const TextStyle(
                  fontSize: 10, color: AppColors.textMuted),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.xs),
        Align(
          alignment: Alignment.centerRight,
          child: _ApplyButton(
            onPressed: isApplying ? null : onApply,
            isLoading: isApplying,
          ),
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Fan slider with auto-fan toggle
// ---------------------------------------------------------------------------

class _FanSliderGroup extends StatelessWidget {
  final double fanSpeed;
  final bool autoFan;
  final Color activeColor;
  final ValueChanged<double> onFanChanged;
  final ValueChanged<bool?> onAutoFanChanged;
  final VoidCallback onApply;
  final bool isApplying;

  const _FanSliderGroup({
    required this.fanSpeed,
    required this.autoFan,
    required this.activeColor,
    required this.onFanChanged,
    required this.onAutoFanChanged,
    required this.onApply,
    required this.isApplying,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Fan Speed',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  autoFan ? 'Auto' : '${fanSpeed.round()}%',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    fontFamily: 'monospace',
                    color: activeColor,
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                SizedBox(
                  height: 24,
                  child: Switch.adaptive(
                    value: autoFan,
                    onChanged: onAutoFanChanged,
                    activeTrackColor: activeColor,
                    activeThumbColor: Colors.white,
                    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                ),
                const SizedBox(width: AppSpacing.xs),
                const Text(
                  'Auto',
                  style: TextStyle(
                    fontSize: 11,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.xs),
        IgnorePointer(
          ignoring: autoFan,
          child: Opacity(
            opacity: autoFan ? 0.35 : 1.0,
            child: Row(
              children: [
                const Text('0',
                    style:
                        TextStyle(fontSize: 10, color: AppColors.textMuted)),
                Expanded(
                  child: SliderTheme(
                    data: SliderThemeData(
                      activeTrackColor: activeColor,
                      inactiveTrackColor:
                          activeColor.withValues(alpha: 0.15),
                      thumbColor: activeColor,
                      overlayColor: activeColor.withValues(alpha: 0.12),
                      trackHeight: 3,
                      thumbShape: const RoundSliderThumbShape(
                          enabledThumbRadius: 7),
                    ),
                    child: Slider(
                      value: fanSpeed,
                      min: 0,
                      max: 100,
                      divisions: 20,
                      onChanged: onFanChanged,
                    ),
                  ),
                ),
                const Text('100',
                    style:
                        TextStyle(fontSize: 10, color: AppColors.textMuted)),
              ],
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.xs),
        Align(
          alignment: Alignment.centerRight,
          child: _ApplyButton(
            onPressed: isApplying ? null : onApply,
            isLoading: isApplying,
          ),
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Shared apply button
// ---------------------------------------------------------------------------

class _ApplyButton extends StatelessWidget {
  final VoidCallback? onPressed;
  final bool isLoading;

  const _ApplyButton({required this.onPressed, this.isLoading = false});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 30,
      child: TextButton(
        onPressed: onPressed,
        style: TextButton.styleFrom(
          backgroundColor: AppColors.primary.withValues(alpha: 0.12),
          foregroundColor: AppColors.primary,
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppSpacing.chipRadius),
          ),
          textStyle: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
        ),
        child: isLoading
            ? const SizedBox(
                width: 14,
                height: 14,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: AppColors.primary,
                ),
              )
            : const Text('Apply'),
      ),
    );
  }
}

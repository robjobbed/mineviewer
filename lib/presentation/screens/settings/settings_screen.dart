import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../config/router/route_names.dart';
import '../../../config/theme/app_colors.dart';
import '../../../config/theme/app_spacing.dart';
import '../../../data/models/miner.dart';
import '../../../data/models/miner_snapshot.dart';
import '../../../data/models/miner_type.dart';
import '../../providers/miners_provider.dart';
import '../../providers/profitability_provider.dart';
import '../../widgets/export_dialog.dart';

// ---------------------------------------------------------------------------
// Providers / Notifiers
// ---------------------------------------------------------------------------

class PrivacyModeNotifier extends Notifier<bool> {
  @override
  bool build() => false;

  void toggle() => state = !state;
  void set(bool value) => state = value;
}

final privacyModeProvider =
    NotifierProvider<PrivacyModeNotifier, bool>(PrivacyModeNotifier.new);

class HapticsEnabledNotifier extends Notifier<bool> {
  @override
  bool build() => false;

  void toggle() => state = !state;
  void set(bool value) => state = value;
}

final hapticsEnabledProvider =
    NotifierProvider<HapticsEnabledNotifier, bool>(HapticsEnabledNotifier.new);

class HapticStrengthNotifier extends Notifier<String> {
  @override
  String build() => 'Light';

  void set(String value) => state = value;
}

final hapticStrengthProvider =
    NotifierProvider<HapticStrengthNotifier, String>(
        HapticStrengthNotifier.new);

class RefreshRateNotifier extends Notifier<int> {
  @override
  int build() => 10;

  void set(int seconds) => state = seconds;
}

final refreshRateProvider =
    NotifierProvider<RefreshRateNotifier, int>(RefreshRateNotifier.new);

class TempAlertsNotifier extends Notifier<bool> {
  @override
  bool build() => false;

  void toggle() => state = !state;
  void set(bool value) => state = value;
}

final tempAlertsProvider =
    NotifierProvider<TempAlertsNotifier, bool>(TempAlertsNotifier.new);

class ChipTempFahrenheitNotifier extends Notifier<bool> {
  @override
  bool build() => false;

  void toggle() => state = !state;
  void set(bool value) => state = value;
}

final chipTempFahrenheitProvider =
    NotifierProvider<ChipTempFahrenheitNotifier, bool>(
        ChipTempFahrenheitNotifier.new);

class ExhaustTempFahrenheitNotifier extends Notifier<bool> {
  @override
  bool build() => false;

  void toggle() => state = !state;
  void set(bool value) => state = value;
}

final exhaustTempFahrenheitProvider =
    NotifierProvider<ExhaustTempFahrenheitNotifier, bool>(
        ExhaustTempFahrenheitNotifier.new);

class CurrencyNotifier extends Notifier<String> {
  @override
  String build() => 'USD';

  void set(String value) => state = value;
}

final currencyProvider =
    NotifierProvider<CurrencyNotifier, String>(CurrencyNotifier.new);

// ---------------------------------------------------------------------------
// Settings screen
// ---------------------------------------------------------------------------

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final privacyMode = ref.watch(privacyModeProvider);
    final electricityCost = ref.watch(electricityCostProvider);
    final hapticsEnabled = ref.watch(hapticsEnabledProvider);
    final hapticStrength = ref.watch(hapticStrengthProvider);
    final refreshRate = ref.watch(refreshRateProvider);
    final tempAlerts = ref.watch(tempAlertsProvider);
    final chipFahrenheit = ref.watch(chipTempFahrenheitProvider);
    final exhaustFahrenheit = ref.watch(exhaustTempFahrenheitProvider);
    final currency = ref.watch(currencyProvider);
    final miners = ref.watch(minersProvider);
    final snapshots = ref.watch(minerSnapshotsProvider);

    // Compute total TH/s
    double totalTHs = 0;
    for (final snap in snapshots.values) {
      totalTHs += snap.hashrate / 1e12;
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Settings',
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
        children: [
          // ---------------------------------------------------------------
          // 1. DEVICE INVENTORY
          // ---------------------------------------------------------------
          const _SectionHeader(title: 'DEVICE INVENTORY'),
          _DeviceInventory(miners: miners, snapshots: snapshots),

          const SizedBox(height: AppSpacing.xl),

          // ---------------------------------------------------------------
          // 2. HAPTICS
          // ---------------------------------------------------------------
          const _SectionHeader(title: 'HAPTICS'),
          _SettingsTile(
            icon: Icons.vibration_rounded,
            title: 'Share Submitted Haptics',
            subtitle: hapticsEnabled ? 'On' : 'Off',
            trailing: Switch(
              value: hapticsEnabled,
              onChanged: (v) =>
                  ref.read(hapticsEnabledProvider.notifier).set(v),
              activeThumbColor: AppColors.primary,
              activeTrackColor: AppColors.primary.withValues(alpha: 0.3),
              inactiveThumbColor: AppColors.textMuted,
              inactiveTrackColor: AppColors.cardDark,
            ),
            onTap: () => ref.read(hapticsEnabledProvider.notifier).toggle(),
          ),
          _SettingsTile(
            icon: Icons.tune_rounded,
            title: 'Haptic Strength',
            subtitle: hapticStrength,
            onTap: () => _showPickerSheet(
              context: context,
              title: 'Haptic Strength',
              options: const ['Light', 'Medium', 'Heavy'],
              current: hapticStrength,
              onSelected: (v) =>
                  ref.read(hapticStrengthProvider.notifier).set(v),
            ),
          ),

          const SizedBox(height: AppSpacing.xl),

          // ---------------------------------------------------------------
          // 3. APP SETTINGS
          // ---------------------------------------------------------------
          const _SectionHeader(title: 'APP SETTINGS'),
          _SettingsTile(
            icon: Icons.timer_outlined,
            title: 'Refresh Rate',
            subtitle: _formatRefreshRate(refreshRate),
            onTap: () => _showPickerSheet(
              context: context,
              title: 'Refresh Rate',
              options: const ['1', '5', '10', '30', '60'],
              labels: const [
                '1 second',
                '5 seconds',
                '10 seconds',
                '30 seconds',
                '60 seconds',
              ],
              current: refreshRate.toString(),
              onSelected: (v) =>
                  ref.read(refreshRateProvider.notifier).set(int.parse(v)),
            ),
          ),
          _SettingsTile(
            icon: Icons.thermostat_outlined,
            title: 'Temperature Alerts',
            subtitle: tempAlerts ? 'On' : 'Off',
            trailing: Switch(
              value: tempAlerts,
              onChanged: (v) =>
                  ref.read(tempAlertsProvider.notifier).set(v),
              activeThumbColor: AppColors.primary,
              activeTrackColor: AppColors.primary.withValues(alpha: 0.3),
              inactiveThumbColor: AppColors.textMuted,
              inactiveTrackColor: AppColors.cardDark,
            ),
            onTap: () => ref.read(tempAlertsProvider.notifier).toggle(),
          ),
          _SettingsTile(
            icon: Icons.device_thermostat_rounded,
            title: 'Use F for Chip & VR Temps',
            subtitle: chipFahrenheit ? 'Fahrenheit' : 'Celsius',
            trailing: Switch(
              value: chipFahrenheit,
              onChanged: (v) =>
                  ref.read(chipTempFahrenheitProvider.notifier).set(v),
              activeThumbColor: AppColors.primary,
              activeTrackColor: AppColors.primary.withValues(alpha: 0.3),
              inactiveThumbColor: AppColors.textMuted,
              inactiveTrackColor: AppColors.cardDark,
            ),
            onTap: () =>
                ref.read(chipTempFahrenheitProvider.notifier).toggle(),
          ),
          _SettingsTile(
            icon: Icons.air_rounded,
            title: 'Use F for Exhaust Temps',
            subtitle: exhaustFahrenheit ? 'Fahrenheit' : 'Celsius',
            trailing: Switch(
              value: exhaustFahrenheit,
              onChanged: (v) =>
                  ref.read(exhaustTempFahrenheitProvider.notifier).set(v),
              activeThumbColor: AppColors.primary,
              activeTrackColor: AppColors.primary.withValues(alpha: 0.3),
              inactiveThumbColor: AppColors.textMuted,
              inactiveTrackColor: AppColors.cardDark,
            ),
            onTap: () =>
                ref.read(exhaustTempFahrenheitProvider.notifier).toggle(),
          ),
          _SettingsTile(
            icon: Icons.visibility_off_outlined,
            title: 'Privacy Mode',
            subtitle: privacyMode
                ? 'IPs & wallets hidden'
                : 'IPs & wallets visible',
            trailing: Switch(
              value: privacyMode,
              onChanged: (v) =>
                  ref.read(privacyModeProvider.notifier).set(v),
              activeThumbColor: AppColors.primary,
              activeTrackColor: AppColors.primary.withValues(alpha: 0.3),
              inactiveThumbColor: AppColors.textMuted,
              inactiveTrackColor: AppColors.cardDark,
            ),
            onTap: () => ref.read(privacyModeProvider.notifier).toggle(),
          ),

          const SizedBox(height: AppSpacing.xl),

          // ---------------------------------------------------------------
          // 4. PROFITABILITY
          // ---------------------------------------------------------------
          const _SectionHeader(title: 'PROFITABILITY'),
          _ElectricityCostTile(currentCost: electricityCost),
          _SettingsTile(
            icon: Icons.currency_exchange_rounded,
            title: 'Pricing & Currency',
            subtitle: currency,
            onTap: () => _showPickerSheet(
              context: context,
              title: 'Currency',
              options: const [
                'USD',
                'EUR',
                'GBP',
                'CAD',
                'AUD',
                'JPY',
              ],
              current: currency,
              onSelected: (v) =>
                  ref.read(currencyProvider.notifier).set(v),
            ),
          ),

          const SizedBox(height: AppSpacing.xl),

          // ---------------------------------------------------------------
          // 5. MAINTENANCE
          // ---------------------------------------------------------------
          const _SectionHeader(title: 'MAINTENANCE'),
          _SettingsTile(
            icon: Icons.build_outlined,
            title: 'Maintenance Schedule',
            subtitle: 'Not set',
            onTap: () {},
          ),
          _SettingsTile(
            icon: Icons.picture_as_pdf_outlined,
            title: 'Export Energy Report',
            subtitle: 'Generate PDF report',
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Coming soon'),
                  behavior: SnackBarBehavior.floating,
                ),
              );
            },
          ),

          const SizedBox(height: AppSpacing.xl),

          // ---------------------------------------------------------------
          // 6. SOLO CHANCES
          // ---------------------------------------------------------------
          const _SectionHeader(title: 'SOLO CHANCES'),
          _SettingsTile(
            icon: Icons.casino_outlined,
            title: 'Recalculate Solo Chances',
            subtitle: '${totalTHs.toStringAsFixed(1)} TH/s total',
            trailing: const Icon(
              Icons.refresh_rounded,
              size: 20,
              color: AppColors.textMuted,
            ),
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Recalculating solo chances...'),
                  behavior: SnackBarBehavior.floating,
                ),
              );
            },
          ),

          const SizedBox(height: AppSpacing.xl),

          // ---------------------------------------------------------------
          // 7. DATA
          // ---------------------------------------------------------------
          const _SectionHeader(title: 'DATA'),
          _SettingsTile(
            icon: Icons.storage_outlined,
            title: 'Data Retention',
            subtitle: '30 days',
            onTap: () {},
          ),
          _SettingsTile(
            icon: Icons.file_download_outlined,
            title: 'Export Data',
            subtitle: 'CSV / JSON / PDF',
            onTap: () => showExportDialog(context),
          ),

          const SizedBox(height: AppSpacing.xl),

          // ---------------------------------------------------------------
          // 8. SUPPORT & FEEDBACK
          // ---------------------------------------------------------------
          const _SectionHeader(title: 'SUPPORT & FEEDBACK'),
          _SettingsTile(
            icon: Icons.lightbulb_outline_rounded,
            title: 'Feature Request',
            subtitle: 'Suggest a feature',
            trailing: const Icon(
              Icons.open_in_new_rounded,
              size: 16,
              color: AppColors.textMuted,
            ),
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Opening feature request form...'),
                  behavior: SnackBarBehavior.floating,
                ),
              );
            },
          ),
          _SettingsTile(
            icon: Icons.star_outline_rounded,
            title: 'Rate MineViewer',
            subtitle: 'Leave a review',
            trailing: const Icon(
              Icons.open_in_new_rounded,
              size: 16,
              color: AppColors.textMuted,
            ),
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Opening app store...'),
                  behavior: SnackBarBehavior.floating,
                ),
              );
            },
          ),

          const SizedBox(height: AppSpacing.xl),

          // ---------------------------------------------------------------
          // 9. ABOUT
          // ---------------------------------------------------------------
          const _SectionHeader(title: 'ABOUT'),
          _SettingsTile(
            icon: Icons.info_outline_rounded,
            title: 'About',
            subtitle: 'MineViewer v0.1.0',
            onTap: () => _showAboutSheet(context),
          ),
          _SettingsTile(
            icon: Icons.code_rounded,
            title: 'GitHub',
            subtitle: 'View source code',
            trailing: const Icon(
              Icons.open_in_new_rounded,
              size: 16,
              color: AppColors.textMuted,
            ),
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Opening GitHub repository...'),
                  behavior: SnackBarBehavior.floating,
                ),
              );
            },
          ),
          _SettingsTile(
            icon: Icons.description_outlined,
            title: 'Licenses',
            subtitle: 'Open source licenses',
            onTap: () {
              showLicensePage(
                context: context,
                applicationName: 'MineViewer',
                applicationVersion: '0.1.0',
              );
            },
          ),

          const SizedBox(height: AppSpacing.xxl),
        ],
      ),
    );
  }

  // -------------------------------------------------------------------------
  // Helpers
  // -------------------------------------------------------------------------

  String _formatRefreshRate(int seconds) {
    if (seconds == 1) return '1 second';
    return '$seconds seconds';
  }

  void _showAboutSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surfaceDark,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(AppSpacing.cardRadius),
        ),
      ),
      builder: (_) => Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.textMuted,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: AppSpacing.xl),
            const Icon(
              Icons.developer_board_rounded,
              size: 48,
              color: AppColors.primary,
            ),
            const SizedBox(height: AppSpacing.lg),
            const Text(
              'MineViewer',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: AppSpacing.xs),
            const Text(
              'v0.1.0',
              style: TextStyle(
                fontSize: 14,
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            const Text(
              'Free, open-source Bitcoin miner monitoring\nfor your local network.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: AppColors.textSecondary,
                height: 1.5,
              ),
            ),
            const SizedBox(height: AppSpacing.xl),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Reusable bottom sheet picker
// ---------------------------------------------------------------------------

void _showPickerSheet({
  required BuildContext context,
  required String title,
  required List<String> options,
  List<String>? labels,
  required String current,
  required ValueChanged<String> onSelected,
}) {
  showModalBottomSheet(
    context: context,
    backgroundColor: AppColors.surfaceDark,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(
        top: Radius.circular(AppSpacing.cardRadius),
      ),
    ),
    builder: (_) => SafeArea(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.lg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Handle
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.textMuted,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            Text(
              title,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            for (int i = 0; i < options.length; i++)
              ListTile(
                title: Text(
                  labels != null ? labels[i] : options[i],
                  style: TextStyle(
                    color: options[i] == current
                        ? AppColors.primary
                        : AppColors.textPrimary,
                    fontWeight: options[i] == current
                        ? FontWeight.w600
                        : FontWeight.w400,
                  ),
                ),
                trailing: options[i] == current
                    ? const Icon(Icons.check_rounded,
                        size: 18, color: AppColors.primary)
                    : null,
                onTap: () {
                  onSelected(options[i]);
                  Navigator.pop(context);
                },
              ),
            const SizedBox(height: AppSpacing.md),
          ],
        ),
      ),
    ),
  );
}

// ---------------------------------------------------------------------------
// Device Inventory (expandable groups by MinerType)
// ---------------------------------------------------------------------------

class _DeviceInventory extends StatefulWidget {
  final List<Miner> miners;
  final Map<String, MinerSnapshot> snapshots;

  const _DeviceInventory({
    required this.miners,
    required this.snapshots,
  });

  @override
  State<_DeviceInventory> createState() => _DeviceInventoryState();
}

class _DeviceInventoryState extends State<_DeviceInventory> {
  final Set<MinerType> _expanded = {};

  @override
  Widget build(BuildContext context) {
    // Group miners by type
    final grouped = <MinerType, List<Miner>>{};
    for (final miner in widget.miners) {
      grouped.putIfAbsent(miner.type, () => []).add(miner);
    }

    if (grouped.isEmpty) {
      return const Padding(
        padding: EdgeInsets.symmetric(
          horizontal: AppSpacing.screenPadding,
          vertical: AppSpacing.lg,
        ),
        child: Text(
          'No miners added yet.',
          style: TextStyle(
            fontSize: 13,
            color: AppColors.textSecondary,
          ),
        ),
      );
    }

    final types = grouped.keys.toList()
      ..sort((a, b) => a.displayName.compareTo(b.displayName));

    return Column(
      children: [
        for (final type in types) ...[
          _buildTypeHeader(type, grouped[type]!),
          AnimatedCrossFade(
            firstChild: const SizedBox.shrink(),
            secondChild: _buildMinerList(grouped[type]!),
            crossFadeState: _expanded.contains(type)
                ? CrossFadeState.showSecond
                : CrossFadeState.showFirst,
            duration: const Duration(milliseconds: 200),
          ),
        ],
      ],
    );
  }

  Widget _buildTypeHeader(MinerType type, List<Miner> miners) {
    final isExpanded = _expanded.contains(type);
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          setState(() {
            if (isExpanded) {
              _expanded.remove(type);
            } else {
              _expanded.add(type);
            }
          });
        },
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.screenPadding,
            vertical: AppSpacing.md,
          ),
          child: Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: AppColors.cardDark,
                  borderRadius: BorderRadius.circular(AppSpacing.sm),
                  border: Border.all(color: AppColors.border, width: 0.5),
                ),
                child: const Icon(Icons.developer_board_rounded,
                    size: 18, color: AppColors.textSecondary),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Text(
                  type.displayName,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
              // Count badge
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.sm,
                  vertical: 2,
                ),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(AppSpacing.chipRadius),
                ),
                child: Text(
                  '${miners.length}',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppColors.primary,
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              AnimatedRotation(
                turns: isExpanded ? 0.25 : 0,
                duration: const Duration(milliseconds: 200),
                child: const Icon(
                  Icons.chevron_right_rounded,
                  size: 20,
                  color: AppColors.textMuted,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMinerList(List<Miner> miners) {
    return Column(
      children: [
        for (final miner in miners) _buildMinerRow(miner),
      ],
    );
  }

  Widget _buildMinerRow(Miner miner) {
    // Determine pool type from snapshot poolUrl
    final snapshot = widget.snapshots[miner.id];
    String poolType = 'Unknown';
    if (snapshot != null) {
      final poolUrl = snapshot.poolUrl ?? '';
      if (poolUrl.contains('public-pool') || poolUrl.contains('solo')) {
        poolType = 'Solo';
      } else if (poolUrl.isNotEmpty) {
        poolType = 'Pool';
      }
    }

    return Padding(
      padding: const EdgeInsets.only(
        left: AppSpacing.screenPadding + 48, // indent past icon
        right: AppSpacing.screenPadding,
        top: AppSpacing.xs,
        bottom: AppSpacing.xs,
      ),
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.sm + 2,
        ),
        decoration: BoxDecoration(
          color: AppColors.cardDark,
          borderRadius: BorderRadius.circular(AppSpacing.sm),
          border: Border.all(color: AppColors.border, width: 0.5),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    miner.name,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: AppColors.textPrimary,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    miner.ipAddress,
                    style: const TextStyle(
                      fontSize: 11,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            // Pool badge
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.sm,
                vertical: 2,
              ),
              decoration: BoxDecoration(
                color: poolType == 'Solo'
                    ? AppColors.accent.withValues(alpha: 0.12)
                    : AppColors.chartHashrate.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(AppSpacing.xs),
              ),
              child: Text(
                poolType,
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  color: poolType == 'Solo'
                      ? AppColors.accent
                      : AppColors.chartHashrate,
                ),
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            // Edit button
            GestureDetector(
              onTap: () => context.goNamed(RouteNames.addMiner),
              child: const Text(
                'Edit',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: AppColors.primary,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Electricity cost tile with inline editing
// ---------------------------------------------------------------------------

class _ElectricityCostTile extends ConsumerStatefulWidget {
  final double currentCost;
  const _ElectricityCostTile({required this.currentCost});

  @override
  ConsumerState<_ElectricityCostTile> createState() =>
      _ElectricityCostTileState();
}

class _ElectricityCostTileState extends ConsumerState<_ElectricityCostTile> {
  bool _editing = false;
  late TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller =
        TextEditingController(text: widget.currentCost.toStringAsFixed(2));
  }

  @override
  void didUpdateWidget(covariant _ElectricityCostTile old) {
    super.didUpdateWidget(old);
    if (!_editing && old.currentCost != widget.currentCost) {
      _controller.text = widget.currentCost.toStringAsFixed(2);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _save() {
    final parsed = double.tryParse(_controller.text);
    if (parsed != null && parsed >= 0) {
      ref.read(electricityCostProvider.notifier).setCost(parsed);
    }
    setState(() => _editing = false);
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => setState(() => _editing = true),
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.screenPadding,
            vertical: AppSpacing.md,
          ),
          child: Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: AppColors.cardDark,
                  borderRadius: BorderRadius.circular(AppSpacing.sm),
                  border: Border.all(color: AppColors.border, width: 0.5),
                ),
                child: const Icon(Icons.bolt_outlined,
                    size: 18, color: AppColors.textSecondary),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Electricity Cost',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w500,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    if (!_editing)
                      Text(
                        '\$${widget.currentCost.toStringAsFixed(2)} / kWh',
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.textSecondary,
                        ),
                      )
                    else
                      SizedBox(
                        height: 28,
                        child: Row(
                          children: [
                            const Text(
                              '\$ ',
                              style: TextStyle(
                                fontSize: 13,
                                color: AppColors.primary,
                              ),
                            ),
                            Expanded(
                              child: TextField(
                                controller: _controller,
                                autofocus: true,
                                keyboardType:
                                    const TextInputType.numberWithOptions(
                                        decimal: true),
                                style: const TextStyle(
                                  fontSize: 13,
                                  color: AppColors.textPrimary,
                                ),
                                decoration: const InputDecoration(
                                  isDense: true,
                                  contentPadding: EdgeInsets.symmetric(
                                      vertical: 4, horizontal: 4),
                                  border: UnderlineInputBorder(
                                    borderSide:
                                        BorderSide(color: AppColors.primary),
                                  ),
                                  focusedBorder: UnderlineInputBorder(
                                    borderSide:
                                        BorderSide(color: AppColors.primary),
                                  ),
                                  suffixText: '/kWh',
                                  suffixStyle: TextStyle(
                                    fontSize: 11,
                                    color: AppColors.textMuted,
                                  ),
                                ),
                                onSubmitted: (_) => _save(),
                              ),
                            ),
                            const SizedBox(width: 4),
                            GestureDetector(
                              onTap: _save,
                              child: const Icon(Icons.check_rounded,
                                  size: 18, color: AppColors.primary),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
              if (!_editing)
                const Icon(
                  Icons.edit_outlined,
                  size: 16,
                  color: AppColors.textMuted,
                ),
            ],
          ),
        ),
      ),
    );
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
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.screenPadding,
        AppSpacing.lg,
        AppSpacing.screenPadding,
        AppSpacing.sm,
      ),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: AppColors.textMuted,
          letterSpacing: 1.0,
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Settings tile
// ---------------------------------------------------------------------------

class _SettingsTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Widget? trailing;
  final VoidCallback onTap;

  const _SettingsTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    this.trailing,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.screenPadding,
            vertical: AppSpacing.md,
          ),
          child: Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: AppColors.cardDark,
                  borderRadius: BorderRadius.circular(AppSpacing.sm),
                  border: Border.all(color: AppColors.border, width: 0.5),
                ),
                child: Icon(icon, size: 18, color: AppColors.textSecondary),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w500,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              trailing ??
                  const Icon(
                    Icons.chevron_right_rounded,
                    size: 20,
                    color: AppColors.textMuted,
                  ),
            ],
          ),
        ),
      ),
    );
  }
}

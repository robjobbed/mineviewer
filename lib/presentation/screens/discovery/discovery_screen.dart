import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../config/theme/app_colors.dart';
import '../../../config/theme/app_spacing.dart';
import '../../../data/models/miner_type.dart';
import '../../../services/discovery/network_scanner.dart';
import '../../providers/discovery_provider.dart';
import '../../providers/miners_provider.dart';

class DiscoveryScreen extends ConsumerWidget {
  const DiscoveryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(discoveryProvider);
    final miners = ref.watch(minersProvider);
    final addedIps = miners.map((m) => m.ipAddress).toSet();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Discover Miners'),
      ),
      body: _buildBody(context, ref, state, addedIps),
    );
  }

  Widget _buildBody(
    BuildContext context,
    WidgetRef ref,
    DiscoveryState state,
    Set<String> addedIps,
  ) {
    // Error state
    if (state.error != null) {
      return _ErrorView(
        message: state.error!,
        onRetry: () => ref.read(discoveryProvider.notifier).startScan(),
      );
    }

    // Scanning state
    if (state.isScanning) {
      return _ScanningView(
        progress: state.progress,
        message: state.message,
        found: state.found,
        addedIps: addedIps,
        onCancel: () => ref.read(discoveryProvider.notifier).cancelScan(),
        onAdd: (miner) => _showAddDialog(context, ref, miner),
      );
    }

    // Results state (scan completed with results)
    if (state.found.isNotEmpty) {
      return _ResultsView(
        found: state.found,
        addedIps: addedIps,
        message: state.message,
        onAdd: (miner) => _showAddDialog(context, ref, miner),
        onScanAgain: () {
          ref.read(discoveryProvider.notifier).clearResults();
          ref.read(discoveryProvider.notifier).startScan();
        },
        onManualAdd: () => context.push('/add-miner'),
      );
    }

    // Idle / start state
    return _StartView(
      message: state.message,
      onStartScan: () => ref.read(discoveryProvider.notifier).startScan(),
      onManualAdd: () => context.push('/add-miner'),
    );
  }

  Future<void> _showAddDialog(
    BuildContext context,
    WidgetRef ref,
    DiscoveredMiner miner,
  ) async {
    final lastOctet = miner.ipAddress.split('.').last;
    final defaultName = miner.model ?? '${miner.type.displayName}-$lastOctet';

    final controller = TextEditingController(text: defaultName);

    final name = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Add Miner'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '${miner.type.displayName} at ${miner.ipAddress}',
              style: TextStyle(
                color: AppColors.textSecondary,
                fontSize: 13,
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            TextField(
              controller: controller,
              autofocus: true,
              decoration: const InputDecoration(
                labelText: 'Name',
                hintText: 'Enter a name for this miner',
                border: OutlineInputBorder(),
              ),
              onSubmitted: (value) =>
                  Navigator.of(ctx).pop(value.trim().isEmpty ? null : value.trim()),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              final value = controller.text.trim();
              Navigator.of(ctx).pop(value.isEmpty ? null : value);
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );

    controller.dispose();

    if (name != null && context.mounted) {
      await ref.read(minersProvider.notifier).addMiner(
            name: name,
            ipAddress: miner.ipAddress,
            port: miner.type.defaultPort,
            type: miner.type,
          );
    }
  }
}

// ---------------------------------------------------------------------------
// Start / idle view
// ---------------------------------------------------------------------------

class _StartView extends StatelessWidget {
  final String message;
  final VoidCallback onStartScan;
  final VoidCallback onManualAdd;

  const _StartView({
    required this.message,
    required this.onStartScan,
    required this.onManualAdd,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.screenPadding),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 96,
              height: 96,
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.wifi_find,
                size: 48,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(height: AppSpacing.xl),
            Text(
              'Scan your local network to find miners',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: AppColors.textSecondary,
                  ),
            ),
            if (message.isNotEmpty) ...[
              const SizedBox(height: AppSpacing.sm),
              Text(
                message,
                style: TextStyle(
                  color: AppColors.textMuted,
                  fontSize: 13,
                ),
              ),
            ],
            const SizedBox(height: AppSpacing.xxl),
            FilledButton.icon(
              onPressed: onStartScan,
              icon: const Icon(Icons.radar),
              label: const Text('Start Scan'),
              style: FilledButton.styleFrom(
                minimumSize: const Size(200, 48),
                backgroundColor: AppColors.primary,
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            TextButton(
              onPressed: onManualAdd,
              child: const Text('Manual Add'),
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Scanning view
// ---------------------------------------------------------------------------

class _ScanningView extends StatelessWidget {
  final double progress;
  final String message;
  final List<DiscoveredMiner> found;
  final Set<String> addedIps;
  final VoidCallback onCancel;
  final void Function(DiscoveredMiner) onAdd;

  const _ScanningView({
    required this.progress,
    required this.message,
    required this.found,
    required this.addedIps,
    required this.onCancel,
    required this.onAdd,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const SizedBox(height: AppSpacing.xxxl),
        SizedBox(
          width: 120,
          height: 120,
          child: Stack(
            alignment: Alignment.center,
            children: [
              SizedBox(
                width: 120,
                height: 120,
                child: CircularProgressIndicator(
                  value: progress,
                  strokeWidth: 6,
                  backgroundColor: AppColors.border,
                  color: AppColors.primary,
                ),
              ),
              Text(
                '${(progress * 100).toInt()}%',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.bold,
                    ),
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.xl),
        Text(
          message,
          style: TextStyle(
            color: AppColors.textSecondary,
            fontSize: 14,
          ),
        ),
        const SizedBox(height: AppSpacing.xl),
        OutlinedButton(
          onPressed: onCancel,
          style: OutlinedButton.styleFrom(
            foregroundColor: AppColors.textSecondary,
            side: const BorderSide(color: AppColors.border),
          ),
          child: const Text('Cancel'),
        ),
        if (found.isNotEmpty) ...[
          const SizedBox(height: AppSpacing.xl),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.screenPadding),
            child: Row(
              children: [
                Text(
                  'Found so far',
                  style: TextStyle(
                    color: AppColors.textMuted,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
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
                    '${found.length}',
                    style: const TextStyle(
                      color: AppColors.primary,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.screenPadding,
              ),
              itemCount: found.length,
              itemBuilder: (context, index) => _MinerTile(
                miner: found[index],
                isAdded: addedIps.contains(found[index].ipAddress),
                onAdd: () => onAdd(found[index]),
              ),
            ),
          ),
        ],
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Results view
// ---------------------------------------------------------------------------

class _ResultsView extends StatelessWidget {
  final List<DiscoveredMiner> found;
  final Set<String> addedIps;
  final String message;
  final void Function(DiscoveredMiner) onAdd;
  final VoidCallback onScanAgain;
  final VoidCallback onManualAdd;

  const _ResultsView({
    required this.found,
    required this.addedIps,
    required this.message,
    required this.onAdd,
    required this.onScanAgain,
    required this.onManualAdd,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.screenPadding,
            AppSpacing.lg,
            AppSpacing.screenPadding,
            AppSpacing.sm,
          ),
          child: Row(
            children: [
              const Icon(Icons.check_circle, color: AppColors.online, size: 18),
              const SizedBox(width: AppSpacing.sm),
              Text(
                message,
                style: TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 13,
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.screenPadding,
            ),
            itemCount: found.length,
            itemBuilder: (context, index) => _MinerTile(
              miner: found[index],
              isAdded: addedIps.contains(found[index].ipAddress),
              onAdd: () => onAdd(found[index]),
            ),
          ),
        ),
        SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.screenPadding),
            child: Column(
              children: [
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: onScanAgain,
                    icon: const Icon(Icons.radar),
                    label: const Text('Scan Again'),
                    style: OutlinedButton.styleFrom(
                      minimumSize: const Size.fromHeight(48),
                      foregroundColor: AppColors.primary,
                      side: const BorderSide(color: AppColors.primary),
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
                TextButton(
                  onPressed: onManualAdd,
                  child: const Text('Manual Add'),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Error view
// ---------------------------------------------------------------------------

class _ErrorView extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _ErrorView({
    required this.message,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.screenPadding),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: AppColors.error.withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.error_outline,
                size: 36,
                color: AppColors.error,
              ),
            ),
            const SizedBox(height: AppSpacing.xl),
            Text(
              'Scan Failed',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: AppColors.textPrimary,
                  ),
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              message,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: AppColors.textSecondary,
                fontSize: 13,
              ),
            ),
            const SizedBox(height: AppSpacing.xl),
            FilledButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.primary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Single miner tile
// ---------------------------------------------------------------------------

class _MinerTile extends StatelessWidget {
  final DiscoveredMiner miner;
  final bool isAdded;
  final VoidCallback onAdd;

  const _MinerTile({
    required this.miner,
    required this.isAdded,
    required this.onAdd,
  });

  IconData _iconForType(MinerType type) => switch (type) {
        MinerType.bitaxe => Icons.memory,
        MinerType.antminer => Icons.precision_manufacturing,
        MinerType.braiins => Icons.developer_board,
        MinerType.canaan => Icons.hardware,
        MinerType.luckyminer => Icons.casino,
      };

  @override
  Widget build(BuildContext context) {
    return Card(
      color: AppColors.cardDark,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
        side: const BorderSide(color: AppColors.border, width: 0.5),
      ),
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.cardPadding),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(AppSpacing.chipRadius),
              ),
              child: Icon(
                _iconForType(miner.type),
                color: AppColors.primary,
                size: 22,
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    miner.ipAddress,
                    style: const TextStyle(
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.elevatedDark,
                          borderRadius:
                              BorderRadius.circular(AppSpacing.chipRadius),
                        ),
                        child: Text(
                          miner.type.displayName,
                          style: const TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 11,
                          ),
                        ),
                      ),
                      if (miner.model != null) ...[
                        const SizedBox(width: AppSpacing.sm),
                        Flexible(
                          child: Text(
                            miner.model!,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: AppColors.textMuted,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            if (isAdded)
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: AppColors.online.withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.check,
                  color: AppColors.online,
                  size: 20,
                ),
              )
            else
              SizedBox(
                height: 36,
                child: FilledButton(
                  onPressed: onAdd,
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    textStyle: const TextStyle(fontSize: 13),
                  ),
                  child: const Text('Add'),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

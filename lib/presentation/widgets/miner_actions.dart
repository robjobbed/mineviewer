import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../config/theme/app_colors.dart';
import '../../config/theme/app_spacing.dart';
import '../../data/models/miner.dart';
import '../../drivers/driver_registry.dart';
import '../providers/miners_provider.dart';

/// Row of primary miner actions: Restart, Identify (LED blink), Remove.
class MinerActions extends ConsumerStatefulWidget {
  final Miner miner;

  const MinerActions({super.key, required this.miner});

  @override
  ConsumerState<MinerActions> createState() => _MinerActionsState();
}

class _MinerActionsState extends ConsumerState<MinerActions> {
  bool _restartLoading = false;
  bool _identifyLoading = false;
  bool _removeLoading = false;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.cardPadding),
      decoration: BoxDecoration(
        color: AppColors.cardDark,
        borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
        border: Border.all(color: AppColors.border, width: 0.5),
      ),
      child: Row(
        children: [
          Expanded(
            child: _ActionButton(
              icon: Icons.restart_alt_rounded,
              label: 'Restart',
              color: AppColors.error,
              isLoading: _restartLoading,
              onTap: () => _confirmRestart(context),
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: _ActionButton(
              icon: Icons.lightbulb_outline_rounded,
              label: 'Identify',
              color: AppColors.warning,
              isLoading: _identifyLoading,
              onTap: _identify,
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: _ActionButton(
              icon: Icons.delete_outline_rounded,
              label: 'Remove',
              color: AppColors.textMuted,
              isLoading: _removeLoading,
              onTap: () => _confirmRemove(context),
            ),
          ),
        ],
      ),
    );
  }

  // -- Restart ---------------------------------------------------------------

  void _confirmRestart(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surfaceDark,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
          side: const BorderSide(color: AppColors.border, width: 0.5),
        ),
        title: const Text('Restart Miner',
            style: TextStyle(color: AppColors.textPrimary)),
        content: Text(
          'Are you sure you want to restart ${widget.miner.name}? '
          'This will temporarily interrupt mining.',
          style: const TextStyle(color: AppColors.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              _restart();
            },
            child: const Text('Restart',
                style: TextStyle(color: AppColors.error)),
          ),
        ],
      ),
    );
  }

  Future<void> _restart() async {
    setState(() => _restartLoading = true);
    try {
      final driver = DriverRegistry.getDriver(widget.miner.type);
      final result = await driver.restart(
        widget.miner.ipAddress,
        port: widget.miner.port,
      );
      if (!mounted) return;
      result.when(
        success: (_) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Restart command sent'),
              behavior: SnackBarBehavior.floating,
              backgroundColor: AppColors.online,
            ),
          );
        },
        failure: (msg, _) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Restart failed: $msg'),
              behavior: SnackBarBehavior.floating,
              backgroundColor: AppColors.error,
            ),
          );
        },
      );
    } finally {
      if (mounted) setState(() => _restartLoading = false);
    }
  }

  // -- Identify --------------------------------------------------------------

  Future<void> _identify() async {
    setState(() => _identifyLoading = true);
    try {
      final driver = DriverRegistry.getDriver(widget.miner.type);
      final result = await driver.identify(
        widget.miner.ipAddress,
        port: widget.miner.port,
      );
      if (!mounted) return;
      result.when(
        success: (_) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('LED blink triggered'),
              behavior: SnackBarBehavior.floating,
              backgroundColor: AppColors.online,
            ),
          );
        },
        failure: (msg, _) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Identify failed: $msg'),
              behavior: SnackBarBehavior.floating,
              backgroundColor: AppColors.error,
            ),
          );
        },
      );
    } finally {
      if (mounted) setState(() => _identifyLoading = false);
    }
  }

  // -- Remove ----------------------------------------------------------------

  void _confirmRemove(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surfaceDark,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
          side: const BorderSide(color: AppColors.border, width: 0.5),
        ),
        title: const Text('Remove Miner',
            style: TextStyle(color: AppColors.textPrimary)),
        content: const Text(
          'Are you sure you want to remove this miner? Historical data will be preserved.',
          style: TextStyle(color: AppColors.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              _remove();
            },
            child: const Text('Remove',
                style: TextStyle(color: AppColors.error)),
          ),
        ],
      ),
    );
  }

  Future<void> _remove() async {
    setState(() => _removeLoading = true);
    try {
      ref.read(minersProvider.notifier).removeMiner(widget.miner.id);
      if (mounted) {
        GoRouter.of(context).go('/');
      }
    } finally {
      if (mounted) setState(() => _removeLoading = false);
    }
  }
}

// ---------------------------------------------------------------------------
// Shared action button
// ---------------------------------------------------------------------------

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final bool isLoading;
  final VoidCallback onTap;

  const _ActionButton({
    required this.icon,
    required this.label,
    required this.color,
    required this.isLoading,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(AppSpacing.chipRadius),
        onTap: isLoading ? null : onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(
            vertical: AppSpacing.md,
          ),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppSpacing.chipRadius),
            border: Border.all(
              color: color.withValues(alpha: 0.3),
              width: 0.5,
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (isLoading)
                SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: color,
                  ),
                )
              else
                Icon(icon, size: 18, color: color),
              const SizedBox(height: AppSpacing.xs),
              Text(
                label,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: color,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

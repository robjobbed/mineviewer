import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../config/theme/app_colors.dart';
import '../../config/theme/app_spacing.dart';
import '../../data/models/miner.dart';
import '../../data/models/miner_config.dart';
import '../../data/models/miner_snapshot.dart';
import '../../drivers/driver_registry.dart';
import '../../drivers/miner_driver.dart';

/// Editable pool configuration card.
///
/// Displays the current stratum URL / worker info from [MinerSnapshot] and lets
/// the user edit via a bottom sheet.  Changes are pushed through the driver's
/// [MinerDriver.applyConfig].
class PoolConfigCard extends ConsumerStatefulWidget {
  final Miner miner;
  final MinerSnapshot snapshot;

  const PoolConfigCard({
    super.key,
    required this.miner,
    required this.snapshot,
  });

  @override
  ConsumerState<PoolConfigCard> createState() => _PoolConfigCardState();
}

class _PoolConfigCardState extends ConsumerState<PoolConfigCard> {
  bool _pool1Expanded = true;
  bool _pool2Expanded = false;

  @override
  Widget build(BuildContext context) {
    final poolUrl = widget.snapshot.poolUrl ?? '';

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
          // Pool 1
          _PoolSection(
            title: 'Pool 1 (Primary)',
            expanded: _pool1Expanded,
            onToggle: () =>
                setState(() => _pool1Expanded = !_pool1Expanded),
            poolUrl: poolUrl,
            worker: '--',
            onEdit: () => _openEditSheet(context, isFallback: false),
          ),

          const Divider(
            height: 0.5,
            thickness: 0.5,
            color: AppColors.border,
          ),

          // Pool 2
          _PoolSection(
            title: 'Pool 2 (Fallback)',
            expanded: _pool2Expanded,
            onToggle: () =>
                setState(() => _pool2Expanded = !_pool2Expanded),
            poolUrl: '--',
            worker: '--',
            onEdit: () => _openEditSheet(context, isFallback: true),
          ),

          // Footer note
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.cardPadding,
              AppSpacing.xs,
              AppSpacing.cardPadding,
              AppSpacing.md,
            ),
            child: Text(
              'Changes take effect after miner restart for some devices.',
              style: TextStyle(
                fontSize: 11,
                color: AppColors.textMuted,
                fontStyle: FontStyle.italic,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _openEditSheet(BuildContext context, {required bool isFallback}) {
    final urlCtrl = TextEditingController();
    final portCtrl = TextEditingController();
    final workerCtrl = TextEditingController();
    final passCtrl = TextEditingController();

    // Pre-populate from snapshot when editing primary pool
    if (!isFallback && widget.snapshot.poolUrl != null) {
      final raw = widget.snapshot.poolUrl!;
      // Attempt to split "stratum+tcp://host:port" pattern
      final uri = Uri.tryParse(raw);
      if (uri != null) {
        urlCtrl.text =
            '${uri.scheme}://${uri.host}'.replaceAll(RegExp(r':\d+$'), '');
        portCtrl.text = uri.port > 0 ? uri.port.toString() : '';
      } else {
        urlCtrl.text = raw;
      }
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surfaceDark,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(AppSpacing.cardRadius),
        ),
      ),
      builder: (ctx) {
        return Padding(
          padding: EdgeInsets.only(
            left: AppSpacing.screenPadding,
            right: AppSpacing.screenPadding,
            top: AppSpacing.lg,
            bottom: MediaQuery.of(ctx).viewInsets.bottom + AppSpacing.lg,
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isFallback ? 'Edit Fallback Pool' : 'Edit Primary Pool',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),
                _SheetField(controller: urlCtrl, label: 'Stratum URL'),
                const SizedBox(height: AppSpacing.md),
                _SheetField(
                  controller: portCtrl,
                  label: 'Port',
                  keyboardType: TextInputType.number,
                ),
                const SizedBox(height: AppSpacing.md),
                _SheetField(controller: workerCtrl, label: 'Worker Name'),
                const SizedBox(height: AppSpacing.md),
                _SheetField(
                  controller: passCtrl,
                  label: 'Password',
                  obscure: true,
                ),
                const SizedBox(height: AppSpacing.xl),
                Row(
                  children: [
                    Expanded(
                      child: _BottomSheetButton(
                        label: 'Test Connection',
                        color: AppColors.accent,
                        outlined: true,
                        onPressed: () => _testConnection(
                          ctx,
                          urlCtrl.text,
                          portCtrl.text,
                          workerCtrl.text,
                          passCtrl.text,
                          isFallback: isFallback,
                        ),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: _BottomSheetButton(
                        label: 'Save',
                        color: AppColors.primary,
                        onPressed: () => _savePool(
                          ctx,
                          urlCtrl.text,
                          portCtrl.text,
                          workerCtrl.text,
                          passCtrl.text,
                          isFallback: isFallback,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _savePool(
    BuildContext ctx,
    String url,
    String portStr,
    String worker,
    String password, {
    required bool isFallback,
  }) async {
    final port = int.tryParse(portStr);
    final driver = DriverRegistry.getDriver(widget.miner.type);

    final config = isFallback
        ? MinerConfig(
            fallbackStratumUrl: url.isNotEmpty ? url : null,
            fallbackStratumPort: port,
            fallbackStratumUser: worker.isNotEmpty ? worker : null,
            fallbackStratumPassword: password.isNotEmpty ? password : null,
          )
        : MinerConfig(
            stratumUrl: url.isNotEmpty ? url : null,
            stratumPort: port,
            stratumUser: worker.isNotEmpty ? worker : null,
            stratumPassword: password.isNotEmpty ? password : null,
          );

    final result = await driver.applyConfig(
      widget.miner.ipAddress,
      config,
      port: widget.miner.port,
    );

    if (!ctx.mounted) return;
    Navigator.of(ctx).pop();

    result.when(
      success: (_) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Pool configuration saved'),
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
  }

  Future<void> _testConnection(
    BuildContext ctx,
    String url,
    String portStr,
    String worker,
    String password, {
    required bool isFallback,
  }) async {
    final port = int.tryParse(portStr);
    final driver = DriverRegistry.getDriver(widget.miner.type);

    final config = isFallback
        ? MinerConfig(
            fallbackStratumUrl: url.isNotEmpty ? url : null,
            fallbackStratumPort: port,
            fallbackStratumUser: worker.isNotEmpty ? worker : null,
            fallbackStratumPassword: password.isNotEmpty ? password : null,
          )
        : MinerConfig(
            stratumUrl: url.isNotEmpty ? url : null,
            stratumPort: port,
            stratumUser: worker.isNotEmpty ? worker : null,
            stratumPassword: password.isNotEmpty ? password : null,
          );

    // Apply the config, then attempt to fetch stats to verify connectivity.
    final applyResult = await driver.applyConfig(
      widget.miner.ipAddress,
      config,
      port: widget.miner.port,
    );

    if (!ctx.mounted) return;

    if (applyResult.isFailure) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Test failed: ${applyResult.errorOrNull}'),
          behavior: SnackBarBehavior.floating,
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    // Quick connectivity check
    final statsResult = await driver.fetchStats(
      widget.miner.ipAddress,
      port: widget.miner.port,
    );

    if (!ctx.mounted) return;
    statsResult.when(
      success: (_) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Connection test passed'),
            behavior: SnackBarBehavior.floating,
            backgroundColor: AppColors.online,
          ),
        );
      },
      failure: (msg, _) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Test inconclusive: $msg'),
            behavior: SnackBarBehavior.floating,
            backgroundColor: AppColors.warning,
          ),
        );
      },
    );
  }
}

// ---------------------------------------------------------------------------
// Expandable pool section
// ---------------------------------------------------------------------------

class _PoolSection extends StatelessWidget {
  final String title;
  final bool expanded;
  final VoidCallback onToggle;
  final String poolUrl;
  final String worker;
  final VoidCallback onEdit;

  const _PoolSection({
    required this.title,
    required this.expanded,
    required this.onToggle,
    required this.poolUrl,
    required this.worker,
    required this.onEdit,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        InkWell(
          onTap: onToggle,
          borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.cardPadding,
              vertical: AppSpacing.md,
            ),
            child: Row(
              children: [
                Icon(
                  expanded
                      ? Icons.expand_less_rounded
                      : Icons.expand_more_rounded,
                  size: 18,
                  color: AppColors.textSecondary,
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Text(
                    title,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ),
                if (expanded)
                  GestureDetector(
                    onTap: onEdit,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.sm,
                        vertical: AppSpacing.xs,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.accent.withValues(alpha: 0.12),
                        borderRadius:
                            BorderRadius.circular(AppSpacing.chipRadius),
                      ),
                      child: const Text(
                        'Edit',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: AppColors.accent,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
        if (expanded)
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.cardPadding,
              0,
              AppSpacing.cardPadding,
              AppSpacing.md,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _InfoRow(label: 'URL', value: poolUrl),
                const SizedBox(height: AppSpacing.xs),
                _InfoRow(label: 'Worker', value: worker),
              ],
            ),
          ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;
  const _InfoRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 56,
          child: Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              color: AppColors.textMuted,
            ),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(
              fontSize: 12,
              color: AppColors.textSecondary,
              fontFamily: 'monospace',
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}

class _SheetField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final bool obscure;
  final TextInputType? keyboardType;

  const _SheetField({
    required this.controller,
    required this.label,
    this.obscure = false,
    this.keyboardType,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      obscureText: obscure,
      keyboardType: keyboardType,
      style: const TextStyle(
        fontSize: 14,
        color: AppColors.textPrimary,
      ),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(
          fontSize: 13,
          color: AppColors.textSecondary,
        ),
        filled: true,
        fillColor: AppColors.cardDark,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppSpacing.chipRadius),
          borderSide: const BorderSide(color: AppColors.border, width: 0.5),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppSpacing.chipRadius),
          borderSide: const BorderSide(color: AppColors.border, width: 0.5),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppSpacing.chipRadius),
          borderSide:
              const BorderSide(color: AppColors.primary, width: 1),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.md,
        ),
      ),
    );
  }
}

class _BottomSheetButton extends StatelessWidget {
  final String label;
  final Color color;
  final bool outlined;
  final VoidCallback onPressed;

  const _BottomSheetButton({
    required this.label,
    required this.color,
    this.outlined = false,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    if (outlined) {
      return OutlinedButton(
        onPressed: onPressed,
        style: OutlinedButton.styleFrom(
          foregroundColor: color,
          side: BorderSide(color: color, width: 1),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppSpacing.chipRadius),
          ),
          padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
        ),
        child: Text(label,
            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
      );
    }
    return ElevatedButton(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSpacing.chipRadius),
        ),
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
      ),
      child: Text(label,
          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
    );
  }
}

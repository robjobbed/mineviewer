import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../config/theme/app_colors.dart';
import '../../../config/theme/app_spacing.dart';
import '../../../pools/pool_adapter.dart';
import '../../../pools/pool_registry.dart';
import '../../../core/extensions/double_ext.dart';

class PoolEarningsScreen extends ConsumerStatefulWidget {
  const PoolEarningsScreen({super.key});

  @override
  ConsumerState<PoolEarningsScreen> createState() =>
      _PoolEarningsScreenState();
}

class _PoolEarningsScreenState extends ConsumerState<PoolEarningsScreen> {
  PoolType _selectedPool = PoolType.ocean;
  final _identifierController = TextEditingController();
  bool _loading = false;
  PoolEarnings? _earnings;
  String? _error;

  @override
  void dispose() {
    _identifierController.dispose();
    super.dispose();
  }

  Future<void> _fetchEarnings() async {
    final identifier = _identifierController.text.trim();
    if (identifier.isEmpty) {
      setState(() => _error = 'Enter an identifier');
      return;
    }

    final adapter = PoolRegistry.getAdapter(_selectedPool);
    if (!adapter.validateIdentifier(identifier)) {
      setState(() => _error = 'Invalid identifier for ${adapter.displayName}');
      return;
    }

    setState(() {
      _loading = true;
      _error = null;
      _earnings = null;
    });

    final result = await adapter.fetchEarnings(identifier);

    if (!mounted) return;

    setState(() {
      _loading = false;
      _earnings = result;
      if (result == null) {
        _error = _selectedPool == PoolType.foundry
            ? 'Foundry USA does not provide a public API. '
                'Check your Foundry dashboard for earnings.'
            : 'Could not fetch earnings. '
                'Check your identifier and try again.';
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Pool Earnings',
          style: TextStyle(fontWeight: FontWeight.w700, letterSpacing: -0.5),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.screenPadding),
        children: [
          // Pool selector
          const _SectionLabel(label: 'POOL'),
          const SizedBox(height: AppSpacing.sm),
          _PoolDropdown(
            value: _selectedPool,
            onChanged: (v) => setState(() {
              _selectedPool = v;
              _earnings = null;
              _error = null;
            }),
          ),
          const SizedBox(height: AppSpacing.lg),

          // Identifier input
          _SectionLabel(label: _selectedPool.identifierHint.toUpperCase()),
          const SizedBox(height: AppSpacing.sm),
          TextField(
            controller: _identifierController,
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontSize: 14,
              fontFamily: 'monospace',
            ),
            decoration: InputDecoration(
              hintText: _selectedPool.identifierHint,
              hintStyle: const TextStyle(color: AppColors.textMuted),
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
            onSubmitted: (_) => _fetchEarnings(),
          ),
          const SizedBox(height: AppSpacing.lg),

          // Fetch button
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: _loading ? null : _fetchEarnings,
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.black,
                padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppSpacing.chipRadius),
                ),
              ),
              child: _loading
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.black,
                      ),
                    )
                  : const Text(
                      'Fetch Earnings',
                      style: TextStyle(fontWeight: FontWeight.w600),
                    ),
            ),
          ),

          // Error message
          if (_error != null) ...[
            const SizedBox(height: AppSpacing.md),
            Container(
              padding: const EdgeInsets.all(AppSpacing.md),
              decoration: BoxDecoration(
                color: AppColors.error.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(AppSpacing.chipRadius),
                border: Border.all(
                  color: AppColors.error.withValues(alpha: 0.3),
                ),
              ),
              child: Text(
                _error!,
                style: const TextStyle(
                  color: AppColors.error,
                  fontSize: 13,
                ),
              ),
            ),
          ],

          // Results
          if (_earnings != null) ...[
            const SizedBox(height: AppSpacing.xl),
            const _SectionLabel(label: 'EARNINGS DATA'),
            const SizedBox(height: AppSpacing.sm),
            _EarningsCard(earnings: _earnings!),
          ],
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Pool type dropdown
// ---------------------------------------------------------------------------

class _PoolDropdown extends StatelessWidget {
  final PoolType value;
  final ValueChanged<PoolType> onChanged;

  const _PoolDropdown({required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.cardDark,
        borderRadius: BorderRadius.circular(AppSpacing.chipRadius),
        border: Border.all(color: AppColors.border),
      ),
      child: DropdownButton<PoolType>(
        value: value,
        isExpanded: true,
        dropdownColor: AppColors.elevatedDark,
        underline: const SizedBox.shrink(),
        style: const TextStyle(
          color: AppColors.textPrimary,
          fontSize: 14,
        ),
        items: PoolType.values.map((pt) {
          return DropdownMenuItem(
            value: pt,
            child: Text(pt.displayName),
          );
        }).toList(),
        onChanged: (v) {
          if (v != null) onChanged(v);
        },
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Earnings results card
// ---------------------------------------------------------------------------

class _EarningsCard extends StatelessWidget {
  final PoolEarnings earnings;

  const _EarningsCard({required this.earnings});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.cardPadding),
      decoration: BoxDecoration(
        color: AppColors.cardDark,
        borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
        border: Border.all(color: AppColors.border, width: 0.5),
      ),
      child: Column(
        children: [
          _DataRow(
            label: 'Total Earned',
            value: earnings.totalEarnedSats,
            subValue:
                '${earnings.totalEarnedBtc.toStringAsFixed(8)} BTC',
          ),
          if (earnings.pendingBtc != null)
            _DataRow(
              label: 'Pending',
              value: earnings.pendingSats,
            ),
          if (earnings.estimatedDailyBtc != null)
            _DataRow(
              label: 'Est. Daily',
              value:
                  '${(earnings.estimatedDailyBtc! * 1e8).toStringAsFixed(0)} sats',
              valueColor: AppColors.accent,
            ),
          if (earnings.poolHashrate != null)
            _DataRow(
              label: 'Pool Hashrate',
              value: earnings.poolHashrate!.toHashrateString(),
              valueColor: AppColors.chartHashrate,
            ),
          if (earnings.blocksFound != null)
            _DataRow(
              label: 'Blocks Found',
              value: '${earnings.blocksFound}',
            ),
          if (earnings.lastPayout != null)
            _DataRow(
              label: 'Last Payout',
              value: _formatDate(earnings.lastPayout!),
            ),
          if (earnings.lastPayoutAmount != null &&
              earnings.pool != PoolType.ckpool &&
              earnings.pool != PoolType.publicPool)
            _DataRow(
              label: 'Last Payout Amt',
              value:
                  '${(earnings.lastPayoutAmount! * 1e8).toStringAsFixed(0)} sats',
            ),
          // Solo pool: show best difficulty instead
          if (earnings.lastPayoutAmount != null &&
              (earnings.pool == PoolType.ckpool ||
                  earnings.pool == PoolType.publicPool))
            _DataRow(
              label: 'Best Difficulty',
              value: _formatDifficulty(earnings.lastPayoutAmount!),
              valueColor: AppColors.primary,
            ),
        ],
      ),
    );
  }

  String _formatDate(DateTime dt) {
    return '${dt.year}-${dt.month.toString().padLeft(2, '0')}'
        '-${dt.day.toString().padLeft(2, '0')} '
        '${dt.hour.toString().padLeft(2, '0')}:'
        '${dt.minute.toString().padLeft(2, '0')}';
  }

  String _formatDifficulty(double diff) {
    if (diff >= 1e12) return '${(diff / 1e12).toStringAsFixed(2)}T';
    if (diff >= 1e9) return '${(diff / 1e9).toStringAsFixed(2)}G';
    if (diff >= 1e6) return '${(diff / 1e6).toStringAsFixed(2)}M';
    if (diff >= 1e3) return '${(diff / 1e3).toStringAsFixed(2)}K';
    return diff.toStringAsFixed(2);
  }
}

// ---------------------------------------------------------------------------
// Shared widgets
// ---------------------------------------------------------------------------

class _DataRow extends StatelessWidget {
  final String label;
  final String value;
  final String? subValue;
  final Color valueColor;

  const _DataRow({
    required this.label,
    required this.value,
    this.subValue,
    this.valueColor = AppColors.textPrimary,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 2,
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 13,
                color: AppColors.textSecondary,
              ),
            ),
          ),
          Expanded(
            flex: 3,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: valueColor,
                    fontFeatures: const [FontFeature.tabularFigures()],
                  ),
                  textAlign: TextAlign.end,
                ),
                if (subValue != null)
                  Text(
                    subValue!,
                    style: const TextStyle(
                      fontSize: 11,
                      color: AppColors.textMuted,
                    ),
                    textAlign: TextAlign.end,
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  final String label;
  const _SectionLabel({required this.label});

  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      style: const TextStyle(
        fontSize: 11,
        fontWeight: FontWeight.w600,
        color: AppColors.textMuted,
        letterSpacing: 1.0,
      ),
    );
  }
}

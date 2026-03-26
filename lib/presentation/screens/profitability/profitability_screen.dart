import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../config/router/route_names.dart';
import '../../../config/theme/app_colors.dart';
import '../../../config/theme/app_spacing.dart';
import '../../../core/extensions/double_ext.dart';
import '../../../data/models/miner_status.dart';
import '../../../services/profitability/profitability_calculator.dart';
import '../../providers/miners_provider.dart';
import '../../providers/pool_earnings_provider.dart';
import '../../providers/profitability_provider.dart';

class ProfitabilityScreen extends ConsumerWidget {
  const ProfitabilityScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final miners = ref.watch(minersProvider);
    final btcPrice = ref.watch(btcPriceValueProvider);
    final btcUpdated = ref.watch(btcPriceLastUpdatedProvider);
    final fleet = ref.watch(fleetProfitabilityProvider);
    final electricityCost = ref.watch(electricityCostProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Profitability',
          style: TextStyle(fontWeight: FontWeight.w700, letterSpacing: -0.5),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.account_balance_wallet_rounded),
            tooltip: 'Pool Earnings',
            onPressed: () => context.goNamed(RouteNames.poolEarnings),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.screenPadding),
        children: [
          // BTC Price banner
          _BtcPriceBanner(price: btcPrice, lastUpdated: btcUpdated),
          const SizedBox(height: AppSpacing.lg),

          // Electricity cost input
          _ElectricityCostInput(
            value: electricityCost,
            onChanged: (v) =>
                ref.read(electricityCostProvider.notifier).setCost(v),
          ),
          const SizedBox(height: AppSpacing.xl),

          // Fleet totals
          const _SectionLabel(label: 'FLEET TOTALS'),
          const SizedBox(height: AppSpacing.sm),
          _FleetTotalsCard(fleet: fleet),
          const SizedBox(height: AppSpacing.xl),

          // Per-miner breakdown
          const _SectionLabel(label: 'PER MINER'),
          const SizedBox(height: AppSpacing.sm),
          if (miners.isEmpty)
            Container(
              padding: const EdgeInsets.all(AppSpacing.xl),
              decoration: BoxDecoration(
                color: AppColors.cardDark,
                borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
                border: Border.all(color: AppColors.border, width: 0.5),
              ),
              child: const Center(
                child: Text(
                  'No miners configured.\nAdd miners from the dashboard.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: AppColors.textMuted,
                    fontSize: 13,
                  ),
                ),
              ),
            )
          else
            ...miners.map((miner) {
              final snapshot = ref.watch(minerLatestSnapshotProvider(miner.id));
              final profit =
                  ref.watch(minerProfitabilityProvider(miner.id));
              return Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                child: _MinerProfitRow(
                  name: miner.name,
                  isOnline: miner.status == MinerStatus.online,
                  hashrate: snapshot?.hashrate,
                  power: snapshot?.power,
                  result: profit,
                ),
              );
            }),
          const SizedBox(height: AppSpacing.xxl),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// BTC Price banner
// ---------------------------------------------------------------------------

class _BtcPriceBanner extends StatelessWidget {
  final double price;
  final DateTime? lastUpdated;

  const _BtcPriceBanner({required this.price, this.lastUpdated});

  @override
  Widget build(BuildContext context) {
    final updatedStr = lastUpdated != null
        ? '${lastUpdated!.hour.toString().padLeft(2, '0')}:'
            '${lastUpdated!.minute.toString().padLeft(2, '0')}'
        : '--:--';

    return Container(
      padding: const EdgeInsets.all(AppSpacing.cardPadding),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
        border: Border.all(
          color: AppColors.primary.withValues(alpha: 0.3),
          width: 0.5,
        ),
      ),
      child: Row(
        children: [
          const Icon(Icons.currency_bitcoin_rounded,
              color: AppColors.primary, size: 28),
          const SizedBox(width: AppSpacing.md),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'BTC / USD',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textMuted,
                  letterSpacing: 0.8,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                price > 0
                    ? '\$${_formatPrice(price)}'
                    : 'Loading...',
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                  color: AppColors.primary,
                  fontFeatures: [FontFeature.tabularFigures()],
                ),
              ),
            ],
          ),
          const Spacer(),
          Text(
            'Updated $updatedStr',
            style: const TextStyle(
              fontSize: 11,
              color: AppColors.textMuted,
            ),
          ),
        ],
      ),
    );
  }

  String _formatPrice(double price) {
    if (price >= 1000) {
      final parts = price.toStringAsFixed(0);
      // Add comma separators
      final buf = StringBuffer();
      for (var i = 0; i < parts.length; i++) {
        if (i > 0 && (parts.length - i) % 3 == 0) buf.write(',');
        buf.write(parts[i]);
      }
      return buf.toString();
    }
    return price.toStringAsFixed(2);
  }
}

// ---------------------------------------------------------------------------
// Electricity cost input
// ---------------------------------------------------------------------------

class _ElectricityCostInput extends StatefulWidget {
  final double value;
  final ValueChanged<double> onChanged;

  const _ElectricityCostInput({
    required this.value,
    required this.onChanged,
  });

  @override
  State<_ElectricityCostInput> createState() => _ElectricityCostInputState();
}

class _ElectricityCostInputState extends State<_ElectricityCostInput> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller =
        TextEditingController(text: widget.value.toStringAsFixed(2));
  }

  @override
  void didUpdateWidget(_ElectricityCostInput oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.value != widget.value) {
      final text = widget.value.toStringAsFixed(2);
      if (_controller.text != text) {
        _controller.text = text;
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'ELECTRICITY COST',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textMuted,
                  letterSpacing: 1.0,
                ),
              ),
              SizedBox(height: 2),
              Text(
                '\$ per kWh',
                style: TextStyle(
                  fontSize: 12,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
        SizedBox(
          width: 100,
          child: TextField(
            controller: _controller,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontSize: 16,
              fontWeight: FontWeight.w600,
              fontFeatures: [FontFeature.tabularFigures()],
            ),
            decoration: InputDecoration(
              prefixText: '\$ ',
              prefixStyle: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 16,
              ),
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
                horizontal: AppSpacing.sm,
                vertical: AppSpacing.sm,
              ),
            ),
            onChanged: (text) {
              final parsed = double.tryParse(text);
              if (parsed != null && parsed >= 0) {
                widget.onChanged(parsed);
              }
            },
          ),
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Fleet totals card
// ---------------------------------------------------------------------------

class _FleetTotalsCard extends StatelessWidget {
  final ProfitabilityResult fleet;

  const _FleetTotalsCard({required this.fleet});

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
          // Daily row
          Row(
            children: [
              Expanded(
                child: _MetricTile(
                  label: 'DAILY REV',
                  value: '\$${fleet.dailyRevenueUsd.toStringAsFixed(2)}',
                  color: AppColors.accent,
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: _MetricTile(
                  label: 'DAILY COST',
                  value: '\$${fleet.dailyCostUsd.toStringAsFixed(2)}',
                  color: AppColors.chartPower,
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: _MetricTile(
                  label: 'DAILY P/L',
                  value:
                      '${fleet.dailyProfitUsd >= 0 ? '+' : ''}\$${fleet.dailyProfitUsd.toStringAsFixed(2)}',
                  color: fleet.isProfitable ? AppColors.online : AppColors.error,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          const Divider(color: AppColors.border, height: 1),
          const SizedBox(height: AppSpacing.md),
          // Monthly row
          Row(
            children: [
              Expanded(
                child: _MetricTile(
                  label: 'MTH REV',
                  value: '\$${fleet.monthlyRevenueUsd.toStringAsFixed(0)}',
                  color: AppColors.accent,
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: _MetricTile(
                  label: 'MTH COST',
                  value: '\$${fleet.monthlyCostUsd.toStringAsFixed(0)}',
                  color: AppColors.chartPower,
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: _MetricTile(
                  label: 'MTH P/L',
                  value:
                      '${fleet.monthlyProfitUsd >= 0 ? '+' : ''}\$${fleet.monthlyProfitUsd.toStringAsFixed(0)}',
                  color: fleet.isProfitable ? AppColors.online : AppColors.error,
                ),
              ),
            ],
          ),
          if (fleet.dailyBtc > 0) ...[
            const SizedBox(height: AppSpacing.md),
            const Divider(color: AppColors.border, height: 1),
            const SizedBox(height: AppSpacing.md),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  '${(fleet.dailyBtc * 1e8).toStringAsFixed(0)} sats/day',
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppColors.primary,
                    fontFeatures: [FontFeature.tabularFigures()],
                  ),
                ),
                const SizedBox(width: AppSpacing.lg),
                Text(
                  '${(fleet.dailyBtc * 30 * 1e8).toStringAsFixed(0)} sats/mth',
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppColors.primary,
                    fontFeatures: [FontFeature.tabularFigures()],
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _MetricTile extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _MetricTile({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 9,
            fontWeight: FontWeight.w600,
            color: AppColors.textMuted,
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(height: AppSpacing.xs),
        Text(
          value,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w700,
            color: color,
            fontFeatures: const [FontFeature.tabularFigures()],
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Per-miner profit row
// ---------------------------------------------------------------------------

class _MinerProfitRow extends StatelessWidget {
  final String name;
  final bool isOnline;
  final double? hashrate;
  final double? power;
  final ProfitabilityResult? result;

  const _MinerProfitRow({
    required this.name,
    required this.isOnline,
    this.hashrate,
    this.power,
    this.result,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.cardDark,
        borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
        border: Border.all(color: AppColors.border, width: 0.5),
      ),
      child: Row(
        children: [
          // Status dot
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: isOnline ? AppColors.online : AppColors.offline,
            ),
          ),
          const SizedBox(width: AppSpacing.md),

          // Name
          Expanded(
            flex: 3,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  hashrate != null
                      ? '${hashrate!.toHashrateString()} / ${power?.toPowerString() ?? '--'}'
                      : '--',
                  style: const TextStyle(
                    fontSize: 11,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),

          // Daily cost
          Expanded(
            flex: 2,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                const Text(
                  'COST',
                  style: TextStyle(
                    fontSize: 9,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textMuted,
                    letterSpacing: 0.5,
                  ),
                ),
                Text(
                  result != null
                      ? '\$${result!.dailyCostUsd.toStringAsFixed(2)}'
                      : '--',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppColors.chartPower,
                    fontFeatures: [FontFeature.tabularFigures()],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.sm),

          // Daily revenue
          Expanded(
            flex: 2,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                const Text(
                  'REV',
                  style: TextStyle(
                    fontSize: 9,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textMuted,
                    letterSpacing: 0.5,
                  ),
                ),
                Text(
                  result != null
                      ? '\$${result!.dailyRevenueUsd.toStringAsFixed(2)}'
                      : '--',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppColors.accent,
                    fontFeatures: [FontFeature.tabularFigures()],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.sm),

          // Daily P/L
          Expanded(
            flex: 2,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                const Text(
                  'P/L',
                  style: TextStyle(
                    fontSize: 9,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textMuted,
                    letterSpacing: 0.5,
                  ),
                ),
                Text(
                  result != null
                      ? '${result!.dailyProfitUsd >= 0 ? '+' : ''}'
                          '\$${result!.dailyProfitUsd.toStringAsFixed(2)}'
                      : '--',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: result != null
                        ? (result!.isProfitable
                            ? AppColors.online
                            : AppColors.error)
                        : AppColors.textMuted,
                    fontFeatures: const [FontFeature.tabularFigures()],
                  ),
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

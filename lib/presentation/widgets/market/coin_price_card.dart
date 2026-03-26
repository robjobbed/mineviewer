import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../config/theme/app_colors.dart';
import '../../../config/theme/app_spacing.dart';
import '../../../core/extensions/double_ext.dart';
import '../../../data/models/coin_market_data.dart';
import '../../../data/models/miner_status.dart';
import '../../../providers/market/market_data_provider.dart';
import '../../../services/market/market_data_service.dart';
import '../../providers/miners_provider.dart';

class CoinPriceCard extends ConsumerStatefulWidget {
  const CoinPriceCard({super.key});

  @override
  ConsumerState<CoinPriceCard> createState() => _CoinPriceCardState();
}

class _CoinPriceCardState extends ConsumerState<CoinPriceCard> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final marketAsync = ref.watch(marketDataProvider);
    final miners = ref.watch(minersProvider);
    final snapshots = ref.watch(minerSnapshotsProvider);

    // Calculate total hashrate from all online miners (in H/s)
    double totalHashrate = 0;
    for (final miner in miners) {
      if (miner.status == MinerStatus.online) {
        final snap = snapshots[miner.id];
        if (snap != null) {
          totalHashrate += snap.hashrate;
        }
      }
    }

    // Convert to TH/s for probability calculations
    final totalHashrateTHs = totalHashrate / 1e12;

    return Container(
      decoration: BoxDecoration(
        color: AppColors.cardDark,
        borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
        border: Border.all(color: AppColors.border, width: 0.5),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Header (always visible, tappable)
          InkWell(
            borderRadius: BorderRadius.vertical(
              top: const Radius.circular(AppSpacing.cardRadius),
              bottom: _expanded
                  ? Radius.zero
                  : const Radius.circular(AppSpacing.cardRadius),
            ),
            onTap: () => setState(() => _expanded = !_expanded),
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.cardPadding),
              child: Row(
                children: [
                  const Icon(
                    Icons.currency_bitcoin_rounded,
                    color: AppColors.primary,
                    size: 20,
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  const Expanded(
                    child: Text(
                      'Coin Price & Solo Block Probability',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ),
                  Text(
                    totalHashrate.toHashrateString(),
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: AppColors.primary,
                      fontFeatures: [FontFeature.tabularFigures()],
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  AnimatedRotation(
                    turns: _expanded ? 0.5 : 0,
                    duration: const Duration(milliseconds: 200),
                    child: const Icon(
                      Icons.expand_more_rounded,
                      color: AppColors.textMuted,
                      size: 20,
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Expandable content
          AnimatedCrossFade(
            firstChild: const SizedBox.shrink(),
            secondChild: marketAsync.when(
              data: (coins) => _ExpandedContent(
                coins: coins,
                totalHashrateTHs: totalHashrateTHs,
              ),
              loading: () => const Padding(
                padding: EdgeInsets.all(AppSpacing.xl),
                child: Center(
                  child: SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: AppColors.primary,
                    ),
                  ),
                ),
              ),
              error: (e, _) => Padding(
                padding: const EdgeInsets.all(AppSpacing.cardPadding),
                child: Text(
                  'Failed to load market data',
                  style: TextStyle(
                    fontSize: 12,
                    color: AppColors.error,
                  ),
                ),
              ),
            ),
            crossFadeState: _expanded
                ? CrossFadeState.showSecond
                : CrossFadeState.showFirst,
            duration: const Duration(milliseconds: 250),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Expanded content showing coin rows + Powerball comparison
// ---------------------------------------------------------------------------

class _ExpandedContent extends StatelessWidget {
  final List<CoinMarketData> coins;
  final double totalHashrateTHs;

  const _ExpandedContent({
    required this.coins,
    required this.totalHashrateTHs,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Divider(color: AppColors.border, height: 1),
        ...coins.map((coin) => _CoinRow(
              coin: coin,
              totalHashrateTHs: totalHashrateTHs,
            )),
        // Powerball comparison
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.cardPadding,
            vertical: AppSpacing.md,
          ),
          decoration: const BoxDecoration(
            border: Border(top: BorderSide(color: AppColors.border, width: 0.5)),
          ),
          child: const Text(
            'Powerball odds: 1 in 292,201,338',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w500,
              color: AppColors.primary,
              fontStyle: FontStyle.italic,
            ),
          ),
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Individual coin row
// ---------------------------------------------------------------------------

class _CoinRow extends StatelessWidget {
  final CoinMarketData coin;
  final double totalHashrateTHs;

  const _CoinRow({required this.coin, required this.totalHashrateTHs});

  Color get _coinColor => switch (coin.symbol) {
        'BTC' => const Color(0xFFF7931A),
        'BCH' => const Color(0xFF8DC351),
        'DGB' => const Color(0xFF006AD2),
        _ => AppColors.textSecondary,
      };

  @override
  Widget build(BuildContext context) {
    final priceColor = coin.priceChange24hPercent >= 0
        ? AppColors.online
        : AppColors.error;

    final prob = MarketDataService.calculateBlockProbability(
      coin: coin,
      userHashrateTHs: totalHashrateTHs,
    );

    final currencyFormat = NumberFormat.currency(symbol: '\$', decimalDigits: 2);

    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.cardPadding,
        vertical: AppSpacing.md,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Top: coin icon + symbol/name + price
          Row(
            children: [
              // Coin icon (colored circle with first letter)
              Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  color: _coinColor.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                alignment: Alignment.center,
                child: Text(
                  coin.symbol[0],
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: _coinColor,
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              // Symbol + name
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    coin.symbol,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  Text(
                    coin.name,
                    style: const TextStyle(
                      fontSize: 10,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
              const Spacer(),
              // Price + change
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    coin.priceUsd >= 1
                        ? currencyFormat.format(coin.priceUsd)
                        : '\$${coin.priceUsd.toStringAsFixed(4)}',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: priceColor,
                      fontFeatures: const [FontFeature.tabularFigures()],
                    ),
                  ),
                  Text(
                    '${coin.priceChange24hPercent >= 0 ? '+' : ''}${coin.priceChange24hPercent.toStringAsFixed(1)}%',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w500,
                      color: priceColor,
                    ),
                  ),
                ],
              ),
            ],
          ),

          const SizedBox(height: AppSpacing.sm),

          // Bottom stats row
          Row(
            children: [
              Expanded(
                child: _MiniInfo(
                  label: 'Reward',
                  value:
                      '${coin.blockReward} = ${currencyFormat.format(coin.blockRewardUsd)}',
                ),
              ),
              Expanded(
                child: _MiniInfo(
                  label: 'Diff',
                  value: _formatDifficulty(coin.networkDifficulty),
                ),
              ),
              Expanded(
                child: _MiniInfo(
                  label: prob.expectedBlocksPerMonth >= 1
                      ? 'Blocks/Mo'
                      : 'Chance/Mo',
                  value: prob.oddsString,
                  valueColor: AppColors.primary,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _formatDifficulty(double diff) {
    if (diff <= 0) return '--';
    if (diff >= 1e12) return '${(diff / 1e12).toStringAsFixed(2)}T';
    if (diff >= 1e9) return '${(diff / 1e9).toStringAsFixed(2)}G';
    if (diff >= 1e6) return '${(diff / 1e6).toStringAsFixed(2)}M';
    if (diff >= 1e3) return '${(diff / 1e3).toStringAsFixed(2)}K';
    return diff.toStringAsFixed(0);
  }
}

class _MiniInfo extends StatelessWidget {
  final String label;
  final String value;
  final Color valueColor;

  const _MiniInfo({
    required this.label,
    required this.value,
    this.valueColor = AppColors.textSecondary,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
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
        const SizedBox(height: 2),
        Text(
          value,
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: valueColor,
            fontFeatures: const [FontFeature.tabularFigures()],
          ),
        ),
      ],
    );
  }
}

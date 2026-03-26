import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../config/router/route_names.dart';
import '../../../config/theme/app_colors.dart';
import '../../../config/theme/app_spacing.dart';
import '../../../core/extensions/double_ext.dart';
import '../../../data/models/miner.dart';
import '../../../data/models/miner_snapshot.dart';
import '../../../data/models/miner_status.dart';
import '../../../providers/polling_provider.dart';
import '../../providers/miners_provider.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/fleet/fleet_ticker.dart';
import '../../widgets/market/coin_price_card.dart';
import '../../widgets/miners/rich_miner_card.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Activate polling service on build
    ref.read(pollingServiceProvider);

    final miners = ref.watch(minersProvider);
    final snapshots = ref.watch(minerSnapshotsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'MineViewer',
          style: TextStyle(
            fontWeight: FontWeight.w700,
            letterSpacing: -0.5,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.add_rounded),
            tooltip: 'Add Miner',
            onPressed: () => context.goNamed(RouteNames.addMiner),
          ),
        ],
      ),
      floatingActionButton: miners.isNotEmpty
          ? FloatingActionButton(
              onPressed: () => context.goNamed(RouteNames.addMiner),
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.black,
              child: const Icon(Icons.add_rounded),
            )
          : null,
      body: miners.isEmpty
          ? EmptyState(
              icon: Icons.developer_board_rounded,
              title: 'No miners yet',
              subtitle:
                  'Add your first miner to start monitoring your fleet.',
              action: FilledButton.icon(
                onPressed: () => context.goNamed(RouteNames.discovery),
                icon: const Icon(Icons.sensors_rounded, size: 18),
                label: const Text('Scan Network'),
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.black,
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.xl,
                    vertical: AppSpacing.md,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius:
                        BorderRadius.circular(AppSpacing.cardRadius),
                  ),
                ),
              ),
            )
          : _FleetBody(miners: miners, snapshots: snapshots),
    );
  }
}

// ---------------------------------------------------------------------------
// Fleet body: ticker + coin price + summary row + responsive miner grid
// ---------------------------------------------------------------------------

class _FleetBody extends ConsumerWidget {
  final List<Miner> miners;
  final Map<String, MinerSnapshot> snapshots;

  const _FleetBody({required this.miners, required this.snapshots});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final screenWidth = MediaQuery.of(context).size.width;
    // 2-column grid on wider screens (tablets, large phones in landscape)
    final crossAxisCount = screenWidth >= 600 ? 2 : 1;

    return Column(
      children: [
        // Scrolling fleet summary ticker
        FleetTicker(miners: miners, snapshots: snapshots),

        // Scrollable content
        Expanded(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.screenPadding,
              AppSpacing.md,
              AppSpacing.screenPadding,
              AppSpacing.xxl + 80, // space for FAB
            ),
            children: [
              // Fleet summary cards
              _FleetSummaryRow(miners: miners, snapshots: snapshots),

              const SizedBox(height: AppSpacing.md),

              // Coin Price & Block Probability widget
              const CoinPriceCard(),

              const SizedBox(height: AppSpacing.lg),

              // Miners section header
              Row(
                children: [
                  const Text(
                    'MINERS',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textMuted,
                      letterSpacing: 1.0,
                    ),
                  ),
                  const Spacer(),
                  Text(
                    '${miners.length}',
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: AppSpacing.sm),

              // Responsive miner grid
              if (crossAxisCount == 1)
                // Single column - list style
                ...miners.map((miner) => Padding(
                      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                      child: RichMinerCard(
                        miner: miner,
                        snapshot: snapshots[miner.id],
                      ),
                    ))
              else
                // Multi-column grid
                GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: crossAxisCount,
                    crossAxisSpacing: AppSpacing.sm,
                    mainAxisSpacing: AppSpacing.sm,
                    childAspectRatio: 0.85,
                  ),
                  itemCount: miners.length,
                  itemBuilder: (context, index) {
                    final miner = miners[index];
                    return RichMinerCard(
                      miner: miner,
                      snapshot: snapshots[miner.id],
                    );
                  },
                ),
            ],
          ),
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Fleet summary cards row
// ---------------------------------------------------------------------------

class _FleetSummaryRow extends StatelessWidget {
  final List<Miner> miners;
  final Map<String, MinerSnapshot> snapshots;

  const _FleetSummaryRow({required this.miners, required this.snapshots});

  @override
  Widget build(BuildContext context) {
    double totalHashrate = 0;
    double totalPower = 0;
    int onlineCount = 0;

    for (final miner in miners) {
      if (miner.status == MinerStatus.online) onlineCount++;
      final snap = snapshots[miner.id];
      if (snap != null) {
        totalHashrate += snap.hashrate;
        totalPower += snap.power ?? 0;
      }
    }

    return Row(
      children: [
        Expanded(
          child: _SummaryCard(
            label: 'HASHRATE',
            value: totalHashrate.toHashrateString(),
            icon: Icons.speed_rounded,
            valueColor: AppColors.chartHashrate,
          ),
        ),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: _SummaryCard(
            label: 'POWER',
            value: totalPower.toPowerString(),
            icon: Icons.bolt_rounded,
            valueColor: AppColors.chartPower,
          ),
        ),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: _SummaryCard(
            label: 'ONLINE',
            value: '$onlineCount / ${miners.length}',
            icon: Icons.wifi_rounded,
            valueColor: onlineCount == miners.length
                ? AppColors.online
                : AppColors.warning,
          ),
        ),
      ],
    );
  }
}

class _SummaryCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color valueColor;

  const _SummaryCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.valueColor,
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 12, color: AppColors.textMuted),
              const SizedBox(width: AppSpacing.xs),
              Text(
                label,
                style: const TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textMuted,
                  letterSpacing: 0.8,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            value,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: valueColor,
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}

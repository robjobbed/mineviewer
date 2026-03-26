import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../services/profitability/profitability_calculator.dart';
import 'miners_provider.dart';
import 'pool_earnings_provider.dart';

// ---------------------------------------------------------------------------
// Electricity cost setting (user input, persisted in state)
// ---------------------------------------------------------------------------

class ElectricityCostNotifier extends Notifier<double> {
  @override
  double build() => 0.12; // Default: $0.12/kWh (US average)

  void setCost(double costPerKwh) {
    state = costPerKwh;
  }
}

final electricityCostProvider =
    NotifierProvider<ElectricityCostNotifier, double>(
  ElectricityCostNotifier.new,
);

// ---------------------------------------------------------------------------
// Per-miner profitability
// ---------------------------------------------------------------------------

/// Calculate profitability for a single miner by ID.
final minerProfitabilityProvider =
    Provider.family<ProfitabilityResult?, String>((ref, minerId) {
  final snapshot = ref.watch(minerLatestSnapshotProvider(minerId));
  final earnings = ref.watch(earningsCacheProvider)[minerId];
  final btcPrice = ref.watch(btcPriceValueProvider);
  final electricityCost = ref.watch(electricityCostProvider);

  if (snapshot == null) return null;

  final power = snapshot.power ?? 0.0;
  final dailyBtc = earnings?.estimatedDailyBtc ?? 0.0;

  if (btcPrice <= 0) return null;

  return ProfitabilityCalculator.calculate(
    powerWatts: power,
    electricityCostPerKwh: electricityCost,
    dailyBtcEarned: dailyBtc,
    btcPriceUsd: btcPrice,
  );
});

// ---------------------------------------------------------------------------
// Fleet-level profitability totals
// ---------------------------------------------------------------------------

final fleetProfitabilityProvider = Provider<ProfitabilityResult>((ref) {
  final miners = ref.watch(minersProvider);
  final results = <ProfitabilityResult>[];

  for (final miner in miners) {
    final result = ref.watch(minerProfitabilityProvider(miner.id));
    if (result != null) {
      results.add(result);
    }
  }

  return ProfitabilityCalculator.sumFleet(results);
});

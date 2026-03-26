/// Result of a profitability calculation for a single miner or fleet.
class ProfitabilityResult {
  /// Daily electricity cost in USD.
  final double dailyCostUsd;

  /// Daily BTC revenue in USD.
  final double dailyRevenueUsd;

  /// Daily profit (or loss if negative) in USD.
  final double dailyProfitUsd;

  /// Monthly projected cost (dailyCost * 30).
  final double monthlyCostUsd;

  /// Monthly projected revenue (dailyRevenue * 30).
  final double monthlyRevenueUsd;

  /// Monthly projected profit (dailyProfit * 30).
  final double monthlyProfitUsd;

  /// Daily BTC earned.
  final double dailyBtc;

  /// The BTC price used for this calculation.
  final double btcPriceUsd;

  const ProfitabilityResult({
    required this.dailyCostUsd,
    required this.dailyRevenueUsd,
    required this.dailyProfitUsd,
    required this.monthlyCostUsd,
    required this.monthlyRevenueUsd,
    required this.monthlyProfitUsd,
    required this.dailyBtc,
    required this.btcPriceUsd,
  });

  bool get isProfitable => dailyProfitUsd > 0;
}

class ProfitabilityCalculator {
  ProfitabilityCalculator._();

  /// Calculate profitability for a miner.
  ///
  /// - [powerWatts]: Miner power consumption in watts.
  /// - [electricityCostPerKwh]: Electricity rate in $/kWh.
  /// - [dailyBtcEarned]: BTC earned per day (from pool or estimate).
  /// - [btcPriceUsd]: Current BTC/USD price.
  static ProfitabilityResult calculate({
    required double powerWatts,
    required double electricityCostPerKwh,
    required double dailyBtcEarned,
    required double btcPriceUsd,
  }) {
    // Daily kWh = watts / 1000 * 24 hours
    final dailyKwh = powerWatts / 1000.0 * 24.0;
    final dailyCost = dailyKwh * electricityCostPerKwh;
    final dailyRevenue = dailyBtcEarned * btcPriceUsd;
    final dailyProfit = dailyRevenue - dailyCost;

    return ProfitabilityResult(
      dailyCostUsd: dailyCost,
      dailyRevenueUsd: dailyRevenue,
      dailyProfitUsd: dailyProfit,
      monthlyCostUsd: dailyCost * 30,
      monthlyRevenueUsd: dailyRevenue * 30,
      monthlyProfitUsd: dailyProfit * 30,
      dailyBtc: dailyBtcEarned,
      btcPriceUsd: btcPriceUsd,
    );
  }

  /// Calculate fleet-level profitability by summing individual results.
  static ProfitabilityResult sumFleet(List<ProfitabilityResult> results) {
    if (results.isEmpty) {
      return const ProfitabilityResult(
        dailyCostUsd: 0,
        dailyRevenueUsd: 0,
        dailyProfitUsd: 0,
        monthlyCostUsd: 0,
        monthlyRevenueUsd: 0,
        monthlyProfitUsd: 0,
        dailyBtc: 0,
        btcPriceUsd: 0,
      );
    }

    double cost = 0, rev = 0, profit = 0, btc = 0;
    for (final r in results) {
      cost += r.dailyCostUsd;
      rev += r.dailyRevenueUsd;
      profit += r.dailyProfitUsd;
      btc += r.dailyBtc;
    }

    return ProfitabilityResult(
      dailyCostUsd: cost,
      dailyRevenueUsd: rev,
      dailyProfitUsd: profit,
      monthlyCostUsd: cost * 30,
      monthlyRevenueUsd: rev * 30,
      monthlyProfitUsd: profit * 30,
      dailyBtc: btc,
      btcPriceUsd: results.first.btcPriceUsd,
    );
  }
}

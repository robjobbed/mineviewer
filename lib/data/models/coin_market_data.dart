import 'package:freezed_annotation/freezed_annotation.dart';

part 'coin_market_data.freezed.dart';
part 'coin_market_data.g.dart';

@freezed
abstract class CoinMarketData with _$CoinMarketData {
  const factory CoinMarketData({
    required String symbol,
    required String name,
    required double priceUsd,
    required double priceChange24hPercent,
    required double networkDifficulty,
    required double networkHashrate,
    required double blockReward,
    required double blockRewardUsd,
    DateTime? lastUpdated,
  }) = _CoinMarketData;

  factory CoinMarketData.fromJson(Map<String, dynamic> json) =>
      _$CoinMarketDataFromJson(json);
}

@freezed
abstract class BlockProbability with _$BlockProbability {
  const factory BlockProbability({
    required String symbol,
    required double userHashrateTHs,
    required double networkHashrateTHs,
    required double blocksPerDay,
    required double chancePerBlock,
    required double expectedBlocksPerMonth,
    required String oddsString,
  }) = _BlockProbability;

  factory BlockProbability.fromJson(Map<String, dynamic> json) =>
      _$BlockProbabilityFromJson(json);
}

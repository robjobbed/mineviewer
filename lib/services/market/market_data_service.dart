import 'package:dio/dio.dart';
import 'package:logging/logging.dart';

import '../../data/models/coin_market_data.dart';

final _log = Logger('MarketDataService');

class MarketDataService {
  final Dio _dio;
  static const _coingeckoBase = 'https://api.coingecko.com/api/v3';
  static const _mempoolBase = 'https://mempool.space/api';

  MarketDataService({Dio? dio})
      : _dio = dio ??
            Dio(BaseOptions(
              connectTimeout: const Duration(seconds: 10),
              receiveTimeout: const Duration(seconds: 10),
            ));

  /// Fetch prices for BTC, BCH, DGB from CoinGecko
  Future<List<CoinMarketData>> fetchMarketData() async {
    try {
      // Fetch prices from CoinGecko
      final priceResponse = await _dio.get(
        '$_coingeckoBase/simple/price',
        queryParameters: {
          'ids': 'bitcoin,bitcoin-cash,digibyte',
          'vs_currencies': 'usd',
          'include_24hr_change': 'true',
        },
      );

      // Fetch BTC difficulty from mempool.space
      final diffResponse =
          await _dio.get('$_mempoolBase/v1/mining/hashrate/1m');
      final btcDifficulty =
          await _dio.get('$_mempoolBase/v1/difficulty-adjustment');

      final prices = priceResponse.data as Map<String, dynamic>;
      final hashData = diffResponse.data;
      final diffData = btcDifficulty.data;

      // Extract BTC network hashrate (comes in H/s, convert to TH/s)
      double btcNetworkHashrateTHs = 0;
      if (hashData is Map && hashData['hashrates'] is List) {
        final hashrates = hashData['hashrates'] as List;
        if (hashrates.isNotEmpty) {
          btcNetworkHashrateTHs =
              (hashrates.last['avgHashrate'] as num).toDouble() / 1e12;
        }
      }

      double btcDifficultyValue = 0;
      if (diffData is Map) {
        btcDifficultyValue =
            (diffData['difficultyChange'] as num?)?.toDouble() ?? 0;
      }

      // Try to get actual difficulty
      try {
        final blockTip = await _dio.get('$_mempoolBase/blocks/tip/height');
        final blockHeight = blockTip.data as int;
        final blockData =
            await _dio.get('$_mempoolBase/block-height/$blockHeight');
        // Calculate from hashrate
        // difficulty = hashrate * 2^32 / 600 (for BTC with 10 min blocks)
        btcDifficultyValue =
            btcNetworkHashrateTHs * 1e12 * 4294967296 / 600;
      } catch (_) {
        // Fallback: approximate difficulty from hashrate
        btcDifficultyValue =
            btcNetworkHashrateTHs * 1e12 * 4294967296 / 600;
      }

      final results = <CoinMarketData>[];

      // BTC
      final btc = prices['bitcoin'] ?? {};
      results.add(CoinMarketData(
        symbol: 'BTC',
        name: 'Bitcoin',
        priceUsd: (btc['usd'] as num?)?.toDouble() ?? 0,
        priceChange24hPercent:
            (btc['usd_24h_change'] as num?)?.toDouble() ?? 0,
        networkDifficulty: btcDifficultyValue,
        networkHashrate: btcNetworkHashrateTHs,
        blockReward: 3.125,
        blockRewardUsd: ((btc['usd'] as num?)?.toDouble() ?? 0) * 3.125,
        lastUpdated: DateTime.now(),
      ));

      // BCH
      final bch = prices['bitcoin-cash'] ?? {};
      results.add(CoinMarketData(
        symbol: 'BCH',
        name: 'Bitcoin Cash',
        priceUsd: (bch['usd'] as num?)?.toDouble() ?? 0,
        priceChange24hPercent:
            (bch['usd_24h_change'] as num?)?.toDouble() ?? 0,
        networkDifficulty: 0,
        networkHashrate: 0,
        blockReward: 3.125,
        blockRewardUsd: ((bch['usd'] as num?)?.toDouble() ?? 0) * 3.125,
        lastUpdated: DateTime.now(),
      ));

      // DGB
      final dgb = prices['digibyte'] ?? {};
      results.add(CoinMarketData(
        symbol: 'DGB',
        name: 'DigiByte (SHA-256)',
        priceUsd: (dgb['usd'] as num?)?.toDouble() ?? 0,
        priceChange24hPercent:
            (dgb['usd_24h_change'] as num?)?.toDouble() ?? 0,
        networkDifficulty: 0,
        networkHashrate: 0,
        blockReward: 625,
        blockRewardUsd: ((dgb['usd'] as num?)?.toDouble() ?? 0) * 625,
        lastUpdated: DateTime.now(),
      ));

      return results;
    } catch (e, st) {
      _log.warning('Failed to fetch market data: $e\n$st');
      return [];
    }
  }

  /// Calculate block probability for solo mining
  static BlockProbability calculateBlockProbability({
    required CoinMarketData coin,
    required double userHashrateTHs,
  }) {
    if (coin.networkHashrate <= 0 || userHashrateTHs <= 0) {
      return BlockProbability(
        symbol: coin.symbol,
        userHashrateTHs: userHashrateTHs,
        networkHashrateTHs: coin.networkHashrate,
        blocksPerDay:
            coin.symbol == 'BTC' ? 144 : (coin.symbol == 'BCH' ? 144 : 8640),
        chancePerBlock: 0,
        expectedBlocksPerMonth: 0,
        oddsString: 'N/A',
      );
    }

    final blocksPerDay = coin.symbol == 'DGB' ? 8640.0 : 144.0;
    final chancePerBlock = userHashrateTHs / coin.networkHashrate;
    final expectedPerMonth = chancePerBlock * blocksPerDay * 30;

    final oddsPerMonth =
        expectedPerMonth > 0 ? (1 / expectedPerMonth).round() : 0;
    final oddsString = oddsPerMonth > 0
        ? '1 in ${_formatNumber(oddsPerMonth)}'
        : expectedPerMonth >= 1
            ? expectedPerMonth.toStringAsFixed(0)
            : 'N/A';

    return BlockProbability(
      symbol: coin.symbol,
      userHashrateTHs: userHashrateTHs,
      networkHashrateTHs: coin.networkHashrate,
      blocksPerDay: blocksPerDay,
      chancePerBlock: chancePerBlock,
      expectedBlocksPerMonth: expectedPerMonth,
      oddsString: oddsString,
    );
  }

  static String _formatNumber(int number) {
    if (number >= 1000000) {
      return '${(number / 1000000).toStringAsFixed(1)}M';
    } else if (number >= 1000) {
      final result = number.toString();
      final buffer = StringBuffer();
      for (int i = 0; i < result.length; i++) {
        if (i > 0 && (result.length - i) % 3 == 0) buffer.write(',');
        buffer.write(result[i]);
      }
      return buffer.toString();
    }
    return number.toString();
  }
}

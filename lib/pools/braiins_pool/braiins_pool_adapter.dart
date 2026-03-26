import 'package:dio/dio.dart';
import 'package:logging/logging.dart';
import '../pool_adapter.dart';

final _log = Logger('BraiinsPoolAdapter');

/// Braiins Pool adapter.
///
/// Requires an API key from pool account settings.
/// Public API endpoint:
///   GET https://pool.braiins.com/accounts/profile/json/{apiKey}
class BraiinsPoolAdapter implements PoolAdapter {
  final Dio _dio = Dio(BaseOptions(
    connectTimeout: const Duration(seconds: 10),
    receiveTimeout: const Duration(seconds: 10),
  ));

  @override
  String get displayName => 'Braiins Pool';

  @override
  PoolType get type => PoolType.braiinsPool;

  @override
  bool validateIdentifier(String identifier) {
    // Braiins API key: typically alphanumeric, 20+ chars
    final trimmed = identifier.trim();
    return trimmed.length >= 10 &&
        RegExp(r'^[a-zA-Z0-9_\-]+$').hasMatch(trimmed);
  }

  @override
  Future<PoolEarnings?> fetchEarnings(String identifier) async {
    try {
      final apiKey = identifier.trim();
      final response = await _dio.get(
        'https://pool.braiins.com/accounts/profile/json/$apiKey',
      );

      if (response.statusCode != 200 || response.data == null) return null;

      final data = response.data as Map<String, dynamic>;

      // Parse btc account info
      final btcData = data['btc'] as Map<String, dynamic>?;
      final confirmed = _parseDouble(btcData?['confirmed_reward']);
      final unconfirmed = _parseDouble(btcData?['unconfirmed_reward']);
      final estimated = _parseDouble(btcData?['estimated_reward']);
      final hashrate = _parseDouble(btcData?['hash_rate_5m']) ??
          _parseDouble(data['hash_rate_5m']);

      final totalEarned = (confirmed ?? 0.0) + (unconfirmed ?? 0.0);

      return PoolEarnings(
        pool: PoolType.braiinsPool,
        identifier: '***${apiKey.substring(apiKey.length - 4)}', // Mask key
        timestamp: DateTime.now(),
        totalEarnedBtc: totalEarned,
        pendingBtc: unconfirmed,
        estimatedDailyBtc: estimated,
        poolHashrate: hashrate,
        blocksFound: null,
        lastPayout: null,
        lastPayoutAmount: null,
      );
    } on DioException catch (e) {
      _log.warning('Braiins Pool fetch failed: ${e.message}');
      return null;
    } catch (e) {
      _log.warning('Braiins Pool parse error: $e');
      return null;
    }
  }

  double? _parseDouble(dynamic v) {
    if (v == null) return null;
    if (v is num) return v.toDouble();
    return double.tryParse(v.toString());
  }
}

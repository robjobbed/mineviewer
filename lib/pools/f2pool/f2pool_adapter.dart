import 'package:dio/dio.dart';
import 'package:logging/logging.dart';
import '../pool_adapter.dart';

final _log = Logger('F2PoolAdapter');

/// F2Pool adapter.
///
/// Public API endpoint:
///   GET https://api.f2pool.com/bitcoin/{btcAddress}
class F2PoolAdapter implements PoolAdapter {
  final Dio _dio = Dio(BaseOptions(
    connectTimeout: const Duration(seconds: 10),
    receiveTimeout: const Duration(seconds: 10),
  ));

  @override
  String get displayName => 'F2Pool';

  @override
  PoolType get type => PoolType.f2pool;

  @override
  bool validateIdentifier(String identifier) {
    final trimmed = identifier.trim();
    return trimmed.length >= 26 &&
        trimmed.length <= 62 &&
        RegExp(r'^(bc1|[13])[a-zA-HJ-NP-Z0-9]+$').hasMatch(trimmed);
  }

  @override
  Future<PoolEarnings?> fetchEarnings(String identifier) async {
    try {
      final address = identifier.trim();
      final response = await _dio.get(
        'https://api.f2pool.com/bitcoin/$address',
      );

      if (response.statusCode != 200 || response.data == null) return null;

      final data = response.data as Map<String, dynamic>;

      final balance = _parseDouble(data['balance']);
      final paid = _parseDouble(data['paid']);
      final hashrate = _parseDouble(data['hashrate']);
      final estDaily = _parseDouble(data['estimated_daily_revenue']) ??
          _parseDouble(data['value_last_day']);

      final totalEarned = (balance ?? 0.0) + (paid ?? 0.0);

      // Last payout info
      double? lastPayoutAmt;
      DateTime? lastPayoutTime;
      if (data['payout_history'] is List) {
        final payouts = data['payout_history'] as List;
        if (payouts.isNotEmpty) {
          final latest = payouts.first;
          if (latest is Map<String, dynamic>) {
            lastPayoutAmt = _parseDouble(latest['amount']);
            if (latest['time'] != null) {
              lastPayoutTime = DateTime.tryParse(latest['time'].toString());
            }
          }
        }
      }

      return PoolEarnings(
        pool: PoolType.f2pool,
        identifier: address,
        timestamp: DateTime.now(),
        totalEarnedBtc: totalEarned,
        pendingBtc: balance,
        estimatedDailyBtc: estDaily,
        poolHashrate: hashrate,
        blocksFound: null,
        lastPayout: lastPayoutTime,
        lastPayoutAmount: lastPayoutAmt,
      );
    } on DioException catch (e) {
      _log.warning('F2Pool fetch failed: ${e.message}');
      return null;
    } catch (e) {
      _log.warning('F2Pool parse error: $e');
      return null;
    }
  }

  double? _parseDouble(dynamic v) {
    if (v == null) return null;
    if (v is num) return v.toDouble();
    return double.tryParse(v.toString());
  }
}

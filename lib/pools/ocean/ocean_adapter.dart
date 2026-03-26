import 'package:dio/dio.dart';
import 'package:logging/logging.dart';
import '../pool_adapter.dart';

final _log = Logger('OceanAdapter');

/// Ocean.xyz pool adapter.
///
/// Public API endpoint:
///   GET https://ocean.xyz/api/v1/statsnap/{btcAddress}
class OceanAdapter implements PoolAdapter {
  final Dio _dio = Dio(BaseOptions(
    connectTimeout: const Duration(seconds: 10),
    receiveTimeout: const Duration(seconds: 10),
  ));

  @override
  String get displayName => 'Ocean.xyz';

  @override
  PoolType get type => PoolType.ocean;

  @override
  bool validateIdentifier(String identifier) {
    final trimmed = identifier.trim();
    // Accept bc1, 1..., or 3... BTC addresses
    return trimmed.length >= 26 &&
        trimmed.length <= 62 &&
        RegExp(r'^(bc1|[13])[a-zA-HJ-NP-Z0-9]+$').hasMatch(trimmed);
  }

  @override
  Future<PoolEarnings?> fetchEarnings(String identifier) async {
    try {
      final address = identifier.trim();
      final response = await _dio.get(
        'https://ocean.xyz/api/v1/statsnap/$address',
      );

      if (response.statusCode != 200 || response.data == null) return null;

      final data = response.data as Map<String, dynamic>;

      final totalEarned = _parseDouble(data['total_earnings']) ??
          _parseDouble(data['total_earned']) ??
          0.0;
      final pending = _parseDouble(data['pending_balance']) ??
          _parseDouble(data['unpaid']);
      final hashrate = _parseDouble(data['hashrate_300s']) ??
          _parseDouble(data['hashrate']);
      final estDaily = _parseDouble(data['estimated_earn_next_day']) ??
          _parseDouble(data['estimated_daily']);

      double? lastPayoutAmt;
      DateTime? lastPayoutTime;
      if (data['last_payout'] is Map) {
        final lp = data['last_payout'] as Map<String, dynamic>;
        lastPayoutAmt = _parseDouble(lp['amount']);
        if (lp['timestamp'] != null) {
          lastPayoutTime = DateTime.tryParse(lp['timestamp'].toString());
        }
      }

      return PoolEarnings(
        pool: PoolType.ocean,
        identifier: address,
        timestamp: DateTime.now(),
        totalEarnedBtc: totalEarned,
        pendingBtc: pending,
        estimatedDailyBtc: estDaily,
        poolHashrate: hashrate,
        blocksFound: _parseInt(data['blocks_found']),
        lastPayout: lastPayoutTime,
        lastPayoutAmount: lastPayoutAmt,
      );
    } on DioException catch (e) {
      _log.warning('Ocean.xyz fetch failed: ${e.message}');
      return null;
    } catch (e) {
      _log.warning('Ocean.xyz parse error: $e');
      return null;
    }
  }

  double? _parseDouble(dynamic v) {
    if (v == null) return null;
    if (v is num) return v.toDouble();
    return double.tryParse(v.toString());
  }

  int? _parseInt(dynamic v) {
    if (v == null) return null;
    if (v is int) return v;
    return int.tryParse(v.toString());
  }
}

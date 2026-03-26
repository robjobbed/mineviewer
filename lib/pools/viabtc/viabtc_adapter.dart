import 'package:dio/dio.dart';
import 'package:logging/logging.dart';
import '../pool_adapter.dart';

final _log = Logger('ViaBtcAdapter');

/// ViaBTC adapter.
///
/// ViaBTC's public stats API is limited. This adapter attempts to fetch
/// basic account info. Full data requires an authenticated API key.
///
/// Attempted endpoint:
///   GET https://www.viabtc.com/res/openapi/v1/hashrate?coin=BTC&worker={address}
class ViaBtcAdapter implements PoolAdapter {
  final Dio _dio = Dio(BaseOptions(
    connectTimeout: const Duration(seconds: 10),
    receiveTimeout: const Duration(seconds: 10),
  ));

  @override
  String get displayName => 'ViaBTC';

  @override
  PoolType get type => PoolType.viabtc;

  @override
  bool validateIdentifier(String identifier) {
    final trimmed = identifier.trim();
    // ViaBTC uses account names or wallet addresses
    return trimmed.isNotEmpty && trimmed.length >= 3;
  }

  @override
  Future<PoolEarnings?> fetchEarnings(String identifier) async {
    try {
      final account = identifier.trim();

      // Attempt the public hashrate endpoint
      final response = await _dio.get(
        'https://www.viabtc.com/res/openapi/v1/hashrate',
        queryParameters: {
          'coin': 'BTC',
          'worker': account,
        },
      );

      if (response.statusCode != 200 || response.data == null) return null;

      final data = response.data;
      Map<String, dynamic>? body;

      if (data is Map<String, dynamic>) {
        // ViaBTC wraps responses in { "code": 0, "data": {...} }
        body = data['data'] as Map<String, dynamic>?;
        body ??= data;
      }

      if (body == null) return null;

      final hashrate = _parseDouble(body['hashrate']) ??
          _parseDouble(body['hashrate_1h']);

      return PoolEarnings(
        pool: PoolType.viabtc,
        identifier: account,
        timestamp: DateTime.now(),
        totalEarnedBtc: _parseDouble(body['total_paid']) ?? 0.0,
        pendingBtc: _parseDouble(body['balance']),
        estimatedDailyBtc: _parseDouble(body['estimated_daily']),
        poolHashrate: hashrate,
        blocksFound: null,
        lastPayout: null,
        lastPayoutAmount: null,
      );
    } on DioException catch (e) {
      _log.warning('ViaBTC fetch failed: ${e.message}');
      return null;
    } catch (e) {
      _log.warning('ViaBTC parse error: $e');
      return null;
    }
  }

  double? _parseDouble(dynamic v) {
    if (v == null) return null;
    if (v is num) return v.toDouble();
    return double.tryParse(v.toString());
  }
}

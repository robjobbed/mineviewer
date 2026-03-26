import 'package:dio/dio.dart';
import 'package:logging/logging.dart';
import '../pool_adapter.dart';

final _log = Logger('PublicPoolAdapter');

/// Public Pool adapter.
///
/// Public API endpoint:
///   GET https://public-pool.io:40557/api/client/{btcAddress}
class PublicPoolAdapter implements PoolAdapter {
  final Dio _dio = Dio(BaseOptions(
    connectTimeout: const Duration(seconds: 10),
    receiveTimeout: const Duration(seconds: 10),
  ));

  @override
  String get displayName => 'Public Pool';

  @override
  PoolType get type => PoolType.publicPool;

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
        'https://public-pool.io:40557/api/client/$address',
      );

      if (response.statusCode != 200 || response.data == null) return null;

      final data = response.data;

      // Public Pool may return a list of workers or a single object
      Map<String, dynamic> clientData;
      if (data is List && data.isNotEmpty) {
        clientData = data.first as Map<String, dynamic>;
      } else if (data is Map<String, dynamic>) {
        clientData = data;
      } else {
        return null;
      }

      final hashrate = _parseDouble(clientData['hashRate']) ??
          _parseDouble(clientData['hashrate']);
      final bestDiff = _parseDouble(clientData['bestDifficulty']) ??
          _parseDouble(clientData['bestEver']);

      return PoolEarnings(
        pool: PoolType.publicPool,
        identifier: address,
        timestamp: DateTime.now(),
        totalEarnedBtc: 0.0, // Solo pool -- no direct earnings tracking
        pendingBtc: null,
        estimatedDailyBtc: null,
        poolHashrate: hashrate,
        blocksFound: _parseInt(clientData['blocksFound']),
        lastPayout: null,
        lastPayoutAmount: bestDiff, // Best difficulty achieved
      );
    } on DioException catch (e) {
      _log.warning('Public Pool fetch failed: ${e.message}');
      return null;
    } catch (e) {
      _log.warning('Public Pool parse error: $e');
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

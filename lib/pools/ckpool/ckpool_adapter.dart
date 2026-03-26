import 'package:dio/dio.dart';
import 'package:logging/logging.dart';
import '../pool_adapter.dart';

final _log = Logger('CkPoolAdapter');

/// CKPool / Solo CKPool adapter.
///
/// Public API endpoint:
///   GET https://solo.ckpool.org/users/{btcAddress}
class CkPoolAdapter implements PoolAdapter {
  final Dio _dio = Dio(BaseOptions(
    connectTimeout: const Duration(seconds: 10),
    receiveTimeout: const Duration(seconds: 10),
  ));

  @override
  String get displayName => 'CKPool / Solo CKPool';

  @override
  PoolType get type => PoolType.ckpool;

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
        'https://solo.ckpool.org/users/$address',
      );

      if (response.statusCode != 200 || response.data == null) return null;

      final data = response.data as Map<String, dynamic>;

      // Solo CKPool returns hashrate in various forms
      final hashrate1m = _parseDouble(data['hashrate1m']);
      final hashrate5m = _parseDouble(data['hashrate5m']);
      final hashrate1hr = _parseDouble(data['hashrate1hr']);
      final hashrate = hashrate5m ?? hashrate1m ?? hashrate1hr;

      // Shares and best difficulty help estimate solo mining progress
      final bestDiff = _parseDouble(data['bestever']);

      return PoolEarnings(
        pool: PoolType.ckpool,
        identifier: address,
        timestamp: DateTime.now(),
        totalEarnedBtc: 0.0, // Solo mining: no pool-side earnings tracking
        pendingBtc: null,
        estimatedDailyBtc: null,
        poolHashrate: _hashrateStringToHs(hashrate),
        blocksFound: _parseInt(data['blocks_found']),
        lastPayout: null,
        lastPayoutAmount: bestDiff, // Repurpose: store best difficulty
      );
    } on DioException catch (e) {
      _log.warning('CKPool fetch failed: ${e.message}');
      return null;
    } catch (e) {
      _log.warning('CKPool parse error: $e');
      return null;
    }
  }

  /// CKPool may return hashrate as a string like "1.234T" or a raw number.
  double? _hashrateStringToHs(dynamic value) {
    if (value == null) return null;
    if (value is num) return value.toDouble();
    final str = value.toString().trim().toUpperCase();
    if (str.isEmpty) return null;

    final suffixes = {
      'P': 1e15,
      'T': 1e12,
      'G': 1e9,
      'M': 1e6,
      'K': 1e3,
    };

    for (final entry in suffixes.entries) {
      if (str.endsWith(entry.key)) {
        final num = double.tryParse(str.substring(0, str.length - 1));
        if (num != null) return num * entry.value;
      }
    }
    return double.tryParse(str);
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

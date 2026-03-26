import 'package:dio/dio.dart';
import 'package:logging/logging.dart';

final _log = Logger('BtcPriceService');

/// Fetches and caches the current BTC/USD price from CoinGecko.
class BtcPriceService {
  static final BtcPriceService _instance = BtcPriceService._();
  factory BtcPriceService() => _instance;
  BtcPriceService._();

  final Dio _dio = Dio(BaseOptions(
    connectTimeout: const Duration(seconds: 10),
    receiveTimeout: const Duration(seconds: 10),
  ));

  double? _cachedPrice;
  DateTime? _lastFetch;
  static const _cacheDuration = Duration(minutes: 5);

  /// Returns the cached price if still fresh, otherwise fetches a new one.
  double? get cachedPrice => _cachedPrice;
  DateTime? get lastUpdated => _lastFetch;

  bool get _cacheValid =>
      _cachedPrice != null &&
      _lastFetch != null &&
      DateTime.now().difference(_lastFetch!) < _cacheDuration;

  /// Fetch BTC price in USD. Returns cached value if under 5 minutes old.
  Future<double?> fetchPrice({bool forceRefresh = false}) async {
    if (!forceRefresh && _cacheValid) return _cachedPrice;

    try {
      final response = await _dio.get(
        'https://api.coingecko.com/api/v3/simple/price',
        queryParameters: {
          'ids': 'bitcoin',
          'vs_currencies': 'usd',
        },
      );

      if (response.statusCode == 200 && response.data != null) {
        final data = response.data as Map<String, dynamic>;
        final btc = data['bitcoin'] as Map<String, dynamic>?;
        final price = btc?['usd'];
        if (price != null) {
          _cachedPrice = (price is num) ? price.toDouble() : double.tryParse(price.toString());
          _lastFetch = DateTime.now();
          _log.fine('BTC price updated: \$$_cachedPrice');
          return _cachedPrice;
        }
      }
    } on DioException catch (e) {
      _log.warning('BTC price fetch failed: ${e.message}');
    } catch (e) {
      _log.warning('BTC price parse error: $e');
    }

    // Return stale cache if available
    return _cachedPrice;
  }
}

import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/models/coin_market_data.dart';
import '../../services/market/market_data_service.dart';

final marketDataServiceProvider = Provider<MarketDataService>((ref) {
  return MarketDataService();
});

final marketDataProvider =
    NotifierProvider<MarketDataNotifier, AsyncValue<List<CoinMarketData>>>(
  MarketDataNotifier.new,
);

class MarketDataNotifier extends Notifier<AsyncValue<List<CoinMarketData>>> {
  Timer? _refreshTimer;

  @override
  AsyncValue<List<CoinMarketData>> build() {
    // Start fetching on init
    _fetch();
    // Auto-refresh every 5 minutes
    _refreshTimer?.cancel();
    _refreshTimer =
        Timer.periodic(const Duration(minutes: 5), (_) => _fetch());

    ref.onDispose(() {
      _refreshTimer?.cancel();
    });

    return const AsyncValue.loading();
  }

  Future<void> _fetch() async {
    final service = ref.read(marketDataServiceProvider);
    try {
      final data = await service.fetchMarketData();
      if (data.isNotEmpty) {
        state = AsyncValue.data(data);
      } else if (state is! AsyncData) {
        state = const AsyncValue.data([]);
      }
    } catch (e, st) {
      if (state is! AsyncData) {
        state = AsyncValue.error(e, st);
      }
    }
  }

  Future<void> refresh() async => _fetch();
}

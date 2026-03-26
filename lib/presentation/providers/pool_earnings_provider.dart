import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../pools/pool_adapter.dart';
import '../../pools/pool_registry.dart';
import '../../services/profitability/btc_price_service.dart';

// ---------------------------------------------------------------------------
// Pool config: which pool + identifier per miner
// ---------------------------------------------------------------------------

class PoolConfig {
  final String minerId;
  final PoolType poolType;
  final String identifier;

  const PoolConfig({
    required this.minerId,
    required this.poolType,
    required this.identifier,
  });
}

/// Stores pool configs keyed by minerId.
class PoolConfigsNotifier extends Notifier<Map<String, PoolConfig>> {
  @override
  Map<String, PoolConfig> build() => {};

  void setConfig(PoolConfig config) {
    state = {...state, config.minerId: config};
  }

  void removeConfig(String minerId) {
    state = Map.from(state)..remove(minerId);
  }
}

final poolConfigsProvider =
    NotifierProvider<PoolConfigsNotifier, Map<String, PoolConfig>>(
  PoolConfigsNotifier.new,
);

// ---------------------------------------------------------------------------
// Earnings cache: fetched pool earnings keyed by minerId
// ---------------------------------------------------------------------------

class EarningsCacheNotifier extends Notifier<Map<String, PoolEarnings>> {
  @override
  Map<String, PoolEarnings> build() => {};

  void update(String minerId, PoolEarnings earnings) {
    state = {...state, minerId: earnings};
  }

  void clear(String minerId) {
    state = Map.from(state)..remove(minerId);
  }
}

final earningsCacheProvider =
    NotifierProvider<EarningsCacheNotifier, Map<String, PoolEarnings>>(
  EarningsCacheNotifier.new,
);

// ---------------------------------------------------------------------------
// Standalone earnings fetch (not tied to a miner)
// ---------------------------------------------------------------------------

/// A single-shot provider for fetching earnings from any pool + identifier.
/// Used by the pool earnings screen for ad-hoc lookups.
final fetchEarningsProvider =
    FutureProvider.family<PoolEarnings?, ({PoolType pool, String identifier})>(
  (ref, params) async {
    final adapter = PoolRegistry.getAdapter(params.pool);
    return adapter.fetchEarnings(params.identifier);
  },
);

// ---------------------------------------------------------------------------
// BTC price provider (auto-refreshing)
// ---------------------------------------------------------------------------

final btcPriceServiceProvider = Provider<BtcPriceService>((ref) {
  return BtcPriceService();
});

/// Auto-refreshing BTC price. Re-fetches every 5 minutes.
final btcPriceProvider = StreamProvider<double?>((ref) async* {
  final service = ref.read(btcPriceServiceProvider);
  // Immediately fetch
  yield await service.fetchPrice();

  // Then refresh every 5 minutes
  await for (final _ in Stream.periodic(const Duration(minutes: 5))) {
    yield await service.fetchPrice(forceRefresh: true);
  }
});

/// Convenience: last known BTC price (non-null fallback to 0).
final btcPriceValueProvider = Provider<double>((ref) {
  final asyncPrice = ref.watch(btcPriceProvider);
  return asyncPrice.when(
    data: (price) => price ?? 0.0,
    loading: () => 0.0,
    error: (_, _) => 0.0,
  );
});

/// Last time BTC price was updated.
final btcPriceLastUpdatedProvider = Provider<DateTime?>((ref) {
  final service = ref.read(btcPriceServiceProvider);
  // Re-read whenever btcPriceProvider changes
  ref.watch(btcPriceProvider);
  return service.lastUpdated;
});

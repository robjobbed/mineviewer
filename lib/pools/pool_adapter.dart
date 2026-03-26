/// Pool earnings adapter interface.
///
/// Each pool implementation fetches earnings, hashrate, and payout data
/// from a mining pool's public API using a wallet address or API key.
library;

enum PoolType {
  ocean,
  ckpool,
  publicPool,
  braiinsPool,
  f2pool,
  viabtc,
  foundry;

  String get displayName => switch (this) {
        PoolType.ocean => 'Ocean.xyz',
        PoolType.ckpool => 'CKPool / Solo CKPool',
        PoolType.publicPool => 'Public Pool',
        PoolType.braiinsPool => 'Braiins Pool',
        PoolType.f2pool => 'F2Pool',
        PoolType.viabtc => 'ViaBTC',
        PoolType.foundry => 'Foundry USA',
      };

  /// What kind of identifier this pool requires.
  String get identifierHint => switch (this) {
        PoolType.ocean => 'BTC wallet address',
        PoolType.ckpool => 'BTC wallet address',
        PoolType.publicPool => 'BTC wallet address',
        PoolType.braiinsPool => 'API key (from pool settings)',
        PoolType.f2pool => 'BTC wallet address',
        PoolType.viabtc => 'BTC wallet address',
        PoolType.foundry => 'Subaccount name',
      };
}

class PoolEarnings {
  final PoolType pool;
  final String identifier;
  final DateTime timestamp;
  final double totalEarnedBtc;
  final double? pendingBtc;
  final double? estimatedDailyBtc;
  final double? poolHashrate; // H/s reported by pool
  final int? blocksFound;
  final DateTime? lastPayout;
  final double? lastPayoutAmount;

  const PoolEarnings({
    required this.pool,
    required this.identifier,
    required this.timestamp,
    required this.totalEarnedBtc,
    this.pendingBtc,
    this.estimatedDailyBtc,
    this.poolHashrate,
    this.blocksFound,
    this.lastPayout,
    this.lastPayoutAmount,
  });

  /// Total earned formatted in sats.
  String get totalEarnedSats =>
      '${(totalEarnedBtc * 1e8).toStringAsFixed(0)} sats';

  /// Pending formatted in sats (or '--').
  String get pendingSats => pendingBtc != null
      ? '${(pendingBtc! * 1e8).toStringAsFixed(0)} sats'
      : '--';
}

abstract class PoolAdapter {
  String get displayName;
  PoolType get type;

  /// Fetch the latest earnings snapshot for [identifier].
  /// Returns null on error or if the pool is unreachable.
  Future<PoolEarnings?> fetchEarnings(String identifier);

  /// Validate that [identifier] looks correct for this pool.
  bool validateIdentifier(String identifier);
}

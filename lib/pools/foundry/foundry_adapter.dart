import 'package:logging/logging.dart';
import '../pool_adapter.dart';

final _log = Logger('FoundryAdapter');

/// Foundry USA Pool adapter.
///
/// Foundry does not provide a public API for miner stats or earnings.
/// This adapter is a placeholder that returns null, indicating the pool
/// cannot be queried automatically.
///
/// Users are directed to check the Foundry dashboard manually.
class FoundryAdapter implements PoolAdapter {
  @override
  String get displayName => 'Foundry USA';

  @override
  PoolType get type => PoolType.foundry;

  @override
  bool validateIdentifier(String identifier) {
    // Foundry uses subaccount names
    return identifier.trim().isNotEmpty;
  }

  @override
  Future<PoolEarnings?> fetchEarnings(String identifier) async {
    _log.info(
      'Foundry USA does not expose a public API. '
      'Check your Foundry dashboard for earnings data.',
    );
    // Return null -- UI will display a "no public API" notice
    return null;
  }
}

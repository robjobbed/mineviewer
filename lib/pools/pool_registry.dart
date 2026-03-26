import 'pool_adapter.dart';
import 'ocean/ocean_adapter.dart';
import 'ckpool/ckpool_adapter.dart';
import 'public_pool/public_pool_adapter.dart';
import 'braiins_pool/braiins_pool_adapter.dart';
import 'f2pool/f2pool_adapter.dart';
import 'viabtc/viabtc_adapter.dart';
import 'foundry/foundry_adapter.dart';

class PoolRegistry {
  static final Map<PoolType, PoolAdapter> _adapters = {
    PoolType.ocean: OceanAdapter(),
    PoolType.ckpool: CkPoolAdapter(),
    PoolType.publicPool: PublicPoolAdapter(),
    PoolType.braiinsPool: BraiinsPoolAdapter(),
    PoolType.f2pool: F2PoolAdapter(),
    PoolType.viabtc: ViaBtcAdapter(),
    PoolType.foundry: FoundryAdapter(),
  };

  static PoolAdapter getAdapter(PoolType type) {
    final adapter = _adapters[type];
    if (adapter == null) {
      throw UnsupportedError('No pool adapter registered for $type');
    }
    return adapter;
  }

  static List<PoolAdapter> get all => _adapters.values.toList();
  static List<PoolType> get supportedTypes => _adapters.keys.toList();
}

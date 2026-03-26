import '../data/models/miner_snapshot.dart';
import '../data/models/miner_info.dart';
import '../data/models/miner_config.dart';
import '../data/models/pool_info.dart';
import '../data/models/miner_type.dart';
import 'driver_result.dart';

enum OverclockCapability {
  frequency,
  voltage,
  hashrateTarget,
  powerTarget,
  fanSpeed,
  workMode,
}

abstract class MinerDriver {
  String get displayName;
  MinerType get type;
  int get defaultPort;
  Set<OverclockCapability> get overclockCapabilities;

  Future<bool> canHandle(String ip, {int? port});
  Future<DriverResult<MinerSnapshot>> fetchStats(String ip, {int? port});
  Future<DriverResult<MinerInfo>> fetchInfo(String ip, {int? port});
  Future<DriverResult<List<PoolInfo>>> fetchPools(String ip, {int? port});
  Future<DriverResult<MinerConfig>> applyConfig(String ip, MinerConfig config, {int? port});
  Future<DriverResult<void>> restart(String ip, {int? port});
  Future<DriverResult<bool>> identify(String ip, {int? port});
}

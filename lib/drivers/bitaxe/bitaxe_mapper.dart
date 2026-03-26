import '../../data/models/miner_snapshot.dart';
import '../../data/models/miner_info.dart';
import '../../data/models/miner_config.dart';
import '../../data/models/pool_info.dart';
import '../../data/models/miner_type.dart';
import 'bitaxe_models.dart';

class BitAxeMapper {
  BitAxeMapper._();

  static MinerSnapshot toSnapshot(String minerId, BitAxeSystemInfo info) {
    return MinerSnapshot(
      minerId: minerId,
      timestamp: DateTime.now(),
      // BitAxe reports in GH/s, convert to H/s for standardization
      hashrate: (info.hashRate ?? 0) * 1e9,
      hashrate1m: info.hashRate1m != null ? info.hashRate1m! * 1e9 : null,
      hashrate10m: info.hashRate10m != null ? info.hashRate10m! * 1e9 : null,
      hashrate1h: info.hashRate1h != null ? info.hashRate1h! * 1e9 : null,
      asicTemp: info.temp,
      vrTemp: info.vrTemp,
      power: info.power,
      fanRpm: info.fanrpm,
      fanSpeedPct: info.fanspeed,
      efficiency: info.efficiency,
      acceptedShares: info.sharesAccepted,
      rejectedShares: info.sharesRejected,
      difficulty: info.bestDiff,
      poolUrl: info.stratumURL,
      uptimeSeconds: info.uptimeSeconds,
      rssi: info.wifiRSSI,
    );
  }

  static MinerInfo toMinerInfo(BitAxeSystemInfo info) {
    return MinerInfo(
      type: MinerType.bitaxe,
      model: info.asicModel ?? 'Unknown BitAxe',
      firmwareVersion: info.version,
      macAddress: info.macAddr,
      hostname: info.hostname,
      ssid: info.ssid,
      rssi: info.wifiRSSI,
    );
  }

  static List<PoolInfo> toPools(BitAxeSystemInfo info) {
    final pools = <PoolInfo>[];
    if (info.stratumURL != null) {
      pools.add(PoolInfo(
        url: info.stratumURL!,
        port: info.stratumPort ?? 3333,
        user: info.stratumUser ?? '',
      ));
    }
    if (info.fallbackStratumURL != null) {
      pools.add(PoolInfo(
        url: info.fallbackStratumURL!,
        port: info.fallbackStratumPort ?? 3333,
        user: info.fallbackStratumUser ?? '',
        isFallback: true,
      ));
    }
    return pools;
  }

  static Map<String, dynamic> toApiPayload(MinerConfig config) {
    final payload = <String, dynamic>{};
    if (config.frequency != null) payload['frequency'] = config.frequency;
    if (config.coreVoltage != null) payload['coreVoltage'] = config.coreVoltage;
    if (config.fanSpeedPct != null) payload['fanspeed'] = config.fanSpeedPct;
    if (config.autoFan != null) payload['autofanspeed'] = config.autoFan;
    if (config.tempTarget != null) payload['temptarget'] = config.tempTarget;
    if (config.stratumUrl != null) payload['stratumURL'] = config.stratumUrl;
    if (config.stratumPort != null) payload['stratumPort'] = config.stratumPort;
    if (config.stratumUser != null) payload['stratumUser'] = config.stratumUser;
    if (config.stratumPassword != null) payload['stratumPassword'] = config.stratumPassword;
    if (config.fallbackStratumUrl != null) payload['fallbackStratumURL'] = config.fallbackStratumUrl;
    if (config.fallbackStratumPort != null) payload['fallbackStratumPort'] = config.fallbackStratumPort;
    if (config.fallbackStratumUser != null) payload['fallbackStratumUser'] = config.fallbackStratumUser;
    if (config.fallbackStratumPassword != null) payload['fallbackStratumPassword'] = config.fallbackStratumPassword;
    return payload;
  }
}

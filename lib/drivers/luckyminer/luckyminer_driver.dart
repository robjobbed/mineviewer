import 'dart:async';

import '../../data/models/miner_snapshot.dart';
import '../../data/models/miner_info.dart';
import '../../data/models/miner_config.dart';
import '../../data/models/pool_info.dart';
import '../../data/models/miner_type.dart';
import '../../core/result.dart';
import '../miner_driver.dart';
import '../driver_result.dart';
import '../bitaxe/bitaxe_api_client.dart';

/// Driver for LuckyMiner devices.
///
/// LuckyMiner hardware runs AxeOS firmware (the same as BitAxe), so this
/// driver delegates to the BitAxe HTTP API client. The only difference is
/// the model-string detection in [canHandle] and the reported [MinerType].
class LuckyMinerDriver implements MinerDriver {
  final BitAxeApiClient _client;

  LuckyMinerDriver({BitAxeApiClient? client})
      : _client = client ?? BitAxeApiClient();

  @override
  String get displayName => 'LuckyMiner';

  @override
  MinerType get type => MinerType.luckyminer;

  @override
  int get defaultPort => 80;

  @override
  Set<OverclockCapability> get overclockCapabilities => {
        OverclockCapability.frequency,
        OverclockCapability.voltage,
        OverclockCapability.fanSpeed,
      };

  @override
  Future<bool> canHandle(String ip, {int? port}) async {
    try {
      final data = await _client.getSystemInfo(ip, port: port ?? defaultPort);
      final model = (data['ASICModel'] ?? data['model'] ?? '').toString().toLowerCase();
      final hostname = (data['hostname'] ?? '').toString().toLowerCase();
      final board = (data['boardVersion'] ?? data['board'] ?? '').toString().toLowerCase();

      return model.contains('lucky') ||
          hostname.contains('lucky') ||
          board.contains('lucky') ||
          model.contains('lm');
    } catch (_) {
      return false;
    }
  }

  @override
  Future<DriverResult<MinerSnapshot>> fetchStats(String ip, {int? port}) async {
    try {
      final data = await _client.getSystemInfo(ip, port: port ?? defaultPort);
      return Success(_mapSnapshot(ip, data));
    } on TimeoutException {
      return const DriverFailure('Connection timed out', type: DriverErrorType.timeout);
    } catch (e) {
      return DriverFailure('Failed to fetch stats: $e', error: e);
    }
  }

  @override
  Future<DriverResult<MinerInfo>> fetchInfo(String ip, {int? port}) async {
    try {
      final data = await _client.getSystemInfo(ip, port: port ?? defaultPort);
      return Success(_mapInfo(data));
    } on TimeoutException {
      return const DriverFailure('Connection timed out', type: DriverErrorType.timeout);
    } catch (e) {
      return DriverFailure('Failed to fetch info: $e', error: e);
    }
  }

  @override
  Future<DriverResult<List<PoolInfo>>> fetchPools(String ip, {int? port}) async {
    try {
      final data = await _client.getSystemInfo(ip, port: port ?? defaultPort);
      return Success(_mapPools(data));
    } catch (e) {
      return DriverFailure('Failed to fetch pools: $e', error: e);
    }
  }

  @override
  Future<DriverResult<MinerConfig>> applyConfig(
    String ip,
    MinerConfig config, {
    int? port,
  }) async {
    try {
      final payload = _toApiPayload(config);
      if (payload.isEmpty) {
        return const DriverFailure('No configuration changes to apply');
      }
      await _client.patchSystem(ip, payload, port: port ?? defaultPort);
      return Success(config);
    } catch (e) {
      return DriverFailure('Failed to apply config: $e', error: e);
    }
  }

  @override
  Future<DriverResult<void>> restart(String ip, {int? port}) async {
    try {
      await _client.restart(ip, port: port ?? defaultPort);
      return const Success(null);
    } catch (e) {
      return DriverFailure('Failed to restart: $e', error: e);
    }
  }

  @override
  Future<DriverResult<bool>> identify(String ip, {int? port}) async {
    try {
      await _client.identify(ip, port: port ?? defaultPort);
      return const Success(true);
    } catch (e) {
      return DriverFailure('Failed to identify: $e', error: e);
    }
  }

  // ---------------------------------------------------------------------------
  // AxeOS response mapping (mirrors BitAxe mapper logic)
  // ---------------------------------------------------------------------------

  MinerSnapshot _mapSnapshot(String ip, Map<String, dynamic> data) {
    final hashrate = _toDouble(data['hashRate'] ?? data['hashrate'] ?? 0) * 1e9;

    return MinerSnapshot(
      minerId: ip,
      timestamp: DateTime.now(),
      hashrate: hashrate,
      asicTemp: _toDoubleOrNull(data['temp']),
      vrTemp: _toDoubleOrNull(data['vrTemp']),
      power: _toDoubleOrNull(data['power']),
      fanRpm: _toIntOrNull(data['fanrpm'] ?? data['fanRpm']),
      fanSpeedPct: _toIntOrNull(data['fanspeed'] ?? data['fanSpeed']),
      efficiency: _toDoubleOrNull(data['efficiency']),
      acceptedShares: _toIntOrNull(data['sharesAccepted']),
      rejectedShares: _toIntOrNull(data['sharesRejected']),
      difficulty: _toDoubleOrNull(data['difficulty']),
      poolUrl: data['stratumURL']?.toString(),
      uptimeSeconds: _toIntOrNull(data['uptimeSeconds']),
      rssi: _toIntOrNull(data['wifiRSSI'] ?? data['rssi']),
    );
  }

  MinerInfo _mapInfo(Map<String, dynamic> data) {
    final model = data['ASICModel'] ?? data['model'] ?? 'LuckyMiner';
    final fw = data['version'] ?? data['firmwareVersion'] ?? '';
    final hostname = data['hostname']?.toString();
    final ssid = data['ssid']?.toString();
    final mac = data['macAddr']?.toString();

    return MinerInfo(
      type: MinerType.luckyminer,
      model: model.toString(),
      firmwareVersion: fw.toString(),
      hostname: hostname,
      ssid: ssid,
      macAddress: mac,
    );
  }

  List<PoolInfo> _mapPools(Map<String, dynamic> data) {
    final pools = <PoolInfo>[];

    final url = data['stratumURL']?.toString();
    final port = _toInt(data['stratumPort'] ?? 0);
    final user = data['stratumUser']?.toString();

    if (url != null && url.isNotEmpty && user != null) {
      pools.add(PoolInfo(
        url: url,
        port: port > 0 ? port : 3333,
        user: user,
        password: (data['stratumPassword'] ?? '').toString(),
      ));
    }

    // Fallback pool
    final fbUrl = data['fallbackStratumURL']?.toString();
    final fbPort = _toInt(data['fallbackStratumPort'] ?? 0);
    final fbUser = data['fallbackStratumUser']?.toString();

    if (fbUrl != null && fbUrl.isNotEmpty && fbUser != null) {
      pools.add(PoolInfo(
        url: fbUrl,
        port: fbPort > 0 ? fbPort : 3333,
        user: fbUser,
        password: (data['fallbackStratumPassword'] ?? '').toString(),
        isFallback: true,
      ));
    }

    return pools;
  }

  Map<String, dynamic> _toApiPayload(MinerConfig config) {
    final payload = <String, dynamic>{};
    if (config.frequency != null) payload['frequency'] = config.frequency;
    if (config.coreVoltage != null) payload['coreVoltage'] = config.coreVoltage;
    if (config.fanSpeedPct != null) payload['fanspeed'] = config.fanSpeedPct;
    if (config.autoFan != null) payload['autofanspeed'] = config.autoFan! ? 1 : 0;
    if (config.tempTarget != null) payload['overheat_temp'] = config.tempTarget;
    if (config.stratumUrl != null) payload['stratumURL'] = config.stratumUrl;
    if (config.stratumPort != null) payload['stratumPort'] = config.stratumPort;
    if (config.stratumUser != null) payload['stratumUser'] = config.stratumUser;
    if (config.stratumPassword != null) payload['stratumPassword'] = config.stratumPassword;
    if (config.fallbackStratumUrl != null) payload['fallbackStratumURL'] = config.fallbackStratumUrl;
    if (config.fallbackStratumPort != null) payload['fallbackStratumPort'] = config.fallbackStratumPort;
    if (config.fallbackStratumUser != null) payload['fallbackStratumUser'] = config.fallbackStratumUser;
    if (config.fallbackStratumPassword != null) {
      payload['fallbackStratumPassword'] = config.fallbackStratumPassword;
    }
    return payload;
  }

  // ---------------------------------------------------------------------------
  // Type coercion helpers
  // ---------------------------------------------------------------------------

  double _toDouble(dynamic v) {
    if (v is double) return v;
    if (v is int) return v.toDouble();
    if (v is String) return double.tryParse(v) ?? 0;
    return 0;
  }

  double? _toDoubleOrNull(dynamic v) {
    if (v == null) return null;
    final d = _toDouble(v);
    return d != 0 ? d : null;
  }

  int _toInt(dynamic v) {
    if (v is int) return v;
    if (v is double) return v.toInt();
    if (v is String) return int.tryParse(v) ?? 0;
    return 0;
  }

  int? _toIntOrNull(dynamic v) {
    if (v == null) return null;
    final i = _toInt(v);
    return i != 0 ? i : null;
  }
}

import 'dart:async';
import '../../data/models/miner_snapshot.dart';
import '../../data/models/miner_info.dart';
import '../../data/models/miner_config.dart';
import '../../data/models/pool_info.dart';
import '../../data/models/miner_type.dart';
import '../../core/result.dart';
import '../miner_driver.dart';
import '../driver_result.dart';
import 'bitaxe_api_client.dart';
import 'bitaxe_models.dart';
import 'bitaxe_mapper.dart';

class BitAxeDriver implements MinerDriver {
  final BitAxeApiClient _client;

  BitAxeDriver({BitAxeApiClient? client})
      : _client = client ?? BitAxeApiClient();

  @override
  String get displayName => 'BitAxe / NerdQAxe';

  @override
  MinerType get type => MinerType.bitaxe;

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
      return data.containsKey('ASICModel');
    } catch (_) {
      return false;
    }
  }

  @override
  Future<DriverResult<MinerSnapshot>> fetchStats(String ip, {int? port}) async {
    try {
      final data = await _client.getSystemInfo(ip, port: port ?? defaultPort);
      final info = BitAxeSystemInfo.fromJson(data);
      return Success(BitAxeMapper.toSnapshot(ip, info));
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
      final info = BitAxeSystemInfo.fromJson(data);
      return Success(BitAxeMapper.toMinerInfo(info));
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
      final info = BitAxeSystemInfo.fromJson(data);
      return Success(BitAxeMapper.toPools(info));
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
      final payload = BitAxeMapper.toApiPayload(config);
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
}

import 'dart:async';
import 'dart:io';

import '../../data/models/miner_snapshot.dart';
import '../../data/models/miner_info.dart';
import '../../data/models/miner_config.dart';
import '../../data/models/pool_info.dart';
import '../../data/models/miner_type.dart';
import '../../core/result.dart';
import '../miner_driver.dart';
import '../driver_result.dart';
import '../antminer/cgminer_rpc_client.dart';

/// Driver for Canaan Avalon miners.
///
/// Avalon miners expose a CGMiner-compatible API on TCP port 4028 with
/// Avalon-specific extensions in the STATS response (GHSmm, GHSavg,
/// TMax, TAvg, Vo, FanR, etc.).
class CanaanDriver implements MinerDriver {
  final CgMinerRpcClient _rpc;

  CanaanDriver({CgMinerRpcClient? rpc})
      : _rpc = rpc ?? CgMinerRpcClient();

  @override
  String get displayName => 'Canaan Avalon';

  @override
  MinerType get type => MinerType.canaan;

  @override
  int get defaultPort => 4028;

  @override
  Set<OverclockCapability> get overclockCapabilities => {
        OverclockCapability.fanSpeed,
        OverclockCapability.workMode,
      };

  @override
  Future<bool> canHandle(String ip, {int? port}) async {
    try {
      final resp = await _rpc.sendCommand(ip, 'version', port: port ?? defaultPort);
      final raw = _flatten(resp).toLowerCase();
      return raw.contains('avalon') || raw.contains('canaan');
    } catch (_) {
      return false;
    }
  }

  @override
  Future<DriverResult<MinerSnapshot>> fetchStats(String ip, {int? port}) async {
    try {
      final p = port ?? defaultPort;
      final summaryResp = await _rpc.sendCommand(ip, 'summary', port: p);
      final statsResp = await _rpc.sendCommand(ip, 'stats', port: p);

      final summary = _firstEntry(summaryResp, 'SUMMARY');
      final stats = _firstEntry(statsResp, 'STATS');

      // Avalon reports GHSmm (theoretical max) and GHSavg (actual average)
      // Prefer GHSavg for real hashrate, fall back to GHS av from summary
      double hashrate = 0;
      if (stats.containsKey('GHSavg')) {
        hashrate = _toDouble(stats['GHSavg']) * 1e9;
      } else if (summary.containsKey('GHS av')) {
        hashrate = _toDouble(summary['GHS av']) * 1e9;
      } else if (summary.containsKey('MHS av')) {
        hashrate = _toDouble(summary['MHS av']) * 1e6;
      }

      // Avalon temperatures:
      // - Temp: ambient/inlet temperature
      // - TMax: maximum chip temperature
      // - TAvg: average chip temperature
      final tMax = _toDouble(stats['TMax'] ?? 0);
      final tAvg = _toDouble(stats['TAvg'] ?? 0);
      final ambientTemp = _toDouble(stats['Temp'] ?? 0);

      // Also check temp1-temp4 style fields
      final temps = <double>[];
      if (tMax > 0) temps.add(tMax);
      if (tAvg > 0) temps.add(tAvg);
      for (var i = 1; i <= 4; i++) {
        final t = _toDouble(stats['temp$i'] ?? 0);
        if (t > 0) temps.add(t);
      }
      final asicTemp = temps.isNotEmpty ? temps.reduce((a, b) => a > b ? a : b) : null;

      // Fan speeds: Fan1, Fan2 are RPM; FanR is percentage
      final fan1 = _toInt(stats['Fan1'] ?? 0);
      final fan2 = _toInt(stats['Fan2'] ?? 0);
      final fanRpm = (fan1 > 0 || fan2 > 0)
          ? (fan1 > fan2 ? fan1 : fan2)
          : null;
      final fanPct = _toInt(stats['FanR'] ?? 0);

      // Voltage (Vo) in millivolts typically
      // Power may not be directly reported; calculate from voltage if available
      final power = _toDouble(stats['Power'] ?? stats['PS Power'] ?? 0);

      final accepted = _toInt(summary['Accepted'] ?? 0);
      final rejected = _toInt(summary['Rejected'] ?? 0);
      final elapsed = _toInt(summary['Elapsed'] ?? 0);

      return Success(MinerSnapshot(
        minerId: ip,
        timestamp: DateTime.now(),
        hashrate: hashrate,
        asicTemp: asicTemp,
        ambientTemp: ambientTemp > 0 ? ambientTemp : null,
        fanRpm: fanRpm,
        fanSpeedPct: fanPct > 0 ? fanPct : null,
        power: power > 0 ? power : null,
        acceptedShares: accepted > 0 ? accepted : null,
        rejectedShares: rejected > 0 ? rejected : null,
        uptimeSeconds: elapsed > 0 ? elapsed : null,
      ));
    } on TimeoutException {
      return const DriverFailure(
        'Connection timed out',
        type: DriverErrorType.timeout,
      );
    } on SocketException {
      return const DriverFailure(
        'Connection refused',
        type: DriverErrorType.connectionRefused,
      );
    } catch (e) {
      return DriverFailure('Failed to fetch stats: $e', error: e);
    }
  }

  @override
  Future<DriverResult<MinerInfo>> fetchInfo(String ip, {int? port}) async {
    try {
      final resp = await _rpc.sendCommand(ip, 'version', port: port ?? defaultPort);
      final version = _firstEntry(resp, 'VERSION');

      final cgminer = version['CGMiner'] ?? 'unknown';
      final model = version['Type'] ??
          version['Model'] ??
          version['PROD'] ??
          'Canaan Avalon';
      final api = version['API'] ?? '';

      return Success(MinerInfo(
        type: MinerType.canaan,
        model: model.toString(),
        firmwareVersion: 'CGMiner $cgminer (API $api)',
      ));
    } on TimeoutException {
      return const DriverFailure(
        'Connection timed out',
        type: DriverErrorType.timeout,
      );
    } catch (e) {
      return DriverFailure('Failed to fetch info: $e', error: e);
    }
  }

  @override
  Future<DriverResult<List<PoolInfo>>> fetchPools(String ip, {int? port}) async {
    try {
      final resp = await _rpc.sendCommand(ip, 'pools', port: port ?? defaultPort);
      final pools = _listEntries(resp, 'POOLS');

      return Success(pools.map((p) {
        final url = (p['URL'] ?? '').toString();
        return PoolInfo(
          url: url,
          port: _extractPort(url),
          user: (p['User'] ?? '').toString(),
          password: (p['Pass'] ?? '').toString(),
        );
      }).toList());
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
      final p = port ?? defaultPort;

      // Fan speed control via ascset command
      if (config.fanSpeedPct != null) {
        await _rpc.sendCommandWithParam(
          ip,
          'ascset',
          '0,fan,${config.fanSpeedPct}',
          port: p,
        );
      }

      // Pool changes
      if (config.stratumUrl != null && config.stratumUser != null) {
        final poolUrl = config.stratumPort != null
            ? '${config.stratumUrl}:${config.stratumPort}'
            : config.stratumUrl!;

        await _rpc.sendCommandWithParam(
          ip,
          'addpool',
          '$poolUrl,${config.stratumUser},${config.stratumPassword ?? ''}',
          port: p,
        );
      }

      return Success(config);
    } catch (e) {
      return DriverFailure('Failed to apply config: $e', error: e);
    }
  }

  @override
  Future<DriverResult<void>> restart(String ip, {int? port}) async {
    try {
      await _rpc.sendCommand(ip, 'restart', port: port ?? defaultPort);
      return const Success(null);
    } catch (e) {
      return DriverFailure('Failed to restart: $e', error: e);
    }
  }

  @override
  Future<DriverResult<bool>> identify(String ip, {int? port}) async {
    return const DriverFailure(
      'Identify not supported on Canaan Avalon',
      type: DriverErrorType.unsupported,
    );
  }

  // ---------------------------------------------------------------------------
  // Helpers
  // ---------------------------------------------------------------------------

  String _flatten(Map<String, dynamic> resp) {
    return resp.values
        .expand((v) => v is List ? v : [v])
        .map((v) => v is Map ? v.values.join(' ') : v.toString())
        .join(' ');
  }

  Map<String, dynamic> _firstEntry(Map<String, dynamic> resp, String key) {
    final list = resp[key];
    if (list is List && list.isNotEmpty && list.first is Map) {
      return Map<String, dynamic>.from(list.first as Map);
    }
    return <String, dynamic>{};
  }

  List<Map<String, dynamic>> _listEntries(Map<String, dynamic> resp, String key) {
    final list = resp[key];
    if (list is List) {
      return list
          .whereType<Map>()
          .map((m) => Map<String, dynamic>.from(m))
          .toList();
    }
    return [];
  }

  int _extractPort(String url) {
    final match = RegExp(r':(\d+)').firstMatch(url);
    if (match != null) return int.tryParse(match.group(1)!) ?? 3333;
    return 3333;
  }

  double _toDouble(dynamic v) {
    if (v is double) return v;
    if (v is int) return v.toDouble();
    if (v is String) return double.tryParse(v) ?? 0;
    return 0;
  }

  int _toInt(dynamic v) {
    if (v is int) return v;
    if (v is double) return v.toInt();
    if (v is String) return int.tryParse(v) ?? 0;
    return 0;
  }
}

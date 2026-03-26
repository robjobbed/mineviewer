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
import 'cgminer_rpc_client.dart';

/// Driver for Bitmain Antminer devices running stock firmware (CGMiner/BMMiner).
class AntminerDriver implements MinerDriver {
  final CgMinerRpcClient _rpc;

  AntminerDriver({CgMinerRpcClient? rpc})
      : _rpc = rpc ?? CgMinerRpcClient();

  @override
  String get displayName => 'Antminer';

  @override
  MinerType get type => MinerType.antminer;

  @override
  int get defaultPort => 4028;

  @override
  Set<OverclockCapability> get overclockCapabilities => {};

  @override
  Future<bool> canHandle(String ip, {int? port}) async {
    try {
      final resp = await _rpc.sendCommand(ip, 'version', port: port ?? defaultPort);
      final raw = _flatten(resp).toLowerCase();
      return raw.contains('cgminer') ||
          raw.contains('bmminer') ||
          raw.contains('antminer');
    } catch (_) {
      return false;
    }
  }

  @override
  Future<DriverResult<MinerSnapshot>> fetchStats(String ip, {int? port}) async {
    try {
      final p = port ?? defaultPort;
      final statsResp = await _rpc.sendCommand(ip, 'stats', port: p);
      final summaryResp = await _rpc.sendCommand(ip, 'summary', port: p);

      final stats = _firstEntry(statsResp, 'STATS');
      final summary = _firstEntry(summaryResp, 'SUMMARY');

      // Hashrate: GHS av -> H/s
      final ghsAvg = _toDouble(summary['GHS av'] ?? stats['GHS av'] ?? 0);
      final hashrate = ghsAvg * 1e9;

      // Temperatures: check temp1-temp4 fields, take the max for asicTemp
      final temps = <double>[];
      for (var i = 1; i <= 4; i++) {
        final t = _toDouble(stats['temp$i'] ?? stats['temp2_$i'] ?? 0);
        if (t > 0) temps.add(t);
      }
      final asicTemp = temps.isNotEmpty ? temps.reduce((a, b) => a > b ? a : b) : null;

      // Fan speeds
      final fans = <int>[];
      for (var i = 1; i <= 8; i++) {
        final f = _toInt(stats['fan$i'] ?? 0);
        if (f > 0) fans.add(f);
      }
      final fanRpm = fans.isNotEmpty ? fans.reduce((a, b) => a > b ? a : b) : null;

      final accepted = _toInt(summary['Accepted'] ?? 0);
      final rejected = _toInt(summary['Rejected'] ?? 0);
      final elapsed = _toInt(summary['Elapsed'] ?? 0);

      // Power estimate from stats if available
      final power = _toDouble(stats['Power'] ?? stats['chain_power'] ?? 0);

      return Success(MinerSnapshot(
        minerId: ip,
        timestamp: DateTime.now(),
        hashrate: hashrate,
        asicTemp: asicTemp,
        fanRpm: fanRpm,
        power: power > 0 ? power : null,
        acceptedShares: accepted > 0 ? accepted : null,
        rejectedShares: rejected > 0 ? rejected : null,
        uptimeSeconds: elapsed > 0 ? elapsed : null,
        efficiency: (power > 0 && ghsAvg > 0) ? power / (ghsAvg / 1000.0) : null,
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

      final cgminer = version['CGMiner'] ?? version['BMMiner'] ?? 'unknown';
      final model = version['Type'] ?? version['Model'] ?? 'Antminer';
      final api = version['API'] ?? '';

      return Success(MinerInfo(
        type: MinerType.antminer,
        model: model.toString(),
        firmwareVersion: '$cgminer (API $api)',
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

      // Antminer stock firmware has limited write API.
      // Pool changes are the primary supported operation.
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
      'Identify not supported on stock Antminer firmware',
      type: DriverErrorType.unsupported,
    );
  }

  // ---------------------------------------------------------------------------
  // Helpers
  // ---------------------------------------------------------------------------

  /// Flatten all response values into a single string for keyword detection.
  String _flatten(Map<String, dynamic> resp) {
    return resp.values
        .expand((v) => v is List ? v : [v])
        .map((v) => v is Map ? v.values.join(' ') : v.toString())
        .join(' ');
  }

  /// Extract the first entry from a named response array.
  Map<String, dynamic> _firstEntry(Map<String, dynamic> resp, String key) {
    final list = resp[key];
    if (list is List && list.isNotEmpty && list.first is Map) {
      return Map<String, dynamic>.from(list.first as Map);
    }
    return <String, dynamic>{};
  }

  /// Extract all entries from a named response array.
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

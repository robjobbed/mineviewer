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
import 'braiins_api_client.dart';

/// Driver for miners running Braiins OS / Braiins OS+ firmware.
///
/// Primary data path uses the CGMiner TCP API on port 4028 (exposed by
/// BOSminer). Advanced control operations (hashrate/power targets) go
/// through the HTTP REST API.
class BraiinsDriver implements MinerDriver {
  final CgMinerRpcClient _rpc;
  final BraiinsApiClient _http;

  BraiinsDriver({CgMinerRpcClient? rpc, BraiinsApiClient? http})
      : _rpc = rpc ?? CgMinerRpcClient(),
        _http = http ?? BraiinsApiClient();

  @override
  String get displayName => 'Braiins OS';

  @override
  MinerType get type => MinerType.braiins;

  @override
  int get defaultPort => 4028;

  @override
  Set<OverclockCapability> get overclockCapabilities => {
        OverclockCapability.hashrateTarget,
        OverclockCapability.powerTarget,
        OverclockCapability.fanSpeed,
      };

  @override
  Future<bool> canHandle(String ip, {int? port}) async {
    try {
      final resp = await _rpc.sendCommand(ip, 'version', port: port ?? defaultPort);
      final raw = _flatten(resp).toLowerCase();
      return raw.contains('braiins') ||
          raw.contains('bosminer') ||
          raw.contains('bos+') ||
          raw.contains('bos toolbox');
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

      // BOSminer may report in GHS 5s, GHS av, or MHS_av
      double hashrate = 0;
      if (summary.containsKey('GHS 5s')) {
        hashrate = _toDouble(summary['GHS 5s']) * 1e9;
      } else if (summary.containsKey('GHS av')) {
        hashrate = _toDouble(summary['GHS av']) * 1e9;
      } else if (summary.containsKey('MHS av')) {
        hashrate = _toDouble(summary['MHS av']) * 1e6;
      }

      // Temperatures from STATS
      final temps = <double>[];
      for (var i = 1; i <= 4; i++) {
        final t = _toDouble(stats['temp$i'] ?? stats['temp_chip_$i'] ?? 0);
        if (t > 0) temps.add(t);
      }
      // Also check board-level temperatures
      for (var i = 0; i < 4; i++) {
        final t = _toDouble(stats['temp${i}_chip'] ?? 0);
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

      // Power consumption (BOSminer typically reports this)
      final power = _toDouble(
        summary['Power'] ??
            stats['Power'] ??
            stats['power_consumption'] ??
            0,
      );

      final accepted = _toInt(summary['Accepted'] ?? 0);
      final rejected = _toInt(summary['Rejected'] ?? 0);
      final elapsed = _toInt(summary['Elapsed'] ?? 0);

      final ghsAvg = hashrate / 1e9;
      final efficiency = (power > 0 && ghsAvg > 0)
          ? power / (ghsAvg / 1000.0)
          : null;

      return Success(MinerSnapshot(
        minerId: ip,
        timestamp: DateTime.now(),
        hashrate: hashrate,
        asicTemp: asicTemp,
        fanRpm: fanRpm,
        power: power > 0 ? power : null,
        efficiency: efficiency,
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

      final firmware = version['BOSminer'] ??
          version['BOSminer+'] ??
          version['CGMiner'] ??
          'unknown';
      final model = version['Type'] ?? version['Model'] ?? 'Braiins OS Miner';
      final api = version['API'] ?? '';

      return Success(MinerInfo(
        type: MinerType.braiins,
        model: model.toString(),
        firmwareVersion: 'Braiins $firmware (API $api)',
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
      // Authenticate with the HTTP API for control operations
      final token = await _http.login(ip, port: 80);

      if (config.hashrateTarget != null) {
        await _http.setHashrateTarget(
          ip,
          config.hashrateTarget!,
          authToken: token,
        );
      }

      if (config.powerTarget != null) {
        await _http.setPowerTarget(
          ip,
          config.powerTarget!,
          authToken: token,
        );
      }

      if (config.fanSpeedPct != null) {
        await _http.setFanSpeed(
          ip,
          config.fanSpeedPct!,
          authToken: token,
        );
      }

      // Pool changes via CGMiner API
      final rpcPort = port ?? defaultPort;
      if (config.stratumUrl != null && config.stratumUser != null) {
        final poolUrl = config.stratumPort != null
            ? '${config.stratumUrl}:${config.stratumPort}'
            : config.stratumUrl!;

        await _rpc.sendCommandWithParam(
          ip,
          'addpool',
          '$poolUrl,${config.stratumUser},${config.stratumPassword ?? ''}',
          port: rpcPort,
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
      'Identify not supported on Braiins OS',
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

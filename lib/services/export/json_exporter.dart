import 'dart:convert';
import 'dart:io';

import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';

import '../../data/models/miner.dart';
import '../../data/models/miner_snapshot.dart';

class JsonExporter {
  static final _dateFormat = DateFormat('yyyy-MM-dd_HH-mm-ss');

  /// Export structured JSON with miner info + snapshots. Returns the file path.
  static Future<String> exportToFile(
    Miner miner,
    List<MinerSnapshot> snapshots,
  ) async {
    final data = {
      'miner': {
        'name': miner.name,
        'type': miner.type.name,
        'model': miner.model,
        'ip_address': miner.ipAddress,
        'port': miner.port,
        'firmware_version': miner.firmwareVersion,
        'mac_address': miner.macAddress,
      },
      'exported_at': DateTime.now().toIso8601String(),
      'snapshot_count': snapshots.length,
      'snapshots': snapshots.map((s) => {
        'timestamp': s.timestamp.toIso8601String(),
        'hashrate': s.hashrate,
        'hashrate_1m': s.hashrate1m,
        'hashrate_10m': s.hashrate10m,
        'hashrate_1h': s.hashrate1h,
        'asic_temp': s.asicTemp,
        'vr_temp': s.vrTemp,
        'ambient_temp': s.ambientTemp,
        'power': s.power,
        'fan_rpm': s.fanRpm,
        'fan_speed_pct': s.fanSpeedPct,
        'efficiency': s.efficiency,
        'accepted_shares': s.acceptedShares,
        'rejected_shares': s.rejectedShares,
        'difficulty': s.difficulty,
        'pool_url': s.poolUrl,
        'uptime_seconds': s.uptimeSeconds,
        'rssi': s.rssi,
      }).toList(),
    };

    final jsonString = const JsonEncoder.withIndent('  ').convert(data);

    final dir = await getApplicationDocumentsDirectory();
    final safeName = miner.name.replaceAll(RegExp(r'[^\w\-]'), '_');
    final dateStr = _dateFormat.format(DateTime.now());
    final filename = 'mineviewer_${safeName}_$dateStr.json';
    final file = File('${dir.path}/$filename');

    await file.writeAsString(jsonString);
    return file.path;
  }
}

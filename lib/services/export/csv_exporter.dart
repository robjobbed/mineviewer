import 'dart:io';

import 'package:csv/csv.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';

import '../../data/models/miner_snapshot.dart';

class CsvExporter {
  static final _dateFormat = DateFormat('yyyy-MM-dd_HH-mm-ss');
  static final _timestampFormat = DateFormat('yyyy-MM-dd HH:mm:ss');

  static const _headers = [
    'timestamp',
    'hashrate_hs',
    'hashrate_ths',
    'asic_temp_c',
    'vr_temp_c',
    'power_w',
    'efficiency_jth',
    'fan_rpm',
    'accepted_shares',
    'rejected_shares',
    'difficulty',
    'pool_url',
  ];

  /// Export snapshot data as CSV. Returns the file path.
  static Future<String> exportToFile(
    String minerName,
    List<MinerSnapshot> snapshots,
  ) async {
    final rows = <List<dynamic>>[
      _headers,
      ...snapshots.map(_snapshotToRow),
    ];

    final csvString = const ListToCsvConverter().convert(rows);

    final dir = await getApplicationDocumentsDirectory();
    final safeName = minerName.replaceAll(RegExp(r'[^\w\-]'), '_');
    final dateStr = _dateFormat.format(DateTime.now());
    final filename = 'mineviewer_${safeName}_$dateStr.csv';
    final file = File('${dir.path}/$filename');

    await file.writeAsString(csvString);
    return file.path;
  }

  static List<dynamic> _snapshotToRow(MinerSnapshot s) {
    final hashrateHs = s.hashrate;
    final hashrateThs = hashrateHs / 1e12;

    return [
      _timestampFormat.format(s.timestamp),
      hashrateHs,
      hashrateThs,
      s.asicTemp ?? '',
      s.vrTemp ?? '',
      s.power ?? '',
      s.efficiency ?? '',
      s.fanRpm ?? '',
      s.acceptedShares ?? '',
      s.rejectedShares ?? '',
      s.difficulty ?? '',
      s.poolUrl ?? '',
    ];
  }
}

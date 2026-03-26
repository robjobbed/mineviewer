import 'package:freezed_annotation/freezed_annotation.dart';

part 'miner_snapshot.freezed.dart';
part 'miner_snapshot.g.dart';

@freezed
abstract class MinerSnapshot with _$MinerSnapshot {
  const factory MinerSnapshot({
    required String minerId,
    required DateTime timestamp,
    required double hashrate,
    double? hashrate1m,
    double? hashrate10m,
    double? hashrate1h,
    double? asicTemp,
    double? vrTemp,
    double? ambientTemp,
    double? power,
    int? fanRpm,
    int? fanSpeedPct,
    double? efficiency,
    int? acceptedShares,
    int? rejectedShares,
    double? difficulty,
    String? poolUrl,
    int? uptimeSeconds,
    int? rssi,
  }) = _MinerSnapshot;

  factory MinerSnapshot.fromJson(Map<String, dynamic> json) =>
      _$MinerSnapshotFromJson(json);
}

import 'package:freezed_annotation/freezed_annotation.dart';
import 'miner_type.dart';

part 'miner_info.freezed.dart';
part 'miner_info.g.dart';

@freezed
abstract class MinerInfo with _$MinerInfo {
  const factory MinerInfo({
    required MinerType type,
    required String model,
    String? firmwareVersion,
    String? macAddress,
    String? hostname,
    String? ssid,
    int? rssi,
  }) = _MinerInfo;

  factory MinerInfo.fromJson(Map<String, dynamic> json) =>
      _$MinerInfoFromJson(json);
}

import 'package:freezed_annotation/freezed_annotation.dart';

part 'miner_config.freezed.dart';
part 'miner_config.g.dart';

@freezed
abstract class MinerConfig with _$MinerConfig {
  const factory MinerConfig({
    int? frequency,
    int? coreVoltage,
    double? hashrateTarget,
    double? powerTarget,
    int? fanSpeedPct,
    bool? autoFan,
    int? tempTarget,
    String? stratumUrl,
    int? stratumPort,
    String? stratumUser,
    String? stratumPassword,
    String? fallbackStratumUrl,
    int? fallbackStratumPort,
    String? fallbackStratumUser,
    String? fallbackStratumPassword,
  }) = _MinerConfig;

  factory MinerConfig.fromJson(Map<String, dynamic> json) =>
      _$MinerConfigFromJson(json);
}

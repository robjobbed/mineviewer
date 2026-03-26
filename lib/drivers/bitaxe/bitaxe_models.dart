import 'package:json_annotation/json_annotation.dart';

part 'bitaxe_models.g.dart';

@JsonSerializable(fieldRename: FieldRename.none, createToJson: false)
class BitAxeSystemInfo {
  // ignore_for_file: non_constant_identifier_names
  @JsonKey(name: 'ASICModel')
  final String? asicModel;
  final String? version;
  final String? hostname;
  final String? macAddr;
  final String? ssid;
  final int? wifiRSSI;
  final double? hashRate;       // GH/s
  @JsonKey(name: 'hashRate_1m')
  final double? hashRate1m;
  @JsonKey(name: 'hashRate_10m')
  final double? hashRate10m;
  @JsonKey(name: 'hashRate_1h')
  final double? hashRate1h;
  final double? temp;           // ASIC temp C
  final double? vrTemp;         // VR temp C
  final double? power;          // Watts
  final int? fanrpm;
  final int? fanspeed;          // 0-100%
  final double? efficiency;     // J/TH
  final int? sharesAccepted;
  final int? sharesRejected;
  final double? bestDiff;
  final String? stratumURL;
  final int? stratumPort;
  final String? stratumUser;
  final String? fallbackStratumURL;
  final int? fallbackStratumPort;
  final String? fallbackStratumUser;
  final int? uptimeSeconds;
  final int? frequency;
  final int? coreVoltage;
  final bool? autofanspeed;
  final int? temptarget;
  final bool? overclockEnabled;

  const BitAxeSystemInfo({
    this.asicModel,
    this.version,
    this.hostname,
    this.macAddr,
    this.ssid,
    this.wifiRSSI,
    this.hashRate,
    this.hashRate1m,
    this.hashRate10m,
    this.hashRate1h,
    this.temp,
    this.vrTemp,
    this.power,
    this.fanrpm,
    this.fanspeed,
    this.efficiency,
    this.sharesAccepted,
    this.sharesRejected,
    this.bestDiff,
    this.stratumURL,
    this.stratumPort,
    this.stratumUser,
    this.fallbackStratumURL,
    this.fallbackStratumPort,
    this.fallbackStratumUser,
    this.uptimeSeconds,
    this.frequency,
    this.coreVoltage,
    this.autofanspeed,
    this.temptarget,
    this.overclockEnabled,
  });

  factory BitAxeSystemInfo.fromJson(Map<String, dynamic> json) =>
      _$BitAxeSystemInfoFromJson(json);
}

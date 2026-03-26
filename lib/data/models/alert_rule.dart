import 'package:freezed_annotation/freezed_annotation.dart';

part 'alert_rule.freezed.dart';
part 'alert_rule.g.dart';

enum AlertMetric {
  asicTemp,
  vrTemp,
  ambientTemp,
  hashrate,
  hashrateDrop,
  power,
  efficiency,
  fanSpeed,
  offline,
  rejectedShares;

  String get displayName => switch (this) {
    AlertMetric.asicTemp => 'ASIC Temperature',
    AlertMetric.vrTemp => 'VR Temperature',
    AlertMetric.ambientTemp => 'Ambient Temperature',
    AlertMetric.hashrate => 'Hashrate',
    AlertMetric.hashrateDrop => 'Hashrate Drop %',
    AlertMetric.power => 'Power',
    AlertMetric.efficiency => 'Efficiency',
    AlertMetric.fanSpeed => 'Fan Speed',
    AlertMetric.offline => 'Offline',
    AlertMetric.rejectedShares => 'Rejected Shares %',
  };

  String get unit => switch (this) {
    AlertMetric.asicTemp ||
    AlertMetric.vrTemp ||
    AlertMetric.ambientTemp =>
      'C',
    AlertMetric.hashrate => 'TH/s',
    AlertMetric.hashrateDrop || AlertMetric.rejectedShares => '%',
    AlertMetric.power => 'W',
    AlertMetric.efficiency => 'J/TH',
    AlertMetric.fanSpeed => 'RPM',
    AlertMetric.offline => 'min',
  };
}

enum AlertCondition {
  above,
  below,
  equals,
  offlineFor;

  String get displayName => switch (this) {
    AlertCondition.above => 'Above',
    AlertCondition.below => 'Below',
    AlertCondition.equals => 'Equals',
    AlertCondition.offlineFor => 'Offline For',
  };
}

@freezed
abstract class AlertRule with _$AlertRule {
  const factory AlertRule({
    required String id,
    String? minerId,
    required AlertMetric metric,
    required AlertCondition condition,
    required double threshold,
    @Default(0) int durationSeconds,
    @Default(true) bool enabled,
    DateTime? createdAt,
  }) = _AlertRule;

  factory AlertRule.fromJson(Map<String, dynamic> json) =>
      _$AlertRuleFromJson(json);
}

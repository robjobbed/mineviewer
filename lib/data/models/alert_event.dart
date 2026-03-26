import 'package:freezed_annotation/freezed_annotation.dart';

part 'alert_event.freezed.dart';
part 'alert_event.g.dart';

@freezed
abstract class AlertEvent with _$AlertEvent {
  const factory AlertEvent({
    int? id,
    required String ruleId,
    required String minerId,
    required DateTime triggeredAt,
    required double actualValue,
    @Default(false) bool acknowledged,
  }) = _AlertEvent;

  factory AlertEvent.fromJson(Map<String, dynamic> json) =>
      _$AlertEventFromJson(json);
}

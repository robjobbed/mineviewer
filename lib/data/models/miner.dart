import 'package:freezed_annotation/freezed_annotation.dart';
import 'miner_type.dart';
import 'miner_status.dart';

part 'miner.freezed.dart';
part 'miner.g.dart';

@freezed
abstract class Miner with _$Miner {
  const factory Miner({
    required String id,
    required String name,
    required String ipAddress,
    required int port,
    required MinerType type,
    required MinerStatus status,
    String? model,
    String? firmwareVersion,
    String? macAddress,
    @Default(0) int sortOrder,
    String? groupId,
    DateTime? createdAt,
    DateTime? lastSeenAt,
  }) = _Miner;

  factory Miner.fromJson(Map<String, dynamic> json) => _$MinerFromJson(json);
}

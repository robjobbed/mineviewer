import 'package:freezed_annotation/freezed_annotation.dart';

part 'miner_group.freezed.dart';
part 'miner_group.g.dart';

@freezed
abstract class MinerGroup with _$MinerGroup {
  const factory MinerGroup({
    required String id,
    required String name,
    @Default(0) int sortOrder,
  }) = _MinerGroup;

  factory MinerGroup.fromJson(Map<String, dynamic> json) => _$MinerGroupFromJson(json);
}

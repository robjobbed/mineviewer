import 'package:freezed_annotation/freezed_annotation.dart';

part 'pool_info.freezed.dart';
part 'pool_info.g.dart';

@freezed
abstract class PoolInfo with _$PoolInfo {
  const factory PoolInfo({
    required String url,
    required int port,
    required String user,
    @Default('') String password,
    @Default(false) bool isFallback,
  }) = _PoolInfo;

  factory PoolInfo.fromJson(Map<String, dynamic> json) =>
      _$PoolInfoFromJson(json);
}

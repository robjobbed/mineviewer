import 'package:dio/dio.dart';

class BitAxeApiClient {
  final Dio _dio;

  BitAxeApiClient({Dio? dio})
      : _dio = dio ?? Dio(BaseOptions(
          connectTimeout: const Duration(seconds: 5),
          receiveTimeout: const Duration(seconds: 5),
        ));

  String _baseUrl(String ip, int port) => 'http://$ip:$port';

  Future<Map<String, dynamic>> getSystemInfo(String ip, {int port = 80}) async {
    final response = await _dio.get<Map<String, dynamic>>(
      '${_baseUrl(ip, port)}/api/system/info',
    );
    return response.data!;
  }

  Future<Map<String, dynamic>> getStatistics(String ip, {int port = 80}) async {
    final response = await _dio.get<Map<String, dynamic>>(
      '${_baseUrl(ip, port)}/api/system/info',
    );
    // BitAxe returns stats in the system/info endpoint
    return response.data!;
  }

  Future<void> patchSystem(
    String ip,
    Map<String, dynamic> payload, {
    int port = 80,
  }) async {
    await _dio.patch<void>(
      '${_baseUrl(ip, port)}/api/system',
      data: payload,
    );
  }

  Future<void> restart(String ip, {int port = 80}) async {
    await _dio.post<void>('${_baseUrl(ip, port)}/api/system/restart');
  }

  Future<void> identify(String ip, {int port = 80}) async {
    await _dio.post<void>('${_baseUrl(ip, port)}/api/system/identify');
  }
}

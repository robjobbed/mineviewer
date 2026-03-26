import 'package:dio/dio.dart';

/// HTTP REST client for Braiins OS control operations.
///
/// Braiins OS exposes the standard CGMiner API on port 4028 for read
/// operations. This client covers the HTTP-based endpoints used for
/// advanced control (hashrate/power targets, tuning) that are only
/// available through the web interface or REST API.
class BraiinsApiClient {
  final Dio _dio;

  BraiinsApiClient({Dio? dio})
      : _dio = dio ??
            Dio(BaseOptions(
              connectTimeout: const Duration(seconds: 5),
              receiveTimeout: const Duration(seconds: 5),
              followRedirects: true,
              validateStatus: (status) => status != null && status < 500,
            ));

  String _baseUrl(String ip, int port) => 'http://$ip:$port';

  /// Login to the Braiins OS web interface and return an auth cookie token.
  ///
  /// Default credentials: root / (empty password).
  Future<String?> login(
    String ip, {
    int port = 80,
    String username = 'root',
    String password = '',
  }) async {
    final response = await _dio.post<dynamic>(
      '${_baseUrl(ip, port)}/cgi-bin/luci/',
      data: 'luci_username=$username&luci_password=$password',
      options: Options(
        contentType: 'application/x-www-form-urlencoded',
        followRedirects: false,
        validateStatus: (status) => status != null && status < 400,
      ),
    );

    // Extract sysauth cookie from Set-Cookie header
    final cookies = response.headers['set-cookie'];
    if (cookies != null) {
      for (final cookie in cookies) {
        final match = RegExp(r'sysauth=([^;]+)').firstMatch(cookie);
        if (match != null) return match.group(1);
      }
    }
    return null;
  }

  /// Get tuner status via the Braiins OS+ REST API.
  Future<Map<String, dynamic>> getTunerStatus(
    String ip, {
    int port = 80,
    String? authToken,
  }) async {
    final response = await _dio.get<Map<String, dynamic>>(
      '${_baseUrl(ip, port)}/cgi-bin/luci/admin/miner/api_status',
      options: _authOptions(authToken),
    );
    return response.data ?? {};
  }

  /// Set the hashrate target (in GH/s) via the Braiins OS+ tuner.
  Future<void> setHashrateTarget(
    String ip,
    double targetGHs, {
    int port = 80,
    String? authToken,
  }) async {
    await _dio.post<void>(
      '${_baseUrl(ip, port)}/cgi-bin/luci/admin/miner/cfg_save',
      data: {
        'mode': 'hashrate_target',
        'hashrate_target': targetGHs,
      },
      options: _authOptions(authToken),
    );
  }

  /// Set the power target (in Watts) via the Braiins OS+ tuner.
  Future<void> setPowerTarget(
    String ip,
    double targetWatts, {
    int port = 80,
    String? authToken,
  }) async {
    await _dio.post<void>(
      '${_baseUrl(ip, port)}/cgi-bin/luci/admin/miner/cfg_save',
      data: {
        'mode': 'power_target',
        'power_target': targetWatts,
      },
      options: _authOptions(authToken),
    );
  }

  /// Set fan speed percentage via the Braiins OS+ API.
  Future<void> setFanSpeed(
    String ip,
    int speedPct, {
    int port = 80,
    String? authToken,
  }) async {
    await _dio.post<void>(
      '${_baseUrl(ip, port)}/cgi-bin/luci/admin/miner/cfg_save',
      data: {
        'fan_mode': 'manual',
        'fan_speed': speedPct,
      },
      options: _authOptions(authToken),
    );
  }

  Options _authOptions(String? token) {
    if (token == null) return Options();
    return Options(
      headers: {'Cookie': 'sysauth=$token'},
    );
  }
}

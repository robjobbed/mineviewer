import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

/// Raw TCP socket client for CGMiner JSON-RPC (port 4028).
///
/// Used by Antminer, Braiins OS, and Canaan Avalon miners that expose
/// the standard CGMiner API over TCP.
class CgMinerRpcClient {
  static const int _defaultPort = 4028;
  static const Duration _timeout = Duration(seconds: 5);

  /// Send a simple command and return the parsed JSON response.
  Future<Map<String, dynamic>> sendCommand(
    String ip,
    String command, {
    int port = _defaultPort,
  }) async {
    final payload = jsonEncode({'command': command});
    return _send(ip, port, payload);
  }

  /// Send a command with a parameter (e.g. `{"command":"ascset","parameter":"0,freq,600"}`).
  Future<Map<String, dynamic>> sendCommandWithParam(
    String ip,
    String command,
    String param, {
    int port = _defaultPort,
  }) async {
    final payload = jsonEncode({'command': command, 'parameter': param});
    return _send(ip, port, payload);
  }

  Future<Map<String, dynamic>> _send(String ip, int port, String payload) async {
    Socket? socket;
    try {
      socket = await Socket.connect(ip, port, timeout: _timeout);

      socket.write(payload);
      await socket.flush();
      socket.destroy(); // half-close: signal we are done writing

      final buffer = BytesBuilder(copy: false);
      await socket
          .timeout(_timeout)
          .forEach((data) => buffer.add(data));

      // CGMiner responses often contain trailing null bytes
      final raw = utf8.decode(buffer.toBytes()).replaceAll('\x00', '').trim();

      if (raw.isEmpty) {
        throw const FormatException('Empty response from CGMiner API');
      }

      final decoded = jsonDecode(raw);
      if (decoded is Map<String, dynamic>) {
        return decoded;
      }
      throw FormatException('Unexpected response type: ${decoded.runtimeType}');
    } on SocketException catch (e) {
      throw SocketException('CGMiner connection to $ip:$port failed: ${e.message}');
    } on TimeoutException {
      throw TimeoutException('CGMiner request to $ip:$port timed out', _timeout);
    } finally {
      socket?.destroy();
    }
  }
}

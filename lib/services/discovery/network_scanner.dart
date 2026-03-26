import 'dart:async';
import 'package:lan_scanner/lan_scanner.dart';
import 'package:network_info_plus/network_info_plus.dart';
import 'package:logging/logging.dart';
import '../../data/models/miner_type.dart';
import '../../drivers/driver_registry.dart';
import '../../drivers/miner_driver.dart';

/// Result of probing a single IP address.
class DiscoveredMiner {
  final String ipAddress;
  final MinerType type;
  final MinerDriver driver;
  final String? model;

  const DiscoveredMiner({
    required this.ipAddress,
    required this.type,
    required this.driver,
    this.model,
  });
}

/// Scans the local network for miners.
class NetworkScanner {
  final _log = Logger('NetworkScanner');
  bool _scanning = false;
  bool _cancelled = false;

  bool get isScanning => _scanning;

  /// Scan the local subnet for miners.
  /// Yields progress (0.0 to 1.0) and discovered miners as a stream.
  Stream<ScanEvent> scan() async* {
    if (_scanning) return;
    _scanning = true;
    _cancelled = false;

    try {
      final info = NetworkInfo();
      final wifiIP = await info.getWifiIP();

      if (wifiIP == null) {
        yield const ScanError('Could not determine WiFi IP address');
        return;
      }

      _log.info('Starting scan from IP: $wifiIP');

      // Get subnet (e.g., 192.168.1)
      final parts = wifiIP.split('.');
      if (parts.length != 4) {
        yield const ScanError('Invalid IP address format');
        return;
      }
      final subnet = '${parts[0]}.${parts[1]}.${parts[2]}';

      final scanner = LanScanner();
      final hosts = <String>[];

      // Phase 1: Ping sweep to find live hosts
      yield const ScanProgress(0.0, 'Scanning network...');

      await for (final host in scanner.icmpScan(subnet)) {
        if (_cancelled) break;
        hosts.add(host.internetAddress.address);
        yield ScanProgress(
          hosts.length / 254.0 * 0.5, // First 50% is ping sweep
          'Found ${hosts.length} hosts...',
        );
      }

      if (_cancelled) return;

      _log.info('Found ${hosts.length} live hosts, probing for miners...');

      // Phase 2: Probe each host with all drivers
      for (var i = 0; i < hosts.length; i++) {
        if (_cancelled) break;

        final ip = hosts[i];
        yield ScanProgress(
          0.5 + (i / hosts.length) * 0.5,
          'Probing $ip... (${i + 1}/${hosts.length})',
        );

        try {
          final driver = await DriverRegistry.identify(ip)
              .timeout(const Duration(seconds: 3));

          if (driver != null) {
            String? model;
            try {
              final infoResult = await driver.fetchInfo(ip);
              model = infoResult.valueOrNull?.model;
            } catch (_) {}

            yield ScanFound(DiscoveredMiner(
              ipAddress: ip,
              type: driver.type,
              driver: driver,
              model: model,
            ));
          }
        } catch (e) {
          _log.fine('Probe failed for $ip: $e');
        }
      }

      yield const ScanProgress(1.0, 'Scan complete');
      yield const ScanComplete();
    } catch (e) {
      yield ScanError('Scan failed: $e');
    } finally {
      _scanning = false;
    }
  }

  void cancel() {
    _cancelled = true;
  }
}

/// Events emitted during scanning.
sealed class ScanEvent {
  const ScanEvent();
}

class ScanProgress extends ScanEvent {
  final double progress; // 0.0 to 1.0
  final String message;
  const ScanProgress(this.progress, this.message);
}

class ScanFound extends ScanEvent {
  final DiscoveredMiner miner;
  const ScanFound(this.miner);
}

class ScanComplete extends ScanEvent {
  const ScanComplete();
}

class ScanError extends ScanEvent {
  final String message;
  const ScanError(this.message);
}

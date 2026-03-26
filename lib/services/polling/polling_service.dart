import 'dart:async';

import 'package:logging/logging.dart';

import '../../core/constants.dart';
import '../../data/models/miner.dart';
import '../../data/models/miner_snapshot.dart';
import '../../data/models/miner_status.dart';
import '../../data/models/miner_type.dart';
import '../../drivers/driver_registry.dart';

typedef OnSnapshotCallback = void Function(
    String minerId, MinerSnapshot snapshot);
typedef OnStatusChangeCallback = void Function(
    String minerId, MinerStatus status);
typedef OnPollErrorCallback = void Function(
    String minerId, String message, int consecutiveFailures);

class PollingService {
  PollingService();

  final _log = Logger('PollingService');
  final Map<String, Timer> _timers = {};
  final Map<String, int> _consecutiveFailures = {};
  final Map<String, Miner> _minerCache = {};

  /// Called with every successful snapshot.
  OnSnapshotCallback? onSnapshot;

  /// Called when a miner transitions between online/offline.
  OnStatusChangeCallback? onStatusChange;

  /// Called on poll failure (for optional UI/logging).
  OnPollErrorCallback? onPollError;

  /// Begin periodic polling for a miner.
  /// Cancels any existing timer for this miner first.
  void startPolling(Miner miner) {
    stopPolling(miner.id);

    _minerCache[miner.id] = miner;
    _consecutiveFailures[miner.id] = 0;

    final interval = _getInterval(miner.type);
    _log.info(
        'Starting poll for ${miner.name} (${miner.ipAddress}) every ${interval.inSeconds}s');

    // Fetch immediately, then on interval
    _poll(miner);
    _timers[miner.id] = Timer.periodic(interval, (_) {
      final cached = _minerCache[miner.id];
      if (cached != null) {
        _poll(cached);
      }
    });
  }

  /// Stop polling a single miner.
  void stopPolling(String minerId) {
    _timers[minerId]?.cancel();
    _timers.remove(minerId);
    _consecutiveFailures.remove(minerId);
    _minerCache.remove(minerId);
  }

  /// Stop all polling.
  void stopAll() {
    for (final timer in _timers.values) {
      timer.cancel();
    }
    _timers.clear();
    _consecutiveFailures.clear();
    _minerCache.clear();
  }

  /// Update the cached miner data (e.g. if IP/port changes).
  void updateMinerInfo(Miner miner) {
    _minerCache[miner.id] = miner;
  }

  /// Whether a miner is currently being polled.
  bool isPolling(String minerId) => _timers.containsKey(minerId);

  /// Number of consecutive failures for a miner.
  int getConsecutiveFailures(String minerId) =>
      _consecutiveFailures[minerId] ?? 0;

  Future<void> _poll(Miner miner) async {
    try {
      final driver = DriverRegistry.getDriver(miner.type);
      final result =
          await driver.fetchStats(miner.ipAddress, port: miner.port);

      result.when(
        success: (snapshot) {
          _consecutiveFailures[miner.id] = 0;
          onSnapshot?.call(miner.id, snapshot);
          if (miner.status != MinerStatus.online) {
            onStatusChange?.call(miner.id, MinerStatus.online);
          }
        },
        failure: (message, error) {
          _handleFailure(miner, message);
        },
      );
    } catch (e) {
      _handleFailure(miner, e.toString());
    }
  }

  void _handleFailure(Miner miner, String message) {
    final failures = (_consecutiveFailures[miner.id] ?? 0) + 1;
    _consecutiveFailures[miner.id] = failures;
    _log.warning(
        'Poll failed for ${miner.name}: $message (attempt $failures)');
    onPollError?.call(miner.id, message, failures);

    if (failures >= AppConstants.offlineConsecutiveFailures) {
      onStatusChange?.call(miner.id, MinerStatus.offline);
    }
  }

  Duration _getInterval(MinerType type) {
    return Duration(
      seconds: switch (type) {
        MinerType.bitaxe => AppConstants.pollIntervalBitaxe,
        MinerType.antminer => AppConstants.pollIntervalAntminer,
        MinerType.braiins => AppConstants.pollIntervalBraiins,
        MinerType.canaan => AppConstants.pollIntervalCanaan,
        MinerType.luckyminer => AppConstants.pollIntervalLuckyminer,
      },
    );
  }
}

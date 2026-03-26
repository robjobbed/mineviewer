import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/models/miner.dart';
import '../data/models/miner_snapshot.dart';
import '../data/models/miner_status.dart';
import '../services/polling/polling_service.dart';
import '../presentation/providers/miners_provider.dart';
import 'miners/snapshot_history_provider.dart';

final pollingServiceProvider = Provider<PollingService>((ref) {
  final service = PollingService();

  service.onSnapshot = (String minerId, MinerSnapshot snapshot) {
    ref.read(minerSnapshotsProvider.notifier).updateSnapshot(snapshot);
    ref.read(snapshotHistoryProvider.notifier).addSnapshot(snapshot);
  };

  service.onStatusChange = (String minerId, MinerStatus status) {
    final miners = ref.read(minersProvider);
    try {
      final miner = miners.firstWhere((m) => m.id == minerId);
      ref.read(minersProvider.notifier).updateMiner(
        miner.copyWith(
          status: status,
          lastSeenAt: status == MinerStatus.online ? DateTime.now() : miner.lastSeenAt,
        ),
      );
    } catch (_) {
      // Miner was removed
    }
  };

  ref.listen<List<Miner>>(minersProvider, (previous, current) {
    final previousIds = previous?.map((m) => m.id).toSet() ?? {};
    final currentIds = current.map((m) => m.id).toSet();

    for (final miner in current) {
      if (!previousIds.contains(miner.id)) {
        service.startPolling(miner);
      }
    }

    for (final id in previousIds) {
      if (!currentIds.contains(id)) {
        service.stopPolling(id);
      }
    }
  });

  ref.onDispose(() {
    service.stopAll();
  });

  return service;
});

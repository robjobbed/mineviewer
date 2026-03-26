import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../../data/models/miner.dart';
import '../../data/models/miner_snapshot.dart';
import '../../data/models/miner_status.dart';
import '../../data/models/miner_type.dart';

const _uuid = Uuid();

class MinersNotifier extends Notifier<List<Miner>> {
  @override
  List<Miner> build() {
    // Only load demo data in debug mode
    if (kDebugMode) {
      _loadDemoData();
    }
    return [];
  }

  void _loadDemoData() {
    Future.microtask(() {
      final now = DateTime.now();
      state = [
        Miner(
          id: 'demo-1',
          name: 'SoloMine.io',
          ipAddress: '10.0.0.133',
          port: 80,
          type: MinerType.bitaxe,
          status: MinerStatus.online,
          model: 'NerdQAxe++',
          firmwareVersion: '2.4.0',
          createdAt: now.subtract(const Duration(days: 12)),
          lastSeenAt: now,
        ),
        Miner(
          id: 'demo-2',
          name: 'SoloMine.io',
          ipAddress: '10.0.0.108',
          port: 80,
          type: MinerType.bitaxe,
          status: MinerStatus.online,
          model: 'NerdQAxe++',
          firmwareVersion: '2.4.0',
          createdAt: now.subtract(const Duration(days: 12)),
          lastSeenAt: now,
        ),
        Miner(
          id: 'demo-3',
          name: 'Contriboot.dev',
          ipAddress: '10.0.0.135',
          port: 80,
          type: MinerType.bitaxe,
          status: MinerStatus.online,
          model: 'NerdQAxe++',
          firmwareVersion: '2.4.0',
          createdAt: now.subtract(const Duration(days: 12)),
          lastSeenAt: now,
        ),
        Miner(
          id: 'demo-4',
          name: 'SoloMine.io',
          ipAddress: '10.0.0.51',
          port: 80,
          type: MinerType.bitaxe,
          status: MinerStatus.warning,
          model: 'BitAxe Ultra',
          firmwareVersion: '2.3.1',
          createdAt: now.subtract(const Duration(days: 30)),
          lastSeenAt: now.subtract(const Duration(minutes: 5)),
        ),
      ];
    });
  }

  Future<void> addMiner({
    required String name,
    required String ipAddress,
    required int port,
    required MinerType type,
  }) async {
    final miner = Miner(
      id: _uuid.v4(),
      name: name,
      ipAddress: ipAddress,
      port: port,
      type: type,
      status: MinerStatus.offline,
      createdAt: DateTime.now(),
    );
    state = [...state, miner];
  }

  void removeMiner(String id) {
    state = state.where((m) => m.id != id).toList();
  }

  void updateMiner(Miner miner) {
    state = [
      for (final m in state)
        if (m.id == miner.id) miner else m,
    ];
  }
}

final minersProvider =
    NotifierProvider<MinersNotifier, List<Miner>>(MinersNotifier.new);

/// Holds the latest snapshot for each miner, keyed by minerId.
class MinerSnapshotsNotifier extends Notifier<Map<String, MinerSnapshot>> {
  @override
  Map<String, MinerSnapshot> build() {
    // Only load demo snapshots in debug mode
    if (kDebugMode) {
      _loadDemoSnapshots();
    }
    return {};
  }

  void _loadDemoSnapshots() {
    Future.microtask(() {
      final now = DateTime.now();
      state = {
        'demo-1': MinerSnapshot(
          minerId: 'demo-1',
          timestamp: now,
          hashrate: 4.8e12, // 4.8 TH/s
          asicTemp: 53,
          vrTemp: 57,
          power: 82,
          efficiency: 17.1,
          acceptedShares: 810080,
          rejectedShares: 12,
          difficulty: 8.5e9, // 8.5G best diff
          poolUrl: 'stratum+tcp://public-pool.io:21496',
          uptimeSeconds: 12 * 24 * 3600 + 10 * 3600, // 12d 10h
          fanRpm: 4200,
          fanSpeedPct: 65,
        ),
        'demo-2': MinerSnapshot(
          minerId: 'demo-2',
          timestamp: now,
          hashrate: 4.8e12,
          asicTemp: 58,
          vrTemp: 50,
          power: 83,
          efficiency: 17.1,
          acceptedShares: 790000,
          rejectedShares: 8,
          difficulty: 108e9, // 108G best diff
          poolUrl: 'stratum+tcp://public-pool.io:21496',
          uptimeSeconds: 12 * 24 * 3600 + 10 * 3600,
          fanRpm: 4100,
          fanSpeedPct: 63,
        ),
        'demo-3': MinerSnapshot(
          minerId: 'demo-3',
          timestamp: now,
          hashrate: 4.7e12,
          asicTemp: 59,
          vrTemp: 50,
          power: 92,
          efficiency: 19.8,
          acceptedShares: 720000,
          rejectedShares: 15,
          difficulty: 16e9, // 16G best diff
          poolUrl: 'stratum+tcp://public-pool.io:21496',
          uptimeSeconds: 12 * 24 * 3600 + 10 * 3600,
          fanRpm: 4500,
          fanSpeedPct: 70,
        ),
        'demo-4': MinerSnapshot(
          minerId: 'demo-4',
          timestamp: now,
          hashrate: 1.2e12,
          asicTemp: 71,
          vrTemp: 65,
          power: 45,
          efficiency: 37.5,
          acceptedShares: 150000,
          rejectedShares: 45,
          difficulty: 2.1e9,
          poolUrl: 'stratum+tcp://public-pool.io:21496',
          uptimeSeconds: 5 * 24 * 3600 + 3 * 3600,
          fanRpm: 5200,
          fanSpeedPct: 85,
        ),
      };
    });
  }

  void updateSnapshot(MinerSnapshot snapshot) {
    state = {...state, snapshot.minerId: snapshot};
  }
}

final minerSnapshotsProvider =
    NotifierProvider<MinerSnapshotsNotifier, Map<String, MinerSnapshot>>(
        MinerSnapshotsNotifier.new);

/// Convenience provider for a single miner's latest snapshot.
final minerLatestSnapshotProvider =
    Provider.family<MinerSnapshot?, String>((ref, minerId) {
  final snapshots = ref.watch(minerSnapshotsProvider);
  return snapshots[minerId];
});

/// Convenience provider to get a single miner by ID.
final minerByIdProvider = Provider.family<Miner?, String>((ref, minerId) {
  final miners = ref.watch(minersProvider);
  try {
    return miners.firstWhere((m) => m.id == minerId);
  } catch (_) {
    return null;
  }
});

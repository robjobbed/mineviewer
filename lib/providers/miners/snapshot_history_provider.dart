import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/miner_snapshot.dart';

/// In-memory historical snapshot storage.
/// Keeps the last N snapshots per miner for charting.
/// Will be replaced by Drift DB persistence in a later phase.
class SnapshotHistoryNotifier extends Notifier<Map<String, List<MinerSnapshot>>> {
  static const int maxSnapshotsPerMiner = 1000;

  @override
  Map<String, List<MinerSnapshot>> build() => {};

  void addSnapshot(MinerSnapshot snapshot) {
    final current = state[snapshot.minerId] ?? [];
    final updated = [...current, snapshot];

    // Trim to max size, keeping most recent
    final trimmed = updated.length > maxSnapshotsPerMiner
        ? updated.sublist(updated.length - maxSnapshotsPerMiner)
        : updated;

    state = {...state, snapshot.minerId: trimmed};
  }

  List<MinerSnapshot> getHistory(String minerId, {Duration? range}) {
    final all = state[minerId] ?? [];
    if (range == null) return all;

    final cutoff = DateTime.now().subtract(range);
    return all.where((s) => s.timestamp.isAfter(cutoff)).toList();
  }

  void clearMiner(String minerId) {
    final updated = {...state};
    updated.remove(minerId);
    state = updated;
  }

  /// Downsample data to a target number of points for chart performance.
  /// Groups snapshots into time buckets and averages each bucket.
  List<MinerSnapshot> getDownsampled(String minerId, Duration range, {int targetPoints = 200}) {
    final data = getHistory(minerId, range: range);
    if (data.length <= targetPoints) return data;

    final bucketSize = range.inMilliseconds ~/ targetPoints;
    final buckets = <int, List<MinerSnapshot>>{};

    for (final snapshot in data) {
      final bucketKey = snapshot.timestamp.millisecondsSinceEpoch ~/ bucketSize;
      buckets.putIfAbsent(bucketKey, () => []).add(snapshot);
    }

    return buckets.entries.map((entry) {
      final points = entry.value;
      return MinerSnapshot(
        minerId: minerId,
        timestamp: points[points.length ~/ 2].timestamp, // median timestamp
        hashrate: points.map((p) => p.hashrate).reduce((a, b) => a + b) / points.length,
        hashrate1m: _avgNullable(points.map((p) => p.hashrate1m)),
        hashrate10m: _avgNullable(points.map((p) => p.hashrate10m)),
        hashrate1h: _avgNullable(points.map((p) => p.hashrate1h)),
        asicTemp: _avgNullable(points.map((p) => p.asicTemp)),
        vrTemp: _avgNullable(points.map((p) => p.vrTemp)),
        ambientTemp: _avgNullable(points.map((p) => p.ambientTemp)),
        power: _avgNullable(points.map((p) => p.power)),
        fanRpm: _avgIntNullable(points.map((p) => p.fanRpm)),
        fanSpeedPct: _avgIntNullable(points.map((p) => p.fanSpeedPct)),
        efficiency: _avgNullable(points.map((p) => p.efficiency)),
        acceptedShares: points.last.acceptedShares,
        rejectedShares: points.last.rejectedShares,
        difficulty: points.last.difficulty,
        poolUrl: points.last.poolUrl,
        uptimeSeconds: points.last.uptimeSeconds,
        rssi: points.last.rssi,
      );
    }).toList()
      ..sort((a, b) => a.timestamp.compareTo(b.timestamp));
  }

  static double? _avgNullable(Iterable<double?> values) {
    final nonNull = values.whereType<double>().toList();
    if (nonNull.isEmpty) return null;
    return nonNull.reduce((a, b) => a + b) / nonNull.length;
  }

  static int? _avgIntNullable(Iterable<int?> values) {
    final nonNull = values.whereType<int>().toList();
    if (nonNull.isEmpty) return null;
    return nonNull.reduce((a, b) => a + b) ~/ nonNull.length;
  }
}

final snapshotHistoryProvider =
    NotifierProvider<SnapshotHistoryNotifier, Map<String, List<MinerSnapshot>>>(
        SnapshotHistoryNotifier.new);

/// Get historical snapshots for a miner within a time range.
final minerHistoryProvider = Provider.family<List<MinerSnapshot>, ({String minerId, Duration range})>((ref, params) {
  final history = ref.watch(snapshotHistoryProvider.notifier);
  return history.getDownsampled(params.minerId, params.range);
});

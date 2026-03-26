import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../../data/models/alert_event.dart';
import '../../data/models/alert_rule.dart';
import '../../data/models/miner_snapshot.dart';
import '../../services/alerts/alert_engine.dart';
import '../../services/alerts/alert_notifier_service.dart';
import 'miners_provider.dart';

const _uuid = Uuid();

// ---------------------------------------------------------------------------
// Alert Rules
// ---------------------------------------------------------------------------

class AlertRulesNotifier extends Notifier<List<AlertRule>> {
  @override
  List<AlertRule> build() => [];

  void addRule(AlertRule rule) {
    final withId = rule.id.isEmpty
        ? rule.copyWith(id: _uuid.v4(), createdAt: DateTime.now())
        : rule;
    state = [...state, withId];
  }

  void removeRule(String id) {
    state = state.where((r) => r.id != id).toList();
  }

  void updateRule(AlertRule updated) {
    state = [
      for (final r in state)
        if (r.id == updated.id) updated else r,
    ];
  }

  void toggleRule(String id) {
    state = [
      for (final r in state)
        if (r.id == id) r.copyWith(enabled: !r.enabled) else r,
    ];
  }
}

final alertRulesProvider =
    NotifierProvider<AlertRulesNotifier, List<AlertRule>>(
  AlertRulesNotifier.new,
);

// ---------------------------------------------------------------------------
// Alert Events
// ---------------------------------------------------------------------------

class AlertEventsNotifier extends Notifier<List<AlertEvent>> {
  @override
  List<AlertEvent> build() => [];

  void addEvent(AlertEvent event) {
    state = [event, ...state];
  }

  void addEvents(List<AlertEvent> events) {
    if (events.isEmpty) return;
    state = [...events, ...state];
  }

  void acknowledgeEvent(int index) {
    if (index < 0 || index >= state.length) return;
    state = [
      for (var i = 0; i < state.length; i++)
        if (i == index) state[i].copyWith(acknowledged: true) else state[i],
    ];
  }

  void clearAll() {
    state = [];
  }
}

final alertEventsProvider =
    NotifierProvider<AlertEventsNotifier, List<AlertEvent>>(
  AlertEventsNotifier.new,
);

// ---------------------------------------------------------------------------
// Alert Engine (singleton)
// ---------------------------------------------------------------------------

final alertEngineProvider = Provider<AlertEngine>((ref) => AlertEngine());

// ---------------------------------------------------------------------------
// Alert Notifier Service (singleton, initialized lazily)
// ---------------------------------------------------------------------------

final alertNotifierServiceProvider = Provider<AlertNotifierService>((ref) {
  final service = AlertNotifierService();
  // Initialize asynchronously; fire-and-forget is acceptable here.
  service.initialize();
  return service;
});

// ---------------------------------------------------------------------------
// Evaluate alerts whenever a snapshot updates
// ---------------------------------------------------------------------------

/// Call this from the polling provider whenever a new snapshot arrives.
void evaluateAlerts({
  required WidgetRef ref,
  required String minerId,
  required MinerSnapshot snapshot,
}) {
  final rules = ref.read(alertRulesProvider);
  if (rules.isEmpty) return;

  final engine = ref.read(alertEngineProvider);
  final events = engine.evaluate(minerId, snapshot, rules);

  if (events.isEmpty) return;

  // Persist events
  ref.read(alertEventsProvider.notifier).addEvents(events);

  // Fire push notifications
  final notifier = ref.read(alertNotifierServiceProvider);
  final miners = ref.read(minersProvider);

  for (final event in events) {
    final rule = rules.firstWhere(
      (r) => r.id == event.ruleId,
      orElse: () => rules.first,
    );
    final miner = miners
        .where((m) => m.id == event.minerId)
        .firstOrNull;
    final minerName = miner?.name ?? event.minerId;

    notifier.show(rule: rule, snapshot: snapshot, minerName: minerName);
  }
}

/// Provider-level wiring: watches snapshot map and evaluates on every change.
/// Add this to a top-level widget (e.g., DashboardScreen) via ref.listen.
final alertEvaluationProvider = Provider<void>((ref) {
  final rules = ref.watch(alertRulesProvider);
  if (rules.isEmpty) return;

  final snapshots = ref.watch(minerSnapshotsProvider);
  final engine = ref.read(alertEngineProvider);

  for (final entry in snapshots.entries) {
    final events = engine.evaluate(entry.key, entry.value, rules);
    if (events.isNotEmpty) {
      ref.read(alertEventsProvider.notifier).addEvents(events);

      final notifierService = ref.read(alertNotifierServiceProvider);
      final miners = ref.read(minersProvider);

      for (final event in events) {
        final rule = rules.firstWhere(
          (r) => r.id == event.ruleId,
          orElse: () => rules.first,
        );
        final miner = miners
            .where((m) => m.id == event.minerId)
            .firstOrNull;
        final minerName = miner?.name ?? event.minerId;
        notifierService.show(
          rule: rule,
          snapshot: entry.value,
          minerName: minerName,
        );
      }
    }
  }
});

// ---------------------------------------------------------------------------
// Derived: unacknowledged alert count (for badges)
// ---------------------------------------------------------------------------

final unacknowledgedAlertCountProvider = Provider<int>((ref) {
  final events = ref.watch(alertEventsProvider);
  return events.where((e) => !e.acknowledged).length;
});

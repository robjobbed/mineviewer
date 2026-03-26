import '../../core/constants.dart';
import '../../data/models/alert_event.dart';
import '../../data/models/alert_rule.dart';
import '../../data/models/miner_snapshot.dart';

class AlertEngine {
  /// Tracks when each rule+miner combo last fired (for cooldown).
  final Map<String, DateTime> _lastFired = {};

  /// Tracks when a sustained condition was first observed (for duration rules).
  final Map<String, DateTime> _firstSeen = {};

  /// Evaluate a snapshot against all enabled rules for this miner.
  /// Returns a list of newly triggered AlertEvents.
  List<AlertEvent> evaluate(
    String minerId,
    MinerSnapshot snapshot,
    List<AlertRule> rules,
  ) {
    final events = <AlertEvent>[];
    final now = DateTime.now();

    for (final rule in rules) {
      if (!rule.enabled) continue;

      // Skip rules that target a different miner
      if (rule.minerId != null && rule.minerId != minerId) continue;

      final key = '${rule.id}:$minerId';

      final metricValue = _extractMetric(rule.metric, snapshot);
      if (metricValue == null) {
        // Metric not available in snapshot -- clear sustained tracking
        _firstSeen.remove(key);
        continue;
      }

      final conditionMet = _checkCondition(rule.condition, metricValue, rule.threshold);

      if (!conditionMet) {
        // Condition no longer holds -- reset sustained tracker
        _firstSeen.remove(key);
        continue;
      }

      // --- Condition is met ---

      // Handle sustained duration requirement
      if (rule.durationSeconds > 0) {
        final firstSeen = _firstSeen[key];
        if (firstSeen == null) {
          // First time we see this condition -- start tracking
          _firstSeen[key] = now;
          continue;
        }
        final elapsed = now.difference(firstSeen).inSeconds;
        if (elapsed < rule.durationSeconds) {
          // Not sustained long enough yet
          continue;
        }
      }

      // Check cooldown -- don't re-fire within cooldown window
      final lastFired = _lastFired[key];
      if (lastFired != null) {
        final cooldown = Duration(minutes: AppConstants.alertCooldownMinutes);
        if (now.difference(lastFired) < cooldown) {
          continue;
        }
      }

      // Fire the alert
      _lastFired[key] = now;
      _firstSeen.remove(key);

      events.add(AlertEvent(
        ruleId: rule.id,
        minerId: minerId,
        triggeredAt: now,
        actualValue: metricValue,
      ));
    }

    return events;
  }

  /// Extract the relevant metric value from a snapshot.
  double? _extractMetric(AlertMetric metric, MinerSnapshot snapshot) {
    return switch (metric) {
      AlertMetric.asicTemp => snapshot.asicTemp,
      AlertMetric.vrTemp => snapshot.vrTemp,
      AlertMetric.ambientTemp => snapshot.ambientTemp,
      AlertMetric.hashrate => snapshot.hashrate,
      AlertMetric.hashrateDrop => _computeHashrateDrop(snapshot),
      AlertMetric.power => snapshot.power,
      AlertMetric.efficiency => snapshot.efficiency,
      AlertMetric.fanSpeed => snapshot.fanRpm?.toDouble(),
      AlertMetric.offline => null, // Handled differently via status, not snapshot values
      AlertMetric.rejectedShares => _computeRejectedPct(snapshot),
    };
  }

  /// Compute hashrate drop as a percentage: ((target - actual) / target * 100).
  /// Uses hashrate1h as reference if available, otherwise returns null.
  double? _computeHashrateDrop(MinerSnapshot snapshot) {
    final reference = snapshot.hashrate1h ?? snapshot.hashrate10m;
    if (reference == null || reference <= 0) return null;
    final drop = ((reference - snapshot.hashrate) / reference) * 100;
    return drop.clamp(0, 100);
  }

  /// Compute rejected share percentage.
  double? _computeRejectedPct(MinerSnapshot snapshot) {
    final accepted = snapshot.acceptedShares;
    final rejected = snapshot.rejectedShares;
    if (accepted == null || rejected == null) return null;
    final total = accepted + rejected;
    if (total == 0) return 0;
    return (rejected / total) * 100;
  }

  /// Check if a value meets the condition relative to a threshold.
  bool _checkCondition(AlertCondition condition, double value, double threshold) {
    return switch (condition) {
      AlertCondition.above => value > threshold,
      AlertCondition.below => value < threshold,
      AlertCondition.equals => (value - threshold).abs() < 0.001,
      AlertCondition.offlineFor => value > threshold,
    };
  }

  /// Clear all tracking state (e.g., on reset).
  void reset() {
    _lastFired.clear();
    _firstSeen.clear();
  }
}

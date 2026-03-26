import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import '../../data/models/alert_rule.dart';
import '../../data/models/miner_snapshot.dart';

class AlertNotifierService {
  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  int _nextId = 0;

  /// Initialize the notification plugin for Android + iOS.
  Future<void> initialize() async {
    const androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestSoundPermission: true,
      requestBadgePermission: true,
    );

    const settings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _plugin.initialize(settings);
  }

  /// Request notification permissions (call once at app startup).
  Future<void> requestPermissions() async {
    // Android 13+ runtime permission
    await _plugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.requestNotificationsPermission();

    // iOS permissions
    await _plugin
        .resolvePlatformSpecificImplementation<
            IOSFlutterLocalNotificationsPlugin>()
        ?.requestPermissions(alert: true, sound: true, badge: true);
  }

  /// Show a push notification for a triggered alert.
  Future<void> show({
    required AlertRule rule,
    required MinerSnapshot snapshot,
    required String minerName,
  }) async {
    final title = _buildTitle(rule.metric);
    final body = _buildBody(
      minerName: minerName,
      metric: rule.metric,
      condition: rule.condition,
      threshold: rule.threshold,
      snapshot: snapshot,
    );

    const androidDetails = AndroidNotificationDetails(
      'mineviewer_alerts',
      'Mining Alerts',
      channelDescription: 'Alerts for miner thresholds and status changes',
      importance: Importance.high,
      priority: Priority.high,
      enableVibration: true,
      playSound: true,
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentSound: true,
      presentBadge: true,
    );

    const details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _plugin.show(_nextId++, title, body, details);
  }

  String _buildTitle(AlertMetric metric) {
    return switch (metric) {
      AlertMetric.asicTemp => 'High ASIC Temperature',
      AlertMetric.vrTemp => 'VR Temperature Alert',
      AlertMetric.ambientTemp => 'Ambient Temperature Alert',
      AlertMetric.hashrate => 'Hashrate Alert',
      AlertMetric.hashrateDrop => 'Hashrate Drop',
      AlertMetric.power => 'Power Alert',
      AlertMetric.efficiency => 'Efficiency Alert',
      AlertMetric.fanSpeed => 'Fan Speed Alert',
      AlertMetric.offline => 'Miner Offline',
      AlertMetric.rejectedShares => 'Rejected Shares Alert',
    };
  }

  String _buildBody({
    required String minerName,
    required AlertMetric metric,
    required AlertCondition condition,
    required double threshold,
    required MinerSnapshot snapshot,
  }) {
    final actualValue = _extractDisplayValue(metric, snapshot);
    final unit = metric.unit;
    final thresholdStr = _formatNumber(threshold);
    final actualStr = actualValue != null ? _formatNumber(actualValue) : '?';

    return '$minerName: $actualStr$unit '
        '(threshold: ${condition.displayName.toLowerCase()} $thresholdStr$unit)';
  }

  double? _extractDisplayValue(AlertMetric metric, MinerSnapshot snapshot) {
    return switch (metric) {
      AlertMetric.asicTemp => snapshot.asicTemp,
      AlertMetric.vrTemp => snapshot.vrTemp,
      AlertMetric.ambientTemp => snapshot.ambientTemp,
      AlertMetric.hashrate => snapshot.hashrate,
      AlertMetric.hashrateDrop => null,
      AlertMetric.power => snapshot.power,
      AlertMetric.efficiency => snapshot.efficiency,
      AlertMetric.fanSpeed => snapshot.fanRpm?.toDouble(),
      AlertMetric.offline => null,
      AlertMetric.rejectedShares => null,
    };
  }

  String _formatNumber(double value) {
    if (value == value.roundToDouble()) {
      return value.toInt().toString();
    }
    return value.toStringAsFixed(1);
  }
}

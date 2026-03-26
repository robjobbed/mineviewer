class AppConstants {
  AppConstants._();

  static const String appName = 'MineViewer';
  static const String appVersion = '0.1.0';

  // Default polling intervals (seconds)
  static const int pollIntervalBitaxe = 10;
  static const int pollIntervalAntminer = 30;
  static const int pollIntervalBraiins = 30;
  static const int pollIntervalCanaan = 30;
  static const int pollIntervalLuckyminer = 10;

  // Network discovery
  static const int discoveryTimeoutMs = 3000;
  static const int connectionTimeoutMs = 5000;

  // Alerts
  static const int alertCooldownMinutes = 15;
  static const int offlineConsecutiveFailures = 3;

  // Data retention
  static const int retentionFullResolutionHours = 24;
  static const int retentionFiveMinAvgDays = 7;
  static const int retentionHourlyAvgDays = 30;
}

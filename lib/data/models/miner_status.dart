enum MinerStatus {
  online,
  offline,
  warning,
  error;

  String get displayName => switch (this) {
    MinerStatus.online => 'Online',
    MinerStatus.offline => 'Offline',
    MinerStatus.warning => 'Warning',
    MinerStatus.error => 'Error',
  };
}

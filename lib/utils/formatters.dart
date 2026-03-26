class Formatters {
  Formatters._();

  static String uptime(int seconds) {
    final days = seconds ~/ 86400;
    final hours = (seconds % 86400) ~/ 3600;
    final minutes = (seconds % 3600) ~/ 60;
    if (days > 0) return '${days}d ${hours}h';
    if (hours > 0) return '${hours}h ${minutes}m';
    return '${minutes}m';
  }

  static String rssi(int dbm) {
    if (dbm >= -50) return 'Excellent';
    if (dbm >= -60) return 'Good';
    if (dbm >= -70) return 'Fair';
    return 'Weak';
  }

  static String percentage(double value) => '${value.toStringAsFixed(1)}%';

  static String satoshis(double btc) =>
      '${(btc * 1e8).toStringAsFixed(0)} sats';
}

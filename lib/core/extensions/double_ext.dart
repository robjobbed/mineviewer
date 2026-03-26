extension DoubleFormatting on double {
  /// Format raw H/s to appropriate unit (H/s, KH/s, MH/s, GH/s, TH/s, PH/s)
  String toHashrateString() {
    if (this >= 1e15) return '${(this / 1e15).toStringAsFixed(2)} PH/s';
    if (this >= 1e12) return '${(this / 1e12).toStringAsFixed(2)} TH/s';
    if (this >= 1e9) return '${(this / 1e9).toStringAsFixed(2)} GH/s';
    if (this >= 1e6) return '${(this / 1e6).toStringAsFixed(2)} MH/s';
    if (this >= 1e3) return '${(this / 1e3).toStringAsFixed(2)} KH/s';
    return '${toStringAsFixed(2)} H/s';
  }

  /// Format watts to W or kW
  String toPowerString() {
    if (this >= 1000) return '${(this / 1000).toStringAsFixed(2)} kW';
    return '${toStringAsFixed(1)} W';
  }

  /// Format temperature with degree symbol
  String toTempString() => '${toStringAsFixed(1)}C';

  /// Format efficiency in J/TH
  String toEfficiencyString() => '${toStringAsFixed(1)} J/TH';
}

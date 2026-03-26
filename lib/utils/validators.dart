class Validators {
  Validators._();

  static bool isValidIpAddress(String ip) {
    final parts = ip.split('.');
    if (parts.length != 4) return false;
    for (final part in parts) {
      final n = int.tryParse(part);
      if (n == null || n < 0 || n > 255) return false;
    }
    return true;
  }

  static bool isValidPort(int port) => port > 0 && port <= 65535;

  static bool isValidBtcAddress(String address) {
    // Basic validation: starts with 1, 3, or bc1, reasonable length
    if (address.startsWith('bc1')) {
      return address.length >= 42 && address.length <= 62;
    }
    if (address.startsWith('1') || address.startsWith('3')) {
      return address.length >= 25 && address.length <= 34;
    }
    return false;
  }
}

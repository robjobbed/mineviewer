import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../services/discovery/network_scanner.dart';

class DiscoveryState {
  final bool isScanning;
  final double progress;
  final String message;
  final List<DiscoveredMiner> found;
  final String? error;

  const DiscoveryState({
    this.isScanning = false,
    this.progress = 0.0,
    this.message = '',
    this.found = const [],
    this.error,
  });

  DiscoveryState copyWith({
    bool? isScanning,
    double? progress,
    String? message,
    List<DiscoveredMiner>? found,
    String? error,
  }) {
    return DiscoveryState(
      isScanning: isScanning ?? this.isScanning,
      progress: progress ?? this.progress,
      message: message ?? this.message,
      found: found ?? this.found,
      error: error,
    );
  }
}

class DiscoveryNotifier extends Notifier<DiscoveryState> {
  NetworkScanner? _scanner;
  StreamSubscription<ScanEvent>? _subscription;

  @override
  DiscoveryState build() => const DiscoveryState();

  Future<void> startScan() async {
    if (state.isScanning) return;

    _scanner = NetworkScanner();
    state = const DiscoveryState(isScanning: true, message: 'Starting scan...');

    _subscription = _scanner!.scan().listen((event) {
      switch (event) {
        case ScanProgress(:final progress, :final message):
          state = state.copyWith(progress: progress, message: message);
        case ScanFound(:final miner):
          state = state.copyWith(found: [...state.found, miner]);
        case ScanComplete():
          state = state.copyWith(
            isScanning: false,
            progress: 1.0,
            message: 'Found ${state.found.length} miners',
          );
        case ScanError(:final message):
          state = state.copyWith(
            isScanning: false,
            error: message,
          );
      }
    });
  }

  void cancelScan() {
    _scanner?.cancel();
    _subscription?.cancel();
    state = state.copyWith(isScanning: false, message: 'Scan cancelled');
  }

  void clearResults() {
    state = const DiscoveryState();
  }
}

final discoveryProvider =
    NotifierProvider<DiscoveryNotifier, DiscoveryState>(DiscoveryNotifier.new);

# Contributing to MineViewer

Thanks for your interest in contributing. This guide covers the most common contribution paths.

## Getting Started

1. Fork the repository and clone your fork.
2. Create a feature branch: `git checkout -b feat/your-feature`
3. Install dependencies: `flutter pub get`
4. Run code generation: `dart run build_runner build --delete-conflicting-outputs`
5. Make your changes.
6. Run checks before committing:
   ```bash
   flutter analyze
   flutter test
   ```
7. Push and open a pull request against `main`.

## Adding a New Miner Driver

Miner drivers handle communication with specific hardware. Each driver implements the `MinerDriver` abstract class.

1. Create a new file in `lib/data/drivers/` (e.g., `whatsminer_driver.dart`).
2. Implement the `MinerDriver` interface:
   ```dart
   class WhatsminerDriver implements MinerDriver {
     @override
     String get id => 'whatsminer';

     @override
     String get displayName => 'MicroBT Whatsminer';

     @override
     Future<bool> canConnect(String host) async { ... }

     @override
     Future<MinerStats> getStats(String host) async { ... }

     @override
     Future<MinerConfig> getConfig(String host) async { ... }

     @override
     Future<void> applyConfig(String host, MinerConfig config) async { ... }

     @override
     Future<void> restart(String host) async { ... }

     @override
     Future<void> identifyLed(String host) async { ... }
   }
   ```
3. Register the driver in `lib/data/drivers/driver_registry.dart`:
   ```dart
   void registerDrivers() {
     DriverRegistry.register(WhatsminerDriver());
   }
   ```
4. Add tests in `test/data/drivers/whatsminer_driver_test.dart`.
5. Update the supported hardware table in `README.md`.

## Adding a New Pool Adapter

Pool adapters fetch earnings data from mining pool APIs.

1. Create a new file in `lib/data/pools/` (e.g., `luxor_adapter.dart`).
2. Implement the `PoolAdapter` interface:
   ```dart
   class LuxorAdapter implements PoolAdapter {
     @override
     String get id => 'luxor';

     @override
     String get displayName => 'Luxor';

     @override
     Future<PoolEarnings> getEarnings(PoolCredentials credentials) async { ... }

     @override
     Future<List<PoolWorker>> getWorkers(PoolCredentials credentials) async { ... }

     @override
     Future<PoolStats> getPoolStats() async { ... }
   }
   ```
3. Register the adapter in `lib/data/pools/pool_registry.dart`.
4. Add tests in `test/data/pools/luxor_adapter_test.dart`.
5. Update the pool earnings list in `README.md`.

## Code Style

- Follow the rules in `analysis_options.yaml`. Run `flutter analyze` and fix all warnings before submitting.
- Use `freezed` for data models and `riverpod_annotation` for providers.
- Run `dart run build_runner build --delete-conflicting-outputs` after modifying annotated files.
- Keep files focused. One class per file, named to match the class (snake_case).
- Write tests for new drivers, adapters, and non-trivial logic.

## Pull Request Process

1. Fill out the PR template completely.
2. Ensure `flutter analyze` and `flutter test` pass.
3. Keep PRs focused on a single change. Split unrelated work into separate PRs.
4. Add screenshots or recordings for UI changes.
5. A maintainer will review your PR. Address feedback in follow-up commits (do not force-push during review).

## Issue Templates

Use the appropriate issue template when reporting bugs, requesting features, or requesting support for a new miner type:

- **Bug Report** -- for crashes, incorrect data, or broken functionality
- **Feature Request** -- for new capabilities or improvements
- **New Miner Driver** -- for requesting support for a specific miner model

## Code of Conduct

Be respectful. Technical disagreements are fine; personal attacks are not. We are building a tool for the Bitcoin mining community -- keep discussions constructive.

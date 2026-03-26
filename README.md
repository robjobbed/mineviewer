# MineViewer

**Free, open-source Bitcoin miner monitoring for iOS, Android, and Web**

[![License: MIT](https://img.shields.io/badge/License-MIT-blue.svg)](LICENSE)
[![Flutter](https://img.shields.io/badge/Flutter-3.27+-02569B?logo=flutter)](https://flutter.dev)
[![Platform](https://img.shields.io/badge/Platform-iOS%20%7C%20Android%20%7C%20Web-brightgreen)](https://github.com/yourusername/mineviewer)

---

## Why MineViewer?

Most miner monitoring apps charge monthly fees for basic features like alerts and CSV export. MineViewer makes everything free and open source.

| Feature | MineViewer | HashWatcher |
|---|---|---|
| Temperature / hashrate / offline alerts | Free | $4.99/mo |
| CSV / JSON / PDF export | Free | $4.99/mo |
| Pool earnings tracking | Yes (6 pools) | No |
| Profitability dashboard | Yes | No |
| Web dashboard | Yes | No |
| Open source | MIT | No |

---

## Features

### Monitoring
- Real-time hashrate, temperature, fan speed, and uptime stats
- Fleet dashboard with aggregate views across all miners
- Historical performance charts with configurable time ranges
- Sparkline widgets for quick at-a-glance status

### Alerts
- Temperature, hashrate, and offline alerts -- all free
- Custom alert rules with configurable thresholds
- Push notifications (mobile) and browser notifications (web)

### Pool Earnings
- Ocean.xyz
- CKPool
- Public Pool
- Braiins Pool
- F2Pool
- ViaBTC

### Profitability
- Live BTC price feed
- Electricity cost configuration (per kWh)
- Profit/loss calculation per miner and fleet-wide
- Daily, weekly, and monthly projections

### Controls
- Overclock / underclock frequency adjustment
- Fan speed control
- Pool configuration (URL, worker, password)
- Miner restart
- LED identify (blink to locate a specific unit)

### Export
- CSV export for spreadsheet analysis
- JSON export for programmatic use
- PDF reports with charts and summary stats

### Discovery
- LAN scan to find miners on your local network
- Auto-identify miner type and firmware version

---

## Supported Hardware

| Manufacturer | Models |
|---|---|
| BitAxe / NerdQAxe | All variants (Supra, Ultra, Hex, Gamma, etc.) |
| Bitmain Antminer | S9, S17, S19, S21, T21, and compatible |
| Braiins OS | Any miner running Braiins OS+ firmware |
| Canaan Avalon | Avalon series |
| LuckyMiner | LV06 and compatible |

---

## Screenshots

> Screenshots coming soon. See the `/doc` directory for design mockups.

---

## Getting Started

### Prerequisites

- [Flutter](https://flutter.dev/docs/get-started/install) 3.27 or later
- [FVM](https://fvm.app/) recommended for version management

### Setup

```bash
git clone https://github.com/yourusername/mineviewer.git
cd mineviewer
fvm use           # or skip if not using FVM
flutter pub get
dart run build_runner build --delete-conflicting-outputs
flutter run
```

### Building

```bash
# Android
flutter build apk --release
flutter build appbundle --release

# iOS
flutter build ios --release

# Web
flutter build web --release
```

---

## Architecture

MineViewer uses a layered architecture with a plugin system for miner drivers and pool adapters.

```
lib/
  core/              # App-wide config, theme, routing, constants
  data/
    drivers/         # Miner communication drivers (one per hardware type)
    pools/           # Pool API adapters (one per mining pool)
    database/        # Drift local database (tables, DAOs)
    models/          # Freezed data models
  domain/            # Repository interfaces, use cases
  presentation/
    screens/         # Full-page screens
    widgets/         # Reusable UI components
    providers/       # Riverpod providers and state
```

**Adding hardware support** is done by implementing the `MinerDriver` interface and registering it in the `DriverRegistry`. See [CONTRIBUTING.md](CONTRIBUTING.md) for details.

**Adding pool support** is done by implementing the `PoolAdapter` interface and registering it in the `PoolRegistry`.

---

## Contributing

Contributions are welcome. See [CONTRIBUTING.md](CONTRIBUTING.md) for guidelines on:

- Adding a new miner driver
- Adding a new pool adapter
- Code style and PR process

---

## Roadmap

- [ ] Drift DB persistence for offline history
- [ ] i18n / localization (Spanish, Portuguese, German, Japanese)
- [ ] Home screen widgets (iOS and Android)
- [ ] MQTT support for real-time miner telemetry
- [ ] Watchdog mode with auto-restart on miner failure
- [ ] Stratum V2 protocol support

---

## License

MIT -- see [LICENSE](LICENSE) for details.

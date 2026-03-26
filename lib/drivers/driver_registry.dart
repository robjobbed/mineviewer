import '../data/models/miner_type.dart';
import 'miner_driver.dart';
import 'bitaxe/bitaxe_driver.dart';
import 'antminer/antminer_driver.dart';
import 'braiins/braiins_driver.dart';
import 'canaan/canaan_driver.dart';
import 'luckyminer/luckyminer_driver.dart';

class DriverRegistry {
  static final Map<MinerType, MinerDriver> _drivers = {
    MinerType.bitaxe: BitAxeDriver(),
    MinerType.antminer: AntminerDriver(),
    MinerType.braiins: BraiinsDriver(),
    MinerType.canaan: CanaanDriver(),
    MinerType.luckyminer: LuckyMinerDriver(),
  };

  static MinerDriver getDriver(MinerType type) {
    final driver = _drivers[type];
    if (driver == null) {
      throw UnsupportedError('No driver registered for $type');
    }
    return driver;
  }

  static void register(MinerDriver driver) {
    _drivers[driver.type] = driver;
  }

  static Future<MinerDriver?> identify(String ip) async {
    for (final driver in _drivers.values) {
      try {
        if (await driver.canHandle(ip)) return driver;
      } catch (_) {
        continue;
      }
    }
    return null;
  }

  static List<MinerDriver> get all => _drivers.values.toList();
  static List<MinerType> get supportedTypes => _drivers.keys.toList();
}

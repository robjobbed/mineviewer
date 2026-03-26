enum MinerType {
  bitaxe,
  antminer,
  braiins,
  canaan,
  luckyminer;

  String get displayName => switch (this) {
    MinerType.bitaxe => 'BitAxe / NerdQAxe',
    MinerType.antminer => 'Antminer',
    MinerType.braiins => 'Braiins OS',
    MinerType.canaan => 'Canaan Avalon',
    MinerType.luckyminer => 'LuckyMiner',
  };

  int get defaultPort => switch (this) {
    MinerType.bitaxe => 80,
    MinerType.antminer => 4028,
    MinerType.braiins => 80,
    MinerType.canaan => 4028,
    MinerType.luckyminer => 80,
  };
}

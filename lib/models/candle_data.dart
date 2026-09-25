class CandleData {
  final DateTime time;
  final double open;
  final double high;
  final double low;
  final double close;
  final double volume;

  CandleData({
    required this.time,
    required this.open,
    required this.high,
    required this.low,
    required this.close,
    required this.volume,
  });

  factory CandleData.fromBitgetList(List<dynamic> list) {
    // Bitget API: [ts, open, high, low, close, volume, ...]
    int ts = int.tryParse(list[0].toString()) ?? 0;
    return CandleData(
      time: DateTime.fromMillisecondsSinceEpoch(ts),
      open: double.tryParse(list[1].toString()) ?? 0.0,
      high: double.tryParse(list[2].toString()) ?? 0.0,
      low: double.tryParse(list[3].toString()) ?? 0.0,
      close: double.tryParse(list[4].toString()) ?? 0.0,
      volume: double.tryParse(list[5].toString()) ?? 0.0,
    );
  }

  factory CandleData.fromBinanceList(List<dynamic> list) {
    // Binance API: [openTime, open, high, low, close, volume, ...]
    int ts = int.tryParse(list[0].toString()) ?? 0;
    return CandleData(
      time: DateTime.fromMillisecondsSinceEpoch(ts),
      open: double.tryParse(list[1].toString()) ?? 0.0,
      high: double.tryParse(list[2].toString()) ?? 0.0,
      low: double.tryParse(list[3].toString()) ?? 0.0,
      close: double.tryParse(list[4].toString()) ?? 0.0,
      volume: double.tryParse(list[5].toString()) ?? 0.0,
    );
  }
}

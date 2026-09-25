class EquityPoint {
  final DateTime time;
  final double equity;
  final double price;

  EquityPoint({
    required this.time,
    required this.equity,
    required this.price,
  });
}

class BacktestResult {
  final double initialCapital;
  final double finalEquity;
  final double totalProfit;
  final double returnRate; // %
  final int totalTrades;
  final int winTrades;
  final int lossTrades;
  final double winRate; // %
  final double maxDrawdown; // %
  final double profitFactor;
  final List<EquityPoint> equityCurve;
  final List<Map<String, dynamic>> tradeLogs;

  BacktestResult({
    required this.initialCapital,
    required this.finalEquity,
    required this.totalProfit,
    required this.returnRate,
    required this.totalTrades,
    required this.winTrades,
    required this.lossTrades,
    required this.winRate,
    required this.maxDrawdown,
    required this.profitFactor,
    required this.equityCurve,
    required this.tradeLogs,
  });
}

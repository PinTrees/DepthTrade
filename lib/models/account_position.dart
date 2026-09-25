class AccountPosition {
  double equity;
  double startEquity;
  double availableMargin;
  double holdSize; // 보유 수량
  double avgPrice; // 평단가
  double unrealizedPnl; // 미실현 손익
  double realizedPnl; // 누적 실현 손익
  int pairTradeCount; // 페어 거래 체결 횟수
  double currentPrice;

  AccountPosition({
    this.equity = 10000.0,
    this.startEquity = 10000.0,
    this.availableMargin = 10000.0,
    this.holdSize = 0.0,
    this.avgPrice = 0.0,
    this.unrealizedPnl = 0.0,
    this.realizedPnl = 0.0,
    this.pairTradeCount = 0,
    this.currentPrice = 0.0,
  });

  double get totalPnl => realizedPnl + unrealizedPnl;

  double get totalReturnPer {
    if (startEquity <= 0) return 0.0;
    return ((equity + unrealizedPnl - startEquity) / startEquity) * 100.0;
  }

  void updateUnrealizedPnl(double marketPrice) {
    currentPrice = marketPrice;
    if (holdSize > 0 && avgPrice > 0) {
      unrealizedPnl = (marketPrice - avgPrice) * holdSize;
    } else {
      unrealizedPnl = 0.0;
    }
  }

  Map<String, dynamic> toMap() {
    return {
      'equity': equity,
      'startEquity': startEquity,
      'availableMargin': availableMargin,
      'holdSize': holdSize,
      'avgPrice': avgPrice,
      'unrealizedPnl': unrealizedPnl,
      'realizedPnl': realizedPnl,
      'pairTradeCount': pairTradeCount,
      'currentPrice': currentPrice,
    };
  }

  factory AccountPosition.fromMap(Map<String, dynamic> map) {
    return AccountPosition(
      equity: (map['equity'] as num?)?.toDouble() ?? 10000.0,
      startEquity: (map['startEquity'] as num?)?.toDouble() ?? 10000.0,
      availableMargin: (map['availableMargin'] as num?)?.toDouble() ?? 10000.0,
      holdSize: (map['holdSize'] as num?)?.toDouble() ?? 0.0,
      avgPrice: (map['avgPrice'] as num?)?.toDouble() ?? 0.0,
      unrealizedPnl: (map['unrealizedPnl'] as num?)?.toDouble() ?? 0.0,
      realizedPnl: (map['realizedPnl'] as num?)?.toDouble() ?? 0.0,
      pairTradeCount: (map['pairTradeCount'] as num?)?.toInt() ?? 0,
      currentPrice: (map['currentPrice'] as num?)?.toDouble() ?? 0.0,
    );
  }
}

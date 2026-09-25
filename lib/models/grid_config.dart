class GridConfig {
  String symbol;
  int leverage;
  double openOrderPer; // 신규 매수 간격 (%) - 기본 0.34%
  double closeOrderPer; // 청산 익절 간격 (%) - 기본 0.34%
  double canclePer; // 취소 이격도 (%) - 기본 1.74%
  double overlapPer; // 중복 허용 오차 (%) - 기본 0.074%
  int orderDepth; // 주문 깊이 레벨 수 (기본 2~10)
  double stoplossFibonacci; // 손절 피보나치 비율 (%) - 기본 33.3%
  int fixedOrderCount; // 고정 카운트 가산치
  double baseOrderSize; // 기본 주문 수량 단위
  double posLowPrice; // 포지션 최저가 기준선

  bool isSimulation; // 모의투자 여부 (API 키 없이 테스트 가능)

  GridConfig({
    this.symbol = 'BTCUSDT',
    this.leverage = 3,
    this.openOrderPer = 0.34,
    this.closeOrderPer = 0.34,
    this.canclePer = 1.74,
    this.overlapPer = 0.074,
    this.orderDepth = 4,
    this.stoplossFibonacci = 33.3,
    this.fixedOrderCount = 0,
    this.baseOrderSize = 0.002, // 0.002 BTC or 1 contract
    this.posLowPrice = 0.0,
    this.isSimulation = true,
  });

  /// 원본 C# SettingAPI.GET_ORDER_SIZE 공식
  /// 주문 누적 개수에 따른 마틴게일/피라미딩 수량 계산
  double calculateOrderSize(int currentFilledCount) {
    int totalCount = currentFilledCount + fixedOrderCount;
    int multiplier = 1;

    if (totalCount < 50) {
      multiplier = 1;
    } else if (totalCount < 100) {
      multiplier = 2;
    } else if (totalCount < 150) {
      multiplier = 4;
    } else if (totalCount < 200) {
      multiplier = 7;
    } else {
      multiplier = 11;
    }

    return baseOrderSize * multiplier * leverage;
  }

  /// 원본 C# BackgorundOrder.GET_ORDER_PRICE_DEPTH
  /// 현재 가격 기준으로 지정된 depth만큼 아래 그리드 매수 가격대 목록 생성
  List<double> calculateGridPrices(double currentPrice) {
    List<double> prices = [];
    for (int i = 1; i <= orderDepth; i++) {
      double targetPrice = currentPrice * (1.0 - (openOrderPer / 100.0) * i);
      prices.add(double.parse(targetPrice.toStringAsFixed(2)));
    }
    return prices;
  }

  /// 원본 C# BitgetAPI.GET_OPENLONG_OVERAP
  /// 기존 걸려있는 주문과의 중복 여부 확인
  bool isPriceOverlap(double targetPrice, List<double> existingPrices) {
    for (double price in existingPrices) {
      double gap = (price - targetPrice).abs();
      double threshold = targetPrice * (overlapPer / 100.0);
      if (gap <= threshold) {
        return true; // 오차 범위 내에 이미 주문 존재
      }
    }
    return false;
  }

  /// 원본 C# Rf_Range_OpenLong
  /// 현재 시장가와 너무 멀어진 주문 취소 여부 판정 (> canclePer %)
  bool shouldCancelOpenOrder(double orderPrice, double currentPrice) {
    double diffPer = ((currentPrice - orderPrice) / currentPrice) * 100.0;
    return diffPer > canclePer;
  }

  Map<String, dynamic> toMap() {
    return {
      'symbol': symbol,
      'leverage': leverage,
      'openOrderPer': openOrderPer,
      'closeOrderPer': closeOrderPer,
      'canclePer': canclePer,
      'overlapPer': overlapPer,
      'orderDepth': orderDepth,
      'stoplossFibonacci': stoplossFibonacci,
      'fixedOrderCount': fixedOrderCount,
      'baseOrderSize': baseOrderSize,
      'posLowPrice': posLowPrice,
      'isSimulation': isSimulation,
    };
  }

  factory GridConfig.fromMap(Map<String, dynamic> map) {
    return GridConfig(
      symbol: map['symbol'] ?? 'BTCUSDT',
      leverage: (map['leverage'] as num?)?.toInt() ?? 3,
      openOrderPer: (map['openOrderPer'] as num?)?.toDouble() ?? 0.34,
      closeOrderPer: (map['closeOrderPer'] as num?)?.toDouble() ?? 0.34,
      canclePer: (map['canclePer'] as num?)?.toDouble() ?? 1.74,
      overlapPer: (map['overlapPer'] as num?)?.toDouble() ?? 0.074,
      orderDepth: (map['orderDepth'] as num?)?.toInt() ?? 4,
      stoplossFibonacci: (map['stoplossFibonacci'] as num?)?.toDouble() ?? 33.3,
      fixedOrderCount: (map['fixedOrderCount'] as num?)?.toInt() ?? 0,
      baseOrderSize: (map['baseOrderSize'] as num?)?.toDouble() ?? 0.002,
      posLowPrice: (map['posLowPrice'] as num?)?.toDouble() ?? 0.0,
      isSimulation: map['isSimulation'] ?? true,
    );
  }
}

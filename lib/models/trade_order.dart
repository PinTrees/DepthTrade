enum OrderSide {
  openLong, // 매수 (그리드 진입)
  closeLong, // 매도 (청산 / 익절)
}

enum OrderStatus {
  live, // 미체결
  filled, // 체결완료
  cancelled, // 취소됨
  closed, // 포지션 청산 완료
}

class TradeOrder {
  final String orderId;
  final String clientOid;
  final String symbol;
  final OrderSide side;
  final double price;
  final double size; // 계약 수량
  double filledSize;
  double avgPrice;
  OrderStatus status;
  final DateTime createdAt;
  DateTime? updatedAt;

  // 페어 매칭용 (어떤 매수 주문에 대응하는 매도 주문인지)
  String? parentOrderId;
  double realizedPnl;

  TradeOrder({
    required this.orderId,
    required this.clientOid,
    required this.symbol,
    required this.side,
    required this.price,
    required this.size,
    this.filledSize = 0,
    this.avgPrice = 0,
    this.status = OrderStatus.live,
    required this.createdAt,
    this.updatedAt,
    this.parentOrderId,
    this.realizedPnl = 0.0,
  });

  Map<String, dynamic> toMap() {
    return {
      'orderId': orderId,
      'clientOid': clientOid,
      'symbol': symbol,
      'side': side.name,
      'price': price,
      'size': size,
      'filledSize': filledSize,
      'avgPrice': avgPrice,
      'status': status.name,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
      'parentOrderId': parentOrderId,
      'realizedPnl': realizedPnl,
    };
  }

  factory TradeOrder.fromMap(Map<String, dynamic> map) {
    return TradeOrder(
      orderId: map['orderId'] ?? '',
      clientOid: map['clientOid'] ?? '',
      symbol: map['symbol'] ?? 'BTCUSDT',
      side: OrderSide.values.firstWhere(
        (e) => e.name == map['side'],
        orElse: () => OrderSide.openLong,
      ),
      price: (map['price'] as num?)?.toDouble() ?? 0.0,
      size: (map['size'] as num?)?.toDouble() ?? 1.0,
      filledSize: (map['filledSize'] as num?)?.toDouble() ?? 0.0,
      avgPrice: (map['avgPrice'] as num?)?.toDouble() ?? 0.0,
      status: OrderStatus.values.firstWhere(
        (e) => e.name == map['status'],
        orElse: () => OrderStatus.live,
      ),
      createdAt: map['createdAt'] != null
          ? DateTime.parse(map['createdAt'])
          : DateTime.now(),
      updatedAt: map['updatedAt'] != null
          ? DateTime.parse(map['updatedAt'])
          : null,
      parentOrderId: map['parentOrderId'],
      realizedPnl: (map['realizedPnl'] as num?)?.toDouble() ?? 0.0,
    );
  }
}

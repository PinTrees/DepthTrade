import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';
import '../models/account_position.dart';
import '../models/grid_config.dart';
import '../models/trade_order.dart';
import '../service/bitget_api_service.dart';
import '../service/firestore_service.dart';

class GridBotEngine extends ChangeNotifier {
  static final GridBotEngine instance = GridBotEngine._();
  GridBotEngine._();

  final _uuid = const Uuid();

  GridConfig config = GridConfig();
  AccountPosition account = AccountPosition();

  bool isRunning = false;
  bool isStopping = false; // 긴급 정지 / 주문 취소 중

  double currentPrice = 0.0;
  DateTime lastUpdateTime = DateTime.now();
  String systemLog = '준비 완료. [자동매매 시작]을 눌러 그리드 봇을 가동하세요.';

  // 주문 목록
  List<TradeOrder> liveOrders = []; // 미체결 매수 주문 (Open Long)
  List<TradeOrder> liveCloseOrders = []; // 미체결 익절 매도 주문 (Close Long)
  List<TradeOrder> filledOrders = []; // 체결된 매수 주문 목록
  List<TradeOrder> closedHistory = []; // 청산 완료된 페어 주문 이력

  Timer? _tickerTimer;
  Timer? _tradeLoopTimer;

  void initialize(GridConfig? initialConfig) {
    if (initialConfig != null) {
      config = initialConfig;
    }
    _startPriceTicker();
  }

  void updateConfig(GridConfig newConfig) {
    config = newConfig;
    FirestoreService.instance.saveConfig(config);
    notifyListeners();
  }

  /// 가격 주기적 갱신
  void _startPriceTicker() {
    _tickerTimer?.cancel();
    _tickerTimer = Timer.periodic(const Duration(seconds: 2), (_) async {
      final price = await BitgetApiService.instance.getMarketPrice(config.symbol);
      if (price != null && price > 0) {
        currentPrice = price;
        lastUpdateTime = DateTime.now();

        if (config.posLowPrice == 0 || config.posLowPrice > currentPrice) {
          config.posLowPrice = currentPrice;
        }

        account.updateUnrealizedPnl(currentPrice);
        notifyListeners();
      }
    });
  }

  /// 자동매매 시작 (C# TR_START)
  void startBot() {
    if (isRunning) return;
    isRunning = true;
    isStopping = false;
    systemLog = '자동매매 봇 시작됨: 그리드 감시 활성화 (${config.symbol})';
    notifyListeners();

    _tradeLoopTimer?.cancel();
    _tradeLoopTimer = Timer.periodic(const Duration(milliseconds: 1500), (_) {
      _executeTradeCycle();
    });
  }

  /// 자동매매 정지
  void stopBot() {
    isRunning = false;
    _tradeLoopTimer?.cancel();
    systemLog = '자동매매 봇 일시정지됨.';
    notifyListeners();
  }

  /// 모든 미체결 주문 일괄 취소 (C# TR_CloseLiveOrders)
  Future<void> emergencyCancelAll() async {
    isStopping = true;
    systemLog = '긴급 정지: 모든 미체결 주문을 일괄 취소합니다...';
    notifyListeners();

    if (!config.isSimulation && BitgetApiService.instance.hasCredentials) {
      await BitgetApiService.instance.cancelAllOrders(config.symbol);
    }

    for (var o in liveOrders) {
      o.status = OrderStatus.cancelled;
      o.updatedAt = DateTime.now();
    }
    for (var o in liveCloseOrders) {
      o.status = OrderStatus.cancelled;
      o.updatedAt = DateTime.now();
    }

    liveOrders.clear();
    liveCloseOrders.clear();

    stopBot();
    isStopping = false;
    systemLog = '모든 미체결 주문이 취소되었습니다.';
    notifyListeners();
  }

  /// 단일 거래 사이클 실행 (C# Update_AutoTrade)
  Future<void> _executeTradeCycle() async {
    if (!isRunning || isStopping || currentPrice <= 0) return;

    try {
      // 1. 시뮬레이션 모드: 가격 도달 시 체결 체크
      if (config.isSimulation) {
        _simulateFills();
      }

      // 2. 이격도가 깊은 미체결 매수 주문 취소 (C# Rf_Range_OpenLong)
      _cancelStaleOrders();

      // 3. 신규 매수 그리드 주문 계산 및 생성 (C# Rf_Start_OpenLong)
      _placeNewGridOrders();

      notifyListeners();
    } catch (e) {
      systemLog = '사이클 오류: $e';
      notifyListeners();
    }
  }

  /// 시뮬레이션 체결 검증 로직
  void _simulateFills() {
    // 1) 매수 주문 체결 체크 (현재가가 매수가 이하로 떨어졌을 때)
    final buyFilled = liveOrders.where((o) => currentPrice <= o.price).toList();
    for (var order in buyFilled) {
      liveOrders.remove(order);
      order.status = OrderStatus.filled;
      order.filledSize = order.size;
      order.avgPrice = order.price;
      order.updatedAt = DateTime.now();
      filledOrders.add(order);

      // 계좌 포지션 업데이트
      double totalCost = (account.avgPrice * account.holdSize) + (order.price * order.size);
      account.holdSize += order.size;
      account.avgPrice = account.holdSize > 0 ? totalCost / account.holdSize : 0.0;
      account.equity -= (order.price * order.size * 0.0006); // 가상 수수료 반영 (0.06%)

      systemLog = '[매수체결] ${order.price.toStringAsFixed(1)} USDT (${order.size} 수량)';

      // 2) 매수 체결 즉시 상단 익절 매도 주문(Close Long) 생성 (C# Rf_Update_CloseLong)
      double takeProfitPrice = order.price * (1.0 + (config.closeOrderPer / 100.0));
      final closeOrder = TradeOrder(
        orderId: 'CL-${_uuid.v4().substring(0, 8)}',
        clientOid: 'cl-${DateTime.now().millisecondsSinceEpoch}',
        symbol: config.symbol,
        side: OrderSide.closeLong,
        price: double.parse(takeProfitPrice.toStringAsFixed(2)),
        size: order.size,
        status: OrderStatus.live,
        createdAt: DateTime.now(),
        parentOrderId: order.orderId,
      );
      liveCloseOrders.add(closeOrder);
    }

    // 2) 매도 익절 주문 체결 체크 (현재가가 목표가 이상 도달했을 때)
    final sellFilled = liveCloseOrders.where((o) => currentPrice >= o.price).toList();
    for (var closeOrder in sellFilled) {
      liveCloseOrders.remove(closeOrder);
      closeOrder.status = OrderStatus.closed;
      closeOrder.filledSize = closeOrder.size;
      closeOrder.avgPrice = closeOrder.price;
      closeOrder.updatedAt = DateTime.now();

      // 대응하는 매수 주문 찾기
      final parent = filledOrders.firstWhere(
        (o) => o.orderId == closeOrder.parentOrderId,
        orElse: () => closeOrder,
      );
      filledOrders.remove(parent);

      // 실현 손익 계산: (매도가 - 매수가) * 수량
      double profit = (closeOrder.price - parent.price) * closeOrder.size;
      closeOrder.realizedPnl = profit;
      account.realizedPnl += profit;
      account.equity += profit;
      account.pairTradeCount++;
      account.holdSize = (account.holdSize - closeOrder.size).clamp(0.0, 999999.0);

      closedHistory.insert(0, closeOrder);
      systemLog = '[익절완료] ${closeOrder.price.toStringAsFixed(1)} USDT (수익: +${profit.toStringAsFixed(2)} USDT)';
    }

    account.updateUnrealizedPnl(currentPrice);
  }

  /// 시장가와 이격도가 벌어진 미체결 매수 주문 취소 (C# Rf_Range_OpenLong)
  void _cancelStaleOrders() {
    final toRemove = <TradeOrder>[];
    for (var order in liveOrders) {
      if (config.shouldCancelOpenOrder(order.price, currentPrice)) {
        order.status = OrderStatus.cancelled;
        toRemove.add(order);
      }
    }
    for (var order in toRemove) {
      liveOrders.remove(order);
      systemLog = '[주문취소] 이격초과 취소: ${order.price.toStringAsFixed(1)} USDT';
    }
  }

  /// 신규 그리드 주문 배치 (C# Rf_Start_OpenLong)
  void _placeNewGridOrders() {
    if (liveOrders.length >= config.orderDepth) return;

    // 현재가 기반 그리드 가격대 계산
    final gridPrices = config.calculateGridPrices(currentPrice);
    final existingPrices = liveOrders.map((o) => o.price).toList();

    int added = 0;
    for (double price in gridPrices) {
      if (liveOrders.length >= config.orderDepth) break;

      // 이미 해당 가격대에 주문이 있는지 오차 체크 (overlapPer)
      if (!config.isPriceOverlap(price, existingPrices)) {
        double orderSize = config.calculateOrderSize(filledOrders.length);

        final newOrder = TradeOrder(
          orderId: 'ORD-${_uuid.v4().substring(0, 8)}',
          clientOid: 'cl-${DateTime.now().millisecondsSinceEpoch}',
          symbol: config.symbol,
          side: OrderSide.openLong,
          price: price,
          size: double.parse(orderSize.toStringAsFixed(4)),
          status: OrderStatus.live,
          createdAt: DateTime.now(),
        );

        liveOrders.add(newOrder);
        existingPrices.add(price);
        added++;

        // 실계좌 모드인 경우 실제 거래소 API 호출
        if (!config.isSimulation && BitgetApiService.instance.hasCredentials) {
          BitgetApiService.instance.placeOrder(
            symbol: config.symbol,
            side: 'buy',
            orderType: 'limit',
            price: price,
            size: orderSize,
            clientOid: newOrder.clientOid,
          );
        }
      }
    }

    if (added > 0) {
      systemLog = '[그리드생성] $added개 신규 매수대기 배치 완료';
    }
  }

  @override
  void dispose() {
    _tickerTimer?.cancel();
    _tradeLoopTimer?.cancel();
    super.dispose();
  }
}

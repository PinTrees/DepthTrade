import 'dart:math';
import '../models/backtest_result.dart';
import '../models/candle_data.dart';
import '../models/grid_config.dart';

class BacktestEngine {
  static final BacktestEngine instance = BacktestEngine._();
  BacktestEngine._();

  /// 과거 캔들 데이터 기반 그리드 백테스트 시뮬레이션 (C# BackTest.cs)
  BacktestResult runBacktest({
    required List<CandleData> candles,
    required GridConfig config,
    double initialCapital = 10000.0,
  }) {
    if (candles.isEmpty) {
      return BacktestResult(
        initialCapital: initialCapital,
        finalEquity: initialCapital,
        totalProfit: 0,
        returnRate: 0,
        totalTrades: 0,
        winTrades: 0,
        lossTrades: 0,
        winRate: 0,
        maxDrawdown: 0,
        profitFactor: 0,
        equityCurve: [],
        tradeLogs: [],
      );
    }

    double equity = initialCapital;
    double peakEquity = initialCapital;
    double maxDrawdownPer = 0.0;

    int totalTrades = 0;
    int winTrades = 0;
    int lossTrades = 0;
    double grossProfit = 0.0;
    double grossLoss = 0.0;

    List<EquityPoint> equityCurve = [];
    List<Map<String, dynamic>> tradeLogs = [];

    // 가상 포지션 & 미체결 주문
    List<double> liveBuyOrders = [];
    // 매수 체결된 목록: [{buyPrice, size, targetSellPrice}]
    List<Map<String, double>> openPositions = [];

    for (var candle in candles) {
      // 1. 기존 매도 익절 체크 (캔들의 high가 목표가 이상인 경우)
      List<Map<String, double>> remainingPositions = [];
      for (var pos in openPositions) {
        if (candle.high >= pos['targetSellPrice']!) {
          // 익절 성공!
          double pnl = (pos['targetSellPrice']! - pos['buyPrice']!) * pos['size']!;
          double fee = (pos['targetSellPrice']! + pos['buyPrice']!) * pos['size']! * 0.0006;
          double netPnl = pnl - fee;

          equity += netPnl;
          totalTrades++;
          if (netPnl > 0) {
            winTrades++;
            grossProfit += netPnl;
          } else {
            lossTrades++;
            grossLoss += netPnl.abs();
          }

          tradeLogs.add({
            'time': candle.time.toIso8601String(),
            'buyPrice': pos['buyPrice'],
            'sellPrice': pos['targetSellPrice'],
            'pnl': netPnl,
            'equity': equity,
          });
        } else {
          remainingPositions.add(pos);
        }
      }
      openPositions = remainingPositions;

      // 2. 미체결 매수 주문 체결 체크 (캔들의 low가 매수가 이하인 경우)
      List<double> stillLiveOrders = [];
      for (var buyPrice in liveBuyOrders) {
        if (candle.low <= buyPrice) {
          // 매수 체결!
          double size = config.calculateOrderSize(openPositions.length);
          double targetSell = buyPrice * (1.0 + (config.closeOrderPer / 100.0));
          openPositions.add({
            'buyPrice': buyPrice,
            'size': size,
            'targetSellPrice': targetSell,
          });
        } else {
          // 이격도 체크 (> canclePer %) 초과 시 주문 취소
          if (!config.shouldCancelOpenOrder(buyPrice, candle.close)) {
            stillLiveOrders.add(buyPrice);
          }
        }
      }
      liveBuyOrders = stillLiveOrders;

      // 3. 신규 그리드 매수 주문 배치
      final gridPrices = config.calculateGridPrices(candle.close);
      for (var price in gridPrices) {
        if (liveBuyOrders.length >= config.orderDepth) break;
        if (!config.isPriceOverlap(price, liveBuyOrders)) {
          liveBuyOrders.add(price);
        }
      }

      // 4. 미실현 손익 반영한 현재 자산 가치 평가
      double unrealizedPnl = 0.0;
      for (var pos in openPositions) {
        unrealizedPnl += (candle.close - pos['buyPrice']!) * pos['size']!;
      }
      double currentTotalEquity = equity + unrealizedPnl;

      // MDD 계산
      peakEquity = max(peakEquity, currentTotalEquity);
      double currentDrawdown = ((peakEquity - currentTotalEquity) / peakEquity) * 100.0;
      maxDrawdownPer = max(maxDrawdownPer, currentDrawdown);

      equityCurve.add(EquityPoint(
        time: candle.time,
        equity: currentTotalEquity,
        price: candle.close,
      ));
    }

    double finalEquity = equityCurve.isNotEmpty ? equityCurve.last.equity : equity;
    double totalProfit = finalEquity - initialCapital;
    double returnRate = (totalProfit / initialCapital) * 100.0;
    double winRate = totalTrades > 0 ? (winTrades / totalTrades) * 100.0 : 0.0;
    double profitFactor = grossLoss > 0 ? (grossProfit / grossLoss) : (grossProfit > 0 ? 99.0 : 1.0);

    return BacktestResult(
      initialCapital: initialCapital,
      finalEquity: finalEquity,
      totalProfit: totalProfit,
      returnRate: returnRate,
      totalTrades: totalTrades,
      winTrades: winTrades,
      lossTrades: lossTrades,
      winRate: winRate,
      maxDrawdown: maxDrawdownPer,
      profitFactor: profitFactor,
      equityCurve: equityCurve,
      tradeLogs: tradeLogs,
    );
  }
}

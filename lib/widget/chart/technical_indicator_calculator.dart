import 'dart:math';
import '../../models/candle_data.dart';

class TechnicalIndicators {
  final List<double?> ma7;
  final List<double?> ma25;
  final List<double?> ma99;
  final List<double?> ema20;
  final List<double?> bbUpper;
  final List<double?> bbMid;
  final List<double?> bbLower;
  final List<double?> rsi14;
  final List<double?> macd;
  final List<double?> macdSignal;
  final List<double?> macdHist;
  final List<double?> volMa20;

  const TechnicalIndicators({
    required this.ma7,
    required this.ma25,
    required this.ma99,
    required this.ema20,
    required this.bbUpper,
    required this.bbMid,
    required this.bbLower,
    required this.rsi14,
    required this.macd,
    required this.macdSignal,
    required this.macdHist,
    required this.volMa20,
  });

  factory TechnicalIndicators.empty(int len) {
    return TechnicalIndicators(
      ma7: List.filled(len, null),
      ma25: List.filled(len, null),
      ma99: List.filled(len, null),
      ema20: List.filled(len, null),
      bbUpper: List.filled(len, null),
      bbMid: List.filled(len, null),
      bbLower: List.filled(len, null),
      rsi14: List.filled(len, null),
      macd: List.filled(len, null),
      macdSignal: List.filled(len, null),
      macdHist: List.filled(len, null),
      volMa20: List.filled(len, null),
    );
  }
}

class TechnicalIndicatorCalculator {
  /// 초고속 지표 계산
  static TechnicalIndicators compute(List<CandleData> candles) {
    final len = candles.length;
    if (len == 0) return TechnicalIndicators.empty(0);

    // 1. Moving Averages
    final ma7 = _computeSMA(candles, 7);
    final ma25 = _computeSMA(candles, 25);
    final ma99 = _computeSMA(candles, 99);
    final ema20 = _computeEMA(candles, 20);

    // 2. Bollinger Bands (20, 2.0)
    final bb = _computeBollinger(candles, 20, 2.0);

    // 3. RSI (14)
    final rsi = _computeRSI(candles, 14);

    // 4. MACD (12, 26, 9)
    final macdData = _computeMACD(candles, 12, 26, 9);

    // 5. Volume MA (20)
    final volMa = _computeVolSMA(candles, 20);

    return TechnicalIndicators(
      ma7: ma7,
      ma25: ma25,
      ma99: ma99,
      ema20: ema20,
      bbUpper: bb['upper']!,
      bbMid: bb['mid']!,
      bbLower: bb['lower']!,
      rsi14: rsi,
      macd: macdData['macd']!,
      macdSignal: macdData['signal']!,
      macdHist: macdData['hist']!,
      volMa20: volMa,
    );
  }

  // 단순이동평균 (SMA)
  static List<double?> _computeSMA(List<CandleData> candles, int period) {
    final len = candles.length;
    final List<double?> res = List.filled(len, null);
    double sum = 0;

    for (int i = 0; i < len; i++) {
      sum += candles[i].close;
      if (i >= period) {
        sum -= candles[i - period].close;
      }
      if (i >= period - 1) {
        res[i] = sum / period;
      }
    }
    return res;
  }

  // 지수이동평균 (EMA)
  static List<double?> _computeEMA(List<CandleData> candles, int period) {
    final len = candles.length;
    final List<double?> res = List.filled(len, null);
    if (len < period) return res;

    final k = 2.0 / (period + 1.0);
    double prevEma = 0.0;

    // 초기 SMA로 시작
    double sum = 0.0;
    for (int i = 0; i < period; i++) {
      sum += candles[i].close;
    }
    prevEma = sum / period;
    res[period - 1] = prevEma;

    for (int i = period; i < len; i++) {
      prevEma = (candles[i].close * k) + (prevEma * (1.0 - k));
      res[i] = prevEma;
    }
    return res;
  }

  // 볼린저 밴드 (Bollinger Bands)
  static Map<String, List<double?>> _computeBollinger(
      List<CandleData> candles, int period, double stdDevMultiplier) {
    final len = candles.length;
    final List<double?> upper = List.filled(len, null);
    final List<double?> mid = List.filled(len, null);
    final List<double?> lower = List.filled(len, null);

    for (int i = period - 1; i < len; i++) {
      double sum = 0;
      for (int j = i - period + 1; j <= i; j++) {
        sum += candles[j].close;
      }
      final mean = sum / period;
      double varSum = 0;
      for (int j = i - period + 1; j <= i; j++) {
        varSum += pow(candles[j].close - mean, 2);
      }
      final std = sqrt(varSum / period);
      mid[i] = mean;
      upper[i] = mean + (std * stdDevMultiplier);
      lower[i] = mean - (std * stdDevMultiplier);
    }

    return {'upper': upper, 'mid': mid, 'lower': lower};
  }

  // RSI (Relative Strength Index 14)
  static List<double?> _computeRSI(List<CandleData> candles, int period) {
    final len = candles.length;
    final List<double?> res = List.filled(len, null);
    if (len <= period) return res;

    double gainSum = 0;
    double lossSum = 0;

    for (int i = 1; i <= period; i++) {
      final diff = candles[i].close - candles[i - 1].close;
      if (diff >= 0) {
        gainSum += diff;
      } else {
        lossSum += diff.abs();
      }
    }

    double avgGain = gainSum / period;
    double avgLoss = lossSum / period;

    res[period] = avgLoss == 0 ? 100.0 : 100.0 - (100.0 / (1.0 + (avgGain / avgLoss)));

    for (int i = period + 1; i < len; i++) {
      final diff = candles[i].close - candles[i - 1].close;
      final gain = diff >= 0 ? diff : 0.0;
      final loss = diff < 0 ? diff.abs() : 0.0;

      avgGain = ((avgGain * (period - 1)) + gain) / period;
      avgLoss = ((avgLoss * (period - 1)) + loss) / period;

      if (avgLoss == 0) {
        res[i] = 100.0;
      } else {
        final rs = avgGain / avgLoss;
        res[i] = 100.0 - (100.0 / (1.0 + rs));
      }
    }

    return res;
  }

  // MACD (Moving Average Convergence Divergence)
  static Map<String, List<double?>> _computeMACD(
      List<CandleData> candles, int fastP, int slowP, int signalP) {
    final len = candles.length;
    final List<double?> macd = List.filled(len, null);
    final List<double?> signal = List.filled(len, null);
    final List<double?> hist = List.filled(len, null);

    final fastEMA = _computeEMA(candles, fastP);
    final slowEMA = _computeEMA(candles, slowP);

    for (int i = 0; i < len; i++) {
      if (fastEMA[i] != null && slowEMA[i] != null) {
        macd[i] = fastEMA[i]! - slowEMA[i]!;
      }
    }

    // MACD 라인의 EMA 구하기 (Signal Line)
    final k = 2.0 / (signalP + 1.0);
    double prevSignal = 0.0;
    int firstValidIndex = -1;

    for (int i = 0; i < len; i++) {
      if (macd[i] != null) {
        if (firstValidIndex == -1) firstValidIndex = i;
        final count = i - firstValidIndex + 1;
        if (count == signalP) {
          double sum = 0.0;
          for (int j = i - signalP + 1; j <= i; j++) {
            sum += macd[j]!;
          }
          prevSignal = sum / signalP;
          signal[i] = prevSignal;
          hist[i] = macd[i]! - signal[i]!;
        } else if (count > signalP) {
          prevSignal = (macd[i]! * k) + (prevSignal * (1.0 - k));
          signal[i] = prevSignal;
          hist[i] = macd[i]! - signal[i]!;
        }
      }
    }

    return {'macd': macd, 'signal': signal, 'hist': hist};
  }

  // 거래량 이동평균
  static List<double?> _computeVolSMA(List<CandleData> candles, int period) {
    final len = candles.length;
    final List<double?> res = List.filled(len, null);
    double sum = 0;

    for (int i = 0; i < len; i++) {
      sum += candles[i].volume;
      if (i >= period) {
        sum -= candles[i - period].volume;
      }
      if (i >= period - 1) {
        res[i] = sum / period;
      }
    }
    return res;
  }
}

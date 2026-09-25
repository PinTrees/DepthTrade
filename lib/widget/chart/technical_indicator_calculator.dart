import 'dart:math';
import '../../models/candle_data.dart';

class TechnicalIndicators {
  // 1. Moving Averages (SMA & EMA)
  final List<double?> ma7;
  final List<double?> ma25;
  final List<double?> ma99;
  final List<double?> ma200;
  final List<double?> ema9;
  final List<double?> ema21;
  final List<double?> ema50;
  final List<double?> ema200;

  // 2. Bollinger Bands (20, 2.0)
  final List<double?> bbUpper;
  final List<double?> bbMid;
  final List<double?> bbLower;

  // 3. Parabolic SAR (0.02, 0.20)
  final List<double?> sar;
  final List<bool> sarIsBull;

  // 4. SuperTrend (10, 3.0)
  final List<double?> superTrend;
  final List<int> superTrendDirection; // +1 = bull, -1 = bear

  // 5. VWAP (Volume Weighted Average Price)
  final List<double?> vwap;

  // 6. Ichimoku Cloud (9, 26, 52)
  final List<double?> ichimokuTenkan; // 전환선 (9)
  final List<double?> ichimokuKijun; // 기준선 (26)
  final List<double?> ichimokuSpanA; // 선행스팬 1
  final List<double?> ichimokuSpanB; // 선행스팬 2 (52)

  // 7. Sub Indicators
  final List<double?> volMa20;
  final List<double?> rsi14;

  // MACD (12, 26, 9)
  final List<double?> macd;
  final List<double?> macdSignal;
  final List<double?> macdHist;

  // KDJ / Stochastic (9, 3, 3)
  final List<double?> kdjK;
  final List<double?> kdjD;
  final List<double?> kdjJ;

  // Williams %R (14)
  final List<double?> wr14;

  // CCI (20)
  final List<double?> cci20;

  // ATR (14)
  final List<double?> atr14;

  // OBV (On-Balance Volume)
  final List<double?> obv;

  // Heikin-Ashi Transformed Candles
  final List<CandleData> heikinAshiCandles;

  const TechnicalIndicators({
    required this.ma7,
    required this.ma25,
    required this.ma99,
    required this.ma200,
    required this.ema9,
    required this.ema21,
    required this.ema50,
    required this.ema200,
    required this.bbUpper,
    required this.bbMid,
    required this.bbLower,
    required this.sar,
    required this.sarIsBull,
    required this.superTrend,
    required this.superTrendDirection,
    required this.vwap,
    required this.ichimokuTenkan,
    required this.ichimokuKijun,
    required this.ichimokuSpanA,
    required this.ichimokuSpanB,
    required this.volMa20,
    required this.rsi14,
    required this.macd,
    required this.macdSignal,
    required this.macdHist,
    required this.kdjK,
    required this.kdjD,
    required this.kdjJ,
    required this.wr14,
    required this.cci20,
    required this.atr14,
    required this.obv,
    required this.heikinAshiCandles,
  });

  factory TechnicalIndicators.empty(int len) {
    return TechnicalIndicators(
      ma7: List.filled(len, null),
      ma25: List.filled(len, null),
      ma99: List.filled(len, null),
      ma200: List.filled(len, null),
      ema9: List.filled(len, null),
      ema21: List.filled(len, null),
      ema50: List.filled(len, null),
      ema200: List.filled(len, null),
      bbUpper: List.filled(len, null),
      bbMid: List.filled(len, null),
      bbLower: List.filled(len, null),
      sar: List.filled(len, null),
      sarIsBull: List.filled(len, true),
      superTrend: List.filled(len, null),
      superTrendDirection: List.filled(len, 1),
      vwap: List.filled(len, null),
      ichimokuTenkan: List.filled(len, null),
      ichimokuKijun: List.filled(len, null),
      ichimokuSpanA: List.filled(len, null),
      ichimokuSpanB: List.filled(len, null),
      volMa20: List.filled(len, null),
      rsi14: List.filled(len, null),
      macd: List.filled(len, null),
      macdSignal: List.filled(len, null),
      macdHist: List.filled(len, null),
      kdjK: List.filled(len, null),
      kdjD: List.filled(len, null),
      kdjJ: List.filled(len, null),
      wr14: List.filled(len, null),
      cci20: List.filled(len, null),
      atr14: List.filled(len, null),
      obv: List.filled(len, null),
      heikinAshiCandles: [],
    );
  }
}

/// 오픈소스 TA-Lib / TradingView / k_chart 표준 수식을 순수 Dart로 100% 직접 구현한 지표 엔진
class TechnicalIndicatorCalculator {
  static TechnicalIndicators compute(List<CandleData> candles) {
    final len = candles.length;
    if (len == 0) return TechnicalIndicators.empty(0);

    // 1. Moving Averages
    final ma7 = _computeSMA(candles, 7);
    final ma25 = _computeSMA(candles, 25);
    final ma99 = _computeSMA(candles, 99);
    final ma200 = _computeSMA(candles, 200);

    final ema9 = _computeEMA(candles, 9);
    final ema21 = _computeEMA(candles, 21);
    final ema50 = _computeEMA(candles, 50);
    final ema200 = _computeEMA(candles, 200);

    // 2. Bollinger Bands (20, 2.0)
    final bb = _computeBollinger(candles, 20, 2.0);

    // 3. Parabolic SAR (0.02, 0.20)
    final sarData = _computeParabolicSAR(candles, 0.02, 0.20);

    // 4. ATR (14)
    final atr14 = _computeATR(candles, 14);

    // 5. SuperTrend (10, 3.0)
    final superTrendData = _computeSuperTrend(candles, 10, 3.0, atr14);

    // 6. VWAP
    final vwap = _computeVWAP(candles);

    // 7. Ichimoku Cloud (9, 26, 52)
    final ichimoku = _computeIchimoku(candles, 9, 26, 52);

    // 8. RSI (14)
    final rsi = _computeRSI(candles, 14);

    // 9. MACD (12, 26, 9)
    final macdData = _computeMACD(candles, 12, 26, 9);

    // 10. Volume MA (20)
    final volMa = _computeVolSMA(candles, 20);

    // 11. KDJ (9, 3, 3)
    final kdjData = _computeKDJ(candles, 9, 3, 3);

    // 12. Williams %R (14)
    final wr14 = _computeWilliamsR(candles, 14);

    // 13. CCI (20)
    final cci20 = _computeCCI(candles, 20);

    // 14. OBV
    final obv = _computeOBV(candles);

    // 15. Heikin-Ashi Candles
    final heikinAshi = _computeHeikinAshi(candles);

    return TechnicalIndicators(
      ma7: ma7,
      ma25: ma25,
      ma99: ma99,
      ma200: ma200,
      ema9: ema9,
      ema21: ema21,
      ema50: ema50,
      ema200: ema200,
      bbUpper: bb['upper']!,
      bbMid: bb['mid']!,
      bbLower: bb['lower']!,
      sar: sarData['sar'] as List<double?>,
      sarIsBull: sarData['isBull'] as List<bool>,
      superTrend: superTrendData['trend'] as List<double?>,
      superTrendDirection: superTrendData['dir'] as List<int>,
      vwap: vwap,
      ichimokuTenkan: ichimoku['tenkan']!,
      ichimokuKijun: ichimoku['kijun']!,
      ichimokuSpanA: ichimoku['spanA']!,
      ichimokuSpanB: ichimoku['spanB']!,
      volMa20: volMa,
      rsi14: rsi,
      macd: macdData['macd']!,
      macdSignal: macdData['signal']!,
      macdHist: macdData['hist']!,
      kdjK: kdjData['k']!,
      kdjD: kdjData['d']!,
      kdjJ: kdjData['j']!,
      wr14: wr14,
      cci20: cci20,
      atr14: atr14,
      obv: obv,
      heikinAshiCandles: heikinAshi,
    );
  }

  // --- 1. 단순이동평균 (SMA) ---
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

  // --- 2. 지수이동평균 (EMA) ---
  static List<double?> _computeEMA(List<CandleData> candles, int period) {
    final len = candles.length;
    final List<double?> res = List.filled(len, null);
    if (len < period) return res;

    final k = 2.0 / (period + 1.0);
    double sum = 0.0;
    for (int i = 0; i < period; i++) {
      sum += candles[i].close;
    }
    double prevEma = sum / period;
    res[period - 1] = prevEma;

    for (int i = period; i < len; i++) {
      prevEma = (candles[i].close * k) + (prevEma * (1.0 - k));
      res[i] = prevEma;
    }
    return res;
  }

  // --- 3. 볼린저 밴드 (Bollinger Bands) ---
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

  // --- 4. 파라볼릭 SAR (Parabolic SAR) ---
  static Map<String, dynamic> _computeParabolicSAR(
      List<CandleData> candles, double step, double maxStep) {
    final len = candles.length;
    final List<double?> sar = List.filled(len, null);
    final List<bool> isBull = List.filled(len, true);
    if (len < 2) return {'sar': sar, 'isBull': isBull};

    bool bull = candles[1].close >= candles[0].close;
    double af = step;
    double ep = bull ? max(candles[0].high, candles[1].high) : min(candles[0].low, candles[1].low);
    double curSar = bull ? min(candles[0].low, candles[1].low) : max(candles[0].high, candles[1].high);

    sar[0] = curSar;
    isBull[0] = bull;
    sar[1] = curSar;
    isBull[1] = bull;

    for (int i = 2; i < len; i++) {
      double nextSar = curSar + af * (ep - curSar);

      if (bull) {
        if (i >= 2) {
          nextSar = min(nextSar, min(candles[i - 1].low, candles[i - 2].low));
        }
        if (candles[i].low < nextSar) {
          // Bullish -> Bearish Switch
          bull = false;
          curSar = ep;
          ep = candles[i].low;
          af = step;
        } else {
          curSar = nextSar;
          if (candles[i].high > ep) {
            ep = candles[i].high;
            af = min(af + step, maxStep);
          }
        }
      } else {
        if (i >= 2) {
          nextSar = max(nextSar, max(candles[i - 1].high, candles[i - 2].high));
        }
        if (candles[i].high > nextSar) {
          // Bearish -> Bullish Switch
          bull = true;
          curSar = ep;
          ep = candles[i].high;
          af = step;
        } else {
          curSar = nextSar;
          if (candles[i].low < ep) {
            ep = candles[i].low;
            af = min(af + step, maxStep);
          }
        }
      }
      sar[i] = curSar;
      isBull[i] = bull;
    }

    return {'sar': sar, 'isBull': isBull};
  }

  // --- 5. ATR (Average True Range 14) ---
  static List<double?> _computeATR(List<CandleData> candles, int period) {
    final len = candles.length;
    final List<double?> atr = List.filled(len, null);
    if (len < period + 1) return atr;

    final List<double> tr = List.filled(len, 0.0);
    tr[0] = candles[0].high - candles[0].low;
    for (int i = 1; i < len; i++) {
      final h = candles[i].high;
      final l = candles[i].low;
      final prevC = candles[i - 1].close;
      tr[i] = max(h - l, max((h - prevC).abs(), (l - prevC).abs()));
    }

    double sum = 0.0;
    for (int i = 1; i <= period; i++) {
      sum += tr[i];
    }
    double prevAtr = sum / period;
    atr[period] = prevAtr;

    for (int i = period + 1; i < len; i++) {
      prevAtr = ((prevAtr * (period - 1)) + tr[i]) / period;
      atr[i] = prevAtr;
    }
    return atr;
  }

  // --- 6. SuperTrend (10, 3.0) ---
  static Map<String, dynamic> _computeSuperTrend(
      List<CandleData> candles, int period, double multiplier, List<double?> atr) {
    final len = candles.length;
    final List<double?> st = List.filled(len, null);
    final List<int> dir = List.filled(len, 1); // 1 = Bull, -1 = Bear
    if (len < period + 1) return {'trend': st, 'dir': dir};

    double prevUpper = 0.0;
    double prevLower = 0.0;
    int prevDir = 1;

    for (int i = period; i < len; i++) {
      final curAtr = atr[i] ?? (candles[i].high - candles[i].low);
      final hl2 = (candles[i].high + candles[i].low) / 2.0;
      double basicUpper = hl2 + (multiplier * curAtr);
      double basicLower = hl2 - (multiplier * curAtr);

      double finalUpper = (basicUpper < prevUpper || candles[i - 1].close > prevUpper)
          ? basicUpper
          : prevUpper;
      double finalLower = (basicLower > prevLower || candles[i - 1].close < prevLower)
          ? basicLower
          : prevLower;

      int curDir = prevDir;
      if (prevDir == 1 && candles[i].close < finalLower) {
        curDir = -1;
      } else if (prevDir == -1 && candles[i].close > finalUpper) {
        curDir = 1;
      }

      st[i] = curDir == 1 ? finalLower : finalUpper;
      dir[i] = curDir;

      prevUpper = finalUpper;
      prevLower = finalLower;
      prevDir = curDir;
    }

    return {'trend': st, 'dir': dir};
  }

  // --- 7. VWAP (Volume Weighted Average Price) ---
  static List<double?> _computeVWAP(List<CandleData> candles) {
    final len = candles.length;
    final List<double?> vwap = List.filled(len, null);
    double cumVol = 0.0;
    double cumPriceVol = 0.0;

    for (int i = 0; i < len; i++) {
      final tp = (candles[i].high + candles[i].low + candles[i].close) / 3.0;
      final vol = candles[i].volume;
      cumVol += vol;
      cumPriceVol += (tp * vol);

      if (cumVol > 0) {
        vwap[i] = cumPriceVol / cumVol;
      } else {
        vwap[i] = tp;
      }
    }
    return vwap;
  }

  // --- 8. 일목균형표 (Ichimoku Cloud: 9, 26, 52) ---
  static Map<String, List<double?>> _computeIchimoku(
      List<CandleData> candles, int tenkanP, int kijunP, int senkouP) {
    final len = candles.length;
    final List<double?> tenkan = List.filled(len, null);
    final List<double?> kijun = List.filled(len, null);
    final List<double?> spanA = List.filled(len, null);
    final List<double?> spanB = List.filled(len, null);

    double getMidPrice(int end, int period) {
      double h = candles[end].high;
      double l = candles[end].low;
      for (int k = max(0, end - period + 1); k <= end; k++) {
        if (candles[k].high > h) h = candles[k].high;
        if (candles[k].low < l) l = candles[k].low;
      }
      return (h + l) / 2.0;
    }

    for (int i = 0; i < len; i++) {
      if (i >= tenkanP - 1) {
        tenkan[i] = getMidPrice(i, tenkanP);
      }
      if (i >= kijunP - 1) {
        kijun[i] = getMidPrice(i, kijunP);
      }
      if (tenkan[i] != null && kijun[i] != null) {
        spanA[i] = (tenkan[i]! + kijun[i]!) / 2.0;
      }
      if (i >= senkouP - 1) {
        spanB[i] = getMidPrice(i, senkouP);
      }
    }

    return {'tenkan': tenkan, 'kijun': kijun, 'spanA': spanA, 'spanB': spanB};
  }

  // --- 9. RSI (Wilder's Smoothing 14) ---
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

  // --- 10. MACD (12, 26, 9) ---
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

  // --- 11. KDJ / Stochastic Oscillator (9, 3, 3) ---
  static Map<String, List<double?>> _computeKDJ(
      List<CandleData> candles, int n, int m1, int m2) {
    final len = candles.length;
    final List<double?> kList = List.filled(len, null);
    final List<double?> dList = List.filled(len, null);
    final List<double?> jList = List.filled(len, null);
    if (len < n) return {'k': kList, 'd': dList, 'j': jList};

    double k = 50.0;
    double d = 50.0;

    for (int i = 0; i < len; i++) {
      if (i >= n - 1) {
        double lowN = candles[i].low;
        double highN = candles[i].high;
        for (int j = i - n + 1; j <= i; j++) {
          if (candles[j].low < lowN) lowN = candles[j].low;
          if (candles[j].high > highN) highN = candles[j].high;
        }

        final diff = highN - lowN;
        final rsv = diff == 0.0 ? 50.0 : ((candles[i].close - lowN) / diff) * 100.0;

        k = (k * 2.0 + rsv) / 3.0;
        d = (d * 2.0 + k) / 3.0;
        final j = 3.0 * k - 2.0 * d;

        kList[i] = k;
        dList[i] = d;
        jList[i] = j;
      }
    }

    return {'k': kList, 'd': dList, 'j': jList};
  }

  // --- 12. Williams %R (14) ---
  static List<double?> _computeWilliamsR(List<CandleData> candles, int period) {
    final len = candles.length;
    final List<double?> wr = List.filled(len, null);
    if (len < period) return wr;

    for (int i = period - 1; i < len; i++) {
      double lowN = candles[i].low;
      double highN = candles[i].high;
      for (int j = i - period + 1; j <= i; j++) {
        if (candles[j].low < lowN) lowN = candles[j].low;
        if (candles[j].high > highN) highN = candles[j].high;
      }

      final diff = highN - lowN;
      if (diff == 0.0) {
        wr[i] = -50.0;
      } else {
        wr[i] = ((highN - candles[i].close) / diff) * -100.0;
      }
    }

    return wr;
  }

  // --- 13. CCI (Commodity Channel Index 20) ---
  static List<double?> _computeCCI(List<CandleData> candles, int period) {
    final len = candles.length;
    final List<double?> cci = List.filled(len, null);
    if (len < period) return cci;

    final List<double> tp = candles
        .map((c) => (c.high + c.low + c.close) / 3.0)
        .toList();

    for (int i = period - 1; i < len; i++) {
      double sum = 0.0;
      for (int j = i - period + 1; j <= i; j++) {
        sum += tp[j];
      }
      final smaTp = sum / period;

      double meanDevSum = 0.0;
      for (int j = i - period + 1; j <= i; j++) {
        meanDevSum += (tp[j] - smaTp).abs();
      }
      final md = meanDevSum / period;

      if (md == 0.0) {
        cci[i] = 0.0;
      } else {
        cci[i] = (tp[i] - smaTp) / (0.015 * md);
      }
    }

    return cci;
  }

  // --- 14. OBV (On-Balance Volume) ---
  static List<double?> _computeOBV(List<CandleData> candles) {
    final len = candles.length;
    final List<double?> obv = List.filled(len, null);
    if (len == 0) return obv;

    double curObv = candles[0].volume;
    obv[0] = curObv;

    for (int i = 1; i < len; i++) {
      if (candles[i].close > candles[i - 1].close) {
        curObv += candles[i].volume;
      } else if (candles[i].close < candles[i - 1].close) {
        curObv -= candles[i].volume;
      }
      obv[i] = curObv;
    }

    return obv;
  }

  // --- 15. Heikin-Ashi 변환 ---
  static List<CandleData> _computeHeikinAshi(List<CandleData> candles) {
    final len = candles.length;
    if (len == 0) return [];

    final List<CandleData> ha = [];
    double prevHaOpen = (candles[0].open + candles[0].close) / 2.0;
    double prevHaClose = (candles[0].open + candles[0].high + candles[0].low + candles[0].close) / 4.0;

    ha.add(CandleData(
      time: candles[0].time,
      open: prevHaOpen,
      high: max(candles[0].high, max(prevHaOpen, prevHaClose)),
      low: min(candles[0].low, min(prevHaOpen, prevHaClose)),
      close: prevHaClose,
      volume: candles[0].volume,
    ));

    for (int i = 1; i < len; i++) {
      final curClose = (candles[i].open + candles[i].high + candles[i].low + candles[i].close) / 4.0;
      final curOpen = (prevHaOpen + prevHaClose) / 2.0;
      final curHigh = max(candles[i].high, max(curOpen, curClose));
      final curLow = min(candles[i].low, min(curOpen, curClose));

      ha.add(CandleData(
        time: candles[i].time,
        open: curOpen,
        high: curHigh,
        low: curLow,
        close: curClose,
        volume: candles[i].volume,
      ));

      prevHaOpen = curOpen;
      prevHaClose = curClose;
    }

    return ha;
  }

  // --- 거래량 이동평균 ---
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

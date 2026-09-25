import 'dart:math';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart' hide TextDirection;
import '../../models/candle_data.dart';
import '../../models/trade_order.dart';
import '../../style/app_color.dart';
import 'technical_indicator_calculator.dart';

enum ChartStyle { candles, line }

enum SubIndicator { none, rsi, macd, volume }

class TradingViewChartViewer extends StatefulWidget {
  final List<CandleData> candles;
  final double currentPrice;
  final List<TradeOrder> liveBuyOrders;
  final List<TradeOrder> liveCloseOrders;
  final String activeInterval;
  final ValueChanged<String>? onIntervalChanged;

  const TradingViewChartViewer({
    super.key,
    required this.candles,
    required this.currentPrice,
    required this.liveBuyOrders,
    required this.liveCloseOrders,
    this.activeInterval = '15m',
    this.onIntervalChanged,
  });

  @override
  State<TradingViewChartViewer> createState() => _TradingViewChartViewerState();
}

class _TradingViewChartViewerState extends State<TradingViewChartViewer> {
  // Chart Display Settings
  ChartStyle _chartStyle = ChartStyle.candles;
  bool _showMA = true;
  bool _showBB = false;
  bool _showGridOrders = true;
  SubIndicator _subIndicator = SubIndicator.volume;

  // Computed Indicators Cache
  TechnicalIndicators? _indicators;

  // Viewport & Pan / Zoom State
  int _visibleCount = 60; // 기본 표시 캔들 개수
  int _scrollOffset = 0; // 최신 캔들 기준 과거로 스크롤한 캔들 수 (0 = 최신)
  Offset? _hoverPosition;
  int? _hoveredCandleIndex;

  @override
  void initState() {
    super.initState();
    _recomputeIndicators();
  }

  @override
  void didUpdateWidget(covariant TradingViewChartViewer oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.candles != oldWidget.candles) {
      _recomputeIndicators();
    }
  }

  void _recomputeIndicators() {
    if (widget.candles.isNotEmpty) {
      _indicators = TechnicalIndicatorCalculator.compute(widget.candles);
    }
  }

  void _resetView() {
    setState(() {
      _scrollOffset = 0;
      _visibleCount = 60;
      _hoverPosition = null;
      _hoveredCandleIndex = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (widget.candles.isEmpty && widget.currentPrice <= 0) {
      return Container(
        height: 480,
        decoration: BoxDecoration(
          color: AppColor.backgroundCard,
          borderRadius: BorderRadius.circular(16),
        ),
        child: const Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(color: AppColor.accent),
              SizedBox(height: 14),
              Text(
                '실시간 캔들 데이터 수신 중...',
                style: TextStyle(fontSize: 12, color: AppColor.textSecondary),
              ),
            ],
          ),
        ),
      );
    }

    final totalCandles = widget.candles.length;
    // 계산된 뷰포트 인덱스 범위
    final int safeVisible = _visibleCount.clamp(15, max(15, totalCandles));
    final int safeOffset = _scrollOffset.clamp(0, max(0, totalCandles - safeVisible));

    final int startIdx = max(0, totalCandles - safeVisible - safeOffset);
    final int endIdx = min(totalCandles, startIdx + safeVisible);
    final List<CandleData> visibleCandles = widget.candles.sublist(startIdx, endIdx);

    // 호버 중인 캔들 또는 가장 최신 캔들 정보
    final activeCandle = (_hoveredCandleIndex != null &&
            _hoveredCandleIndex! >= 0 &&
            _hoveredCandleIndex! < widget.candles.length)
        ? widget.candles[_hoveredCandleIndex!]
        : (widget.candles.isNotEmpty ? widget.candles.last : null);

    return Container(
      decoration: BoxDecoration(
        color: AppColor.backgroundCard,
        borderRadius: BorderRadius.circular(16),
        boxShadow: AppColor.subtleShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // 1. TradingView Top Toolbar (Timeframes, Indicators, Chart Style)
          _buildToolbar(),

          // 2. OHLCV & Indicators Live Legend
          _buildLegendBar(activeCandle),

          // 3. Interactive Chart Canvas (Main + Sub Indicator)
          Expanded(
            child: Listener(
              onPointerSignal: (pointerSignal) {
                if (pointerSignal is PointerScrollEvent) {
                  setState(() {
                    if (pointerSignal.scrollDelta.dy < 0) {
                      // Zoom In
                      _visibleCount = (_visibleCount - 4).clamp(15, totalCandles);
                    } else {
                      // Zoom Out
                      _visibleCount = (_visibleCount + 4).clamp(15, totalCandles);
                    }
                  });
                }
              },
              child: GestureDetector(
                onHorizontalDragUpdate: (details) {
                  setState(() {
                    final delta = (details.primaryDelta! / 8).round();
                    _scrollOffset = (_scrollOffset + delta).clamp(0, totalCandles - safeVisible);
                  });
                },
                onDoubleTap: _resetView,
                child: MouseRegion(
                  onHover: (event) {
                    setState(() {
                      _hoverPosition = event.localPosition;
                    });
                  },
                  onExit: (_) {
                    setState(() {
                      _hoverPosition = null;
                      _hoveredCandleIndex = null;
                    });
                  },
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      return CustomPaint(
                        size: Size(constraints.maxWidth, constraints.maxHeight),
                        painter: _TradingViewChartPainter(
                          candles: widget.candles,
                          visibleCandles: visibleCandles,
                          startIndex: startIdx,
                          indicators: _indicators,
                          currentPrice: widget.currentPrice,
                          liveBuyOrders: _showGridOrders ? widget.liveBuyOrders : [],
                          liveCloseOrders: _showGridOrders ? widget.liveCloseOrders : [],
                          chartStyle: _chartStyle,
                          showMA: _showMA,
                          showBB: _showBB,
                          subIndicator: _subIndicator,
                          hoverPosition: _hoverPosition,
                          onHoverCandleIndex: (idx) {
                            if (_hoveredCandleIndex != idx) {
                              WidgetsBinding.instance.addPostFrameCallback((_) {
                                if (mounted) setState(() => _hoveredCandleIndex = idx);
                              });
                            }
                          },
                        ),
                      );
                    },
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // 1. TradingView Top Toolbar
  Widget _buildToolbar() {
    const timeframes = ['1m', '5m', '15m', '1h', '4h', '1D'];

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: AppColor.cardSurface.withValues(alpha: 0.5),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
      ),
      child: Wrap(
        spacing: 8,
        runSpacing: 6,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          // Timeframe Pills
          Row(
            mainAxisSize: MainAxisSize.min,
            children: timeframes.map((tf) {
              final isSel = tf == widget.activeInterval;
              return Padding(
                padding: const EdgeInsets.only(right: 4),
                child: InkWell(
                  onTap: () => widget.onIntervalChanged?.call(tf),
                  borderRadius: BorderRadius.circular(6),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: isSel ? AppColor.primary.withValues(alpha: 0.3) : Colors.transparent,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      tf,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: isSel ? FontWeight.bold : FontWeight.w600,
                        color: isSel ? AppColor.accent : AppColor.textSecondary,
                      ),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),

          // Divider pill
          Container(width: 1, height: 16, color: Colors.white10),

          // Chart Style Toggle (Candles vs Line)
          InkWell(
            onTap: () {
              setState(() {
                _chartStyle = _chartStyle == ChartStyle.candles
                    ? ChartStyle.line
                    : ChartStyle.candles;
              });
            },
            borderRadius: BorderRadius.circular(6),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: AppColor.inputSurface,
                borderRadius: BorderRadius.circular(6),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    _chartStyle == ChartStyle.candles
                        ? Icons.candlestick_chart
                        : Icons.show_chart,
                    size: 14,
                    color: AppColor.accent,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    _chartStyle == ChartStyle.candles ? '봉차트' : '라인차트',
                    style: const TextStyle(fontSize: 11, color: AppColor.textPrimary),
                  ),
                ],
              ),
            ),
          ),

          // Indicator Toggles
          _indicatorToggleChip(
            label: 'MA 7/25/99',
            active: _showMA,
            activeColor: const Color(0xFFFFD700),
            onTap: () => setState(() => _showMA = !_showMA),
          ),
          _indicatorToggleChip(
            label: 'BB (20,2)',
            active: _showBB,
            activeColor: const Color(0xFF2979FF),
            onTap: () => setState(() => _showBB = !_showBB),
          ),
          _indicatorToggleChip(
            label: 'VOL',
            active: _subIndicator == SubIndicator.volume,
            activeColor: AppColor.longGreen,
            onTap: () {
              setState(() {
                _subIndicator = _subIndicator == SubIndicator.volume
                    ? SubIndicator.none
                    : SubIndicator.volume;
              });
            },
          ),
          _indicatorToggleChip(
            label: 'RSI (14)',
            active: _subIndicator == SubIndicator.rsi,
            activeColor: const Color(0xFFBA68C8),
            onTap: () {
              setState(() {
                _subIndicator = _subIndicator == SubIndicator.rsi
                    ? SubIndicator.none
                    : SubIndicator.rsi;
              });
            },
          ),
          _indicatorToggleChip(
            label: 'MACD',
            active: _subIndicator == SubIndicator.macd,
            activeColor: const Color(0xFF00E5FF),
            onTap: () {
              setState(() {
                _subIndicator = _subIndicator == SubIndicator.macd
                    ? SubIndicator.none
                    : SubIndicator.macd;
              });
            },
          ),
          _indicatorToggleChip(
            label: '그리드 오더선',
            active: _showGridOrders,
            activeColor: AppColor.secondary,
            onTap: () => setState(() => _showGridOrders = !_showGridOrders),
          ),

          // Reset View
          IconButton(
            icon: const Icon(Icons.restart_alt, size: 16, color: AppColor.textSecondary),
            tooltip: '초기 뷰로 리셋',
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
            onPressed: _resetView,
          ),
        ],
      ),
    );
  }

  Widget _indicatorToggleChip({
    required String label,
    required bool active,
    required Color activeColor,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(6),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: active ? activeColor.withValues(alpha: 0.15) : AppColor.inputSurface.withValues(alpha: 0.6),
          borderRadius: BorderRadius.circular(6),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 6,
              height: 6,
              decoration: BoxDecoration(
                color: active ? activeColor : AppColor.textDisabled,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 10,
                fontWeight: active ? FontWeight.bold : FontWeight.w500,
                color: active ? Colors.white : AppColor.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // 2. TradingView OHLCV Legend Bar
  Widget _buildLegendBar(CandleData? c) {
    if (c == null) return const SizedBox.shrink();

    final isUp = c.close >= c.open;
    final diff = c.close - c.open;
    final diffPct = c.open > 0 ? (diff / c.open) * 100 : 0.0;
    final color = isUp ? AppColor.longGreen : AppColor.shortRed;
    final timeStr = DateFormat('yyyy-MM-dd HH:mm').format(c.time);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
      child: Wrap(
        spacing: 12,
        runSpacing: 4,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          Text(timeStr, style: const TextStyle(fontSize: 11, color: AppColor.textDisabled, fontFamily: 'monospace')),
          _ohlcItem('시(O)', c.open.toStringAsFixed(1), AppColor.textPrimary),
          _ohlcItem('고(H)', c.high.toStringAsFixed(1), AppColor.textPrimary),
          _ohlcItem('저(L)', c.low.toStringAsFixed(1), AppColor.textPrimary),
          _ohlcItem('종(C)', c.close.toStringAsFixed(1), color),
          Text(
            '${diff >= 0 ? '+' : ''}${diff.toStringAsFixed(1)} (${diffPct.toStringAsFixed(2)}%)',
            style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: color, fontFamily: 'monospace'),
          ),
          _ohlcItem('거래량', c.volume.toStringAsFixed(1), AppColor.textSecondary),

          // Indicator live value tags
          if (_showMA && _indicators != null && _hoveredCandleIndex != null && _hoveredCandleIndex! < _indicators!.ma7.length) ...[
            if (_indicators!.ma7[_hoveredCandleIndex!] != null)
              _indicatorVal('MA7', _indicators!.ma7[_hoveredCandleIndex!]!, const Color(0xFFFFD700)),
            if (_indicators!.ma25[_hoveredCandleIndex!] != null)
              _indicatorVal('MA25', _indicators!.ma25[_hoveredCandleIndex!]!, const Color(0xFFFF4081)),
            if (_indicators!.ma99[_hoveredCandleIndex!] != null)
              _indicatorVal('MA99', _indicators!.ma99[_hoveredCandleIndex!]!, const Color(0xFF00E5FF)),
          ],
        ],
      ),
    );
  }

  Widget _ohlcItem(String label, String val, Color valColor) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text('$label ', style: const TextStyle(fontSize: 10, color: AppColor.textDisabled)),
        Text(val, style: TextStyle(fontSize: 11, fontFamily: 'monospace', fontWeight: FontWeight.bold, color: valColor)),
      ],
    );
  }

  Widget _indicatorVal(String label, double val, Color color) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text('$label: ', style: TextStyle(fontSize: 10, color: color)),
        Text(val.toStringAsFixed(1), style: TextStyle(fontSize: 10, fontFamily: 'monospace', fontWeight: FontWeight.bold, color: color)),
      ],
    );
  }
}

/// 3. TradingView Custom Canvas Painter
class _TradingViewChartPainter extends CustomPainter {
  final List<CandleData> candles;
  final List<CandleData> visibleCandles;
  final int startIndex;
  final TechnicalIndicators? indicators;
  final double currentPrice;
  final List<TradeOrder> liveBuyOrders;
  final List<TradeOrder> liveCloseOrders;
  final ChartStyle chartStyle;
  final bool showMA;
  final bool showBB;
  final SubIndicator subIndicator;
  final Offset? hoverPosition;
  final ValueChanged<int>? onHoverCandleIndex;

  _TradingViewChartPainter({
    required this.candles,
    required this.visibleCandles,
    required this.startIndex,
    required this.indicators,
    required this.currentPrice,
    required this.liveBuyOrders,
    required this.liveCloseOrders,
    required this.chartStyle,
    required this.showMA,
    required this.showBB,
    required this.subIndicator,
    required this.hoverPosition,
    required this.onHoverCandleIndex,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (size.width <= 0 || size.height <= 0 || visibleCandles.isEmpty) return;

    const double yAxisWidth = 72.0;
    const double xAxisHeight = 22.0;

    final double mainWidth = size.width - yAxisWidth;
    final bool hasSub = subIndicator != SubIndicator.none;
    final double subHeight = hasSub ? max(80.0, size.height * 0.24) : 0.0;
    final double mainHeight = size.height - xAxisHeight - subHeight;

    // 1. Min / Max Price in Visible Window
    double minPrice = currentPrice > 0 ? currentPrice : 1000000;
    double maxPrice = currentPrice > 0 ? currentPrice : 0;

    for (var c in visibleCandles) {
      minPrice = min(minPrice, c.low);
      maxPrice = max(maxPrice, c.high);
    }
    for (var o in liveBuyOrders) {
      minPrice = min(minPrice, o.price);
      maxPrice = max(maxPrice, o.price);
    }
    for (var o in liveCloseOrders) {
      minPrice = min(minPrice, o.price);
      maxPrice = max(maxPrice, o.price);
    }

    if (showBB && indicators != null) {
      for (int i = 0; i < visibleCandles.length; i++) {
        final globalIdx = startIndex + i;
        if (globalIdx < indicators!.bbLower.length) {
          final l = indicators!.bbLower[globalIdx];
          final u = indicators!.bbUpper[globalIdx];
          if (l != null) minPrice = min(minPrice, l);
          if (u != null) maxPrice = max(maxPrice, u);
        }
      }
    }

    double pricePadding = (maxPrice - minPrice) * 0.08;
    if (pricePadding <= 0) pricePadding = maxPrice * 0.02;
    minPrice -= pricePadding;
    maxPrice += pricePadding;

    double priceToY(double price) {
      if (maxPrice == minPrice) return mainHeight / 2;
      return mainHeight - ((price - minPrice) / (maxPrice - minPrice)) * mainHeight;
    }

    double yToPrice(double y) {
      return maxPrice - (y / mainHeight) * (maxPrice - minPrice);
    }

    // 2. Draw Background Grid Lines
    _drawGridLines(canvas, size, mainWidth, mainHeight, minPrice, maxPrice);

    // 3. Draw Sub Indicator Separator
    if (hasSub) {
      final sepPaint = Paint()
        ..color = Colors.white.withValues(alpha: 0.08)
        ..strokeWidth = 1.0;
      canvas.drawLine(Offset(0, mainHeight), Offset(mainWidth, mainHeight), sepPaint);
    }

    // 4. Draw Bollinger Bands Area & Lines
    if (showBB && indicators != null) {
      _drawBollingerBands(canvas, mainWidth, startIndex, priceToY);
    }

    // 5. Draw Volume Bars behind candles (if Volume is active in sub or background)
    if (subIndicator == SubIndicator.volume) {
      _drawVolumePanel(canvas, mainWidth, mainHeight, subHeight, startIndex);
    } else if (subIndicator == SubIndicator.rsi) {
      _drawRsiPanel(canvas, mainWidth, mainHeight, subHeight, startIndex);
    } else if (subIndicator == SubIndicator.macd) {
      _drawMacdPanel(canvas, mainWidth, mainHeight, subHeight, startIndex);
    }

    // 6. Draw Candlesticks or Line
    final candleWidth = mainWidth / visibleCandles.length;
    if (chartStyle == ChartStyle.candles) {
      _drawCandles(canvas, candleWidth, priceToY);
    } else {
      _drawLineChart(canvas, mainWidth, candleWidth, priceToY);
    }

    // 7. Draw Moving Averages (MA 7, 25, 99)
    if (showMA && indicators != null) {
      _drawMovingAverages(canvas, mainWidth, startIndex, priceToY);
    }

    // 8. Draw High / Low Tags on Visible Candles
    _drawHighLowMarkers(canvas, candleWidth, priceToY);

    // 9. Draw DepthTrade Dynamic Grid Orders
    _drawGridOrders(canvas, mainWidth, priceToY);

    // 10. Draw Live Current Price Line & Right Badge
    _drawLivePrice(canvas, mainWidth, size.width, priceToY);

    // 11. Crosshair & Hover Interaction
    _drawCrosshair(
      canvas,
      size,
      mainWidth,
      mainHeight,
      candleWidth,
      yToPrice,
    );
  }

  void _drawGridLines(
    Canvas canvas,
    Size size,
    double mainWidth,
    double mainHeight,
    double minPrice,
    double maxPrice,
  ) {
    final gridPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.035)
      ..strokeWidth = 1.0;

    const int steps = 5;
    for (int i = 0; i <= steps; i++) {
      final y = mainHeight * (i / steps);
      canvas.drawLine(Offset(0, y), Offset(mainWidth, y), gridPaint);

      final price = maxPrice - (i / steps) * (maxPrice - minPrice);
      _drawText(
        canvas,
        price.toStringAsFixed(1),
        Offset(mainWidth + 6, y - 6),
        AppColor.textDisabled,
        10,
      );
    }
  }

  void _drawCandles(Canvas canvas, double candleWidth, double Function(double) priceToY) {
    for (int i = 0; i < visibleCandles.length; i++) {
      final c = visibleCandles[i];
      final x = i * candleWidth + (candleWidth / 2);
      final isUp = c.close >= c.open;

      final candleColor = isUp ? AppColor.longGreen : AppColor.shortRed;

      // Wick
      final wickPaint = Paint()
        ..color = candleColor
        ..strokeWidth = max(1.0, candleWidth * 0.12);
      canvas.drawLine(Offset(x, priceToY(c.high)), Offset(x, priceToY(c.low)), wickPaint);

      // Body
      final yOpen = priceToY(c.open);
      final yClose = priceToY(c.close);
      final top = min(yOpen, yClose);
      final height = max(1.5, (yOpen - yClose).abs());
      final bodyW = max(2.0, candleWidth * 0.72);

      final bodyPaint = Paint()
        ..color = candleColor
        ..style = PaintingStyle.fill;
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(x - (bodyW / 2), top, bodyW, height),
          const Radius.circular(1.5),
        ),
        bodyPaint,
      );
    }
  }

  void _drawLineChart(
    Canvas canvas,
    double mainWidth,
    double candleWidth,
    double Function(double) priceToY,
  ) {
    final path = Path();
    final fillPath = Path();

    for (int i = 0; i < visibleCandles.length; i++) {
      final x = i * candleWidth + (candleWidth / 2);
      final y = priceToY(visibleCandles[i].close);

      if (i == 0) {
        path.moveTo(x, y);
        fillPath.moveTo(x, priceToY(visibleCandles[0].close));
      } else {
        path.lineTo(x, y);
        fillPath.lineTo(x, y);
      }
    }

    final linePaint = Paint()
      ..color = AppColor.accent
      ..strokeWidth = 2.0
      ..style = PaintingStyle.stroke;
    canvas.drawPath(path, linePaint);

    // Gradient Area Fill
    if (visibleCandles.isNotEmpty) {
      final lastX = (visibleCandles.length - 1) * candleWidth + (candleWidth / 2);
      fillPath.lineTo(lastX, priceToY(min(visibleCandles.first.low, visibleCandles.last.low) * 0.99));
      fillPath.lineTo(candleWidth / 2, priceToY(min(visibleCandles.first.low, visibleCandles.last.low) * 0.99));
      fillPath.close();

      final fillPaint = Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            AppColor.accent.withValues(alpha: 0.25),
            AppColor.accent.withValues(alpha: 0.0),
          ],
        ).createShader(Rect.fromLTWH(0, 0, mainWidth, mainWidth));
      canvas.drawPath(fillPath, fillPaint);
    }
  }

  void _drawMovingAverages(
    Canvas canvas,
    double mainWidth,
    int startIdx,
    double Function(double) priceToY,
  ) {
    final candleWidth = mainWidth / visibleCandles.length;

    _drawSmoothLine(canvas, indicators!.ma7, startIdx, candleWidth, priceToY, const Color(0xFFFFD700), 1.4);
    _drawSmoothLine(canvas, indicators!.ma25, startIdx, candleWidth, priceToY, const Color(0xFFFF4081), 1.4);
    _drawSmoothLine(canvas, indicators!.ma99, startIdx, candleWidth, priceToY, const Color(0xFF00E5FF), 1.6);
  }

  void _drawSmoothLine(
    Canvas canvas,
    List<double?> series,
    int startIdx,
    double candleWidth,
    double Function(double) priceToY,
    Color color,
    double strokeWidth,
  ) {
    final path = Path();
    bool started = false;

    for (int i = 0; i < visibleCandles.length; i++) {
      final gIdx = startIdx + i;
      if (gIdx < series.length && series[gIdx] != null) {
        final x = i * candleWidth + (candleWidth / 2);
        final y = priceToY(series[gIdx]!);
        if (!started) {
          path.moveTo(x, y);
          started = true;
        } else {
          path.lineTo(x, y);
        }
      }
    }

    if (started) {
      final paint = Paint()
        ..color = color
        ..strokeWidth = strokeWidth
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round;
      canvas.drawPath(path, paint);
    }
  }

  void _drawBollingerBands(
    Canvas canvas,
    double mainWidth,
    int startIdx,
    double Function(double) priceToY,
  ) {
    final candleWidth = mainWidth / visibleCandles.length;
    final upperPath = Path();
    final lowerPath = Path();
    final areaPath = Path();
    bool started = false;

    for (int i = 0; i < visibleCandles.length; i++) {
      final gIdx = startIdx + i;
      if (gIdx < indicators!.bbUpper.length && indicators!.bbUpper[gIdx] != null) {
        final x = i * candleWidth + (candleWidth / 2);
        final uY = priceToY(indicators!.bbUpper[gIdx]!);
        final lY = priceToY(indicators!.bbLower[gIdx]!);

        if (!started) {
          upperPath.moveTo(x, uY);
          lowerPath.moveTo(x, lY);
          areaPath.moveTo(x, uY);
          started = true;
        } else {
          upperPath.lineTo(x, uY);
          lowerPath.lineTo(x, lY);
          areaPath.lineTo(x, uY);
        }
      }
    }

    // Shaded Area between bands
    if (started) {
      for (int i = visibleCandles.length - 1; i >= 0; i--) {
        final gIdx = startIdx + i;
        if (gIdx < indicators!.bbLower.length && indicators!.bbLower[gIdx] != null) {
          final x = i * candleWidth + (candleWidth / 2);
          final lY = priceToY(indicators!.bbLower[gIdx]!);
          areaPath.lineTo(x, lY);
        }
      }
      areaPath.close();

      final areaPaint = Paint()
        ..color = const Color(0xFF2979FF).withValues(alpha: 0.06)
        ..style = PaintingStyle.fill;
      canvas.drawPath(areaPath, areaPaint);

      final linePaint = Paint()
        ..color = const Color(0xFF2979FF).withValues(alpha: 0.6)
        ..strokeWidth = 1.0
        ..style = PaintingStyle.stroke;
      canvas.drawPath(upperPath, linePaint);
      canvas.drawPath(lowerPath, linePaint);
    }
  }

  void _drawHighLowMarkers(
    Canvas canvas,
    double candleWidth,
    double Function(double) priceToY,
  ) {
    if (visibleCandles.isEmpty) return;

    int maxIdx = 0;
    int minIdx = 0;
    for (int i = 1; i < visibleCandles.length; i++) {
      if (visibleCandles[i].high > visibleCandles[maxIdx].high) maxIdx = i;
      if (visibleCandles[i].low < visibleCandles[minIdx].low) minIdx = i;
    }

    final maxC = visibleCandles[maxIdx];
    final minC = visibleCandles[minIdx];

    // High Marker
    final maxX = maxIdx * candleWidth + (candleWidth / 2);
    final maxY = priceToY(maxC.high);
    _drawMarkerBadge(canvas, Offset(maxX, maxY - 8), '▼ ${maxC.high.toStringAsFixed(1)}', AppColor.shortRed);

    // Low Marker
    final minX = minIdx * candleWidth + (candleWidth / 2);
    final minY = priceToY(minC.low);
    _drawMarkerBadge(canvas, Offset(minX, minY + 14), '▲ ${minC.low.toStringAsFixed(1)}', AppColor.longGreen);
  }

  void _drawMarkerBadge(Canvas canvas, Offset offset, String text, Color color) {
    _drawText(canvas, text, offset, color, 9, isBold: true);
  }

  void _drawGridOrders(Canvas canvas, double mainWidth, double Function(double) priceToY) {
    final buyPaint = Paint()
      ..color = AppColor.longGreen.withValues(alpha: 0.6)
      ..strokeWidth = 1.0;
    final sellPaint = Paint()
      ..color = AppColor.shortRed.withValues(alpha: 0.6)
      ..strokeWidth = 1.0;

    for (var o in liveBuyOrders) {
      final y = priceToY(o.price);
      _drawDashedLine(canvas, Offset(0, y), Offset(mainWidth, y), buyPaint);
      _drawText(canvas, 'BUY ${o.price.toStringAsFixed(1)}', Offset(mainWidth - 90, y - 11), AppColor.longGreen, 9);
    }
    for (var o in liveCloseOrders) {
      final y = priceToY(o.price);
      _drawDashedLine(canvas, Offset(0, y), Offset(mainWidth, y), sellPaint);
      _drawText(canvas, 'SELL ${o.price.toStringAsFixed(1)}', Offset(mainWidth - 90, y - 11), AppColor.shortRed, 9);
    }
  }

  void _drawLivePrice(
    Canvas canvas,
    double mainWidth,
    double fullWidth,
    double Function(double) priceToY,
  ) {
    if (currentPrice <= 0) return;
    final y = priceToY(currentPrice);

    final linePaint = Paint()
      ..color = AppColor.accent
      ..strokeWidth = 1.2;
    _drawDashedLine(canvas, Offset(0, y), Offset(mainWidth, y), linePaint);

    // Right Y-axis Live Price Tag
    final badgePaint = Paint()..color = AppColor.accent;
    final badgeRect = RRect.fromRectAndRadius(
      Rect.fromLTWH(mainWidth + 2, y - 9, fullWidth - mainWidth - 4, 18),
      const Radius.circular(4),
    );
    canvas.drawRRect(badgeRect, badgePaint);

    _drawText(
      canvas,
      currentPrice.toStringAsFixed(1),
      Offset(mainWidth + 6, y - 5),
      Colors.black,
      10,
      isBold: true,
    );
  }

  // Sub Indicator: Volume Panel
  void _drawVolumePanel(
    Canvas canvas,
    double mainWidth,
    double mainHeight,
    double subHeight,
    int startIdx,
  ) {
    double maxVol = 1.0;
    for (var c in visibleCandles) {
      maxVol = max(maxVol, c.volume);
    }

    final candleWidth = mainWidth / visibleCandles.length;
    final baseY = mainHeight + subHeight;

    for (int i = 0; i < visibleCandles.length; i++) {
      final c = visibleCandles[i];
      final x = i * candleWidth + (candleWidth / 2);
      final isUp = c.close >= c.open;
      final h = (c.volume / maxVol) * (subHeight - 16);

      final volPaint = Paint()
        ..color = (isUp ? AppColor.longGreen : AppColor.shortRed).withValues(alpha: 0.35)
        ..style = PaintingStyle.fill;

      canvas.drawRect(
        Rect.fromLTWH(x - (candleWidth * 0.35), baseY - h, candleWidth * 0.7, h),
        volPaint,
      );
    }

    // Volume Panel Header
    _drawText(canvas, 'VOL (거래량)', Offset(8, mainHeight + 6), AppColor.textSecondary, 10);
  }

  // Sub Indicator: RSI Panel
  void _drawRsiPanel(
    Canvas canvas,
    double mainWidth,
    double mainHeight,
    double subHeight,
    int startIdx,
  ) {
    final topY = mainHeight + 4;
    final botY = mainHeight + subHeight - 4;
    final h = botY - topY;

    double rsiToY(double rsi) => botY - (rsi / 100.0) * h;

    // 70 and 30 Lines
    final dashPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.1)
      ..strokeWidth = 1.0;
    _drawDashedLine(canvas, Offset(0, rsiToY(70)), Offset(mainWidth, rsiToY(70)), dashPaint);
    _drawDashedLine(canvas, Offset(0, rsiToY(30)), Offset(mainWidth, rsiToY(30)), dashPaint);

    // Shaded band 30~70
    final bandPaint = Paint()
      ..color = const Color(0xFFBA68C8).withValues(alpha: 0.05)
      ..style = PaintingStyle.fill;
    canvas.drawRect(Rect.fromLTRB(0, rsiToY(70), mainWidth, rsiToY(30)), bandPaint);

    // RSI Curve
    final candleWidth = mainWidth / visibleCandles.length;
    final rsiPath = Path();
    bool started = false;

    if (indicators != null) {
      for (int i = 0; i < visibleCandles.length; i++) {
        final gIdx = startIdx + i;
        if (gIdx < indicators!.rsi14.length && indicators!.rsi14[gIdx] != null) {
          final x = i * candleWidth + (candleWidth / 2);
          final y = rsiToY(indicators!.rsi14[gIdx]!);
          if (!started) {
            rsiPath.moveTo(x, y);
            started = true;
          } else {
            rsiPath.lineTo(x, y);
          }
        }
      }
    }

    if (started) {
      final rsiPaint = Paint()
        ..color = const Color(0xFFBA68C8)
        ..strokeWidth = 1.5
        ..style = PaintingStyle.stroke;
      canvas.drawPath(rsiPath, rsiPaint);
    }

    _drawText(canvas, 'RSI (14)', Offset(8, mainHeight + 6), const Color(0xFFBA68C8), 10);
    _drawText(canvas, '70', Offset(mainWidth + 6, rsiToY(70) - 5), AppColor.shortRed, 9);
    _drawText(canvas, '30', Offset(mainWidth + 6, rsiToY(30) - 5), AppColor.longGreen, 9);
  }

  // Sub Indicator: MACD Panel
  void _drawMacdPanel(
    Canvas canvas,
    double mainWidth,
    double mainHeight,
    double subHeight,
    int startIdx,
  ) {
    if (indicators == null) return;
    final candleWidth = mainWidth / visibleCandles.length;
    final midY = mainHeight + (subHeight / 2);

    // Zero line
    final zeroPaint = Paint()
      ..color = Colors.white10
      ..strokeWidth = 1.0;
    canvas.drawLine(Offset(0, midY), Offset(mainWidth, midY), zeroPaint);

    // Histogram & Lines
    for (int i = 0; i < visibleCandles.length; i++) {
      final gIdx = startIdx + i;
      if (gIdx < indicators!.macdHist.length && indicators!.macdHist[gIdx] != null) {
        final hist = indicators!.macdHist[gIdx]!;
        final x = i * candleWidth + (candleWidth / 2);
        final barH = (hist * 0.8).clamp(-subHeight * 0.45, subHeight * 0.45);

        final histPaint = Paint()
          ..color = (hist >= 0 ? AppColor.longGreen : AppColor.shortRed).withValues(alpha: 0.6)
          ..style = PaintingStyle.fill;
        canvas.drawRect(Rect.fromLTWH(x - (candleWidth * 0.3), midY, candleWidth * 0.6, -barH), histPaint);
      }
    }

    _drawText(canvas, 'MACD (12, 26, 9)', Offset(8, mainHeight + 6), const Color(0xFF00E5FF), 10);
  }

  // 11. Crosshair & Hover Tooltip
  void _drawCrosshair(
    Canvas canvas,
    Size size,
    double mainWidth,
    double mainHeight,
    double candleWidth,
    double Function(double) yToPrice,
  ) {
    if (hoverPosition == null) return;

    final x = hoverPosition!.dx;
    final y = hoverPosition!.dy;

    if (x < 0 || x > mainWidth || y < 0 || y > mainHeight) return;

    final candleIdx = (x / candleWidth).floor().clamp(0, visibleCandles.length - 1);
    final candle = visibleCandles[candleIdx];
    final snappedX = candleIdx * candleWidth + (candleWidth / 2);

    onHoverCandleIndex?.call(startIndex + candleIdx);

    final crosshairPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.3)
      ..strokeWidth = 1.0;

    // Vertical line
    _drawDashedLine(canvas, Offset(snappedX, 0), Offset(snappedX, size.height - 20), crosshairPaint);
    // Horizontal line
    _drawDashedLine(canvas, Offset(0, y), Offset(mainWidth, y), crosshairPaint);

    // Right Y-axis Hovered Price Badge
    final hoverPrice = yToPrice(y);
    final priceBadgeRect = RRect.fromRectAndRadius(
      Rect.fromLTWH(mainWidth + 2, y - 9, size.width - mainWidth - 4, 18),
      const Radius.circular(4),
    );
    canvas.drawRRect(priceBadgeRect, Paint()..color = AppColor.cardSurface);
    _drawText(canvas, hoverPrice.toStringAsFixed(1), Offset(mainWidth + 6, y - 5), AppColor.textPrimary, 10, isBold: true);

    // Bottom X-axis Time Badge
    final timeStr = DateFormat('MM-dd HH:mm').format(candle.time);
    final timeBadgeRect = RRect.fromRectAndRadius(
      Rect.fromLTWH(snappedX - 35, size.height - 18, 70, 16),
      const Radius.circular(4),
    );
    canvas.drawRRect(timeBadgeRect, Paint()..color = AppColor.cardSurface);
    _drawText(canvas, timeStr, Offset(snappedX - 28, size.height - 15), AppColor.textPrimary, 9, isBold: true);
  }

  void _drawDashedLine(Canvas canvas, Offset p1, Offset p2, Paint paint) {
    const double dashWidth = 4.0;
    const double dashSpace = 4.0;
    final dx = p2.dx - p1.dx;
    final dy = p2.dy - p1.dy;
    final dist = sqrt(dx * dx + dy * dy);
    if (dist <= 0) return;

    final ux = dx / dist;
    final uy = dy / dist;

    double currentDist = 0;
    while (currentDist < dist) {
      final len = min(dashWidth, dist - currentDist);
      final start = Offset(p1.dx + ux * currentDist, p1.dy + uy * currentDist);
      final end = Offset(start.dx + ux * len, start.dy + uy * len);
      canvas.drawLine(start, end, paint);
      currentDist += dashWidth + dashSpace;
    }
  }

  void _drawText(
    Canvas canvas,
    String text,
    Offset offset,
    Color color,
    double fontSize, {
    bool isBold = false,
  }) {
    final tp = TextPainter(
      text: TextSpan(
        text: text,
        style: TextStyle(
          color: color,
          fontSize: fontSize,
          fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
          fontFamily: 'monospace',
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    tp.paint(canvas, offset);
  }

  @override
  bool shouldRepaint(covariant _TradingViewChartPainter oldDelegate) {
    return true;
  }
}

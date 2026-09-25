import 'dart:async';
import 'dart:math';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart' hide TextDirection;
import '../../models/candle_data.dart';
import '../../models/trade_order.dart';
import '../../style/app_color.dart';
import 'technical_indicator_calculator.dart';

enum ChartStyle {
  candles('캔들', Icons.candlestick_chart),
  heikinAshi('하이킨아시', Icons.auto_graph),
  line('라인', Icons.show_chart),
  area('영역', Icons.area_chart),
  bars('바(OHLC)', Icons.waterfall_chart),
  hollow('할로우', Icons.check_box_outline_blank);

  final String label;
  final IconData icon;
  const ChartStyle(this.label, this.icon);
}

enum SubIndicator {
  none('없음'),
  volume('VOL 거래량'),
  rsi('RSI (14)'),
  macd('MACD'),
  kdj('KDJ 스토캐스틱'),
  wr('WR (14)'),
  cci('CCI (20)'),
  atr('ATR (14)'),
  obv('OBV 거래량');

  final String label;
  const SubIndicator(this.label);
}

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
  bool _showEMA = false;
  bool _showBB = false;
  bool _showSAR = false;
  bool _showSuperTrend = false;
  bool _showVWAP = false;
  bool _showIchimoku = false;
  bool _showGridOrders = true;
  bool _showHighLowBadges = true;
  bool _useLogScale = false;
  bool _showCountdown = true;

  SubIndicator _subIndicator = SubIndicator.volume;

  // Computed Indicators Cache
  TechnicalIndicators? _indicators;

  // Viewport & Pan / Zoom State
  int _visibleCount = 60; // 기본 표시 캔들 개수
  int _scrollOffset = 0; // 최신 캔들 기준 과거로 스크롤한 캔들 수 (0 = 최신)
  Offset? _hoverPosition;
  int? _hoveredCandleIndex;

  // Realtime Countdown Timer
  Timer? _countdownTimer;
  String _countdownStr = '';

  @override
  void initState() {
    super.initState();
    _recomputeIndicators();
    _startCountdownTimer();
  }

  @override
  void didUpdateWidget(covariant TradingViewChartViewer oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.candles != oldWidget.candles) {
      _recomputeIndicators();
    }
    if (widget.activeInterval != oldWidget.activeInterval) {
      _updateCountdown();
    }
  }

  @override
  void dispose() {
    _countdownTimer?.cancel();
    super.dispose();
  }

  void _startCountdownTimer() {
    _updateCountdown();
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) _updateCountdown();
    });
  }

  void _updateCountdown() {
    final now = DateTime.now().toUtc();
    int intervalSec = 900; // 15m default
    switch (widget.activeInterval.toLowerCase()) {
      case '1m':
        intervalSec = 60;
        break;
      case '5m':
        intervalSec = 300;
        break;
      case '15m':
        intervalSec = 900;
        break;
      case '1h':
        intervalSec = 3600;
        break;
      case '4h':
        intervalSec = 14400;
        break;
      case '1d':
        intervalSec = 86400;
        break;
    }

    final curEpochSec = now.millisecondsSinceEpoch ~/ 1000;
    final remainingSec = intervalSec - (curEpochSec % intervalSec);

    final m = (remainingSec ~/ 60).toString().padLeft(2, '0');
    final s = (remainingSec % 60).toString().padLeft(2, '0');
    final str = '$m:$s';
    if (str != _countdownStr) {
      setState(() => _countdownStr = str);
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
        height: 540,
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
                '실시간 차트 및 보조지표 연산 엔진 준비 중...',
                style: TextStyle(fontSize: 12, color: AppColor.textSecondary),
              ),
            ],
          ),
        ),
      );
    }

    final totalCandles = widget.candles.length;
    final int safeVisible = _visibleCount.clamp(15, max(15, totalCandles));
    final int safeOffset = _scrollOffset.clamp(0, max(0, totalCandles - safeVisible));

    final int startIdx = max(0, totalCandles - safeVisible - safeOffset);
    final int endIdx = min(totalCandles, startIdx + safeVisible);

    // Heikin-Ashi 선택 시 변환된 캔들 사용
    final effectiveCandles = (_chartStyle == ChartStyle.heikinAshi && _indicators != null && _indicators!.heikinAshiCandles.isNotEmpty)
        ? _indicators!.heikinAshiCandles
        : widget.candles;

    final List<CandleData> visibleCandles = effectiveCandles.sublist(startIdx, endIdx);

    // 활성 캔들 정보
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
          // 1. TradingView Top Toolbar (Timeframes, Chart Styles, Indicators, Settings Modal)
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
                      _visibleCount = (_visibleCount - 4).clamp(15, totalCandles);
                    } else {
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
                          candles: effectiveCandles,
                          visibleCandles: visibleCandles,
                          startIndex: startIdx,
                          indicators: _indicators,
                          currentPrice: widget.currentPrice,
                          liveBuyOrders: _showGridOrders ? widget.liveBuyOrders : [],
                          liveCloseOrders: _showGridOrders ? widget.liveCloseOrders : [],
                          chartStyle: _chartStyle,
                          showMA: _showMA,
                          showEMA: _showEMA,
                          showBB: _showBB,
                          showSAR: _showSAR,
                          showSuperTrend: _showSuperTrend,
                          showVWAP: _showVWAP,
                          showIchimoku: _showIchimoku,
                          showHighLowBadges: _showHighLowBadges,
                          useLogScale: _useLogScale,
                          subIndicator: _subIndicator,
                          countdownStr: _showCountdown ? _countdownStr : null,
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
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
      decoration: BoxDecoration(
        color: AppColor.cardSurface.withValues(alpha: 0.5),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
      ),
      child: Wrap(
        spacing: 6,
        runSpacing: 6,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          // Timeframe Pills
          Row(
            mainAxisSize: MainAxisSize.min,
            children: timeframes.map((tf) {
              final isSel = tf == widget.activeInterval;
              return Padding(
                padding: const EdgeInsets.only(right: 3),
                child: InkWell(
                  onTap: () => widget.onIntervalChanged?.call(tf),
                  borderRadius: BorderRadius.circular(6),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 4),
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

          // Divider
          Container(width: 1, height: 16, color: Colors.white10),

          // Chart Style Quick Dropdown
          PopupMenuButton<ChartStyle>(
            initialValue: _chartStyle,
            tooltip: '차트 형태 변경',
            color: AppColor.backgroundCard,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            onSelected: (style) => setState(() => _chartStyle = style),
            itemBuilder: (context) => ChartStyle.values.map((s) {
              return PopupMenuItem<ChartStyle>(
                value: s,
                height: 36,
                child: Row(
                  children: [
                    Icon(s.icon, size: 15, color: s == _chartStyle ? AppColor.accent : AppColor.textSecondary),
                    const SizedBox(width: 8),
                    Text(s.label, style: TextStyle(fontSize: 12, color: s == _chartStyle ? Colors.white : AppColor.textSecondary)),
                  ],
                ),
              );
            }).toList(),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: AppColor.inputSurface,
                borderRadius: BorderRadius.circular(6),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(_chartStyle.icon, size: 14, color: AppColor.accent),
                  const SizedBox(width: 4),
                  Text(_chartStyle.label, style: const TextStyle(fontSize: 11, color: AppColor.textPrimary)),
                  const Icon(Icons.arrow_drop_down, size: 14, color: AppColor.textSecondary),
                ],
              ),
            ),
          ),

          // Divider
          Container(width: 1, height: 16, color: Colors.white10),

          // Quick Main Indicator Chips
          _indicatorToggleChip(
            label: 'MA',
            active: _showMA,
            activeColor: const Color(0xFFFFD700),
            onTap: () => setState(() => _showMA = !_showMA),
          ),
          _indicatorToggleChip(
            label: 'EMA',
            active: _showEMA,
            activeColor: const Color(0xFF00E676),
            onTap: () => setState(() => _showEMA = !_showEMA),
          ),
          _indicatorToggleChip(
            label: 'BOLL',
            active: _showBB,
            activeColor: const Color(0xFF2979FF),
            onTap: () => setState(() => _showBB = !_showBB),
          ),
          _indicatorToggleChip(
            label: 'SAR',
            active: _showSAR,
            activeColor: const Color(0xFFFF9100),
            onTap: () => setState(() => _showSAR = !_showSAR),
          ),
          _indicatorToggleChip(
            label: 'ST(슈퍼트렌드)',
            active: _showSuperTrend,
            activeColor: const Color(0xFF7C4DFF),
            onTap: () => setState(() => _showSuperTrend = !_showSuperTrend),
          ),
          _indicatorToggleChip(
            label: 'VWAP',
            active: _showVWAP,
            activeColor: const Color(0xFF00E5FF),
            onTap: () => setState(() => _showVWAP = !_showVWAP),
          ),
          _indicatorToggleChip(
            label: '일목',
            active: _showIchimoku,
            activeColor: const Color(0xFFFF5252),
            onTap: () => setState(() => _showIchimoku = !_showIchimoku),
          ),

          // Divider
          Container(width: 1, height: 16, color: Colors.white10),

          // Sub-Indicator Quick Selector
          PopupMenuButton<SubIndicator>(
            initialValue: _subIndicator,
            tooltip: '하단 보조지표 선택',
            color: AppColor.backgroundCard,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            onSelected: (sub) => setState(() => _subIndicator = sub),
            itemBuilder: (context) => SubIndicator.values.map((s) {
              return PopupMenuItem<SubIndicator>(
                value: s,
                height: 34,
                child: Row(
                  children: [
                    Icon(
                      s == _subIndicator ? Icons.check_circle : Icons.circle_outlined,
                      size: 13,
                      color: s == _subIndicator ? AppColor.accent : AppColor.textDisabled,
                    ),
                    const SizedBox(width: 8),
                    Text(s.label, style: TextStyle(fontSize: 12, color: s == _subIndicator ? Colors.white : AppColor.textSecondary)),
                  ],
                ),
              );
            }).toList(),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: _subIndicator != SubIndicator.none
                    ? AppColor.primary.withValues(alpha: 0.25)
                    : AppColor.inputSurface,
                borderRadius: BorderRadius.circular(6),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.bar_chart, size: 13, color: _subIndicator != SubIndicator.none ? AppColor.accent : AppColor.textSecondary),
                  const SizedBox(width: 4),
                  Text(
                    _subIndicator.label,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: _subIndicator != SubIndicator.none ? FontWeight.bold : FontWeight.normal,
                      color: _subIndicator != SubIndicator.none ? AppColor.accent : AppColor.textPrimary,
                    ),
                  ),
                  const Icon(Icons.arrow_drop_down, size: 14, color: AppColor.textSecondary),
                ],
              ),
            ),
          ),

          // Divider
          Container(width: 1, height: 16, color: Colors.white10),

          // Log Scale Toggle
          _indicatorToggleChip(
            label: 'LOG',
            active: _useLogScale,
            activeColor: const Color(0xFF00E5FF),
            onTap: () => setState(() => _useLogScale = !_useLogScale),
          ),

          // Comprehensive Indicator & Setting Dialog Button
          InkWell(
            onTap: _showSettingsModal,
            borderRadius: BorderRadius.circular(6),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: AppColor.inputSurface,
                borderRadius: BorderRadius.circular(6),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.tune, size: 13, color: AppColor.accent),
                  SizedBox(width: 4),
                  Text('지표 설정', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColor.textPrimary)),
                ],
              ),
            ),
          ),

          // Reset View
          IconButton(
            icon: const Icon(Icons.restart_alt, size: 15, color: AppColor.textSecondary),
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
        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 4),
        decoration: BoxDecoration(
          color: active ? activeColor.withValues(alpha: 0.15) : AppColor.inputSurface.withValues(alpha: 0.6),
          borderRadius: BorderRadius.circular(6),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 5,
              height: 5,
              decoration: BoxDecoration(
                color: active ? activeColor : AppColor.textDisabled,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 5),
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

    final idx = _hoveredCandleIndex ?? (widget.candles.isNotEmpty ? widget.candles.length - 1 : null);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
      child: Wrap(
        spacing: 10,
        runSpacing: 3,
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

          // Countdown Badge
          if (_showCountdown && _countdownStr.isNotEmpty)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
              decoration: BoxDecoration(
                color: AppColor.accent.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                '⏳ 마감 $_countdownStr',
                style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, fontFamily: 'monospace', color: AppColor.accent),
              ),
            ),

          // Indicators Live Values
          if (_indicators != null && idx != null && idx < widget.candles.length) ...[
            if (_showMA) ...[
              if (_indicators!.ma7[idx] != null) _indicatorVal('MA7', _indicators!.ma7[idx]!, const Color(0xFFFFD700)),
              if (_indicators!.ma25[idx] != null) _indicatorVal('MA25', _indicators!.ma25[idx]!, const Color(0xFFFF4081)),
              if (_indicators!.ma99[idx] != null) _indicatorVal('MA99', _indicators!.ma99[idx]!, const Color(0xFF00E5FF)),
            ],
            if (_showEMA) ...[
              if (_indicators!.ema9[idx] != null) _indicatorVal('EMA9', _indicators!.ema9[idx]!, const Color(0xFF00E676)),
              if (_indicators!.ema21[idx] != null) _indicatorVal('EMA21', _indicators!.ema21[idx]!, const Color(0xFFFF7043)),
            ],
            if (_showBB && _indicators!.bbUpper[idx] != null) ...[
              _indicatorVal('BB상단', _indicators!.bbUpper[idx]!, const Color(0xFF2979FF)),
              _indicatorVal('BB하단', _indicators!.bbLower[idx]!, const Color(0xFF2979FF)),
            ],
            if (_showSuperTrend && _indicators!.superTrend[idx] != null)
              _indicatorVal(
                'SuperTrend',
                _indicators!.superTrend[idx]!,
                _indicators!.superTrendDirection[idx] == 1 ? AppColor.longGreen : AppColor.shortRed,
              ),
            if (_showVWAP && _indicators!.vwap[idx] != null)
              _indicatorVal('VWAP', _indicators!.vwap[idx]!, const Color(0xFF00E5FF)),
            if (_showSAR && _indicators!.sar[idx] != null)
              _indicatorVal(
                'SAR',
                _indicators!.sar[idx]!,
                _indicators!.sarIsBull[idx] ? AppColor.longGreen : AppColor.shortRed,
              ),

            // Sub Indicator value
            if (_subIndicator == SubIndicator.rsi && _indicators!.rsi14[idx] != null)
              _indicatorVal('RSI(14)', _indicators!.rsi14[idx]!, const Color(0xFFBA68C8)),
            if (_subIndicator == SubIndicator.macd && _indicators!.macd[idx] != null) ...[
              _indicatorVal('MACD', _indicators!.macd[idx]!, const Color(0xFF00E5FF)),
              if (_indicators!.macdSignal[idx] != null) _indicatorVal('Sig', _indicators!.macdSignal[idx]!, const Color(0xFFFFB300)),
            ],
            if (_subIndicator == SubIndicator.kdj && _indicators!.kdjK[idx] != null) ...[
              _indicatorVal('K', _indicators!.kdjK[idx]!, const Color(0xFF00E5FF)),
              if (_indicators!.kdjD[idx] != null) _indicatorVal('D', _indicators!.kdjD[idx]!, const Color(0xFFFFB300)),
              if (_indicators!.kdjJ[idx] != null) _indicatorVal('J', _indicators!.kdjJ[idx]!, const Color(0xFFE040FB)),
            ],
            if (_subIndicator == SubIndicator.wr && _indicators!.wr14[idx] != null)
              _indicatorVal('WR(14)', _indicators!.wr14[idx]!, const Color(0xFFFF7043)),
            if (_subIndicator == SubIndicator.cci && _indicators!.cci20[idx] != null)
              _indicatorVal('CCI(20)', _indicators!.cci20[idx]!, const Color(0xFFFFCA28)),
            if (_subIndicator == SubIndicator.atr && _indicators!.atr14[idx] != null)
              _indicatorVal('ATR(14)', _indicators!.atr14[idx]!, const Color(0xFF26A69A)),
            if (_subIndicator == SubIndicator.obv && _indicators!.obv[idx] != null)
              _indicatorVal('OBV', _indicators!.obv[idx]!, const Color(0xFF42A5F5)),
          ],
        ],
      ),
    );
  }

  Widget _ohlcItem(String label, String val, Color valColor) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text('$label: ', style: const TextStyle(fontSize: 11, color: AppColor.textSecondary)),
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

  // --- 지표 및 옵션 상세 설정 모달 ---
  void _showSettingsModal() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Container(
              padding: const EdgeInsets.all(20),
              constraints: const BoxConstraints(maxHeight: 650, maxWidth: 600),
              decoration: BoxDecoration(
                color: AppColor.backgroundCard,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
                boxShadow: AppColor.subtleShadow,
              ),
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Row(
                          children: [
                            Icon(Icons.tune, color: AppColor.accent, size: 20),
                            SizedBox(width: 8),
                            Text(
                              '차트 & 보조지표 종합 설정',
                              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
                            ),
                          ],
                        ),
                        IconButton(
                          icon: const Icon(Icons.close, color: AppColor.textSecondary, size: 20),
                          onPressed: () => Navigator.pop(ctx),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // 1. 차트 형태 선택
                    const Text('🎨 차트 캔들 스타일', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppColor.accent)),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: ChartStyle.values.map((s) {
                        final isSel = _chartStyle == s;
                        return ChoiceChip(
                          avatar: Icon(s.icon, size: 14, color: isSel ? Colors.white : AppColor.textSecondary),
                          label: Text(s.label),
                          selected: isSel,
                          selectedColor: AppColor.primary,
                          backgroundColor: AppColor.inputSurface,
                          labelStyle: TextStyle(fontSize: 11, color: isSel ? Colors.white : AppColor.textSecondary),
                          onSelected: (_) {
                            setState(() => _chartStyle = s);
                            setModalState(() {});
                          },
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 20),

                    // 2. 메인 오버레이 지표
                    const Text('📈 메인 오버레이 지표 (순수 Dart 자체 계산)', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppColor.accent)),
                    const SizedBox(height: 8),
                    _buildSwitchTile('단순이동평균 (SMA 7 / 25 / 99 / 200)', '단기, 중기, 장기 추세 평균선', _showMA, (val) {
                      setState(() => _showMA = val);
                      setModalState(() {});
                    }),
                    _buildSwitchTile('지수이동평균 (EMA 9 / 21 / 50 / 200)', '최신 가격 가중치가 높은 골든크로스 지표', _showEMA, (val) {
                      setState(() => _showEMA = val);
                      setModalState(() {});
                    }),
                    _buildSwitchTile('볼린저 밴드 (Bollinger Bands 20, 2.0)', '표준편차 기반 가격 변동성 채널 및 밴드 필', _showBB, (val) {
                      setState(() => _showBB = val);
                      setModalState(() {});
                    }),
                    _buildSwitchTile('파라볼릭 SAR (Parabolic Stop & Reverse)', '가속도 0.02, 한계 0.20 기반 추세 반전 도트', _showSAR, (val) {
                      setState(() => _showSAR = val);
                      setModalState(() {});
                    }),
                    _buildSwitchTile('슈퍼트렌드 (SuperTrend 10, 3.0)', 'ATR 기반 자동 추세 지지/저항 및 매수/매도 밴드', _showSuperTrend, (val) {
                      setState(() => _showSuperTrend = val);
                      setModalState(() {});
                    }),
                    _buildSwitchTile('VWAP (거래량 가중 평균가)', '기관 투자자 필수 기준선 (Cumulative Price*Vol / Vol)', _showVWAP, (val) {
                      setState(() => _showVWAP = val);
                      setModalState(() {});
                    }),
                    _buildSwitchTile('일목균형표 (Ichimoku Cloud)', '전환선(9), 기준선(26), 선행스팬 구름대', _showIchimoku, (val) {
                      setState(() => _showIchimoku = val);
                      setModalState(() {});
                    }),
                    const SizedBox(height: 20),

                    // 3. 서브 패널 보조지표
                    const Text('📊 하단 서브 보조지표 선택', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppColor.accent)),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: SubIndicator.values.map((sub) {
                        final isSel = _subIndicator == sub;
                        return ChoiceChip(
                          label: Text(sub.label),
                          selected: isSel,
                          selectedColor: AppColor.secondary,
                          backgroundColor: AppColor.inputSurface,
                          labelStyle: TextStyle(fontSize: 11, color: isSel ? Colors.white : AppColor.textSecondary),
                          onSelected: (_) {
                            setState(() => _subIndicator = sub);
                            setModalState(() {});
                          },
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 20),

                    // 4. 차트 표시 편의 옵션
                    const Text('⚙️ 부가 디스플레이 옵션', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppColor.accent)),
                    const SizedBox(height: 8),
                    _buildSwitchTile('로그 스케일 (Logarithmic Y-Axis)', '가격 비율(%) 중심의 수직 축 스케일링', _useLogScale, (val) {
                      setState(() => _useLogScale = val);
                      setModalState(() {});
                    }),
                    _buildSwitchTile('그리드 봇 주문선 표시', '미체결 매수/익절 주문의 실시간 가격 수평선', _showGridOrders, (val) {
                      setState(() => _showGridOrders = val);
                      setModalState(() {});
                    }),
                    _buildSwitchTile('최고가/최저가 뱃지 표시', '현재 화면 내 최고가(High) / 최저가(Low) 자동 마킹', _showHighLowBadges, (val) {
                      setState(() => _showHighLowBadges = val);
                      setModalState(() {});
                    }),
                    _buildSwitchTile('다음 봉 마감 카운트다운 타이머', '선택한 타임프레임의 캔들 마감까지 잔여 분:초 표시', _showCountdown, (val) {
                      setState(() => _showCountdown = val);
                      setModalState(() {});
                    }),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildSwitchTile(String title, String subtitle, bool value, ValueChanged<bool> onChanged) {
    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: AppColor.cardSurface.withValues(alpha: 0.4),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white)),
                Text(subtitle, style: const TextStyle(fontSize: 10, color: AppColor.textSecondary)),
              ],
            ),
          ),
          Switch(
            value: value,
            activeThumbColor: AppColor.accent,
            onChanged: onChanged,
          ),
        ],
      ),
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
  final bool showEMA;
  final bool showBB;
  final bool showSAR;
  final bool showSuperTrend;
  final bool showVWAP;
  final bool showIchimoku;
  final bool showHighLowBadges;
  final bool useLogScale;
  final SubIndicator subIndicator;
  final String? countdownStr;
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
    required this.showEMA,
    required this.showBB,
    required this.showSAR,
    required this.showSuperTrend,
    required this.showVWAP,
    required this.showIchimoku,
    required this.showHighLowBadges,
    required this.useLogScale,
    required this.subIndicator,
    required this.countdownStr,
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
    final double subHeight = hasSub ? max(80.0, size.height * 0.25) : 0.0;
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
    if (minPrice <= 0) minPrice = 0.0001;

    double priceToY(double price) {
      if (maxPrice <= minPrice) return mainHeight / 2;
      if (useLogScale && minPrice > 0 && price > 0) {
        final logMin = log(minPrice);
        final logMax = log(maxPrice);
        final logP = log(price);
        return mainHeight - ((logP - logMin) / (logMax - logMin)) * mainHeight;
      }
      return mainHeight - ((price - minPrice) / (maxPrice - minPrice)) * mainHeight;
    }

    double yToPrice(double y) {
      if (useLogScale && minPrice > 0) {
        final logMin = log(minPrice);
        final logMax = log(maxPrice);
        final logP = logMax - (y / mainHeight) * (logMax - logMin);
        return exp(logP);
      }
      return maxPrice - (y / mainHeight) * (maxPrice - minPrice);
    }

    // 2. Draw Background Grid Lines
    _drawGridLines(canvas, mainWidth, mainHeight, minPrice, maxPrice, priceToY);

    // 3. Draw Sub Indicator Separator
    if (hasSub) {
      final sepPaint = Paint()
        ..color = Colors.white.withValues(alpha: 0.08)
        ..strokeWidth = 1.0;
      canvas.drawLine(Offset(0, mainHeight), Offset(mainWidth, mainHeight), sepPaint);
    }

    // 4. Overlays under candles
    if (showIchimoku && indicators != null) {
      _drawIchimokuCloud(canvas, mainWidth, startIndex, priceToY);
    }
    if (showBB && indicators != null) {
      _drawBollingerBands(canvas, mainWidth, startIndex, priceToY);
    }

    // 5. Draw Sub Indicator Panel
    if (subIndicator == SubIndicator.volume) {
      _drawVolumePanel(canvas, mainWidth, mainHeight, subHeight, startIndex);
    } else if (subIndicator == SubIndicator.rsi) {
      _drawRsiPanel(canvas, mainWidth, mainHeight, subHeight, startIndex);
    } else if (subIndicator == SubIndicator.macd) {
      _drawMacdPanel(canvas, mainWidth, mainHeight, subHeight, startIndex);
    } else if (subIndicator == SubIndicator.kdj) {
      _drawKdjPanel(canvas, mainWidth, mainHeight, subHeight, startIndex);
    } else if (subIndicator == SubIndicator.wr) {
      _drawWrPanel(canvas, mainWidth, mainHeight, subHeight, startIndex);
    } else if (subIndicator == SubIndicator.cci) {
      _drawCciPanel(canvas, mainWidth, mainHeight, subHeight, startIndex);
    } else if (subIndicator == SubIndicator.atr) {
      _drawAtrPanel(canvas, mainWidth, mainHeight, subHeight, startIndex);
    } else if (subIndicator == SubIndicator.obv) {
      _drawObvPanel(canvas, mainWidth, mainHeight, subHeight, startIndex);
    }

    // 6. Draw Candlesticks, Heikin-Ashi, Line, Area, Bars, Hollow
    final candleWidth = mainWidth / visibleCandles.length;
    switch (chartStyle) {
      case ChartStyle.candles:
      case ChartStyle.heikinAshi:
        _drawCandles(canvas, candleWidth, priceToY);
        break;
      case ChartStyle.line:
        _drawLineChart(canvas, mainWidth, candleWidth, priceToY, false);
        break;
      case ChartStyle.area:
        _drawLineChart(canvas, mainWidth, candleWidth, priceToY, true);
        break;
      case ChartStyle.bars:
        _drawBarChart(canvas, candleWidth, priceToY);
        break;
      case ChartStyle.hollow:
        _drawHollowCandles(canvas, candleWidth, priceToY);
        break;
    }

    // 7. Draw Overlays (MA, EMA, SAR, SuperTrend, VWAP)
    if (showMA && indicators != null) {
      _drawMovingAverages(canvas, mainWidth, startIndex, priceToY);
    }
    if (showEMA && indicators != null) {
      _drawExponentialMovingAverages(canvas, mainWidth, startIndex, priceToY);
    }
    if (showSuperTrend && indicators != null) {
      _drawSuperTrend(canvas, mainWidth, startIndex, priceToY);
    }
    if (showVWAP && indicators != null) {
      _drawVWAP(canvas, mainWidth, startIndex, priceToY);
    }
    if (showSAR && indicators != null) {
      _drawParabolicSAR(canvas, mainWidth, startIndex, candleWidth, priceToY);
    }

    // 8. Draw High / Low Tags
    if (showHighLowBadges) {
      _drawHighLowMarkers(canvas, candleWidth, priceToY);
    }

    // 9. Draw Grid Orders
    _drawGridOrders(canvas, mainWidth, priceToY);

    // 10. Draw Live Price Line & Countdown
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
    double mainWidth,
    double mainHeight,
    double minPrice,
    double maxPrice,
    double Function(double) priceToY,
  ) {
    final gridPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.035)
      ..strokeWidth = 1.0;

    const int steps = 5;
    for (int i = 0; i <= steps; i++) {
      final price = maxPrice - (i / steps) * (maxPrice - minPrice);
      final y = priceToY(price);
      canvas.drawLine(Offset(0, y), Offset(mainWidth, y), gridPaint);

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

  void _drawBarChart(Canvas canvas, double candleWidth, double Function(double) priceToY) {
    for (int i = 0; i < visibleCandles.length; i++) {
      final c = visibleCandles[i];
      final x = i * candleWidth + (candleWidth / 2);
      final isUp = c.close >= c.open;
      final barColor = isUp ? AppColor.longGreen : AppColor.shortRed;
      final tickW = max(2.0, candleWidth * 0.35);

      final barPaint = Paint()
        ..color = barColor
        ..strokeWidth = max(1.2, candleWidth * 0.14);

      // High-low vertical line
      canvas.drawLine(Offset(x, priceToY(c.high)), Offset(x, priceToY(c.low)), barPaint);

      // Open horizontal tick (left)
      canvas.drawLine(Offset(x - tickW, priceToY(c.open)), Offset(x, priceToY(c.open)), barPaint);

      // Close horizontal tick (right)
      canvas.drawLine(Offset(x, priceToY(c.close)), Offset(x + tickW, priceToY(c.close)), barPaint);
    }
  }

  void _drawHollowCandles(Canvas canvas, double candleWidth, double Function(double) priceToY) {
    for (int i = 0; i < visibleCandles.length; i++) {
      final c = visibleCandles[i];
      final x = i * candleWidth + (candleWidth / 2);
      final prevC = (i > 0) ? visibleCandles[i - 1].close : c.open;
      final isUpVsPrev = c.close >= prevC;
      final candleColor = isUpVsPrev ? AppColor.longGreen : AppColor.shortRed;

      final isBull = c.close >= c.open;

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

      final bodyPaint = Paint()..color = candleColor;
      if (isBull) {
        bodyPaint.style = PaintingStyle.stroke;
        bodyPaint.strokeWidth = 1.2;
      } else {
        bodyPaint.style = PaintingStyle.fill;
      }

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
    bool withArea,
  ) {
    final path = Path();
    final fillPath = Path();

    for (int i = 0; i < visibleCandles.length; i++) {
      final x = i * candleWidth + (candleWidth / 2);
      final y = priceToY(visibleCandles[i].close);

      if (i == 0) {
        path.moveTo(x, y);
        if (withArea) fillPath.moveTo(x, y);
      } else {
        path.lineTo(x, y);
        if (withArea) fillPath.lineTo(x, y);
      }
    }

    final linePaint = Paint()
      ..color = AppColor.accent
      ..strokeWidth = 2.0
      ..style = PaintingStyle.stroke;
    canvas.drawPath(path, linePaint);

    if (withArea && visibleCandles.isNotEmpty) {
      final lastX = (visibleCandles.length - 1) * candleWidth + (candleWidth / 2);
      fillPath.lineTo(lastX, priceToY(visibleCandles.last.close) + 120);
      fillPath.lineTo(candleWidth / 2, priceToY(visibleCandles.first.close) + 120);
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
    _drawSmoothLine(canvas, indicators!.ma200, startIdx, candleWidth, priceToY, const Color(0xFFFFFFFF), 1.6);
  }

  void _drawExponentialMovingAverages(
    Canvas canvas,
    double mainWidth,
    int startIdx,
    double Function(double) priceToY,
  ) {
    final candleWidth = mainWidth / visibleCandles.length;
    _drawSmoothLine(canvas, indicators!.ema9, startIdx, candleWidth, priceToY, const Color(0xFF00E676), 1.4);
    _drawSmoothLine(canvas, indicators!.ema21, startIdx, candleWidth, priceToY, const Color(0xFFFF7043), 1.4);
    _drawSmoothLine(canvas, indicators!.ema50, startIdx, candleWidth, priceToY, const Color(0xFFE040FB), 1.6);
    _drawSmoothLine(canvas, indicators!.ema200, startIdx, candleWidth, priceToY, const Color(0xFFFFD600), 1.6);
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

  void _drawParabolicSAR(
    Canvas canvas,
    double mainWidth,
    int startIdx,
    double candleWidth,
    double Function(double) priceToY,
  ) {
    for (int i = 0; i < visibleCandles.length; i++) {
      final gIdx = startIdx + i;
      if (gIdx < indicators!.sar.length && indicators!.sar[gIdx] != null) {
        final x = i * candleWidth + (candleWidth / 2);
        final y = priceToY(indicators!.sar[gIdx]!);
        final isBull = indicators!.sarIsBull[gIdx];

        final dotPaint = Paint()
          ..color = isBull ? AppColor.longGreen : AppColor.shortRed
          ..style = PaintingStyle.fill;
        canvas.drawCircle(Offset(x, y), max(1.5, candleWidth * 0.16), dotPaint);
      }
    }
  }

  void _drawSuperTrend(
    Canvas canvas,
    double mainWidth,
    int startIdx,
    double Function(double) priceToY,
  ) {
    final candleWidth = mainWidth / visibleCandles.length;
    for (int i = 0; i < visibleCandles.length - 1; i++) {
      final gIdx = startIdx + i;
      final nextIdx = gIdx + 1;
      if (gIdx < indicators!.superTrend.length && nextIdx < indicators!.superTrend.length) {
        final val1 = indicators!.superTrend[gIdx];
        final val2 = indicators!.superTrend[nextIdx];
        final dir = indicators!.superTrendDirection[gIdx];

        if (val1 != null && val2 != null) {
          final x1 = i * candleWidth + (candleWidth / 2);
          final y1 = priceToY(val1);
          final x2 = (i + 1) * candleWidth + (candleWidth / 2);
          final y2 = priceToY(val2);

          final stPaint = Paint()
            ..color = dir == 1 ? AppColor.longGreen : AppColor.shortRed
            ..strokeWidth = 2.0;
          canvas.drawLine(Offset(x1, y1), Offset(x2, y2), stPaint);
        }
      }
    }
  }

  void _drawVWAP(
    Canvas canvas,
    double mainWidth,
    int startIdx,
    double Function(double) priceToY,
  ) {
    final candleWidth = mainWidth / visibleCandles.length;
    _drawSmoothLine(canvas, indicators!.vwap, startIdx, candleWidth, priceToY, const Color(0xFF00E5FF), 1.6);
  }

  void _drawIchimokuCloud(
    Canvas canvas,
    double mainWidth,
    int startIdx,
    double Function(double) priceToY,
  ) {
    final candleWidth = mainWidth / visibleCandles.length;
    _drawSmoothLine(canvas, indicators!.ichimokuTenkan, startIdx, candleWidth, priceToY, const Color(0xFFFF9100), 1.2);
    _drawSmoothLine(canvas, indicators!.ichimokuKijun, startIdx, candleWidth, priceToY, const Color(0xFF2979FF), 1.2);

    // Cloud Fill
    final areaPath = Path();
    bool started = false;

    for (int i = 0; i < visibleCandles.length; i++) {
      final gIdx = startIdx + i;
      if (gIdx < indicators!.ichimokuSpanA.length &&
          indicators!.ichimokuSpanA[gIdx] != null &&
          indicators!.ichimokuSpanB[gIdx] != null) {
        final x = i * candleWidth + (candleWidth / 2);
        final aY = priceToY(indicators!.ichimokuSpanA[gIdx]!);

        if (!started) {
          areaPath.moveTo(x, aY);
          started = true;
        } else {
          areaPath.lineTo(x, aY);
        }
      }
    }

    if (started) {
      for (int i = visibleCandles.length - 1; i >= 0; i--) {
        final gIdx = startIdx + i;
        if (gIdx < indicators!.ichimokuSpanB.length && indicators!.ichimokuSpanB[gIdx] != null) {
          final x = i * candleWidth + (candleWidth / 2);
          final bY = priceToY(indicators!.ichimokuSpanB[gIdx]!);
          areaPath.lineTo(x, bY);
        }
      }
      areaPath.close();

      final cloudPaint = Paint()
        ..color = const Color(0xFF7C4DFF).withValues(alpha: 0.08)
        ..style = PaintingStyle.fill;
      canvas.drawPath(areaPath, cloudPaint);
    }
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

  // --- Sub Panels ---
  void _drawVolumePanel(Canvas canvas, double mainWidth, double mainHeight, double subHeight, int startIdx) {
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
      canvas.drawRect(Rect.fromLTWH(x - (candleWidth * 0.35), baseY - h, candleWidth * 0.7, h), volPaint);
    }

    if (indicators != null) {
      _drawSmoothLine(canvas, indicators!.volMa20, startIdx, candleWidth, (v) => baseY - (v / maxVol) * (subHeight - 16), const Color(0xFFFFD700), 1.2);
    }

    _drawText(canvas, 'VOL (거래량) / MA 20', Offset(8, mainHeight + 6), AppColor.textSecondary, 10);
  }

  void _drawRsiPanel(Canvas canvas, double mainWidth, double mainHeight, double subHeight, int startIdx) {
    final topY = mainHeight + 4;
    final botY = mainHeight + subHeight - 4;
    final h = botY - topY;
    double rsiToY(double rsi) => botY - (rsi / 100.0) * h;

    final dashPaint = Paint()..color = Colors.white.withValues(alpha: 0.1)..strokeWidth = 1.0;
    _drawDashedLine(canvas, Offset(0, rsiToY(70)), Offset(mainWidth, rsiToY(70)), dashPaint);
    _drawDashedLine(canvas, Offset(0, rsiToY(30)), Offset(mainWidth, rsiToY(30)), dashPaint);

    final bandPaint = Paint()..color = const Color(0xFFBA68C8).withValues(alpha: 0.05)..style = PaintingStyle.fill;
    canvas.drawRect(Rect.fromLTRB(0, rsiToY(70), mainWidth, rsiToY(30)), bandPaint);

    final candleWidth = mainWidth / visibleCandles.length;
    if (indicators != null) {
      _drawSmoothLine(canvas, indicators!.rsi14, startIdx, candleWidth, rsiToY, const Color(0xFFBA68C8), 1.5);
    }

    _drawText(canvas, 'RSI (14)', Offset(8, mainHeight + 6), const Color(0xFFBA68C8), 10);
    _drawText(canvas, '70', Offset(mainWidth + 6, rsiToY(70) - 5), AppColor.shortRed, 9);
    _drawText(canvas, '30', Offset(mainWidth + 6, rsiToY(30) - 5), AppColor.longGreen, 9);
  }

  void _drawMacdPanel(Canvas canvas, double mainWidth, double mainHeight, double subHeight, int startIdx) {
    if (indicators == null) return;
    final candleWidth = mainWidth / visibleCandles.length;
    final midY = mainHeight + (subHeight / 2);

    final zeroPaint = Paint()..color = Colors.white10..strokeWidth = 1.0;
    canvas.drawLine(Offset(0, midY), Offset(mainWidth, midY), zeroPaint);

    double maxVal = 1.0;
    for (int i = 0; i < visibleCandles.length; i++) {
      final gIdx = startIdx + i;
      if (gIdx < indicators!.macd.length) {
        final m = indicators!.macd[gIdx];
        final h = indicators!.macdHist[gIdx];
        if (m != null) maxVal = max(maxVal, m.abs());
        if (h != null) maxVal = max(maxVal, h.abs());
      }
    }

    double macdToY(double val) => midY - (val / maxVal) * (subHeight * 0.42);

    for (int i = 0; i < visibleCandles.length; i++) {
      final gIdx = startIdx + i;
      if (gIdx < indicators!.macdHist.length && indicators!.macdHist[gIdx] != null) {
        final hist = indicators!.macdHist[gIdx]!;
        final x = i * candleWidth + (candleWidth / 2);
        final barH = (hist / maxVal) * (subHeight * 0.42);

        final histPaint = Paint()
          ..color = (hist >= 0 ? AppColor.longGreen : AppColor.shortRed).withValues(alpha: 0.6)
          ..style = PaintingStyle.fill;
        canvas.drawRect(Rect.fromLTWH(x - (candleWidth * 0.3), midY, candleWidth * 0.6, -barH), histPaint);
      }
    }

    _drawSmoothLine(canvas, indicators!.macd, startIdx, candleWidth, macdToY, const Color(0xFF00E5FF), 1.4);
    _drawSmoothLine(canvas, indicators!.macdSignal, startIdx, candleWidth, macdToY, const Color(0xFFFFB300), 1.4);

    _drawText(canvas, 'MACD (12, 26, 9)', Offset(8, mainHeight + 6), const Color(0xFF00E5FF), 10);
  }

  void _drawKdjPanel(Canvas canvas, double mainWidth, double mainHeight, double subHeight, int startIdx) {
    final topY = mainHeight + 4;
    final botY = mainHeight + subHeight - 4;
    final h = botY - topY;
    double kdjToY(double v) => botY - (v / 100.0) * h;

    final dashPaint = Paint()..color = Colors.white.withValues(alpha: 0.1)..strokeWidth = 1.0;
    _drawDashedLine(canvas, Offset(0, kdjToY(80)), Offset(mainWidth, kdjToY(80)), dashPaint);
    _drawDashedLine(canvas, Offset(0, kdjToY(20)), Offset(mainWidth, kdjToY(20)), dashPaint);

    final candleWidth = mainWidth / visibleCandles.length;
    if (indicators != null) {
      _drawSmoothLine(canvas, indicators!.kdjK, startIdx, candleWidth, kdjToY, const Color(0xFF00E5FF), 1.2);
      _drawSmoothLine(canvas, indicators!.kdjD, startIdx, candleWidth, kdjToY, const Color(0xFFFFB300), 1.2);
      _drawSmoothLine(canvas, indicators!.kdjJ, startIdx, candleWidth, kdjToY, const Color(0xFFE040FB), 1.4);
    }

    _drawText(canvas, 'KDJ (9, 3, 3) - K(청) D(황) J(자)', Offset(8, mainHeight + 6), const Color(0xFF00E5FF), 10);
  }

  void _drawWrPanel(Canvas canvas, double mainWidth, double mainHeight, double subHeight, int startIdx) {
    final topY = mainHeight + 4;
    final botY = mainHeight + subHeight - 4;
    final h = botY - topY;
    double wrToY(double v) => topY + (v.abs() / 100.0) * h;

    final dashPaint = Paint()..color = Colors.white.withValues(alpha: 0.1)..strokeWidth = 1.0;
    _drawDashedLine(canvas, Offset(0, wrToY(-20)), Offset(mainWidth, wrToY(-20)), dashPaint);
    _drawDashedLine(canvas, Offset(0, wrToY(-80)), Offset(mainWidth, wrToY(-80)), dashPaint);

    final candleWidth = mainWidth / visibleCandles.length;
    if (indicators != null) {
      _drawSmoothLine(canvas, indicators!.wr14, startIdx, candleWidth, wrToY, const Color(0xFFFF7043), 1.4);
    }
    _drawText(canvas, 'Williams %R (14)', Offset(8, mainHeight + 6), const Color(0xFFFF7043), 10);
  }

  void _drawCciPanel(Canvas canvas, double mainWidth, double mainHeight, double subHeight, int startIdx) {
    final midY = mainHeight + (subHeight / 2);
    final candleWidth = mainWidth / visibleCandles.length;

    final zeroPaint = Paint()..color = Colors.white10..strokeWidth = 1.0;
    canvas.drawLine(Offset(0, midY), Offset(mainWidth, midY), zeroPaint);

    double cciToY(double v) => midY - (v / 200.0) * (subHeight * 0.42);

    final dashPaint = Paint()..color = Colors.white.withValues(alpha: 0.1)..strokeWidth = 1.0;
    _drawDashedLine(canvas, Offset(0, cciToY(100)), Offset(mainWidth, cciToY(100)), dashPaint);
    _drawDashedLine(canvas, Offset(0, cciToY(-100)), Offset(mainWidth, cciToY(-100)), dashPaint);

    if (indicators != null) {
      _drawSmoothLine(canvas, indicators!.cci20, startIdx, candleWidth, cciToY, const Color(0xFFFFCA28), 1.4);
    }
    _drawText(canvas, 'CCI (20) ±100', Offset(8, mainHeight + 6), const Color(0xFFFFCA28), 10);
  }

  void _drawAtrPanel(Canvas canvas, double mainWidth, double mainHeight, double subHeight, int startIdx) {
    if (indicators == null) return;
    double maxAtr = 1.0;
    for (int i = 0; i < visibleCandles.length; i++) {
      final gIdx = startIdx + i;
      if (gIdx < indicators!.atr14.length && indicators!.atr14[gIdx] != null) {
        maxAtr = max(maxAtr, indicators!.atr14[gIdx]!);
      }
    }
    final baseY = mainHeight + subHeight - 4;
    double atrToY(double v) => baseY - (v / maxAtr) * (subHeight - 20);

    final candleWidth = mainWidth / visibleCandles.length;
    _drawSmoothLine(canvas, indicators!.atr14, startIdx, candleWidth, atrToY, const Color(0xFF26A69A), 1.5);
    _drawText(canvas, 'ATR (14) 변동성', Offset(8, mainHeight + 6), const Color(0xFF26A69A), 10);
  }

  void _drawObvPanel(Canvas canvas, double mainWidth, double mainHeight, double subHeight, int startIdx) {
    if (indicators == null) return;
    double minObv = 1e12;
    double maxObv = -1e12;
    for (int i = 0; i < visibleCandles.length; i++) {
      final gIdx = startIdx + i;
      if (gIdx < indicators!.obv.length && indicators!.obv[gIdx] != null) {
        minObv = min(minObv, indicators!.obv[gIdx]!);
        maxObv = max(maxObv, indicators!.obv[gIdx]!);
      }
    }
    if (maxObv <= minObv) maxObv = minObv + 1.0;

    final topY = mainHeight + 8;
    final botY = mainHeight + subHeight - 8;
    double obvToY(double v) => botY - ((v - minObv) / (maxObv - minObv)) * (botY - topY);

    final candleWidth = mainWidth / visibleCandles.length;
    _drawSmoothLine(canvas, indicators!.obv, startIdx, candleWidth, obvToY, const Color(0xFF42A5F5), 1.4);
    _drawText(canvas, 'OBV (On-Balance Volume)', Offset(8, mainHeight + 6), const Color(0xFF42A5F5), 10);
  }

  // --- Crosshair ---
  void _drawCrosshair(
    Canvas canvas,
    Size size,
    double mainWidth,
    double mainHeight,
    double candleWidth,
    double Function(double) yToPrice,
  ) {
    if (hoverPosition == null) return;
    final pos = hoverPosition!;
    if (pos.dx < 0 || pos.dx > mainWidth || pos.dy < 0 || pos.dy > size.height) return;

    final crossPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.3)
      ..strokeWidth = 1.0;

    // Horizontal line
    _drawDashedLine(canvas, Offset(0, pos.dy), Offset(mainWidth, pos.dy), crossPaint);

    // Vertical line
    final int candleIdx = (pos.dx / candleWidth).floor().clamp(0, visibleCandles.length - 1);
    final candleCenterX = candleIdx * candleWidth + (candleWidth / 2);
    _drawDashedLine(canvas, Offset(candleCenterX, 0), Offset(candleCenterX, size.height), crossPaint);

    onHoverCandleIndex?.call(startIndex + candleIdx);

    // Right Y-axis Hover Price Badge
    if (pos.dy <= mainHeight) {
      final hoverPrice = yToPrice(pos.dy);
      final priceTagRect = RRect.fromRectAndRadius(
        Rect.fromLTWH(mainWidth + 2, pos.dy - 9, size.width - mainWidth - 4, 18),
        const Radius.circular(4),
      );
      canvas.drawRRect(priceTagRect, Paint()..color = const Color(0xFF374151));
      _drawText(
        canvas,
        hoverPrice.toStringAsFixed(1),
        Offset(mainWidth + 6, pos.dy - 5),
        Colors.white,
        10,
        isBold: true,
      );
    }

    // Bottom X-axis Hover Date Badge
    if (candleIdx < visibleCandles.length) {
      final timeStr = DateFormat('MM/dd HH:mm').format(visibleCandles[candleIdx].time);
      const badgeW = 74.0;
      final timeBadgeRect = RRect.fromRectAndRadius(
        Rect.fromLTWH(candleCenterX - (badgeW / 2), size.height - 18, badgeW, 16),
        const Radius.circular(4),
      );
      canvas.drawRRect(timeBadgeRect, Paint()..color = const Color(0xFF374151));
      _drawText(
        canvas,
        timeStr,
        Offset(candleCenterX - (badgeW / 2) + 4, size.height - 16),
        Colors.white,
        9,
      );
    }
  }

  void _drawDashedLine(Canvas canvas, Offset p1, Offset p2, Paint paint) {
    const double dashWidth = 4.0;
    const double dashSpace = 4.0;
    final double dx = p2.dx - p1.dx;
    final double dy = p2.dy - p1.dy;
    final double distance = sqrt(dx * dx + dy * dy);
    final double unitX = dx / distance;
    final double unitY = dy / distance;

    double current = 0.0;
    while (current < distance) {
      final start = Offset(p1.dx + unitX * current, p1.dy + unitY * current);
      current = min(distance, current + dashWidth);
      final end = Offset(p1.dx + unitX * current, p1.dy + unitY * current);
      canvas.drawLine(start, end, paint);
      current += dashSpace;
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

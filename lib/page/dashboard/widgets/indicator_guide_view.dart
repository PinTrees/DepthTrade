import 'dart:math';
import 'package:flutter/material.dart';
import '../../../engine/grid_bot_engine.dart';
import '../../../models/candle_data.dart';
import '../../../models/grid_config.dart';
import '../../../service/bitget_api_service.dart';
import '../../../style/style.dart';
import '../../../widget/chart/indicator_guide_dialog.dart';
import '../../../widget/chart/technical_indicator_calculator.dart';
import '../../../widget/chart/trading_view_chart_viewer.dart';

/// Unified Technical Indicator Guide & Simulation View for Dashboard
class IndicatorGuideView extends StatefulWidget {
  final String? initialIndicatorId;
  final List<CandleData>? candles;
  final double? currentPrice;
  final String? activeInterval;
  final VoidCallback? onReturnToTerminal;
  final ValueChanged<String>? onIndicatorChanged;
  final ValueChanged<String>? onIntervalChanged;

  const IndicatorGuideView({
    super.key,
    this.initialIndicatorId,
    this.candles,
    this.currentPrice,
    this.activeInterval,
    this.onReturnToTerminal,
    this.onIndicatorChanged,
    this.onIntervalChanged,
  });

  @override
  State<IndicatorGuideView> createState() => _IndicatorGuideViewState();
}

class _IndicatorGuideViewState extends State<IndicatorGuideView> {
  late String _currentId;
  String _searchQuery = '';
  String _selectedCategory = '전체';
  final TextEditingController _searchController = TextEditingController();

  List<CandleData> _btcCandles = [];
  double _btcPrice = 0.0;
  String _chartInterval = '15m';
  bool _isLoadingCandles = false;

  IndicatorParams _indicatorParams = const IndicatorParams();
  String? _injectedFeedback;

  @override
  void initState() {
    super.initState();
    _currentId = widget.initialIndicatorId ?? 'sma';
    _chartInterval = widget.activeInterval ?? '15m';
    if (widget.candles != null && widget.candles!.isNotEmpty) {
      _btcCandles = widget.candles!;
    }
    if (widget.currentPrice != null && widget.currentPrice! > 0) {
      _btcPrice = widget.currentPrice!;
    }
    if (_btcCandles.isEmpty) {
      _fetchBtcCandles();
    }
  }

  Future<void> _fetchBtcCandles() async {
    if (_isLoadingCandles) return;
    _isLoadingCandles = true;
    try {
      final candles = await BitgetApiService.instance.getCandles('BTCUSDT', _chartInterval, 120);
      if (mounted && candles.isNotEmpty) {
        setState(() {
          _btcCandles = candles;
          if (_btcPrice <= 0) {
            _btcPrice = candles.last.close;
          }
        });
      }
    } catch (_) {
    } finally {
      _isLoadingCandles = false;
    }
  }

  @override
  void didUpdateWidget(covariant IndicatorGuideView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.initialIndicatorId != null &&
        widget.initialIndicatorId != oldWidget.initialIndicatorId &&
        widget.initialIndicatorId != _currentId) {
      setState(() {
        _currentId = widget.initialIndicatorId!;
      });
    }
    if (widget.candles != null && widget.candles != oldWidget.candles && widget.candles!.isNotEmpty) {
      setState(() {
        _btcCandles = widget.candles!;
      });
    }
    if (widget.currentPrice != null && widget.currentPrice != oldWidget.currentPrice && widget.currentPrice! > 0) {
      setState(() {
        _btcPrice = widget.currentPrice!;
      });
    }
    if (widget.activeInterval != null && widget.activeInterval != oldWidget.activeInterval) {
      setState(() {
        _chartInterval = widget.activeInterval!;
      });
      _fetchBtcCandles();
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _selectIndicator(String id) {
    if (_currentId == id) return;
    setState(() {
      _currentId = id;
    });
    widget.onIndicatorChanged?.call(id);
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: ThemeService.instance,
      builder: (context, _) {
        final isDark = ThemeService.instance.isDark;
        final allIndicators = IndicatorMeta.all;
        final meta = IndicatorMeta.get(_currentId);

        final filteredList = allIndicators.where((item) {
          if (_selectedCategory != '전체') {
            if (!item.category.contains(_selectedCategory)) {
              return false;
            }
          }
          if (_searchQuery.trim().isEmpty) return true;
          final q = _searchQuery.toLowerCase();
          return item.title.toLowerCase().contains(q) ||
              item.englishName.toLowerCase().contains(q) ||
              item.category.toLowerCase().contains(q) ||
              item.summary.toLowerCase().contains(q);
        }).toList();

        return LayoutBuilder(
          builder: (context, constraints) {
            final isWide = constraints.maxWidth >= 960;

            if (isWide) {
              return Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // 1. Left Indicator List Sidebar (Width 290)
                  SizedBox(
                    width: 290,
                    child: _buildSidebar(filteredList, isDark),
                  ),

                  // 2. Main Indicator Simulation & Guide Content Area
                  Expanded(
                    child: _buildMainContent(meta, allIndicators, isDark),
                  ),
                ],
              );
            } else {
              // Mobile & Tablet Layout
              return Column(
                children: [
                  // Top horizontal chips
                  _buildMobileIndicatorChips(allIndicators, isDark),

                  // Main Content
                  Expanded(
                    child: _buildMainContent(meta, allIndicators, isDark),
                  ),
                ],
              );
            }
          },
        );
      },
    );
  }

  /// 1. Indicator Sidebar (Desktop) - Unifies with DashboardSidebar & DepthTrade Design System
  Widget _buildSidebar(List<IndicatorMeta> list, bool isDark) {
    return Container(
      decoration: BoxDecoration(
        color: AppColor.backgroundCard.withValues(alpha: 0.95),
        boxShadow: AppColor.subtleShadow,
      ),
      child: Column(
        children: [
          // Sidebar Header (Branding & Indicator Count)
          _buildSidebarHeader(list),

          // Search Input Bar
          _buildSidebarSearch(),

          // Category Quick Filter Chips
          _buildSidebarCategoryChips(isDark),
          const SizedBox(height: 4),

          // Indicator Item List
          Expanded(
            child: list.isEmpty
                ? Center(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Text(
                        '검색 결과와 일치하는 지표가 없습니다.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 12,
                          color: AppColor.textDisabled,
                        ),
                      ),
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    itemCount: list.length,
                    itemBuilder: (context, idx) {
                      final item = list[idx];
                      return _IndicatorSidebarItem(
                        item: item,
                        isSelected: item.id == _currentId,
                        isDark: isDark,
                        onTap: () => _selectIndicator(item.id),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  /// Sidebar Branding Header
  Widget _buildSidebarHeader(List<IndicatorMeta> list) {
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 16, 12, 10),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [AppColor.accent, AppColor.primary],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(8),
              boxShadow: [
                BoxShadow(
                  color: AppColor.accent.withValues(alpha: 0.35),
                  blurRadius: 8,
                ),
              ],
            ),
            child: const Icon(Icons.auto_stories_rounded, color: Colors.white, size: 18),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'INDICATOR LAB',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1.1,
                    color: AppColor.textPrimary,
                  ),
                ),
                Text(
                  'TECHNICAL ANALYSIS',
                  style: TextStyle(
                    fontSize: 8.5,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.8,
                    color: AppColor.accent,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
            decoration: BoxDecoration(
              color: AppColor.accent.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              '${list.length}개',
              style: const TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.bold,
                color: AppColor.accent,
                fontFamily: 'monospace',
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Sidebar Search Bar
  Widget _buildSidebarSearch() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      child: Container(
        height: 38,
        decoration: BoxDecoration(
          color: AppColor.inputSurface,
          borderRadius: BorderRadius.circular(10),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 10),
        child: TextField(
          controller: _searchController,
          onChanged: (val) => setState(() => _searchQuery = val),
          style: TextStyle(fontSize: 12, color: AppColor.textPrimary),
          decoration: InputDecoration(
            isDense: true,
            border: InputBorder.none,
            icon: Icon(Icons.search, size: 16, color: AppColor.textSecondary),
            hintText: '지표명 또는 카테고리 검색...',
            hintStyle: TextStyle(fontSize: 11, color: AppColor.textDisabled),
            contentPadding: const EdgeInsets.symmetric(vertical: 10),
            suffixIcon: _searchQuery.isNotEmpty
                ? IconButton(
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                    icon: const Icon(Icons.clear, size: 14),
                    onPressed: () {
                      _searchController.clear();
                      setState(() => _searchQuery = '');
                    },
                  )
                : null,
          ),
        ),
      ),
    );
  }

  /// Sidebar Category Chips
  Widget _buildSidebarCategoryChips(bool isDark) {
    final categories = const ['전체', '추세', '변동성', '오실레이터', '거래량'];
    return Padding(
      padding: const EdgeInsets.fromLTRB(10, 4, 10, 4),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: categories.map((cat) {
            final isSelected = _selectedCategory == cat;
            return Padding(
              padding: const EdgeInsets.only(right: 6),
              child: InkWell(
                onTap: () => setState(() => _selectedCategory = cat),
                borderRadius: BorderRadius.circular(6),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3.5),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? AppColor.primary.withValues(alpha: 0.22)
                        : AppColor.inputSurface.withValues(alpha: 0.6),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    cat,
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                      color: isSelected ? AppColor.accent : AppColor.textSecondary,
                    ),
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  /// Mobile & Tablet Horizontal Chips
  Widget _buildMobileIndicatorChips(List<IndicatorMeta> list, bool isDark) {
    return Container(
      height: 52,
      padding: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        color: AppColor.backgroundCard.withValues(alpha: 0.95),
        boxShadow: AppColor.subtleShadow,
      ),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        itemCount: list.length,
        itemBuilder: (context, idx) {
          final item = list[idx];
          final isSelected = item.id == _currentId;

          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: InkWell(
              borderRadius: BorderRadius.circular(10),
              onTap: () => _selectIndicator(item.id),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 160),
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: isSelected
                      ? AppColor.primary.withValues(alpha: isDark ? 0.22 : 0.15)
                      : AppColor.inputSurface,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      item.icon,
                      size: 14,
                      color: isSelected ? AppColor.accent : AppColor.textSecondary,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      item.title.split(' ').first,
                      style: TextStyle(
                        fontSize: 11.5,
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                        color: isSelected ? AppColor.accent : AppColor.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  /// 2. Main Detail Content Area
  Widget _buildMainContent(
    IndicatorMeta meta,
    List<IndicatorMeta> all,
    bool isDark,
  ) {
    final currentIndex = all.indexWhere((m) => m.id == meta.id);

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 40),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 880),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Top Action Row (Return to Terminal Button + Category Badge)
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppColor.primary.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          meta.category,
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: AppColor.accent,
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Text(
                        'URL: /indicators/${meta.id}',
                        style: TextStyle(
                          fontSize: 11,
                          fontFamily: 'monospace',
                          color: AppColor.textDisabled,
                        ),
                      ),
                    ],
                  ),

                  // Return to Terminal Quick Button
                  if (widget.onReturnToTerminal != null)
                    InkWell(
                      borderRadius: BorderRadius.circular(8),
                      onTap: widget.onReturnToTerminal,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(
                          color: AppColor.inputSurface,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.candlestick_chart, size: 14, color: AppColor.accent),
                            const SizedBox(width: 6),
                            Text(
                              '터미널 차트로 복귀',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: AppColor.textPrimary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 10),

              // Title & Subtitle
              Text(
                meta.title,
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w900,
                  color: AppColor.textPrimary,
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 4),

              Text(
                meta.englishName,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: AppColor.textSecondary,
                ),
              ),
              const SizedBox(height: 16),

              // Summary Box (Simple is Best, Accent Bar)
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColor.cardSurface.withValues(alpha: isDark ? 0.8 : 0.95),
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: AppColor.subtleShadow,
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 4,
                      height: 40,
                      decoration: BoxDecoration(
                        color: AppColor.accent,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        meta.summary,
                        style: TextStyle(
                          fontSize: 13.5,
                          height: 1.55,
                          color: AppColor.textPrimary,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Real Bitcoin (BTC/USDT) Chart Card with active indicator
              _buildRealBtcChartCard(meta, isDark),
              const SizedBox(height: 24),

              // Formula Box
              _buildSectionTitle('📐 수학적 계산 공식 및 알고리즘'),
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: (isDark ? Colors.black : const Color(0xFFF1F5F9)).withValues(alpha: 0.75),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: SelectableText(
                  meta.formula,
                  style: const TextStyle(
                    fontFamily: 'monospace',
                    fontSize: 12.5,
                    height: 1.5,
                    color: AppColor.accent,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Actionable Trading Signals
              _buildSectionTitle('⚡ 실전 트레이딩 매매 시그널'),
              const SizedBox(height: 10),
              ...meta.signals.map((sig) => Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: AppColor.cardSurface.withValues(alpha: isDark ? 0.7 : 0.9),
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: AppColor.subtleShadow,
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Padding(
                            padding: EdgeInsets.only(top: 2),
                            child: Icon(Icons.check_circle_rounded, size: 16, color: AppColor.accent),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              sig,
                              style: TextStyle(
                                fontSize: 13,
                                height: 1.5,
                                color: AppColor.textPrimary,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  )),
              const SizedBox(height: 24),

              // Quant Bot Synergy Section
              _buildSectionTitle('🤖 DepthTrade 퀀트 봇 활용 시너지 전략'),
              const SizedBox(height: 10),
              ...meta.quantBotTips.map((tip) => Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: AppColor.cardSurface.withValues(alpha: isDark ? 0.7 : 0.9),
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: AppColor.subtleShadow,
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Padding(
                            padding: EdgeInsets.only(top: 2),
                            child: Icon(Icons.smart_toy_rounded, size: 16, color: AppColor.accent),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              tip,
                              style: TextStyle(
                                fontSize: 13,
                                height: 1.5,
                                color: AppColor.textSecondary,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  )),
              const SizedBox(height: 16),

              // Quant Bot Strategy Preset One-Click Injection Card
              _buildQuantPresetInjectionCard(meta, isDark),
              const SizedBox(height: 32),

              // Footer Navigation
              _buildFooterActions(context, all, currentIndex),
            ],
          ),
        ),
      ),
    );
  }

  /// Real Bitcoin (BTC/USDT) Chart Card with active indicator, live tuner, and signal confluence badge
  Widget _buildRealBtcChartCard(IndicatorMeta meta, bool isDark) {
    final effectivePrice = widget.currentPrice != null && widget.currentPrice! > 0
        ? widget.currentPrice!
        : (_btcPrice > 0 ? _btcPrice : (GridBotEngine.instance.currentPrice > 0 ? GridBotEngine.instance.currentPrice : 0.0));

    final effectiveCandles = widget.candles != null && widget.candles!.isNotEmpty
        ? widget.candles!
        : _btcCandles;

    final signal = _computeSignalAnalysis(meta.id, effectiveCandles, _indicatorParams);

    return Container(
      decoration: BoxDecoration(
        color: AppColor.cardSurface.withValues(alpha: isDark ? 0.9 : 0.95),
        borderRadius: BorderRadius.circular(16),
        boxShadow: AppColor.elevationShadow,
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Top Bar: Symbol Title, Signal Confluence Status Badge, Live Price
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              color: AppColor.inputSurface,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Row(
                      children: [
                        Container(
                          width: 8,
                          height: 8,
                          decoration: const BoxDecoration(
                            color: AppColor.accent,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Flexible(
                          child: Text(
                            'BTC/USDT 실시간 비트코인 차트 (${meta.title})',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: AppColor.textPrimary,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 10),

                  // Signal & Confluence Badge + Price Badge
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Realtime Signal Status Badge (Zero border)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                        decoration: BoxDecoration(
                          color: signal.color.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(signal.icon, size: 12, color: signal.color),
                            const SizedBox(width: 5),
                            Text(
                              signal.label,
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: signal.color,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),

                      // Live BTC Price Badge
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3.5),
                        decoration: BoxDecoration(
                          color: AppColor.primary.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          effectivePrice > 0
                              ? '${effectivePrice.toStringAsFixed(1)} USDT'
                              : 'LIVE BTC/USDT',
                          style: const TextStyle(
                            fontSize: 10.5,
                            fontWeight: FontWeight.bold,
                            color: AppColor.accent,
                            fontFamily: 'monospace',
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // Live Indicator Parameter Tuner Bar (Simple is best, zero borders)
            _buildLiveParameterTuner(meta, isDark),

            // Live Interactive TradingView Candlestick Chart
            SizedBox(
              height: 440,
              child: effectiveCandles.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(strokeWidth: 2, color: AppColor.accent),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            '비트코인 실시간 캔들 로딩 중...',
                            style: TextStyle(fontSize: 12, color: AppColor.textSecondary),
                          ),
                        ],
                      ),
                    )
                  : TradingViewChartViewer(
                      candles: effectiveCandles,
                      currentPrice: effectivePrice,
                      liveBuyOrders: const [],
                      liveCloseOrders: const [],
                      activeInterval: _chartInterval,
                      focusedIndicatorId: meta.id,
                      indicatorParams: _indicatorParams,
                      onIntervalChanged: (newInterval) {
                        setState(() => _chartInterval = newInterval);
                        _fetchBtcCandles();
                        widget.onIntervalChanged?.call(newInterval);
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }

  /// Live Parameter Tuner Bar for focused indicator
  Widget _buildLiveParameterTuner(IndicatorMeta meta, bool isDark) {
    final widgets = <Widget>[];

    switch (meta.id) {
      case 'rsi':
        widgets.add(_TunerIntStepper(
          label: 'RSI Period',
          value: _indicatorParams.rsiPeriod,
          min: 5,
          max: 50,
          step: 1,
          onChanged: (v) => setState(() => _indicatorParams = _indicatorParams.copyWith(rsiPeriod: v)),
        ));
        break;

      case 'bb':
        widgets.add(_TunerIntStepper(
          label: 'BB Period',
          value: _indicatorParams.bbPeriod,
          min: 10,
          max: 60,
          step: 5,
          onChanged: (v) => setState(() => _indicatorParams = _indicatorParams.copyWith(bbPeriod: v)),
        ));
        widgets.add(const SizedBox(width: 8));
        widgets.add(_TunerDoubleStepper(
          label: 'Multiplier',
          value: _indicatorParams.bbMultiplier,
          min: 1.0,
          max: 4.0,
          step: 0.5,
          onChanged: (v) => setState(() => _indicatorParams = _indicatorParams.copyWith(bbMultiplier: v)),
        ));
        break;

      case 'sma':
        widgets.add(_TunerIntStepper(
          label: 'Fast',
          value: _indicatorParams.sma7,
          min: 3,
          max: 20,
          step: 1,
          onChanged: (v) => setState(() => _indicatorParams = _indicatorParams.copyWith(sma7: v)),
        ));
        widgets.add(const SizedBox(width: 8));
        widgets.add(_TunerIntStepper(
          label: 'Mid',
          value: _indicatorParams.sma25,
          min: 10,
          max: 50,
          step: 5,
          onChanged: (v) => setState(() => _indicatorParams = _indicatorParams.copyWith(sma25: v)),
        ));
        widgets.add(const SizedBox(width: 8));
        widgets.add(_TunerIntStepper(
          label: 'Slow',
          value: _indicatorParams.sma99,
          min: 50,
          max: 150,
          step: 10,
          onChanged: (v) => setState(() => _indicatorParams = _indicatorParams.copyWith(sma99: v)),
        ));
        break;

      case 'ema':
        widgets.add(_TunerIntStepper(
          label: 'EMA 1',
          value: _indicatorParams.ema9,
          min: 3,
          max: 20,
          step: 1,
          onChanged: (v) => setState(() => _indicatorParams = _indicatorParams.copyWith(ema9: v)),
        ));
        widgets.add(const SizedBox(width: 8));
        widgets.add(_TunerIntStepper(
          label: 'EMA 2',
          value: _indicatorParams.ema21,
          min: 10,
          max: 50,
          step: 2,
          onChanged: (v) => setState(() => _indicatorParams = _indicatorParams.copyWith(ema21: v)),
        ));
        break;

      case 'super_trend':
        widgets.add(_TunerIntStepper(
          label: 'ATR Period',
          value: _indicatorParams.superTrendPeriod,
          min: 5,
          max: 30,
          step: 1,
          onChanged: (v) => setState(() => _indicatorParams = _indicatorParams.copyWith(superTrendPeriod: v)),
        ));
        widgets.add(const SizedBox(width: 8));
        widgets.add(_TunerDoubleStepper(
          label: 'Multiplier',
          value: _indicatorParams.superTrendMultiplier,
          min: 1.0,
          max: 5.0,
          step: 0.5,
          onChanged: (v) => setState(() => _indicatorParams = _indicatorParams.copyWith(superTrendMultiplier: v)),
        ));
        break;

      case 'macd':
        widgets.add(_TunerIntStepper(
          label: 'Fast',
          value: _indicatorParams.macdFast,
          min: 5,
          max: 20,
          step: 1,
          onChanged: (v) => setState(() => _indicatorParams = _indicatorParams.copyWith(macdFast: v)),
        ));
        widgets.add(const SizedBox(width: 8));
        widgets.add(_TunerIntStepper(
          label: 'Slow',
          value: _indicatorParams.macdSlow,
          min: 20,
          max: 40,
          step: 2,
          onChanged: (v) => setState(() => _indicatorParams = _indicatorParams.copyWith(macdSlow: v)),
        ));
        widgets.add(const SizedBox(width: 8));
        widgets.add(_TunerIntStepper(
          label: 'Signal',
          value: _indicatorParams.macdSignal,
          min: 5,
          max: 15,
          step: 1,
          onChanged: (v) => setState(() => _indicatorParams = _indicatorParams.copyWith(macdSignal: v)),
        ));
        break;

      case 'kdj':
        widgets.add(_TunerIntStepper(
          label: 'N Period',
          value: _indicatorParams.kdjN,
          min: 5,
          max: 25,
          step: 1,
          onChanged: (v) => setState(() => _indicatorParams = _indicatorParams.copyWith(kdjN: v)),
        ));
        break;

      case 'wr':
        widgets.add(_TunerIntStepper(
          label: 'Period',
          value: _indicatorParams.wrPeriod,
          min: 5,
          max: 30,
          step: 1,
          onChanged: (v) => setState(() => _indicatorParams = _indicatorParams.copyWith(wrPeriod: v)),
        ));
        break;

      case 'cci':
        widgets.add(_TunerIntStepper(
          label: 'Period',
          value: _indicatorParams.cciPeriod,
          min: 10,
          max: 40,
          step: 2,
          onChanged: (v) => setState(() => _indicatorParams = _indicatorParams.copyWith(cciPeriod: v)),
        ));
        break;

      case 'atr':
        widgets.add(_TunerIntStepper(
          label: 'Period',
          value: _indicatorParams.atrPeriod,
          min: 5,
          max: 30,
          step: 1,
          onChanged: (v) => setState(() => _indicatorParams = _indicatorParams.copyWith(atrPeriod: v)),
        ));
        break;

      case 'sar':
        widgets.add(_TunerDoubleStepper(
          label: 'Step',
          value: _indicatorParams.sarStep,
          min: 0.01,
          max: 0.05,
          step: 0.01,
          onChanged: (v) => setState(() => _indicatorParams = _indicatorParams.copyWith(sarStep: v)),
        ));
        widgets.add(const SizedBox(width: 8));
        widgets.add(_TunerDoubleStepper(
          label: 'Max Step',
          value: _indicatorParams.sarMaxStep,
          min: 0.10,
          max: 0.40,
          step: 0.05,
          onChanged: (v) => setState(() => _indicatorParams = _indicatorParams.copyWith(sarMaxStep: v)),
        ));
        break;

      default:
        widgets.add(
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: AppColor.cardSurface,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.check_circle_outline, size: 13, color: AppColor.accent),
                const SizedBox(width: 6),
                Text(
                  '표준 수식 연산 모드 (TradingView/TA-Lib 표준)',
                  style: TextStyle(fontSize: 11, color: AppColor.textSecondary),
                ),
              ],
            ),
          ),
        );
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      color: AppColor.cardSurface.withValues(alpha: isDark ? 0.7 : 0.85),
      child: Row(
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.tune_rounded, size: 14, color: AppColor.accent),
              const SizedBox(width: 6),
              Text(
                '파라미터 튜너:',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: AppColor.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(width: 12),
          Expanded(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  ...widgets,
                  const SizedBox(width: 12),
                  // Reset Button
                  InkWell(
                    borderRadius: BorderRadius.circular(6),
                    onTap: () {
                      setState(() {
                        _indicatorParams = const IndicatorParams();
                      });
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppColor.inputSurface,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.refresh_rounded, size: 12, color: AppColor.textSecondary),
                          const SizedBox(width: 4),
                          Text(
                            '기본값',
                            style: TextStyle(fontSize: 10.5, color: AppColor.textSecondary),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Quant Bot Strategy Preset One-Click Card
  Widget _buildQuantPresetInjectionCard(IndicatorMeta meta, bool isDark) {
    final preset = _QuantBotPreset.forIndicator(meta.id);
    final botRunning = GridBotEngine.instance.isRunning;
    final currentCfg = GridBotEngine.instance.config;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColor.cardSurface.withValues(alpha: isDark ? 0.88 : 0.96),
        borderRadius: BorderRadius.circular(16),
        boxShadow: AppColor.elevationShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header Row
          Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [AppColor.accent, AppColor.primary],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(10),
                  boxShadow: [
                    BoxShadow(
                      color: AppColor.accent.withValues(alpha: 0.3),
                      blurRadius: 8,
                    ),
                  ],
                ),
                child: const Icon(Icons.smart_toy_rounded, color: Colors.white, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '퀀트 봇 파라미터 즉시 주입 (One-Click Bot Preset)',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: AppColor.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${meta.title} 전략에 최적화된 그리드 간격과 주문 깊이를 즉시 주입합니다.',
                      style: TextStyle(
                        fontSize: 11.5,
                        color: AppColor.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              // Current Bot Live State Indicator Pill
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: botRunning
                      ? AppColor.upColor.withValues(alpha: 0.15)
                      : AppColor.inputSurface,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 7,
                      height: 7,
                      decoration: BoxDecoration(
                        color: botRunning ? AppColor.upColor : AppColor.textDisabled,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      botRunning ? '봇 가동 중' : '봇 대기 중',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: botRunning ? AppColor.upColor : AppColor.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Strategy Description Box
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: AppColor.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.tips_and_updates_rounded, size: 16, color: AppColor.accent),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    preset.description,
                    style: TextStyle(
                      fontSize: 12.5,
                      height: 1.45,
                      color: AppColor.textPrimary,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // 4 Metric Tiles (Grid)
          Row(
            children: [
              Expanded(
                child: _buildMetricTile(
                  label: '매수 간격 (openOrderPer)',
                  value: '+${preset.openOrderPer.toStringAsFixed(2)}%',
                  current: '현재: ${currentCfg.openOrderPer.toStringAsFixed(2)}%',
                  accentColor: AppColor.accent,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _buildMetricTile(
                  label: '익절 간격 (closeOrderPer)',
                  value: '+${preset.closeOrderPer.toStringAsFixed(2)}%',
                  current: '현재: ${currentCfg.closeOrderPer.toStringAsFixed(2)}%',
                  accentColor: AppColor.upColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: _buildMetricTile(
                  label: '이격 취소도 (canclePer)',
                  value: '+${preset.canclePer.toStringAsFixed(2)}%',
                  current: '현재: ${currentCfg.canclePer.toStringAsFixed(2)}%',
                  accentColor: AppColor.downColor,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _buildMetricTile(
                  label: '주문 깊이 (orderDepth)',
                  value: '${preset.orderDepth}단계',
                  current: '현재: ${currentCfg.orderDepth}단계',
                  accentColor: AppColor.accent,
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),

          // Injection Confirmation Feedback Banner (if triggered)
          if (_injectedFeedback != null) ...[
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              decoration: BoxDecoration(
                color: AppColor.accent.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                children: [
                  const Icon(Icons.check_circle_rounded, color: AppColor.accent, size: 18),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      _injectedFeedback!,
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: AppColor.accent,
                      ),
                    ),
                  ),
                  if (widget.onReturnToTerminal != null)
                    InkWell(
                      borderRadius: BorderRadius.circular(6),
                      onTap: widget.onReturnToTerminal,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppColor.primary,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: const Text(
                          '터미널로 이동',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 14),
          ],

          // One-Click Inject Action Button
          SizedBox(
            height: 46,
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColor.primary,
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              icon: const Icon(Icons.bolt_rounded, size: 20),
              label: Text(
                '🤖 "${preset.title}" 전략 파라미터 그리드 봇에 즉시 주입하기',
                style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.bold),
              ),
              onPressed: () {
                final currentConfig = GridBotEngine.instance.config;
                final newConfig = GridConfig(
                  symbol: currentConfig.symbol,
                  leverage: currentConfig.leverage,
                  openOrderPer: preset.openOrderPer,
                  closeOrderPer: preset.closeOrderPer,
                  canclePer: preset.canclePer,
                  orderDepth: preset.orderDepth,
                  overlapPer: currentConfig.overlapPer,
                  stoplossFibonacci: currentConfig.stoplossFibonacci,
                  fixedOrderCount: currentConfig.fixedOrderCount,
                  baseOrderSize: currentConfig.baseOrderSize,
                  posLowPrice: currentConfig.posLowPrice,
                  isSimulation: currentConfig.isSimulation,
                );
                GridBotEngine.instance.updateConfig(newConfig);
                setState(() {
                  _injectedFeedback = '${preset.title} 파라미터가 그리드 봇에 즉시 주입되었습니다!';
                });
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('${preset.title} 파라미터가 그리드 봇에 주입되었습니다.'),
                    backgroundColor: AppColor.primary,
                    behavior: SnackBarBehavior.floating,
                    duration: const Duration(seconds: 2),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  /// Metric Tile for Preset Card
  Widget _buildMetricTile({
    required String label,
    required String value,
    required String current,
    required Color accentColor,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: AppColor.inputSurface,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(fontSize: 11, color: AppColor.textSecondary),
          ),
          const SizedBox(height: 4),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                value,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  fontFamily: 'monospace',
                  color: accentColor,
                ),
              ),
              Text(
                current,
                style: TextStyle(
                  fontSize: 10,
                  fontFamily: 'monospace',
                  color: AppColor.textDisabled,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// Real-time Signal Confluence Analysis on BTC Candles
  _SignalInfo _computeSignalAnalysis(
    String id,
    List<CandleData> candles,
    IndicatorParams params,
  ) {
    if (candles.isEmpty) {
      return _SignalInfo(
        label: '비트코인 캔들 수신 대기 중',
        color: AppColor.textSecondary,
        icon: Icons.sync,
      );
    }

    final ind = TechnicalIndicatorCalculator.compute(candles, params);
    final lastClose = candles.last.close;

    switch (id) {
      case 'rsi':
        final rsi = ind.rsi14.lastWhere((v) => v != null, orElse: () => null);
        if (rsi != null) {
          if (rsi <= 30) {
            return _SignalInfo(
              label: '과매도 반등 대기 (RSI ${rsi.toStringAsFixed(1)})',
              color: AppColor.upColor,
              icon: Icons.arrow_upward_rounded,
            );
          } else if (rsi >= 70) {
            return _SignalInfo(
              label: '과매수 저항 경계 (RSI ${rsi.toStringAsFixed(1)})',
              color: AppColor.downColor,
              icon: Icons.arrow_downward_rounded,
            );
          } else {
            return _SignalInfo(
              label: '중립 모멘텀 순항 (RSI ${rsi.toStringAsFixed(1)})',
              color: AppColor.accent,
              icon: Icons.check_circle_outline_rounded,
            );
          }
        }
        break;

      case 'bb':
        final upper = ind.bbUpper.lastWhere((v) => v != null, orElse: () => null);
        final lower = ind.bbLower.lastWhere((v) => v != null, orElse: () => null);
        final mid = ind.bbMid.lastWhere((v) => v != null, orElse: () => null);
        if (upper != null && lower != null && mid != null) {
          final bandwidth = ((upper - lower) / mid) * 100.0;
          if (lastClose <= lower) {
            return _SignalInfo(
              label: '볼린저 하단 지지 터치 (폭 ${bandwidth.toStringAsFixed(1)}%)',
              color: AppColor.upColor,
              icon: Icons.arrow_upward_rounded,
            );
          } else if (lastClose >= upper) {
            return _SignalInfo(
              label: '볼린저 상단 저항 돌파 (폭 ${bandwidth.toStringAsFixed(1)}%)',
              color: AppColor.downColor,
              icon: Icons.arrow_downward_rounded,
            );
          } else {
            return _SignalInfo(
              label: '밴드 내 중심 회귀 중 (폭 ${bandwidth.toStringAsFixed(1)}%)',
              color: AppColor.accent,
              icon: Icons.sync_rounded,
            );
          }
        }
        break;

      case 'super_trend':
        final dir = ind.superTrendDirection.isNotEmpty ? ind.superTrendDirection.last : 1;
        final st = ind.superTrend.lastWhere((v) => v != null, orElse: () => null);
        if (dir == 1) {
          return _SignalInfo(
            label: '슈퍼트렌드 강세 매수 유지 (${st != null ? st.toStringAsFixed(0) : ''} 지지)',
            color: AppColor.upColor,
            icon: Icons.trending_up_rounded,
          );
        } else {
          return _SignalInfo(
            label: '슈퍼트렌드 약세 매도 압력 (${st != null ? st.toStringAsFixed(0) : ''} 저항)',
            color: AppColor.downColor,
            icon: Icons.trending_down_rounded,
          );
        }

      case 'sma':
        final ma7 = ind.ma7.lastWhere((v) => v != null, orElse: () => null);
        final ma25 = ind.ma25.lastWhere((v) => v != null, orElse: () => null);
        if (ma7 != null && ma25 != null) {
          if (ma7 > ma25) {
            return _SignalInfo(
              label: 'SMA 단기 정배열 상승 (7 > 25)',
              color: AppColor.upColor,
              icon: Icons.trending_up_rounded,
            );
          } else {
            return _SignalInfo(
              label: 'SMA 단기 역배열 조정 (7 < 25)',
              color: AppColor.downColor,
              icon: Icons.trending_down_rounded,
            );
          }
        }
        break;

      case 'ema':
        final ema9 = ind.ema9.lastWhere((v) => v != null, orElse: () => null);
        final ema21 = ind.ema21.lastWhere((v) => v != null, orElse: () => null);
        if (ema9 != null && ema21 != null) {
          if (ema9 > ema21) {
            return _SignalInfo(
              label: 'EMA 가중 골든크로스 강세 (9 > 21)',
              color: AppColor.upColor,
              icon: Icons.trending_up_rounded,
            );
          } else {
            return _SignalInfo(
              label: 'EMA 가중 데드크로스 약세 (9 < 21)',
              color: AppColor.downColor,
              icon: Icons.trending_down_rounded,
            );
          }
        }
        break;

      case 'macd':
        final hist = ind.macdHist.lastWhere((v) => v != null, orElse: () => null);
        if (hist != null) {
          if (hist > 0) {
            return _SignalInfo(
              label: 'MACD 상승 모멘텀 (+${hist.toStringAsFixed(1)})',
              color: AppColor.upColor,
              icon: Icons.arrow_upward_rounded,
            );
          } else {
            return _SignalInfo(
              label: 'MACD 하방 모멘텀 (${hist.toStringAsFixed(1)})',
              color: AppColor.downColor,
              icon: Icons.arrow_downward_rounded,
            );
          }
        }
        break;

      case 'kdj':
        final j = ind.kdjJ.lastWhere((v) => v != null, orElse: () => null);
        if (j != null) {
          if (j <= 20) {
            return _SignalInfo(
              label: 'KDJ 침체권 반등 모색 (J: ${j.toStringAsFixed(1)})',
              color: AppColor.upColor,
              icon: Icons.arrow_upward_rounded,
            );
          } else if (j >= 80) {
            return _SignalInfo(
              label: 'KDJ 과열권 경계 (J: ${j.toStringAsFixed(1)})',
              color: AppColor.downColor,
              icon: Icons.arrow_downward_rounded,
            );
          } else {
            return _SignalInfo(
              label: 'KDJ 파동 정상 진행 (J: ${j.toStringAsFixed(1)})',
              color: AppColor.accent,
              icon: Icons.timeline_rounded,
            );
          }
        }
        break;

      case 'wr':
        final wr = ind.wr14.lastWhere((v) => v != null, orElse: () => null);
        if (wr != null) {
          if (wr <= -80) {
            return _SignalInfo(
              label: '%R 극단 과매도 타점 (${wr.toStringAsFixed(1)})',
              color: AppColor.upColor,
              icon: Icons.arrow_upward_rounded,
            );
          } else if (wr >= -20) {
            return _SignalInfo(
              label: '%R 극단 과매수 경계 (${wr.toStringAsFixed(1)})',
              color: AppColor.downColor,
              icon: Icons.arrow_downward_rounded,
            );
          } else {
            return _SignalInfo(
              label: '%R 정상 밸런스 (${wr.toStringAsFixed(1)})',
              color: AppColor.accent,
              icon: Icons.waves_rounded,
            );
          }
        }
        break;

      case 'cci':
        final cci = ind.cci20.lastWhere((v) => v != null, orElse: () => null);
        if (cci != null) {
          if (cci <= -100) {
            return _SignalInfo(
              label: 'CCI 통계적 침체 이탈 (${cci.toStringAsFixed(1)})',
              color: AppColor.upColor,
              icon: Icons.arrow_upward_rounded,
            );
          } else if (cci >= 100) {
            return _SignalInfo(
              label: 'CCI 통계적 과열 이탈 (${cci.toStringAsFixed(1)})',
              color: AppColor.downColor,
              icon: Icons.arrow_downward_rounded,
            );
          } else {
            return _SignalInfo(
              label: 'CCI 정상 변동 폭 (${cci.toStringAsFixed(1)})',
              color: AppColor.accent,
              icon: Icons.tune_rounded,
            );
          }
        }
        break;

      case 'atr':
        final atr = ind.atr14.lastWhere((v) => v != null, orElse: () => null);
        if (atr != null) {
          final atrPer = (atr / lastClose) * 100.0;
          return _SignalInfo(
            label: 'ATR 변동폭: ${atr.toStringAsFixed(1)} USDT (${atrPer.toStringAsFixed(2)}%)',
            color: AppColor.accent,
            icon: Icons.straighten_rounded,
          );
        }
        break;

      case 'sar':
        final isBull = ind.sarIsBull.isNotEmpty ? ind.sarIsBull.last : true;
        if (isBull) {
          return _SignalInfo(
            label: '파라볼릭 매수 상승 랠리 지속',
            color: AppColor.upColor,
            icon: Icons.scatter_plot_rounded,
          );
        } else {
          return _SignalInfo(
            label: '파라볼릭 매도 하방 압력 지속',
            color: AppColor.downColor,
            icon: Icons.scatter_plot_rounded,
          );
        }

      case 'vwap':
        final vwap = ind.vwap.lastWhere((v) => v != null, orElse: () => null);
        if (vwap != null) {
          if (lastClose >= vwap) {
            return _SignalInfo(
              label: '기관 평단가(VWAP) 상회 매수세 우위',
              color: AppColor.upColor,
              icon: Icons.equalizer_rounded,
            );
          } else {
            return _SignalInfo(
              label: '기관 평단가(VWAP) 하회 저평가 매수 기회',
              color: AppColor.accent,
              icon: Icons.equalizer_rounded,
            );
          }
        }
        break;

      case 'ichimoku':
        final spanA = ind.ichimokuSpanA.lastWhere((v) => v != null, orElse: () => null);
        final spanB = ind.ichimokuSpanB.lastWhere((v) => v != null, orElse: () => null);
        if (spanA != null && spanB != null) {
          final cloudTop = max(spanA, spanB);
          final cloudBottom = min(spanA, spanB);
          if (lastClose > cloudTop) {
            return _SignalInfo(
              label: '일목 구름대 상단 지지 강세장',
              color: AppColor.upColor,
              icon: Icons.cloud_outlined,
            );
          } else if (lastClose < cloudBottom) {
            return _SignalInfo(
              label: '일목 구름대 하단 저항 약세장',
              color: AppColor.downColor,
              icon: Icons.cloud_outlined,
            );
          } else {
            return _SignalInfo(
              label: '일목 구름대 내부 공방 및 수렴',
              color: AppColor.accent,
              icon: Icons.cloud_outlined,
            );
          }
        }
        break;

      default:
        break;
    }

    return _SignalInfo(
      label: '실시간 비트코인 캔들 분석 정상',
      color: AppColor.accent,
      icon: Icons.analytics_outlined,
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: TextStyle(
        fontSize: 15,
        fontWeight: FontWeight.bold,
        color: AppColor.textPrimary,
      ),
    );
  }

  /// Footer Navigation between indicators and return to Terminal
  Widget _buildFooterActions(
    BuildContext context,
    List<IndicatorMeta> all,
    int currentIndex,
  ) {
    final prevIndex = (currentIndex - 1 + all.length) % all.length;
    final nextIndex = (currentIndex + 1) % all.length;

    final prevMeta = all[prevIndex];
    final nextMeta = all[nextIndex];

    return Column(
      children: [
        // Previous / Next Indicator Buttons
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColor.inputSurface,
                  foregroundColor: AppColor.textSecondary,
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                icon: const Icon(Icons.arrow_back, size: 14),
                label: Text(
                  '이전: ${prevMeta.title.split(' ').first}',
                  style: TextStyle(fontSize: 12, color: AppColor.textSecondary),
                  overflow: TextOverflow.ellipsis,
                ),
                onPressed: () => _selectIndicator(prevMeta.id),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColor.inputSurface,
                  foregroundColor: AppColor.textSecondary,
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                icon: const Icon(Icons.arrow_forward, size: 14),
                label: Text(
                  '다음: ${nextMeta.title.split(' ').first}',
                  style: TextStyle(fontSize: 12, color: AppColor.textSecondary),
                  overflow: TextOverflow.ellipsis,
                ),
                onPressed: () => _selectIndicator(nextMeta.id),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),

        // Primary Return to Terminal Action Button
        if (widget.onReturnToTerminal != null)
          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColor.primary,
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              icon: const Icon(Icons.candlestick_chart, size: 18),
              label: const Text(
                '실시간 터미널 차트에서 적용 및 관찰하기',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
              ),
              onPressed: widget.onReturnToTerminal,
            ),
          ),
      ],
    );
  }
}

/// Rescene-styled Interactive Indicator Sidebar Item matching DashboardSidebar
class _IndicatorSidebarItem extends StatefulWidget {
  final IndicatorMeta item;
  final bool isSelected;
  final bool isDark;
  final VoidCallback onTap;

  const _IndicatorSidebarItem({
    required this.item,
    required this.isSelected,
    required this.isDark,
    required this.onTap,
  });

  @override
  State<_IndicatorSidebarItem> createState() => _IndicatorSidebarItemState();
}

class _IndicatorSidebarItemState extends State<_IndicatorSidebarItem> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final item = widget.item;
    final isSelected = widget.isSelected;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
      child: AnimatedScale(
        scale: _pressed ? 0.96 : 1.0,
        duration: const Duration(milliseconds: 110),
        curve: Curves.easeOutCubic,
        child: InkWell(
          onTap: widget.onTap,
          onTapDown: (_) => setState(() => _pressed = true),
          onTapUp: (_) => setState(() => _pressed = false),
          onTapCancel: () => setState(() => _pressed = false),
          borderRadius: BorderRadius.circular(12),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 170),
            curve: Curves.easeOutCubic,
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            decoration: BoxDecoration(
              color: isSelected
                  ? AppColor.primary.withValues(alpha: widget.isDark ? 0.18 : 0.12)
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                // Neutral Icon Box (No rainbow colors, Simple is Best)
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: isSelected
                        ? AppColor.primary.withValues(alpha: 0.25)
                        : AppColor.inputSurface,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    item.icon,
                    size: 16,
                    color: isSelected ? AppColor.accent : AppColor.textSecondary,
                  ),
                ),
                const SizedBox(width: 10),

                // Title & Subtitle (Clean unified palette)
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        item.title,
                        style: TextStyle(
                          fontSize: 12.5,
                          fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                          color: isSelected ? AppColor.textPrimary : AppColor.textSecondary,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        item.category,
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                          color: isSelected ? AppColor.accent : AppColor.textDisabled,
                        ),
                      ),
                    ],
                  ),
                ),

                // Right Accent Pill (matches DashboardSidebar _SidebarMenuItem)
                if (isSelected)
                  Container(
                    width: 4,
                    height: 18,
                    decoration: BoxDecoration(
                      color: AppColor.accent,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Signal & Confluence Info Data Model
class _SignalInfo {
  final String label;
  final Color color;
  final IconData icon;

  const _SignalInfo({
    required this.label,
    required this.color,
    required this.icon,
  });
}

/// Quant Bot Strategy Preset for Each Indicator
class _QuantBotPreset {
  final String title;
  final String description;
  final double openOrderPer;
  final double closeOrderPer;
  final double canclePer;
  final int orderDepth;

  const _QuantBotPreset({
    required this.title,
    required this.description,
    required this.openOrderPer,
    required this.closeOrderPer,
    required this.canclePer,
    required this.orderDepth,
  });

  static _QuantBotPreset forIndicator(String id) {
    switch (id) {
      case 'bb':
        return const _QuantBotPreset(
          title: '볼린저 밴드 스퀴즈 & 하단 반등 그리드',
          description: '밴드 수축 후 확장 시 하단 지지선(0.45% 간격) 5단계 분할 매수 및 중심선/상단(0.65%) 반등 청산 전략',
          openOrderPer: 0.45,
          closeOrderPer: 0.65,
          canclePer: 2.20,
          orderDepth: 5,
        );
      case 'rsi':
        return const _QuantBotPreset(
          title: 'RSI 과매도 급반등 고속 스캘핑',
          description: 'RSI 30 이하 과매도 구간에서 0.22% 촘촘한 6단계 그리드로 분할 진입 후 빠른 0.35% 기술적 반등 청산',
          openOrderPer: 0.22,
          closeOrderPer: 0.35,
          canclePer: 1.20,
          orderDepth: 6,
        );
      case 'super_trend':
        return const _QuantBotPreset(
          title: '슈퍼트렌드 추세 동행 완충 그리드',
          description: 'ATR 추세 전환 지지선을 완충 지대로 활용하여 0.55% 간격 4단계 매수 및 0.75% 추세 확장 청산',
          openOrderPer: 0.55,
          closeOrderPer: 0.75,
          canclePer: 2.80,
          orderDepth: 4,
        );
      case 'sma':
        return const _QuantBotPreset(
          title: '단순이동평균(SMA) 정배열 눌림목 그리드',
          description: '단기/중기 이평선(7, 25) 지지 구간에서 0.34% 간격 4단계 매수 및 이격 회복 시 0.45% 익절',
          openOrderPer: 0.34,
          closeOrderPer: 0.45,
          canclePer: 1.74,
          orderDepth: 4,
        );
      case 'ema':
        return const _QuantBotPreset(
          title: '지수이동평균(EMA) 가중 추세 추종 그리드',
          description: '최근 가격에 민감한 EMA 9/21 지지선을 추종하여 0.30% 간격 4단계 진입 및 0.42% 빠른 청산',
          openOrderPer: 0.30,
          closeOrderPer: 0.42,
          canclePer: 1.60,
          orderDepth: 4,
        );
      case 'macd':
        return const _QuantBotPreset(
          title: 'MACD 모멘텀 골든크로스 스캘핑',
          description: 'MACD 히스토그램 반등 모멘텀 포착 시 0.28% 간격 5단계 분할 매수 및 0.42% 이익 실현',
          openOrderPer: 0.28,
          closeOrderPer: 0.42,
          canclePer: 1.50,
          orderDepth: 5,
        );
      case 'kdj':
        return const _QuantBotPreset(
          title: 'KDJ 침체권 극단 반등 역추세 그리드',
          description: 'J선 극단 저평가(-10~15) 시 0.20% 촘촘한 6단계 분할 매수 후 K/D 골든크로스(0.30%) 청산',
          openOrderPer: 0.20,
          closeOrderPer: 0.30,
          canclePer: 1.10,
          orderDepth: 6,
        );
      case 'wr':
        return const _QuantBotPreset(
          title: 'Williams %R 과매도 스캘핑 그리드',
          description: '%R -80 이하 과매도 시그널에서 0.22% 간격 6단계 매수 및 -20 과열권 복귀 시 0.32% 청산',
          openOrderPer: 0.22,
          closeOrderPer: 0.32,
          canclePer: 1.15,
          orderDepth: 6,
        );
      case 'cci':
        return const _QuantBotPreset(
          title: 'CCI 오차범위 이탈 반등 그리드',
          description: 'CCI -100 이하 통계적 저평가 이탈 시 0.32% 간격 5단계 분할 매수 및 중심선 회귀(0.48%) 청산',
          openOrderPer: 0.32,
          closeOrderPer: 0.48,
          canclePer: 1.60,
          orderDepth: 5,
        );
      case 'atr':
        return const _QuantBotPreset(
          title: 'ATR 변동성 적응형 롱 디펜스 그리드',
          description: '평균 실질 변동폭(ATR)에 비례한 0.60% 넓은 간격 3단계 배치로 급변동장 슬리피지 방어',
          openOrderPer: 0.60,
          closeOrderPer: 0.80,
          canclePer: 3.00,
          orderDepth: 3,
        );
      case 'sar':
        return const _QuantBotPreset(
          title: '파라볼릭 SAR 가속 추세 돌파 그리드',
          description: '도트(SAR) 전환점 지지 확인 후 0.38% 간격 4단계 진입 및 가속도 증가(0.58%) 청산',
          openOrderPer: 0.38,
          closeOrderPer: 0.58,
          canclePer: 2.00,
          orderDepth: 4,
        );
      case 'vwap':
        return const _QuantBotPreset(
          title: 'VWAP 기관 평단가 하단 괴리율 저가 매수',
          description: '거래량 가중 평균가(VWAP) 하단 이격 시 0.30% 간격 5단계 분할 매수 및 VWAP 회귀(0.50%) 청산',
          openOrderPer: 0.30,
          closeOrderPer: 0.50,
          canclePer: 1.80,
          orderDepth: 5,
        );
      case 'ichimoku':
        return const _QuantBotPreset(
          title: '일목균형표 구름대 지지선 방어형 그리드',
          description: '선행스팬(구름대) 상하단 지지대를 활용한 0.50% 간격 4단계 매수 및 구름 돌파 시 0.70% 익절',
          openOrderPer: 0.50,
          closeOrderPer: 0.70,
          canclePer: 2.50,
          orderDepth: 4,
        );
      case 'obv':
        return const _QuantBotPreset(
          title: 'OBV 거래량 매집 확인 추세 그리드',
          description: 'OBV 다이버전스 및 거래량 매집 확인 후 0.35% 간격 5단계 매수 및 거래량 분산(0.50%) 청산',
          openOrderPer: 0.35,
          closeOrderPer: 0.50,
          canclePer: 1.70,
          orderDepth: 5,
        );
      default:
        return const _QuantBotPreset(
          title: 'DepthTrade 표준 밸런스 그리드',
          description: '비트코인 선물 시장의 일상 변동성을 완벽 방어하는 0.34% 간격 4단계 표준 퀀트 설정',
          openOrderPer: 0.34,
          closeOrderPer: 0.34,
          canclePer: 1.74,
          orderDepth: 4,
        );
    }
  }
}

/// Borderless compact integer stepper for tuner toolbar
class _TunerIntStepper extends StatelessWidget {
  final String label;
  final int value;
  final int min;
  final int max;
  final int step;
  final ValueChanged<int> onChanged;

  const _TunerIntStepper({
    required this.label,
    required this.value,
    required this.min,
    required this.max,
    required this.step,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
      decoration: BoxDecoration(
        color: AppColor.inputSurface,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            '$label: ',
            style: TextStyle(fontSize: 11, color: AppColor.textSecondary),
          ),
          InkWell(
            borderRadius: BorderRadius.circular(4),
            onTap: value > min ? () => onChanged(value - step) : null,
            child: Padding(
              padding: const EdgeInsets.all(2),
              child: Icon(
                Icons.remove,
                size: 13,
                color: value > min ? AppColor.accent : AppColor.textDisabled,
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 5),
            child: Text(
              '$value',
              style: const TextStyle(
                fontSize: 11.5,
                fontWeight: FontWeight.bold,
                fontFamily: 'monospace',
                color: AppColor.accent,
              ),
            ),
          ),
          InkWell(
            borderRadius: BorderRadius.circular(4),
            onTap: value < max ? () => onChanged(value + step) : null,
            child: Padding(
              padding: const EdgeInsets.all(2),
              child: Icon(
                Icons.add,
                size: 13,
                color: value < max ? AppColor.accent : AppColor.textDisabled,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Borderless compact double stepper for tuner toolbar
class _TunerDoubleStepper extends StatelessWidget {
  final String label;
  final double value;
  final double min;
  final double max;
  final double step;
  final ValueChanged<double> onChanged;

  const _TunerDoubleStepper({
    required this.label,
    required this.value,
    required this.min,
    required this.max,
    required this.step,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
      decoration: BoxDecoration(
        color: AppColor.inputSurface,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            '$label: ',
            style: TextStyle(fontSize: 11, color: AppColor.textSecondary),
          ),
          InkWell(
            borderRadius: BorderRadius.circular(4),
            onTap: value > min ? () => onChanged(double.parse((value - step).toStringAsFixed(2))) : null,
            child: Padding(
              padding: const EdgeInsets.all(2),
              child: Icon(
                Icons.remove,
                size: 13,
                color: value > min ? AppColor.accent : AppColor.textDisabled,
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 5),
            child: Text(
              value.toStringAsFixed(value.truncateToDouble() == value ? 1 : 2),
              style: const TextStyle(
                fontSize: 11.5,
                fontWeight: FontWeight.bold,
                fontFamily: 'monospace',
                color: AppColor.accent,
              ),
            ),
          ),
          InkWell(
            borderRadius: BorderRadius.circular(4),
            onTap: value < max ? () => onChanged(double.parse((value + step).toStringAsFixed(2))) : null,
            child: Padding(
              padding: const EdgeInsets.all(2),
              child: Icon(
                Icons.add,
                size: 13,
                color: value < max ? AppColor.accent : AppColor.textDisabled,
              ),
            ),
          ),
        ],
      ),
    );
  }
}



import 'package:flutter/material.dart';
import '../../../engine/grid_bot_engine.dart';
import '../../../models/candle_data.dart';
import '../../../service/bitget_api_service.dart';
import '../../../style/style.dart';
import '../../../widget/chart/indicator_guide_dialog.dart';
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
              const SizedBox(height: 32),

              // Footer Navigation
              _buildFooterActions(context, all, currentIndex),
            ],
          ),
        ),
      ),
    );
  }

  /// Real Bitcoin (BTC/USDT) Chart Card with active indicator
  Widget _buildRealBtcChartCard(IndicatorMeta meta, bool isDark) {
    final effectivePrice = widget.currentPrice != null && widget.currentPrice! > 0
        ? widget.currentPrice!
        : (_btcPrice > 0 ? _btcPrice : (GridBotEngine.instance.currentPrice > 0 ? GridBotEngine.instance.currentPrice : 0.0));

    final effectiveCandles = widget.candles != null && widget.candles!.isNotEmpty
        ? widget.candles!
        : _btcCandles;

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
            // Top Bar
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              color: AppColor.inputSurface,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
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
                      Text(
                        'BTC/USDT 실시간 비트코인 차트 (${meta.title})',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: AppColor.textPrimary,
                        ),
                      ),
                    ],
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
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
            ),

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


import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../routes/app_routes.dart';
import '../../style/style.dart';
import '../../widget/chart/indicator_guide_dialog.dart';

/// Full-page dedicated Technical Indicator Guide & Visual Simulation Lab
class IndicatorDetailPage extends StatefulWidget {
  final String initialIndicatorId;

  const IndicatorDetailPage({
    super.key,
    this.initialIndicatorId = 'sma',
  });

  @override
  State<IndicatorDetailPage> createState() => _IndicatorDetailPageState();
}

class _IndicatorDetailPageState extends State<IndicatorDetailPage> {
  late String _currentId;
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _currentId = widget.initialIndicatorId.isEmpty ? 'sma' : widget.initialIndicatorId;
  }

  @override
  void didUpdateWidget(covariant IndicatorDetailPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.initialIndicatorId != widget.initialIndicatorId &&
        widget.initialIndicatorId.isNotEmpty) {
      setState(() {
        _currentId = widget.initialIndicatorId;
      });
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
    // Update browser URL routing without page reload
    SystemNavigator.routeInformationUpdated(
      uri: Uri.parse(AppRoutes.indicatorDetail(id)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = AppColor.isDark;
    final allIndicators = IndicatorMeta.all;
    final meta = IndicatorMeta.get(_currentId);

    final filteredList = allIndicators.where((item) {
      if (_searchQuery.trim().isEmpty) return true;
      final q = _searchQuery.toLowerCase();
      return item.title.toLowerCase().contains(q) ||
          item.englishName.toLowerCase().contains(q) ||
          item.category.toLowerCase().contains(q) ||
          item.summary.toLowerCase().contains(q);
    }).toList();

    return Scaffold(
      backgroundColor: AppColor.background,
      body: SafeArea(
        child: Column(
          children: [
            // 1. Top Navigation Bar
            _buildTopNavBar(context, meta),

            // 2. Main Content Layout (Sidebar + Detail Canvas)
            Expanded(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final isWide = constraints.maxWidth >= 960;

                  if (isWide) {
                    return Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Left Sidebar for Wide Screens
                        SizedBox(
                          width: 320,
                          child: _buildSidebar(filteredList, isDark),
                        ),
                        // Vertical Divider
                        Container(
                          width: 1,
                          color: AppColor.divider.withValues(alpha: 0.15),
                        ),
                        // Main Detail Content Area
                        Expanded(
                          child: _buildMainContent(meta, allIndicators, isDark),
                        ),
                      ],
                    );
                  } else {
                    // Mobile & Tablet Layout
                    return Column(
                      children: [
                        // Top horizontal indicator scroll
                        _buildMobileIndicatorChips(allIndicators, isDark),
                        // Main Content
                        Expanded(
                          child: _buildMainContent(meta, allIndicators, isDark),
                        ),
                      ],
                    );
                  }
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// 1. Top Navigation Bar
  Widget _buildTopNavBar(BuildContext context, IndicatorMeta meta) {
    final isDark = AppColor.isDark;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
      decoration: BoxDecoration(
        color: AppColor.cardSurface.withValues(alpha: isDark ? 0.95 : 0.98),
        boxShadow: AppColor.subtleShadow,
      ),
      child: Row(
        children: [
          // Back to Terminal Button
          InkWell(
            borderRadius: BorderRadius.circular(10),
            onTap: () {
              if (Navigator.canPop(context)) {
                Navigator.pop(context);
              } else {
                Navigator.pushReplacementNamed(context, AppRoutes.terminal);
              }
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: AppColor.inputSurface,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.arrow_back_rounded, size: 16, color: AppColor.accent),
                  const SizedBox(width: 6),
                  Text(
                    '터미널 차트로 복귀',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: AppColor.textPrimary,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 16),

          // Title & Breadcrumb
          Expanded(
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: AppColor.primary.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.auto_graph_rounded, color: AppColor.accent, size: 18),
                ),
                const SizedBox(width: 10),
                Flexible(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            'DepthTrade',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: AppColor.textSecondary,
                            ),
                          ),
                          const SizedBox(width: 4),
                          Icon(Icons.chevron_right, size: 14, color: AppColor.textDisabled),
                          const SizedBox(width: 4),
                          Text(
                            '보조지표 연구소 & 가이드',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: AppColor.accent,
                            ),
                          ),
                        ],
                      ),
                      Text(
                        meta.title,
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                          color: AppColor.textPrimary,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Theme Toggle Button
          IconButton(
            tooltip: isDark ? '라이트 모드로 전환' : '다크 모드로 전환',
            icon: Icon(
              isDark ? Icons.light_mode_outlined : Icons.dark_mode_outlined,
              size: 20,
              color: AppColor.textSecondary,
            ),
            onPressed: () => ThemeService.instance.toggleTheme(),
          ),
        ],
      ),
    );
  }

  /// 2. Left Sidebar (for Desktop)
  Widget _buildSidebar(List<IndicatorMeta> list, bool isDark) {
    return Container(
      color: AppColor.backgroundCard.withValues(alpha: 0.5),
      child: Column(
        children: [
          // Search Box
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 14, 14, 8),
            child: TextField(
              controller: _searchController,
              onChanged: (val) => setState(() => _searchQuery = val),
              style: TextStyle(fontSize: 12, color: AppColor.textPrimary),
              decoration: InputDecoration(
                hintText: '지표명 또는 카테고리 검색...',
                hintStyle: TextStyle(fontSize: 11, color: AppColor.textDisabled),
                prefixIcon: Icon(Icons.search, size: 16, color: AppColor.textSecondary),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear, size: 14),
                        onPressed: () {
                          _searchController.clear();
                          setState(() => _searchQuery = '');
                        },
                      )
                    : null,
                filled: true,
                fillColor: AppColor.inputSurface,
                isDense: true,
                contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),

          // Category/Count Header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '전체 보조지표 및 옵션',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: AppColor.textDisabled,
                  ),
                ),
                Text(
                  '${list.length}개',
                  style: const TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: AppColor.accent,
                    fontFamily: 'monospace',
                  ),
                ),
              ],
            ),
          ),

          // Indicator List Items
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              itemCount: list.length,
              itemBuilder: (context, idx) {
                final item = list[idx];
                final isSelected = item.id == _currentId;

                return Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(10),
                    onTap: () => _selectIndicator(item.id),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? item.categoryColor.withValues(alpha: isDark ? 0.2 : 0.12)
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 8,
                            height: 8,
                            decoration: BoxDecoration(
                              color: item.categoryColor,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  item.title,
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                                    color: isSelected ? AppColor.textPrimary : AppColor.textSecondary,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                Text(
                                  item.category,
                                  style: TextStyle(
                                    fontSize: 10,
                                    color: item.categoryColor.withValues(alpha: 0.9),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          if (isSelected)
                            Icon(Icons.chevron_right, size: 16, color: item.categoryColor),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  /// Mobile & Tablet Horizontal Chips
  Widget _buildMobileIndicatorChips(List<IndicatorMeta> list, bool isDark) {
    return Container(
      height: 48,
      padding: const EdgeInsets.symmetric(vertical: 6),
      decoration: BoxDecoration(
        color: AppColor.cardSurface.withValues(alpha: 0.6),
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
              borderRadius: BorderRadius.circular(16),
              onTap: () => _selectIndicator(item.id),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: isSelected
                      ? item.categoryColor.withValues(alpha: 0.25)
                      : AppColor.inputSurface,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 6,
                      height: 6,
                      decoration: BoxDecoration(
                        color: item.categoryColor,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      item.title.split(' ').first,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                        color: isSelected ? AppColor.textPrimary : AppColor.textSecondary,
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

  /// 3. Main Detail Content Area
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
          constraints: const BoxConstraints(maxWidth: 860),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Header Badge & Title
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: meta.categoryColor.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      meta.category,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: meta.categoryColor,
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
              const SizedBox(height: 8),

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

              // Summary Box
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
                        color: meta.categoryColor,
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

              // Virtual Simulation Canvas Card
              _buildVirtualSimulationCard(meta, isDark),
              const SizedBox(height: 24),

              // Formula Box
              _buildSectionTitle('📐 수학적 계산 공식 및 알고리즘', meta.categoryColor),
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: (isDark ? Colors.black : const Color(0xFFF1F5F9)).withValues(alpha: 0.75),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: SelectableText(
                  meta.formula,
                  style: TextStyle(
                    fontFamily: 'monospace',
                    fontSize: 12.5,
                    height: 1.5,
                    color: meta.categoryColor,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Actionable Trading Signals
              _buildSectionTitle('⚡ 실전 트레이딩 매매 시그널', AppColor.accent),
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
                            child: Icon(Icons.check_circle_rounded, size: 16, color: AppColor.longGreen),
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
              _buildSectionTitle('🤖 DepthTrade 퀀트 봇 활용 시너지 전략', AppColor.primary),
              const SizedBox(height: 10),
              ...meta.quantBotTips.map((tip) => Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: AppColor.primary.withValues(alpha: isDark ? 0.12 : 0.08),
                        borderRadius: BorderRadius.circular(12),
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

              // Bottom Navigation & Actions
              _buildFooterActions(context, all, currentIndex),
            ],
          ),
        ),
      ),
    );
  }

  /// Virtual Simulation Chart Card
  Widget _buildVirtualSimulationCard(IndicatorMeta meta, bool isDark) {
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
            // Canvas Toolbar
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              color: AppColor.inputSurface.withValues(alpha: 0.6),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: meta.categoryColor,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '가상 시뮬레이션 캔들 엔진 (22개 봉 실시간 렌더링)',
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
                      color: AppColor.accent.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: const Text(
                      '순수 Dart 연산 (외부 SDK 0%)',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: AppColor.accent,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Canvas Area
            SizedBox(
              height: 280,
              child: CustomPaint(
                painter: VirtualIndicatorChartPainter(
                  indicatorId: meta.id,
                  isDark: isDark,
                  primaryColor: meta.categoryColor,
                ),
                child: const SizedBox.expand(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title, Color color) {
    return Text(
      title,
      style: TextStyle(
        fontSize: 15,
        fontWeight: FontWeight.bold,
        color: color,
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
              child: OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  side: BorderSide(color: AppColor.inputSurface),
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
              child: OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  side: BorderSide(color: AppColor.inputSurface),
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
            onPressed: () {
              Navigator.pushNamedAndRemoveUntil(
                context,
                AppRoutes.terminal,
                (route) => false,
              );
            },
          ),
        ),
      ],
    );
  }
}

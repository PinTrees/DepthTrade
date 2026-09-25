import 'dart:async';
import 'package:flutter/material.dart';
import '../../engine/grid_bot_engine.dart';
import '../../models/candle_data.dart';
import '../../models/crypto_symbol.dart';
import '../../service/bitget_api_service.dart';
import '../../style/app_color.dart';
import '../../widget/chart/orderbook_depth_widget.dart';
import '../../widget/chart/trading_view_chart_viewer.dart';
import '../../widget/galaxy_background.dart';
import '../../widget/glow_button.dart';
import 'widgets/account_stat_card.dart';
import 'widgets/api_setting_view.dart';
import 'widgets/backtest_view.dart';
import 'widgets/coin_selector_dialog.dart';
import 'widgets/dashboard_sidebar.dart';
import 'widgets/order_table_view.dart';
import 'widgets/trade_editor_panel.dart';

class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  int _selectedTab = 0;
  bool _isSidebarCollapsed = false;

  String _activeSymbol = '';
  String _activeInterval = '15m';
  List<CandleData> _candles = [];
  Map<String, List<List<double>>> _orderBook = {'bids': [], 'asks': []};
  Timer? _marketDataTimer;
  bool _isFetchingCandles = false;

  @override
  void initState() {
    super.initState();
    GridBotEngine.instance.initialize(null);
    _activeSymbol = GridBotEngine.instance.config.symbol;
    GridBotEngine.instance.addListener(_onEngineChanged);
    _fetchMarketData();

    _marketDataTimer = Timer.periodic(const Duration(seconds: 3), (_) {
      _fetchMarketData();
    });
  }

  void _onEngineChanged() {
    final currentSymbol = GridBotEngine.instance.config.symbol;
    if (_activeSymbol != currentSymbol) {
      _activeSymbol = currentSymbol;
      if (mounted) {
        setState(() {
          _candles = [];
        });
        _fetchMarketData();
      }
    }
  }

  void _changeInterval(String interval) {
    if (_activeInterval == interval) return;
    setState(() {
      _activeInterval = interval;
      _candles = [];
    });
    _fetchMarketData();
  }

  @override
  void dispose() {
    GridBotEngine.instance.removeListener(_onEngineChanged);
    _marketDataTimer?.cancel();
    super.dispose();
  }

  Future<void> _fetchMarketData() async {
    final symbol = GridBotEngine.instance.config.symbol;
    final book = await BitgetApiService.instance.getOrderBook(symbol);

    if (_isFetchingCandles) {
      if (mounted && book['bids']!.isNotEmpty) {
        setState(() => _orderBook = book);
      }
      return;
    }

    _isFetchingCandles = true;
    try {
      final candles = await BitgetApiService.instance.getCandles(symbol, _activeInterval, 120);
      if (mounted) {
        setState(() {
          if (candles.isNotEmpty) _candles = candles;
          if (book['bids']!.isNotEmpty) _orderBook = book;
        });
      }
    } finally {
      _isFetchingCandles = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final bool autoCollapse = screenWidth < 1000;
    final bool collapsed = _isSidebarCollapsed || autoCollapse;

    return Scaffold(
      backgroundColor: AppColor.background,
      body: GalaxyBackground(
        child: SafeArea(
          child: Row(
            children: [
              // 1. Rescene-styled Left Navigation Sidebar
              DashboardSidebar(
                currentIndex: _selectedTab,
                onTabSelected: (index) => setState(() => _selectedTab = index),
                isCollapsed: collapsed,
                onToggleCollapse: () {
                  setState(() => _isSidebarCollapsed = !_isSidebarCollapsed);
                },
              ),

              // 2. Main Content & Active Tab View
              Expanded(
                child: Column(
                  children: [
                    // Top App Bar (Active Coin Badge + Quick Switchers + Bot Controls)
                    _buildTopBar(),

                    // Active Tab Content
                    Expanded(
                      child: IndexedStack(
                        index: _selectedTab,
                        children: [
                          // Tab 0: 실시간 터미널 (Terminal: Chart + Orderbook + Account Stat)
                          _buildTerminalTab(),

                          // Tab 1: 전략 파라미터 (Strategy & Sizing)
                          _buildStrategyTab(),

                          // Tab 2: 백테스트 랩 (Historical Backtest Lab)
                          const SingleChildScrollView(
                            padding: EdgeInsets.all(16),
                            child: BacktestView(),
                          ),

                          // Tab 3: 주문 & 체결 내역 (Orders & History)
                          const Padding(
                            padding: EdgeInsets.all(16),
                            child: OrderTableView(),
                          ),

                          // Tab 4: API & 계정 설정 (Bitget API Settings)
                          const ApiSettingView(),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Top Action Bar
  Widget _buildTopBar() {
    return ListenableBuilder(
      listenable: GridBotEngine.instance,
      builder: (context, _) {
        final engine = GridBotEngine.instance;
        final coin = CryptoCoin.findBySymbol(engine.config.symbol);

        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          decoration: BoxDecoration(
            color: AppColor.backgroundCard.withValues(alpha: 0.8),
            boxShadow: AppColor.subtleShadow,
          ),
          child: Row(
            children: [
              // Active Coin Chip
              InkWell(
                onTap: () => CoinSelectorDialog.show(context),
                borderRadius: BorderRadius.circular(10),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppColor.cardSurface,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 22,
                        height: 22,
                        decoration: BoxDecoration(
                          color: coin.color.withValues(alpha: 0.2),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(coin.icon, color: coin.color, size: 14),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        coin.displaySymbol,
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: AppColor.textPrimary,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        coin.koreanName,
                        style: const TextStyle(fontSize: 11, color: AppColor.textSecondary),
                      ),
                      const SizedBox(width: 4),
                      const Icon(Icons.arrow_drop_down, color: AppColor.textSecondary, size: 18),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 12),

              // Live Market Price Display
              if (engine.currentPrice > 0) ...[
                Text(
                  '${engine.currentPrice.toStringAsFixed(coin.priceDecimals)} USDT',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'monospace',
                    color: AppColor.accent,
                  ),
                ),
                const SizedBox(width: 16),
              ],

              // Quick Coin Switcher Bar (Top 5 popular coins)
              if (MediaQuery.of(context).size.width > 900) ...[
                Expanded(
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: CryptoCoin.popularCoins.take(6).map((c) {
                        final isSelected = c.symbol == engine.config.symbol;
                        return Padding(
                          padding: const EdgeInsets.only(right: 6),
                          child: InkWell(
                            onTap: () => engine.switchCoin(c),
                            borderRadius: BorderRadius.circular(8),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
                              decoration: BoxDecoration(
                                color: isSelected
                                    ? c.color.withValues(alpha: 0.2)
                                    : AppColor.inputSurface.withValues(alpha: 0.5),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Row(
                                children: [
                                  Icon(c.icon, size: 12, color: isSelected ? c.color : AppColor.textSecondary),
                                  const SizedBox(width: 4),
                                  Text(
                                    c.symbol.replaceFirst('USDT', ''),
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                      color: isSelected ? Colors.white : AppColor.textSecondary,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                ),
              ] else
                const Spacer(),

              // Bot Running Status Badge
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: engine.isRunning
                      ? AppColor.longGreen.withValues(alpha: 0.15)
                      : AppColor.inputSurface,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.fiber_manual_record,
                      size: 10,
                      color: engine.isRunning ? AppColor.longGreen : AppColor.textDisabled,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      engine.isRunning ? 'LIVE RUNNING' : 'BOT IDLE',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        fontFamily: 'monospace',
                        color: engine.isRunning ? AppColor.longGreen : AppColor.textDisabled,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),

              // Quick Start / Stop / Panic Buttons
              if (!engine.isRunning)
                GlowButton(
                  text: 'START',
                  icon: Icons.play_arrow,
                  height: 36,
                  glowColor: AppColor.longGreen,
                  gradient: AppColor.greenGradient,
                  onPressed: () => engine.startBot(),
                )
              else ...[
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColor.shortRed.withValues(alpha: 0.8),
                    foregroundColor: Colors.white,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  onPressed: () => engine.stopBot(),
                  icon: const Icon(Icons.pause, size: 16),
                  label: const Text('PAUSE', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                ),
                const SizedBox(width: 8),
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red.shade900,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  onPressed: engine.isStopping ? null : () => engine.emergencyCancelAll(),
                  icon: const Icon(Icons.warning_amber, size: 14),
                  label: const Text('PANIC', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                ),
              ],
            ],
          ),
        );
      },
    );
  }

  // Tab 0: 실시간 터미널 (Terminal: Chart + Orderbook + Account Stat)
  Widget _buildTerminalTab() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final bool isDesktop = constraints.maxWidth >= 960;

        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              // 1. Chart & Orderbook Depth Section
              ListenableBuilder(
                listenable: GridBotEngine.instance,
                builder: (context, _) {
                  final engine = GridBotEngine.instance;

                  return SizedBox(
                    height: isDesktop ? 540 : 760,
                    child: isDesktop
                        ? Row(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              // TradingView Candlestick & Technical Indicator Chart
                              Expanded(
                                flex: 7,
                                child: TradingViewChartViewer(
                                  candles: _candles,
                                  currentPrice: engine.currentPrice,
                                  liveBuyOrders: engine.liveOrders,
                                  liveCloseOrders: engine.liveCloseOrders,
                                  activeInterval: _activeInterval,
                                  onIntervalChanged: _changeInterval,
                                ),
                              ),
                              const SizedBox(width: 12),
                              // Orderbook Depth Bars
                              Expanded(
                                flex: 3,
                                child: OrderbookDepthWidget(
                                  orderBook: _orderBook,
                                  currentPrice: engine.currentPrice,
                                ),
                              ),
                            ],
                          )
                        : Column(
                            children: [
                              Expanded(
                                flex: 6,
                                child: TradingViewChartViewer(
                                  candles: _candles,
                                  currentPrice: engine.currentPrice,
                                  liveBuyOrders: engine.liveOrders,
                                  liveCloseOrders: engine.liveCloseOrders,
                                  activeInterval: _activeInterval,
                                  onIntervalChanged: _changeInterval,
                                ),
                              ),
                              const SizedBox(height: 10),
                              Expanded(
                                flex: 4,
                                child: OrderbookDepthWidget(
                                  orderBook: _orderBook,
                                  currentPrice: engine.currentPrice,
                                ),
                              ),
                            ],
                          ),
                  );
                },
              ),
              const SizedBox(height: 16),

              // 2. Realtime Account Stats & Log Card
              const AccountStatCard(),
              const SizedBox(height: 16),

              // 3. Compact Live Orders Snippet
              const SizedBox(
                height: 320,
                child: OrderTableView(),
              ),
            ],
          ),
        );
      },
    );
  }

  // Tab 1: 전략 파라미터 (Strategy & Sizing)
  Widget _buildStrategyTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 860),
          child: const Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TradeEditorPanel(),
            ],
          ),
        ),
      ),
    );
  }
}

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../engine/grid_bot_engine.dart';
import '../../models/candle_data.dart';
import '../../service/auth_service.dart';
import '../../service/bitget_api_service.dart';
import '../../style/app_color.dart';
import '../../widget/chart/grid_chart_widget.dart';
import '../../widget/chart/orderbook_depth_widget.dart';
import '../../widget/galaxy_background.dart';
import '../../widget/glass_container.dart';
import 'widgets/account_stat_card.dart';
import 'widgets/api_setting_dialog.dart';
import 'widgets/backtest_view.dart';
import 'widgets/order_table_view.dart';
import 'widgets/trade_editor_panel.dart';

class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  List<CandleData> _candles = [];
  Map<String, List<List<double>>> _orderBook = {'bids': [], 'asks': []};
  Timer? _marketDataTimer;

  int _selectedRightTab = 0; // 0: Trade Editor, 1: Backtest Lab

  @override
  void initState() {
    super.initState();
    GridBotEngine.instance.initialize(null);
    _fetchMarketData();

    _marketDataTimer = Timer.periodic(const Duration(seconds: 3), (_) {
      _fetchMarketData();
    });
  }

  @override
  void dispose() {
    _marketDataTimer?.cancel();
    super.dispose();
  }

  Future<void> _fetchMarketData() async {
    final symbol = GridBotEngine.instance.config.symbol;
    final candles = await BitgetApiService.instance.getCandles(symbol, '15m', 60);
    final book = await BitgetApiService.instance.getOrderBook(symbol);

    if (mounted) {
      setState(() {
        if (candles.isNotEmpty) _candles = candles;
        if (book['bids']!.isNotEmpty) _orderBook = book;
      });
    }
  }

  void _openApiSettings() {
    showDialog(
      context: context,
      builder: (_) => const ApiSettingDialog(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: GalaxyBackground(
        child: SafeArea(
          child: Column(
            children: [
              // Top Navigation Bar
              _buildTopNavBar(),

              // Main Responsive Layout
              Expanded(
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    bool isWide = constraints.maxWidth >= 1050;

                    if (isWide) {
                      return Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Left Panel: Chart + Orderbook + Account + Orders
                          Expanded(
                            flex: 6,
                            child: SingleChildScrollView(
                              padding: const EdgeInsets.only(
                                left: 16,
                                right: 8,
                                top: 12,
                                bottom: 20,
                              ),
                              child: Column(
                                children: [
                                  _buildChartAndDepthSection(height: 380),
                                  const SizedBox(height: 14),
                                  const AccountStatCard(),
                                  const SizedBox(height: 14),
                                  const OrderTableView(),
                                ],
                              ),
                            ),
                          ),

                          // Right Panel: Trade Editor / Backtest Lab Tabs
                          Expanded(
                            flex: 4,
                            child: SingleChildScrollView(
                              padding: const EdgeInsets.only(
                                left: 8,
                                right: 16,
                                top: 12,
                                bottom: 20,
                              ),
                              child: Column(
                                children: [
                                  _buildRightPanelTabs(),
                                  const SizedBox(height: 12),
                                  if (_selectedRightTab == 0)
                                    const TradeEditorPanel()
                                  else
                                    const BacktestView(),
                                ],
                              ),
                            ),
                          ),
                        ],
                      );
                    } else {
                      // Mobile / Tablet stacked layout
                      return SingleChildScrollView(
                        padding: const EdgeInsets.all(12),
                        child: Column(
                          children: [
                            _buildChartAndDepthSection(height: 320),
                            const SizedBox(height: 14),
                            const AccountStatCard(),
                            const SizedBox(height: 14),
                            _buildRightPanelTabs(),
                            const SizedBox(height: 12),
                            if (_selectedRightTab == 0)
                              const TradeEditorPanel()
                            else
                              const BacktestView(),
                            const SizedBox(height: 14),
                            const OrderTableView(),
                          ],
                        ),
                      );
                    }
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTopNavBar() {
    return ListenableBuilder(
      listenable: GridBotEngine.instance,
      builder: (context, _) {
        final engine = GridBotEngine.instance;
        final cfg = engine.config;

        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          decoration: BoxDecoration(
            color: AppColor.backgroundCard.withValues(alpha: 0.8),
            boxShadow: AppColor.subtleShadow,
          ),
          child: Row(
            children: [
              // Logo
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  gradient: AppColor.primaryGradient,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.show_chart, color: Colors.white, size: 20),
              ),
              const SizedBox(width: 12),
              const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'DEPTH TRADE',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 1.5,
                      color: AppColor.textPrimary,
                    ),
                  ),
                  Text(
                    'Bitget Grid Trading Platform',
                    style: TextStyle(fontSize: 10, color: AppColor.textSecondary),
                  ),
                ],
              ),
              const SizedBox(width: 24),

              // Symbol Selector
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: AppColor.cardSurface, // 아웃라인 제거
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.currency_bitcoin, color: Colors.amber, size: 18),
                    const SizedBox(width: 4),
                    Text(
                      cfg.symbol,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: AppColor.textPrimary,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 14),

              // Live Ticker Display
              if (engine.currentPrice > 0) ...[
                Text(
                  '${engine.currentPrice.toStringAsFixed(1)} USDT',
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'monospace',
                    color: AppColor.accent,
                  ),
                ),
              ],

              const Spacer(),

              // User Profile Info
              if (FirebaseAuth.instance.currentUser != null) ...[
                Row(
                  children: [
                    CircleAvatar(
                      radius: 14,
                      backgroundColor: AppColor.primary.withValues(alpha: 0.3),
                      backgroundImage: FirebaseAuth.instance.currentUser?.photoURL != null
                          ? NetworkImage(FirebaseAuth.instance.currentUser!.photoURL!)
                          : null,
                      child: FirebaseAuth.instance.currentUser?.photoURL == null
                          ? Text(
                              (FirebaseAuth.instance.currentUser?.displayName?.isNotEmpty == true
                                      ? FirebaseAuth.instance.currentUser!.displayName![0]
                                      : FirebaseAuth.instance.currentUser?.email?[0] ?? 'U')
                                  .toUpperCase(),
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            )
                          : null,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      FirebaseAuth.instance.currentUser?.displayName ??
                          FirebaseAuth.instance.currentUser?.email?.split('@')[0] ??
                          'Trader',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: AppColor.textSecondary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(width: 14),
              ],

              // API Key / Mode Settings Button
              IconButton(
                icon: const Icon(Icons.settings, color: AppColor.textSecondary),
                tooltip: 'Bitget API 설정',
                onPressed: _openApiSettings,
              ),

              const SizedBox(width: 4),

              // Logout / Exit
              IconButton(
                icon: const Icon(Icons.logout, color: AppColor.textSecondary),
                tooltip: '로그아웃',
                onPressed: () async {
                  await AuthService.instance.signOut();
                  if (context.mounted) {
                    Navigator.pushReplacementNamed(context, '/');
                  }
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildChartAndDepthSection({required double height}) {
    return ListenableBuilder(
      listenable: GridBotEngine.instance,
      builder: (context, _) {
        final engine = GridBotEngine.instance;

        return GlassContainer(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Chart Header Bar
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.candlestick_chart, color: AppColor.accent, size: 18),
                      SizedBox(width: 8),
                      Text(
                        '실시간 차트 & 그리드 오더 레이어 (Realtime Grid View)',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: AppColor.textPrimary,
                        ),
                      ),
                    ],
                  ),
                  Text(
                    '갱신: ${engine.lastUpdateTime.hour.toString().padLeft(2, '0')}:${engine.lastUpdateTime.minute.toString().padLeft(2, '0')}:${engine.lastUpdateTime.second.toString().padLeft(2, '0')}',
                    style: const TextStyle(
                      fontSize: 11,
                      color: AppColor.textDisabled,
                      fontFamily: 'monospace',
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),

              // Chart and Orderbook Row
              SizedBox(
                height: height,
                child: Row(
                  children: [
                    // Main Candle & Grid Lines Chart
                    Expanded(
                      flex: 7,
                      child: GridChartWidget(
                        candles: _candles,
                        currentPrice: engine.currentPrice,
                        liveBuyOrders: engine.liveOrders,
                        liveCloseOrders: engine.liveCloseOrders,
                      ),
                    ),
                    const SizedBox(width: 12),
                    // Order Book Depth
                    Expanded(
                      flex: 3,
                      child: OrderbookDepthWidget(
                        orderBook: _orderBook,
                        currentPrice: engine.currentPrice,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildRightPanelTabs() {
    return Container(
      padding: const EdgeInsets.all(5),
      decoration: BoxDecoration(
        color: AppColor.cardSurface, // 아웃라인 제거, 레이어드 서피스
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Expanded(
            child: _tabButton('그리드 트레이드 설정', 0, Icons.tune),
          ),
          Expanded(
            child: _tabButton('백테스트 연구소', 1, Icons.analytics),
          ),
        ],
      ),
    );
  }

  Widget _tabButton(String title, int index, IconData icon) {
    bool isSelected = _selectedRightTab == index;

    return InkWell(
      onTap: () => setState(() => _selectedRightTab = index),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? AppColor.primary : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 16,
              color: isSelected ? Colors.white : AppColor.textSecondary,
            ),
            const SizedBox(width: 8),
            Text(
              title,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.bold,
                color: isSelected ? Colors.white : AppColor.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

import 'dart:math';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../engine/grid_bot_engine.dart';
import '../../../models/trade_order.dart';
import '../../../style/style.dart';

class OrderTableView extends StatefulWidget {
  final bool isFullPage;

  const OrderTableView({
    super.key,
    this.isFullPage = false,
  });

  @override
  State<OrderTableView> createState() => _OrderTableViewState();
}

class _OrderTableViewState extends State<OrderTableView> {
  int _activeTabIndex = 0; // 0: 미체결 매수, 1: 미체결 익절, 2: 체결 대기, 3: 청산 완료

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: GridBotEngine.instance,
      builder: (context, _) {
        final engine = GridBotEngine.instance;

        // Cumulative Realized PnL
        double totalRealizedPnl = 0.0;
        for (var h in engine.closedHistory) {
          totalRealizedPnl += h.realizedPnl;
        }

        return Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: AppColor.cardSurface,
            borderRadius: AppDimensions.borderRadiusLg,
            boxShadow: AppColor.subtleShadow,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // 1. Full-page Mode KPI Summary Cards
              if (widget.isFullPage) ...[
                _buildOrderKpiBar(engine, totalRealizedPnl),
                const SizedBox(height: 18),
              ],

              // 2. Modern Segmented Capsule Tab Bar
              _buildSegmentedTabBar(engine),
              const SizedBox(height: 16),

              // 3. Tab Content Area
              widget.isFullPage
                  ? Expanded(
                      child: _buildActiveTabContent(engine),
                    )
                  : SizedBox(
                      height: 230,
                      child: _buildActiveTabContent(engine),
                    ),
            ],
          ),
        );
      },
    );
  }

  // --- 1. Top Order KPI Summary Bar ---
  Widget _buildOrderKpiBar(GridBotEngine engine, double totalPnl) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isWide = constraints.maxWidth >= 720;
        final totalOrders = engine.liveOrders.length + engine.liveCloseOrders.length;

        final items = [
          _buildKpiCard(
            label: '총 활성 주문',
            value: '$totalOrders 건',
            icon: Icons.layers_outlined,
            color: AppColor.primary,
          ),
          _buildKpiCard(
            label: '미체결 매수',
            value: '${engine.liveOrders.length} 건',
            icon: Icons.south_west,
            color: AppColor.longGreen,
          ),
          _buildKpiCard(
            label: '미체결 익절',
            value: '${engine.liveCloseOrders.length} 건',
            icon: Icons.north_east,
            color: AppColor.shortRed,
          ),
          _buildKpiCard(
            label: '누적 실현 손익',
            value: '${totalPnl >= 0 ? '+' : ''}${totalPnl.toStringAsFixed(2)} USDT',
            icon: Icons.monetization_on_outlined,
            color: totalPnl >= 0 ? AppColor.longGreen : AppColor.shortRed,
          ),
        ];

        if (isWide) {
          return Row(
            children: items
                .map((widget) => Expanded(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 5),
                        child: widget,
                      ),
                    ))
                .toList(),
          );
        } else {
          return Wrap(
            spacing: 8,
            runSpacing: 8,
            children: items
                .map((w) => SizedBox(
                      width: (constraints.maxWidth - 8) / 2,
                      child: w,
                    ))
                .toList(),
          );
        }
      },
    );
  }

  Widget _buildKpiCard({
    required String label,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: AppColor.inputSurface.withValues(alpha: 0.6),
        borderRadius: AppDimensions.borderRadiusMd,
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, size: 16, color: color),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 11,
                    color: AppColor.textSecondary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'monospace',
                    color: color,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // --- 2. Modern Segmented Capsule Tab Bar ---
  Widget _buildSegmentedTabBar(GridBotEngine engine) {
    final tabs = [
      _TabDef(
        index: 0,
        title: '미체결 매수',
        count: engine.liveOrders.length,
        icon: Icons.south_west,
        color: AppColor.longGreen,
      ),
      _TabDef(
        index: 1,
        title: '미체결 익절',
        count: engine.liveCloseOrders.length,
        icon: Icons.north_east,
        color: AppColor.shortRed,
      ),
      _TabDef(
        index: 2,
        title: '체결 대기',
        count: engine.filledOrders.length,
        icon: Icons.hourglass_top,
        color: AppColor.warning,
      ),
      _TabDef(
        index: 3,
        title: '청산 완료',
        count: engine.closedHistory.length,
        icon: Icons.task_alt,
        color: AppColor.accent,
      ),
    ];

    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: AppColor.inputSurface.withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(14),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final isNarrow = constraints.maxWidth < 600;

          if (isNarrow) {
            return SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: tabs.map((t) => _buildSegmentItem(t, flex: false)).toList(),
              ),
            );
          }

          return Row(
            children: tabs.map((t) => _buildSegmentItem(t, flex: true)).toList(),
          );
        },
      ),
    );
  }

  Widget _buildSegmentItem(_TabDef tab, {required bool flex}) {
    final isSelected = _activeTabIndex == tab.index;

    final item = InkWell(
      onTap: () => setState(() => _activeTabIndex = tab.index),
      borderRadius: BorderRadius.circular(10),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOutCubic,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColor.backgroundCard
              : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
          boxShadow: isSelected ? AppColor.subtleShadow : null,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              tab.icon,
              size: 14,
              color: isSelected ? tab.color : AppColor.textSecondary,
            ),
            const SizedBox(width: 6),
            Text(
              tab.title,
              style: TextStyle(
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                color: isSelected ? AppColor.textPrimary : AppColor.textSecondary,
              ),
            ),
            const SizedBox(width: 8),
            // Count Capsule Badge
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: tab.count > 0
                    ? tab.color.withValues(alpha: isSelected ? 0.25 : 0.15)
                    : AppColor.inputSurface,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                '${tab.count}',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  fontFamily: 'monospace',
                  color: tab.count > 0 ? tab.color : AppColor.textDisabled,
                ),
              ),
            ),
          ],
        ),
      ),
    );

    return flex ? Expanded(child: item) : Padding(padding: const EdgeInsets.only(right: 6), child: item);
  }

  // --- 3. Active Tab Content ---
  Widget _buildActiveTabContent(GridBotEngine engine) {
    switch (_activeTabIndex) {
      case 0:
        return _buildOrderList(
          orders: engine.liveOrders,
          isBuy: true,
          emptyTitle: '미체결 매수 주문이 없습니다',
          emptyHint: '그리드 봇을 시작하면 현재 시장 가격 아래에 지정가 분할 매수 주문이 자동 배치됩니다.',
        );
      case 1:
        return _buildOrderList(
          orders: engine.liveCloseOrders,
          isBuy: false,
          emptyTitle: '미체결 익절 매도 주문이 없습니다',
          emptyHint: '매수 주문이 체결되면 목표 익절 마진에 맞춰 자동으로 분할 매도 주문이 등록됩니다.',
        );
      case 2:
        return _buildOrderList(
          orders: engine.filledOrders,
          isBuy: true,
          emptyTitle: '체결 대기 포지션이 없습니다',
          emptyHint: '체결된 매수 주문 중 아직 익절 매도가 완료되지 않은 포지션 목록입니다.',
        );
      case 3:
      default:
        return _buildHistoryList(engine.closedHistory);
    }
  }

  Widget _buildOrderList({
    required List<TradeOrder> orders,
    required bool isBuy,
    required String emptyTitle,
    required String emptyHint,
  }) {
    if (orders.isEmpty) {
      return _buildEmptyState(
        icon: isBuy ? Icons.south_west : Icons.north_east,
        title: emptyTitle,
        hint: emptyHint,
      );
    }

    return Column(
      children: [
        // Column Header
        _buildTableHeader(isHistory: false),
        const SizedBox(height: 6),
        Expanded(
          child: ListView.separated(
            itemCount: orders.length,
            separatorBuilder: (_, __) => const SizedBox(height: 6),
            itemBuilder: (context, idx) {
              final o = orders[idx];
              final timeStr = DateFormat('yyyy-MM-dd HH:mm:ss').format(o.createdAt);

              return Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: AppColor.inputSurface.withValues(alpha: 0.4),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  children: [
                    // Type Badge
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: (isBuy ? AppColor.longGreen : AppColor.shortRed)
                            .withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            isBuy ? Icons.arrow_downward : Icons.arrow_upward,
                            size: 11,
                            color: isBuy ? AppColor.longGreen : AppColor.shortRed,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            isBuy ? '매수 (OPEN)' : '익절 (CLOSE)',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: isBuy ? AppColor.longGreen : AppColor.shortRed,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 14),

                    // Price
                    Expanded(
                      flex: 3,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '${o.price.toStringAsFixed(1)} USDT',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                              fontFamily: 'monospace',
                              color: AppColor.textPrimary,
                            ),
                          ),
                          Text(
                            'ID: ${o.orderId.substring(0, min(14, o.orderId.length))}...',
                            style: TextStyle(
                              fontSize: 10,
                              color: AppColor.textDisabled,
                              fontFamily: 'monospace',
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Quantity
                    Expanded(
                      flex: 2,
                      child: Text(
                        '${o.size.toStringAsFixed(4)} 수량',
                        style: TextStyle(
                          fontSize: 12,
                          fontFamily: 'monospace',
                          color: AppColor.textSecondary,
                        ),
                      ),
                    ),

                    // Time
                    Text(
                      timeStr,
                      style: TextStyle(
                        fontSize: 11,
                        color: AppColor.textDisabled,
                        fontFamily: 'monospace',
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildHistoryList(List<TradeOrder> history) {
    if (history.isEmpty) {
      return _buildEmptyState(
        icon: Icons.task_alt,
        title: '청산 완료된 페어 거래가 없습니다',
        hint: '그리드 봇의 매수 주문 체결 후 익절 매도가 완료되면 실현 손익 및 체결 이력이 기록됩니다.',
      );
    }

    return Column(
      children: [
        // Column Header
        _buildTableHeader(isHistory: true),
        const SizedBox(height: 6),
        Expanded(
          child: ListView.separated(
            itemCount: history.length,
            separatorBuilder: (_, __) => const SizedBox(height: 6),
            itemBuilder: (context, idx) {
              final o = history[idx];
              final timeStr = DateFormat('yyyy-MM-dd HH:mm:ss').format(o.updatedAt ?? o.createdAt);
              final isProfit = o.realizedPnl >= 0;

              return Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: AppColor.inputSurface.withValues(alpha: 0.4),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  children: [
                    // Status Badge
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: AppColor.accent.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.check_circle, size: 11, color: AppColor.accent),
                          SizedBox(width: 4),
                          Text(
                            'PAIR EXIT',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: AppColor.accent,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 14),

                    // Exit Price
                    Expanded(
                      flex: 3,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '체결가: ${o.price.toStringAsFixed(1)} USDT',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              fontFamily: 'monospace',
                              color: AppColor.textPrimary,
                            ),
                          ),
                          Text(
                            'ID: ${o.orderId.substring(0, min(14, o.orderId.length))}...',
                            style: TextStyle(
                              fontSize: 10,
                              color: AppColor.textDisabled,
                              fontFamily: 'monospace',
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Realized PnL
                    Expanded(
                      flex: 2,
                      child: Text(
                        '${isProfit ? '+' : ''}${o.realizedPnl.toStringAsFixed(2)} USDT',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          fontFamily: 'monospace',
                          color: isProfit ? AppColor.longGreen : AppColor.shortRed,
                        ),
                      ),
                    ),

                    // Time
                    Text(
                      timeStr,
                      style: TextStyle(
                        fontSize: 11,
                        color: AppColor.textDisabled,
                        fontFamily: 'monospace',
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildTableHeader({required bool isHistory}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: AppColor.inputSurface.withValues(alpha: 0.25),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 90,
            child: Text(
              '구분',
              style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColor.textSecondary),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            flex: 3,
            child: Text(
              '주문 가격',
              style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColor.textSecondary),
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              isHistory ? '실현 손익' : '주문 수량',
              style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColor.textSecondary),
            ),
          ),
          Text(
            '주문 일시',
            style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColor.textSecondary),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState({
    required IconData icon,
    required String title,
    required String hint,
  }) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                color: AppColor.inputSurface.withValues(alpha: 0.8),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 24, color: AppColor.textDisabled),
            ),
            const SizedBox(height: 14),
            Text(
              title,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: AppColor.textPrimary,
              ),
            ),
            const SizedBox(height: 6),
            ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Text(
                hint,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 12,
                  color: AppColor.textSecondary,
                  height: 1.4,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TabDef {
  final int index;
  final String title;
  final int count;
  final IconData icon;
  final Color color;

  _TabDef({
    required this.index,
    required this.title,
    required this.count,
    required this.icon,
    required this.color,
  });
}

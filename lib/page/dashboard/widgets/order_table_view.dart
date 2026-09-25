import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../engine/grid_bot_engine.dart';
import '../../../models/trade_order.dart';
import '../../../style/app_color.dart';
import '../../../widget/glass_container.dart';

class OrderTableView extends StatefulWidget {
  const OrderTableView({super.key});

  @override
  State<OrderTableView> createState() => _OrderTableViewState();
}

class _OrderTableViewState extends State<OrderTableView>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: GridBotEngine.instance,
      builder: (context, _) {
        final engine = GridBotEngine.instance;

        return GlassContainer(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Tab Header
              TabBar(
                controller: _tabController,
                indicatorColor: AppColor.accent,
                indicatorWeight: 2,
                labelColor: AppColor.accent,
                unselectedLabelColor: AppColor.textSecondary,
                labelStyle: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                ),
                tabs: [
                  Tab(text: '미체결 매수 (${engine.liveOrders.length})'),
                  Tab(text: '미체결 익절 (${engine.liveCloseOrders.length})'),
                  Tab(text: '체결 대기 (${engine.filledOrders.length})'),
                  Tab(text: '청산 완료 (${engine.closedHistory.length})'),
                ],
              ),
              const SizedBox(height: 12),

              // Tab Views
              SizedBox(
                height: 240,
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    _buildOrderList(engine.liveOrders, isBuy: true),
                    _buildOrderList(engine.liveCloseOrders, isBuy: false),
                    _buildOrderList(engine.filledOrders, isBuy: true),
                    _buildHistoryList(engine.closedHistory),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildOrderList(List<TradeOrder> orders, {required bool isBuy}) {
    if (orders.isEmpty) {
      return const Center(
        child: Text(
          '주문 내역이 없습니다.',
          style: TextStyle(color: AppColor.textDisabled, fontSize: 13),
        ),
      );
    }

    return ListView.separated(
      itemCount: orders.length,
      separatorBuilder: (_, __) => const Divider(color: Colors.white10, height: 1),
      itemBuilder: (context, idx) {
        final o = orders[idx];
        final timeStr = DateFormat('HH:mm:ss').format(o.createdAt);

        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
          child: Row(
            children: [
              // Side Badge
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: isBuy
                      ? AppColor.longGreen.withValues(alpha: 0.2)
                      : AppColor.shortRed.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  isBuy ? 'BUY' : 'SELL',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: isBuy ? AppColor.longGreen : AppColor.shortRed,
                  ),
                ),
              ),
              const SizedBox(width: 12),

              // Price
              Expanded(
                flex: 3,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${o.price.toStringAsFixed(1)} USDT',
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        fontFamily: 'monospace',
                        color: AppColor.textPrimary,
                      ),
                    ),
                    Text(
                      'ID: ${o.orderId}',
                      style: const TextStyle(
                        fontSize: 10,
                        color: AppColor.textDisabled,
                      ),
                    ),
                  ],
                ),
              ),

              // Size
              Expanded(
                flex: 2,
                child: Text(
                  '${o.size.toStringAsFixed(4)} BTC',
                  style: const TextStyle(
                    fontSize: 12,
                    fontFamily: 'monospace',
                    color: AppColor.textSecondary,
                  ),
                ),
              ),

              // Time
              Text(
                timeStr,
                style: const TextStyle(
                  fontSize: 11,
                  color: AppColor.textDisabled,
                  fontFamily: 'monospace',
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildHistoryList(List<TradeOrder> history) {
    if (history.isEmpty) {
      return const Center(
        child: Text(
          '청산 완료된 페어 거래가 없습니다.',
          style: TextStyle(color: AppColor.textDisabled, fontSize: 13),
        ),
      );
    }

    return ListView.separated(
      itemCount: history.length,
      separatorBuilder: (_, __) => const Divider(color: Colors.white10, height: 1),
      itemBuilder: (context, idx) {
        final o = history[idx];
        final timeStr = DateFormat('HH:mm:ss').format(o.updatedAt ?? o.createdAt);

        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: AppColor.accent.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: const Text(
                  'PAIR EXIT',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: AppColor.accent,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                flex: 3,
                child: Text(
                  '체결가: ${o.price.toStringAsFixed(1)} USDT',
                  style: const TextStyle(
                    fontSize: 12,
                    fontFamily: 'monospace',
                    color: AppColor.textPrimary,
                  ),
                ),
              ),
              Expanded(
                flex: 2,
                child: Text(
                  '+${o.realizedPnl.toStringAsFixed(2)} USDT',
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'monospace',
                    color: AppColor.longGreen,
                  ),
                ),
              ),
              Text(
                timeStr,
                style: const TextStyle(
                  fontSize: 11,
                  color: AppColor.textDisabled,
                  fontFamily: 'monospace',
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

import 'package:flutter/material.dart';
import '../../style/app_color.dart';

class OrderbookDepthWidget extends StatelessWidget {
  final Map<String, List<List<double>>> orderBook;
  final double currentPrice;

  const OrderbookDepthWidget({
    super.key,
    required this.orderBook,
    required this.currentPrice,
  });

  @override
  Widget build(BuildContext context) {
    final asks = (orderBook['asks'] ?? []).take(8).toList().reversed.toList();
    final bids = (orderBook['bids'] ?? []).take(8).toList();

    double maxVol = 1.0;
    for (var a in asks) {
      if (a.length > 1 && a[1] > maxVol) maxVol = a[1];
    }
    for (var b in bids) {
      if (b.length > 1 && b[1] > maxVol) maxVol = b[1];
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Header
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '호가(USDT)',
                style: TextStyle(fontSize: 11, color: AppColor.textDisabled),
              ),
              Text(
                '수량(BTC)',
                style: TextStyle(fontSize: 11, color: AppColor.textDisabled),
              ),
            ],
          ),
        ),

        // Asks (매도 호가)
        Expanded(
          child: ListView.builder(
            reverse: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: asks.length,
            itemBuilder: (context, idx) {
              final row = asks[idx];
              double price = row[0];
              double amount = row[1];
              double ratio = (amount / maxVol).clamp(0.05, 1.0);

              return _buildRow(
                price: price,
                amount: amount,
                ratio: ratio,
                color: AppColor.shortRed,
              );
            },
          ),
        ),

        // Center Current Price
        Container(
          padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 10),
          margin: const EdgeInsets.symmetric(vertical: 4),
          decoration: BoxDecoration(
            color: AppColor.glassBackgroundActive,
            borderRadius: BorderRadius.circular(6),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                currentPrice > 0 ? currentPrice.toStringAsFixed(1) : '---',
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: AppColor.accent,
                ),
              ),
              Text(
                '실시간 체결가',
                style: TextStyle(fontSize: 11, color: AppColor.textSecondary),
              ),
            ],
          ),
        ),

        // Bids (매수 호가)
        Expanded(
          child: ListView.builder(
            physics: const NeverScrollableScrollPhysics(),
            itemCount: bids.length,
            itemBuilder: (context, idx) {
              final row = bids[idx];
              double price = row[0];
              double amount = row[1];
              double ratio = (amount / maxVol).clamp(0.05, 1.0);

              return _buildRow(
                price: price,
                amount: amount,
                ratio: ratio,
                color: AppColor.longGreen,
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildRow({
    required double price,
    required double amount,
    required double ratio,
    required Color color,
  }) {
    return Stack(
      children: [
        // Depth Volume Bar Fill
        Positioned.fill(
          child: Align(
            alignment: Alignment.centerRight,
            child: FractionallySizedBox(
              widthFactor: ratio,
              child: Container(
                color: color.withValues(alpha: 0.12),
              ),
            ),
          ),
        ),
        // Text Content
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2.5),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                price.toStringAsFixed(1),
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: color,
                  fontFamily: 'monospace',
                ),
              ),
              Text(
                amount.toStringAsFixed(3),
                style: TextStyle(
                  fontSize: 12,
                  color: AppColor.textSecondary,
                  fontFamily: 'monospace',
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

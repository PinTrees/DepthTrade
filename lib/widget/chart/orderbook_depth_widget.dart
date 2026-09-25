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
    final rawAsks = orderBook['asks'] ?? [];
    final rawBids = orderBook['bids'] ?? [];

    final asks = rawAsks.take(8).toList().reversed.toList();
    final bids = rawBids.take(8).toList();

    double maxVol = 1.0;
    for (var a in asks) {
      if (a.length > 1 && a[1] > maxVol) maxVol = a[1];
    }
    for (var b in bids) {
      if (b.length > 1 && b[1] > maxVol) maxVol = b[1];
    }

    // Calculate Orderbook Price Spread
    double spread = 0.0;
    double spreadPct = 0.0;
    if (rawAsks.isNotEmpty && rawBids.isNotEmpty) {
      final lowestAsk = rawAsks.first[0];
      final highestBid = rawBids.first[0];
      if (lowestAsk > highestBid && lowestAsk > 0) {
        spread = lowestAsk - highestBid;
        spreadPct = (spread / lowestAsk) * 100;
      }
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

        // Center Current Price & Real-time Spread
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
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    currentPrice > 0 ? currentPrice.toStringAsFixed(1) : '---',
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: AppColor.accent,
                    ),
                  ),
                  // 값이 0이면 표시하지 않음 (Spread > 0 조건)
                  if (spread > 0.0001) ...[
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: AppColor.inputSurface,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        '스프레드 ${spread.toStringAsFixed(1)} (${spreadPct.toStringAsFixed(2)}%)',
                        style: TextStyle(
                          fontSize: 10,
                          fontFamily: 'monospace',
                          color: AppColor.textSecondary,
                        ),
                      ),
                    ),
                  ],
                ],
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

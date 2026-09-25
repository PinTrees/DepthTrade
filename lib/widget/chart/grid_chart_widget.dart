import 'dart:math';
import 'package:flutter/material.dart';
import '../../models/candle_data.dart';
import '../../models/trade_order.dart';
import '../../style/app_color.dart';

class GridChartWidget extends StatelessWidget {
  final List<CandleData> candles;
  final double currentPrice;
  final List<TradeOrder> liveBuyOrders;
  final List<TradeOrder> liveCloseOrders;

  const GridChartWidget({
    super.key,
    required this.candles,
    required this.currentPrice,
    required this.liveBuyOrders,
    required this.liveCloseOrders,
  });

  @override
  Widget build(BuildContext context) {
    if (candles.isEmpty && currentPrice <= 0) {
      return const Center(
        child: CircularProgressIndicator(color: AppColor.primary),
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        return CustomPaint(
          size: Size(constraints.maxWidth, constraints.maxHeight),
          painter: _GridChartPainter(
            candles: candles,
            currentPrice: currentPrice,
            liveBuyOrders: liveBuyOrders,
            liveCloseOrders: liveCloseOrders,
          ),
        );
      },
    );
  }
}

class _GridChartPainter extends CustomPainter {
  final List<CandleData> candles;
  final double currentPrice;
  final List<TradeOrder> liveBuyOrders;
  final List<TradeOrder> liveCloseOrders;

  _GridChartPainter({
    required this.candles,
    required this.currentPrice,
    required this.liveBuyOrders,
    required this.liveCloseOrders,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (size.width <= 0 || size.height <= 0) return;

    // 1. Min / Max Price 계산
    double minPrice = currentPrice > 0 ? currentPrice : 100000;
    double maxPrice = currentPrice > 0 ? currentPrice : 0;

    for (var c in candles) {
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

    double padding = (maxPrice - minPrice) * 0.1;
    if (padding <= 0) padding = minPrice * 0.05;
    minPrice -= padding;
    maxPrice += padding;

    double priceToY(double price) {
      if (maxPrice == minPrice) return size.height / 2;
      return size.height - ((price - minPrice) / (maxPrice - minPrice)) * size.height;
    }

    // 2. 배경 수평 그리드 눈금선
    final gridLinePaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.04)
      ..strokeWidth = 1.0;

    const int gridSteps = 6;
    for (int i = 0; i <= gridSteps; i++) {
      double y = size.height * (i / gridSteps);
      canvas.drawLine(Offset(0, y), Offset(size.width, y), gridLinePaint);

      double p = maxPrice - (i / gridSteps) * (maxPrice - minPrice);
      _drawText(
        canvas,
        p.toStringAsFixed(1),
        Offset(size.width - 65, y - 12),
        AppColor.textDisabled,
        10,
      );
    }

    // 3. 캔들스틱 그리기
    if (candles.isNotEmpty) {
      double candleWidth = max(2.0, (size.width - 80) / candles.length);
      for (int i = 0; i < candles.length; i++) {
        final c = candles[i];
        double x = i * candleWidth + candleWidth / 2;

        bool isUp = c.close >= c.open;
        final candlePaint = Paint()
          ..color = isUp ? AppColor.longGreen : AppColor.shortRed
          ..strokeWidth = 1.2;

        // Wick
        double yHigh = priceToY(c.high);
        double yLow = priceToY(c.low);
        canvas.drawLine(Offset(x, yHigh), Offset(x, yLow), candlePaint);

        // Body
        double yOpen = priceToY(c.open);
        double yClose = priceToY(c.close);
        double top = min(yOpen, yClose);
        double height = max(1.5, (yOpen - yClose).abs());

        final bodyPaint = Paint()
          ..color = isUp ? AppColor.longGreen : AppColor.shortRed
          ..style = PaintingStyle.fill;

        canvas.drawRect(
          Rect.fromLTWH(x - candleWidth * 0.35, top, candleWidth * 0.7, height),
          bodyPaint,
        );
      }
    }

    // 4. 미체결 매수 그리드선 (Open Long Lines - Green)
    final buyOrderPaint = Paint()
      ..color = AppColor.longGreen.withValues(alpha: 0.7)
      ..strokeWidth = 1.0;

    for (var order in liveBuyOrders) {
      double y = priceToY(order.price);
      _drawDashedLine(canvas, Offset(0, y), Offset(size.width - 70, y), buyOrderPaint);
      _drawTag(
        canvas,
        'BUY ${order.price.toStringAsFixed(1)}',
        Offset(size.width - 70, y - 9),
        AppColor.longGreen.withValues(alpha: 0.2),
        AppColor.longGreen,
      );
    }

    // 5. 미체결 익절 그리드선 (Close Long Lines - Cyan/Red)
    final closeOrderPaint = Paint()
      ..color = AppColor.accent.withValues(alpha: 0.7)
      ..strokeWidth = 1.0;

    for (var order in liveCloseOrders) {
      double y = priceToY(order.price);
      _drawDashedLine(canvas, Offset(0, y), Offset(size.width - 70, y), closeOrderPaint);
      _drawTag(
        canvas,
        'SELL ${order.price.toStringAsFixed(1)}',
        Offset(size.width - 70, y - 9),
        AppColor.accent.withValues(alpha: 0.2),
        AppColor.accent,
      );
    }

    // 6. 현재 실시간 가격선 (Current Price Line)
    if (currentPrice > 0) {
      double curY = priceToY(currentPrice);
      final curPricePaint = Paint()
        ..color = AppColor.primary
        ..strokeWidth = 1.5;

      canvas.drawLine(Offset(0, curY), Offset(size.width - 70, curY), curPricePaint);
      _drawTag(
        canvas,
        currentPrice.toStringAsFixed(1),
        Offset(size.width - 70, curY - 10),
        AppColor.primary,
        Colors.white,
      );
    }
  }

  void _drawDashedLine(Canvas canvas, Offset p1, Offset p2, Paint paint) {
    const double dashWidth = 5;
    const double dashSpace = 4;
    double startX = p1.dx;
    while (startX < p2.dx) {
      canvas.drawLine(
        Offset(startX, p1.dy),
        Offset(min(startX + dashWidth, p2.dx), p1.dy),
        paint,
      );
      startX += dashWidth + dashSpace;
    }
  }

  void _drawTag(
      Canvas canvas, String text, Offset pos, Color bgColor, Color textColor) {
    final textSpan = TextSpan(
      text: text,
      style: TextStyle(
        color: textColor,
        fontSize: 10,
        fontWeight: FontWeight.bold,
      ),
    );
    final tp = TextPainter(
      text: textSpan,
      textDirection: TextDirection.ltr,
    )..layout();

    final bgRect = Rect.fromLTWH(
      pos.dx,
      pos.dy,
      tp.width + 8,
      tp.height + 4,
    );
    final bgPaint = Paint()..color = bgColor;
    canvas.drawRRect(RRect.fromRectAndRadius(bgRect, const Radius.circular(4)), bgPaint);
    tp.paint(canvas, Offset(pos.dx + 4, pos.dy + 2));
  }

  void _drawText(Canvas canvas, String text, Offset pos, Color color, double size) {
    final textSpan = TextSpan(
      text: text,
      style: TextStyle(color: color, fontSize: size, fontWeight: FontWeight.w500),
    );
    final tp = TextPainter(text: textSpan, textDirection: TextDirection.ltr)..layout();
    tp.paint(canvas, pos);
  }

  @override
  bool shouldRepaint(covariant _GridChartPainter oldDelegate) => true;
}

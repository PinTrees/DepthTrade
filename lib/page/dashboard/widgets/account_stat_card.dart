import 'package:flutter/material.dart';
import '../../../engine/grid_bot_engine.dart';
import '../../../style/app_color.dart';
import '../../../widget/glass_container.dart';

class AccountStatCard extends StatelessWidget {
  const AccountStatCard({super.key});

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: GridBotEngine.instance,
      builder: (context, _) {
        final engine = GridBotEngine.instance;
        final acc = engine.account;

        final bool isProfit = acc.totalPnl >= 0;
        final Color pnlColor = isProfit ? AppColor.longGreen : AppColor.shortRed;

        return GlassContainer(
          padding: const EdgeInsets.all(18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Top Bar
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.account_balance_wallet,
                          color: AppColor.accent, size: 20),
                      SizedBox(width: 8),
                      Text(
                        '계좌 및 포지션 현황 (Account & Position)',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: AppColor.textPrimary,
                        ),
                      ),
                    ],
                  ),
                  Row(
                    children: [
                      Container(
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: engine.isRunning
                              ? AppColor.longGreen
                              : AppColor.textDisabled,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        engine.isRunning ? '봇 가동 중 (RUNNING)' : '대기 상태 (IDLE)',
                        style: TextStyle(
                          fontSize: 12,
                          color: engine.isRunning
                              ? AppColor.longGreen
                              : AppColor.textDisabled,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Metrics Row
              LayoutBuilder(
                builder: (context, constraints) {
                  int cols = constraints.maxWidth > 700 ? 4 : 2;
                  return Wrap(
                    spacing: 12,
                    runSpacing: 12,
                    children: [
                      _metricBox(
                        title: '총 자산 (Total Equity)',
                        value: '${acc.equity.toStringAsFixed(2)} USDT',
                        subText: '시작: ${acc.startEquity.toStringAsFixed(1)} USDT',
                        width: (constraints.maxWidth - (cols - 1) * 12) / cols,
                        valueColor: AppColor.textPrimary,
                      ),
                      _metricBox(
                        title: '총 손익 (Total PnL)',
                        value:
                            '${isProfit ? '+' : ''}${acc.totalPnl.toStringAsFixed(2)} USDT',
                        subText:
                            '수익률: ${isProfit ? '+' : ''}${acc.totalReturnPer.toStringAsFixed(2)}%',
                        width: (constraints.maxWidth - (cols - 1) * 12) / cols,
                        valueColor: pnlColor,
                      ),
                      _metricBox(
                        title: '실현 / 미실현 손익',
                        value:
                            '실현: +${acc.realizedPnl.toStringAsFixed(2)} USDT',
                        subText:
                            '미실현: ${acc.unrealizedPnl >= 0 ? '+' : ''}${acc.unrealizedPnl.toStringAsFixed(2)} USDT',
                        width: (constraints.maxWidth - (cols - 1) * 12) / cols,
                        valueColor: AppColor.secondary,
                      ),
                      _metricBox(
                        title: '페어 거래 횟수',
                        value: '${acc.pairTradeCount} 회 완료',
                        subText:
                            '보유 포지션: ${acc.holdSize.toStringAsFixed(4)} BTC',
                        width: (constraints.maxWidth - (cols - 1) * 12) / cols,
                        valueColor: AppColor.accent,
                      ),
                    ],
                  );
                },
              ),
              const SizedBox(height: 14),

              // Realtime Log Output Line
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  color: AppColor.inputSurface,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.terminal,
                        size: 14, color: AppColor.accent),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        engine.systemLog,
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColor.textSecondary,
                          fontFamily: 'monospace',
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
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

  Widget _metricBox({
    required String title,
    required String value,
    required String subText,
    required double width,
    required Color valueColor,
  }) {
    return Container(
      width: width,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColor.cardSurface,
        borderRadius: BorderRadius.circular(12),
        boxShadow: AppColor.subtleShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 11,
              color: AppColor.textSecondary,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.bold,
              color: valueColor,
              fontFamily: 'monospace',
            ),
          ),
          const SizedBox(height: 2),
          Text(
            subText,
            style: const TextStyle(
              fontSize: 11,
              color: AppColor.textDisabled,
            ),
          ),
        ],
      ),
    );
  }
}

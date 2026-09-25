import 'package:flutter/material.dart';
import '../../../engine/grid_bot_engine.dart';
import '../../../models/crypto_symbol.dart';
import '../../../style/app_color.dart';

class CoinSelectorDialog extends StatefulWidget {
  const CoinSelectorDialog({super.key});

  static Future<void> show(BuildContext context) {
    return showDialog(
      context: context,
      builder: (_) => const CoinSelectorDialog(),
    );
  }

  @override
  State<CoinSelectorDialog> createState() => _CoinSelectorDialogState();
}

class _CoinSelectorDialogState extends State<CoinSelectorDialog> {
  String _searchQuery = '';

  @override
  Widget build(BuildContext context) {
    final currentSymbol = GridBotEngine.instance.config.symbol;
    final filtered = CryptoCoin.popularCoins.where((c) {
      final q = _searchQuery.toLowerCase();
      return c.symbol.toLowerCase().contains(q) ||
          c.name.toLowerCase().contains(q) ||
          c.koreanName.contains(_searchQuery);
    }).toList();

    return Dialog(
      backgroundColor: AppColor.backgroundCard,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide.none,
      ),
      child: Container(
        width: 480,
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Title Bar
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    const Icon(Icons.currency_exchange, color: AppColor.accent, size: 22),
                    const SizedBox(width: 10),
                    Text(
                      '거래 코인 선택 (Market)',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: AppColor.textPrimary,
                      ),
                    ),
                  ],
                ),
                IconButton(
                  icon: Icon(Icons.close, color: AppColor.textSecondary, size: 20),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              '유동성이 풍부한 메이저 및 인기 암호화폐 선물 종목입니다.',
              style: TextStyle(fontSize: 12, color: AppColor.textSecondary),
            ),
            const SizedBox(height: 16),

            // Search Bar
            Container(
              decoration: BoxDecoration(
                color: AppColor.inputSurface,
                borderRadius: BorderRadius.circular(12),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 14),
              child: TextField(
                style: TextStyle(fontSize: 13, color: AppColor.textPrimary),
                decoration: InputDecoration(
                  icon: Icon(Icons.search, size: 18, color: AppColor.textSecondary),
                  hintText: '심볼, 영문명 또는 한글명 검색 (예: BTC, 솔라나)',
                  hintStyle: TextStyle(fontSize: 12, color: AppColor.textDisabled),
                  border: InputBorder.none,
                ),
                onChanged: (v) => setState(() => _searchQuery = v),
              ),
            ),
            const SizedBox(height: 16),

            // Coin List
            ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: 380),
              child: ListView.separated(
                shrinkWrap: true,
                itemCount: filtered.length,
                separatorBuilder: (_, __) => const SizedBox(height: 6),
                itemBuilder: (context, idx) {
                  final coin = filtered[idx];
                  final isSelected = coin.symbol == currentSymbol;

                  return InkWell(
                    onTap: () {
                      GridBotEngine.instance.switchCoin(coin);
                      Navigator.pop(context);
                    },
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? AppColor.primary.withValues(alpha: 0.18)
                            : AppColor.cardSurface,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: isSelected ? AppColor.subtleShadow : null,
                      ),
                      child: Row(
                        children: [
                          // Coin Icon Badge
                          Container(
                            width: 38,
                            height: 38,
                            decoration: BoxDecoration(
                              color: coin.color.withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Icon(coin.icon, color: coin.color, size: 20),
                          ),
                          const SizedBox(width: 14),

                          // Symbol & Name
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Text(
                                      coin.displaySymbol,
                                      style: TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.bold,
                                        color: isSelected ? AppColor.accent : AppColor.textPrimary,
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: AppColor.inputSurface,
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                      child: Text(
                                        'USDT-FUTURES',
                                        style: TextStyle(
                                          fontSize: 9,
                                          fontWeight: FontWeight.w600,
                                          color: AppColor.textSecondary,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  '${coin.koreanName} · ${coin.name}',
                                  style: TextStyle(fontSize: 11, color: AppColor.textSecondary),
                                ),
                              ],
                            ),
                          ),

                          // Base Order Size Info
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(
                                '기본: ${coin.defaultBaseSize} ${coin.symbol.replaceAll('USDT', '')}',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontFamily: 'monospace',
                                  color: AppColor.textSecondary,
                                ),
                              ),
                              if (isSelected)
                                const Text(
                                  '선택됨',
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                    color: AppColor.longGreen,
                                  ),
                                ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

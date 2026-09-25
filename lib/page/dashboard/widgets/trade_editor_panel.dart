import 'package:flutter/material.dart';
import '../../../engine/grid_bot_engine.dart';
import '../../../style/app_color.dart';
import '../../../widget/glass_container.dart';
import '../../../widget/glass_input_field.dart';
import '../../../widget/glow_button.dart';

class TradeEditorPanel extends StatefulWidget {
  const TradeEditorPanel({super.key});

  @override
  State<TradeEditorPanel> createState() => _TradeEditorPanelState();
}

class _TradeEditorPanelState extends State<TradeEditorPanel> {
  late TextEditingController _depthCtrl;
  late TextEditingController _cancelPerCtrl;
  late TextEditingController _openPerCtrl;
  late TextEditingController _closePerCtrl;
  late TextEditingController _lowPriceCtrl;
  late TextEditingController _fixedCountCtrl;

  @override
  void initState() {
    super.initState();
    final cfg = GridBotEngine.instance.config;
    _depthCtrl = TextEditingController(text: cfg.orderDepth.toString());
    _cancelPerCtrl = TextEditingController(text: cfg.canclePer.toString());
    _openPerCtrl = TextEditingController(text: cfg.openOrderPer.toString());
    _closePerCtrl = TextEditingController(text: cfg.closeOrderPer.toString());
    _lowPriceCtrl = TextEditingController(
        text: cfg.posLowPrice > 0 ? cfg.posLowPrice.toStringAsFixed(1) : '');
    _fixedCountCtrl = TextEditingController(text: cfg.fixedOrderCount.toString());
  }

  @override
  void dispose() {
    _depthCtrl.dispose();
    _cancelPerCtrl.dispose();
    _openPerCtrl.dispose();
    _closePerCtrl.dispose();
    _lowPriceCtrl.dispose();
    _fixedCountCtrl.dispose();
    super.dispose();
  }

  void _applySettings() {
    final cfg = GridBotEngine.instance.config;
    cfg.orderDepth = int.tryParse(_depthCtrl.text) ?? cfg.orderDepth;
    cfg.canclePer = double.tryParse(_cancelPerCtrl.text) ?? cfg.canclePer;
    cfg.openOrderPer = double.tryParse(_openPerCtrl.text) ?? cfg.openOrderPer;
    cfg.closeOrderPer = double.tryParse(_closePerCtrl.text) ?? cfg.closeOrderPer;
    cfg.fixedOrderCount = int.tryParse(_fixedCountCtrl.text) ?? cfg.fixedOrderCount;

    final low = double.tryParse(_lowPriceCtrl.text);
    if (low != null && low > 0) {
      cfg.posLowPrice = low;
    }

    GridBotEngine.instance.updateConfig(cfg);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('그리드 파라미터가 적용되었습니다.'),
        backgroundColor: AppColor.primary,
        duration: Duration(seconds: 1),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: GridBotEngine.instance,
      builder: (context, _) {
        final engine = GridBotEngine.instance;
        final cfg = engine.config;

        return GlassContainer(
          padding: const EdgeInsets.all(18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.tune, color: AppColor.accent, size: 20),
                      const SizedBox(width: 8),
                      Text(
                        '그리드 트레이드 설정 (Trade Editor)',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: AppColor.textPrimary,
                        ),
                      ),
                    ],
                  ),
                  // Simulation / Real Mode Badge
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: cfg.isSimulation
                          ? AppColor.primary.withValues(alpha: 0.2)
                          : AppColor.longGreen.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      cfg.isSimulation ? '모의투자 (SIMULATION)' : '실거래 (BITGET REAL)',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: cfg.isSimulation ? AppColor.secondary : AppColor.longGreen,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Inputs Grid (2 columns)
              Row(
                children: [
                  Expanded(
                    child: GlassInputField(
                      controller: _depthCtrl,
                      label: '주문 깊이 (Depth 레벨)',
                      hint: '예: 4',
                      keyboardType: TextInputType.number,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: GlassInputField(
                      controller: _cancelPerCtrl,
                      label: '이격 취소율 (canclePer %)',
                      hint: '예: 1.74',
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              Row(
                children: [
                  Expanded(
                    child: GlassInputField(
                      controller: _openPerCtrl,
                      label: '매수 간격 (openOrderPer %)',
                      hint: '예: 0.34',
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: GlassInputField(
                      controller: _closePerCtrl,
                      label: '익절 간격 (closeOrderPer %)',
                      hint: '예: 0.34',
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              Row(
                children: [
                  Expanded(
                    child: GlassInputField(
                      controller: _lowPriceCtrl,
                      label: '포지션 최저가 기준선 (pos_low_price)',
                      hint: cfg.posLowPrice > 0
                          ? cfg.posLowPrice.toStringAsFixed(1)
                          : '현재가 자동 추적',
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: GlassInputField(
                      controller: _fixedCountCtrl,
                      label: '고정 카운트 가산치 (fixedOrderCount)',
                      hint: '0',
                      keyboardType: TextInputType.number,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),

              // Leverage Slider
              Row(
                children: [
                  Text(
                    '레버리지:',
                    style: TextStyle(fontSize: 13, color: AppColor.textSecondary),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: SliderTheme(
                      data: SliderTheme.of(context).copyWith(
                        activeTrackColor: AppColor.primary,
                        inactiveTrackColor: Colors.white12,
                        thumbColor: AppColor.accent,
                        overlayColor: AppColor.primary.withValues(alpha: 0.2),
                      ),
                      child: Slider(
                        value: cfg.leverage.toDouble(),
                        min: 1,
                        max: 20,
                        divisions: 19,
                        label: '${cfg.leverage}x',
                        onChanged: (val) {
                          setState(() {
                            cfg.leverage = val.toInt();
                          });
                        },
                      ),
                    ),
                  ),
                  Text(
                    '${cfg.leverage}x',
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: AppColor.accent,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),

              // Control Buttons Bar
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: [
                  // 설정 적용
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColor.cardSurface,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    onPressed: _applySettings,
                    icon: const Icon(Icons.check, size: 16),
                    label: const Text('파라미터 적용'),
                  ),

                  // 봇 가동 / 정지
                  if (!engine.isRunning)
                    GlowButton(
                      text: '자동매매 가동 시작 (START)',
                      icon: Icons.play_arrow,
                      glowColor: AppColor.longGreen,
                      gradient: AppColor.greenGradient,
                      onPressed: () {
                        _applySettings();
                        engine.startBot();
                      },
                    )
                  else
                    GlowButton(
                      text: '일시 정지 (PAUSE)',
                      icon: Icons.pause,
                      glowColor: AppColor.warning,
                      gradient: const LinearGradient(
                        colors: [Color(0xFFFFA000), Color(0xFFFF6D00)],
                      ),
                      onPressed: () => engine.stopBot(),
                    ),

                  // 긴급 미체결 주문 전액 취소 (C# TR_CloseLiveOrders)
                  GlowButton(
                    text: '긴급 주문취소 (Close Orders)',
                    icon: Icons.cancel,
                    glowColor: AppColor.shortRed,
                    gradient: AppColor.redGradient,
                    isLoading: engine.isStopping,
                    onPressed: () => engine.emergencyCancelAll(),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}

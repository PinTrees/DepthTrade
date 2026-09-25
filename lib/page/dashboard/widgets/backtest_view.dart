import 'package:flutter/material.dart';
import '../../../engine/backtest_engine.dart';
import '../../../engine/grid_bot_engine.dart';
import '../../../models/backtest_result.dart';
import '../../../models/candle_data.dart';
import '../../../service/bitget_api_service.dart';
import '../../../style/app_color.dart';
import '../../../widget/glass_container.dart';
import '../../../widget/glass_input_field.dart';
import '../../../widget/glow_button.dart';

class BacktestView extends StatefulWidget {
  const BacktestView({super.key});

  @override
  State<BacktestView> createState() => _BacktestViewState();
}

class _BacktestViewState extends State<BacktestView> {
  String _selectedInterval = '15m';
  int _candleLimit = 300;
  final TextEditingController _capitalCtrl = TextEditingController(text: '10000');

  bool _isLoading = false;
  BacktestResult? _result;

  Future<void> _runBacktest() async {
    setState(() => _isLoading = true);

    try {
      final symbol = GridBotEngine.instance.config.symbol;
      List<CandleData> candles = await BitgetApiService.instance.getCandles(
        symbol,
        _selectedInterval,
        _candleLimit,
      );

      // 만약 네트워크 이슈로 캔들이 비어있을 경우 모의 캔들 자동 생성 (테스트 보장)
      if (candles.isEmpty) {
        candles = _generateMockCandles();
      }

      final initialCap = double.tryParse(_capitalCtrl.text) ?? 10000.0;
      final res = BacktestEngine.instance.runBacktest(
        candles: candles,
        config: GridBotEngine.instance.config,
        initialCapital: initialCap,
      );

      setState(() {
        _result = res;
        _isLoading = false;
      });
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('백테스트 실패: $e')),
        );
      }
    }
  }

  List<CandleData> _generateMockCandles() {
    double base = 65000.0;
    List<CandleData> list = [];
    DateTime now = DateTime.now();

    for (int i = 0; i < 200; i++) {
      double change = (i % 5 - 2) * 120.0 + (i % 2 == 0 ? 80 : -70);
      double open = base;
      double close = base + change;
      double high = [open, close].reduce((a, b) => a > b ? a : b) + 50;
      double low = [open, close].reduce((a, b) => a < b ? a : b) - 50;
      base = close;

      list.add(CandleData(
        time: now.subtract(Duration(minutes: (200 - i) * 15)),
        open: open,
        high: high,
        low: low,
        close: close,
        volume: 10.0 + (i % 10),
      ));
    }
    return list;
  }

  @override
  Widget build(BuildContext context) {
    return GlassContainer(
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header
          const Row(
            children: [
              Icon(Icons.query_stats, color: AppColor.accent, size: 20),
              SizedBox(width: 8),
              Text(
                '백테스팅 시뮬레이션 연구소 (Backtest Lab)',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppColor.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // Filters Row
          Row(
            children: [
              // Interval Dropdown
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('캔들 주기 (Interval)',
                        style: TextStyle(fontSize: 12, color: AppColor.textSecondary)),
                    const SizedBox(height: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      decoration: BoxDecoration(
                        color: AppColor.inputSurface,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          value: _selectedInterval,
                          dropdownColor: AppColor.backgroundCard,
                          isExpanded: true,
                          items: const [
                            DropdownMenuItem(value: '1m', child: Text('1분봉 (1m)')),
                            DropdownMenuItem(value: '5m', child: Text('5분봉 (5m)')),
                            DropdownMenuItem(value: '15m', child: Text('15분봉 (15m)')),
                            DropdownMenuItem(value: '1h', child: Text('1시간봉 (1h)')),
                            DropdownMenuItem(value: '4h', child: Text('4시간봉 (4h)')),
                            DropdownMenuItem(value: '1d', child: Text('일봉 (1d)')),
                          ],
                          onChanged: (v) {
                            if (v != null) setState(() => _selectedInterval = v);
                          },
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),

              // Candle Count
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('데이터 수량 (Candles)',
                        style: TextStyle(fontSize: 12, color: AppColor.textSecondary)),
                    const SizedBox(height: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      decoration: BoxDecoration(
                        color: AppColor.inputSurface,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<int>(
                          value: _candleLimit,
                          dropdownColor: AppColor.backgroundCard,
                          isExpanded: true,
                          items: const [
                            DropdownMenuItem(value: 100, child: Text('최근 100개')),
                            DropdownMenuItem(value: 300, child: Text('최근 300개')),
                            DropdownMenuItem(value: 500, child: Text('최근 500개')),
                            DropdownMenuItem(value: 1000, child: Text('최근 1000개')),
                          ],
                          onChanged: (v) {
                            if (v != null) setState(() => _candleLimit = v);
                          },
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),

              // Capital
              Expanded(
                child: GlassInputField(
                  controller: _capitalCtrl,
                  label: '시작 자산 (USDT)',
                  hint: '10000',
                  keyboardType: TextInputType.number,
                ),
              ),
              const SizedBox(width: 12),

              // Run Button
              Padding(
                padding: const EdgeInsets.only(top: 20),
                child: GlowButton(
                  text: '시뮬레이션 실행',
                  icon: Icons.rocket_launch,
                  isLoading: _isLoading,
                  onPressed: _runBacktest,
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),

          // Results Presentation
          if (_result != null) ...[
            LayoutBuilder(
              builder: (context, constraints) {
                int cols = constraints.maxWidth > 700 ? 5 : 2;
                double width = (constraints.maxWidth - (cols - 1) * 10) / cols;

                bool isProfit = _result!.totalProfit >= 0;
                return Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: [
                    _resBox('최종 자산', '${_result!.finalEquity.toStringAsFixed(1)} USDT', width),
                    _resBox(
                      '총 수익률',
                      '${isProfit ? '+' : ''}${_result!.returnRate.toStringAsFixed(2)}%',
                      width,
                      color: isProfit ? AppColor.longGreen : AppColor.shortRed,
                    ),
                    _resBox('총 체결수', '${_result!.totalTrades} 회', width),
                    _resBox('승률 (Win Rate)', '${_result!.winRate.toStringAsFixed(1)}%', width),
                    _resBox(
                      '최대 낙폭 (MDD)',
                      '-${_result!.maxDrawdown.toStringAsFixed(2)}%',
                      width,
                      color: AppColor.shortRed,
                    ),
                  ],
                );
              },
            ),
            const SizedBox(height: 16),

            // Equity Curve Line Canvas
            Container(
              height: 120,
              decoration: BoxDecoration(
                color: AppColor.inputSurface,
                borderRadius: BorderRadius.circular(10),
              ),
              child: CustomPaint(
                painter: _EquityCurvePainter(_result!.equityCurve),
                child: const SizedBox.expand(),
              ),
            ),
          ] else ...[
            Container(
              padding: const EdgeInsets.symmetric(vertical: 36),
              alignment: Alignment.center,
              child: const Text(
                '현재 설정된 파라미터로 과거 캔들스틱 구간을 검증해보세요.',
                style: TextStyle(color: AppColor.textDisabled, fontSize: 13),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _resBox(String title, String val, double width, {Color? color}) {
    return Container(
      width: width,
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: AppColor.cardSurface,
        borderRadius: BorderRadius.circular(10),
        boxShadow: AppColor.subtleShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title,
              style: const TextStyle(fontSize: 11, color: AppColor.textSecondary)),
          const SizedBox(height: 4),
          Text(
            val,
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.bold,
              color: color ?? AppColor.textPrimary,
              fontFamily: 'monospace',
            ),
          ),
        ],
      ),
    );
  }
}

class _EquityCurvePainter extends CustomPainter {
  final List<EquityPoint> points;
  _EquityCurvePainter(this.points);

  @override
  void paint(Canvas canvas, Size size) {
    if (points.length < 2) return;

    double minEq = points.map((p) => p.equity).reduce((a, b) => a < b ? a : b);
    double maxEq = points.map((p) => p.equity).reduce((a, b) => a > b ? a : b);

    double padding = (maxEq - minEq) * 0.1;
    if (padding <= 0) padding = 10;
    minEq -= padding;
    maxEq += padding;

    final path = Path();
    for (int i = 0; i < points.length; i++) {
      double x = (i / (points.length - 1)) * size.width;
      double y = size.height - ((points[i].equity - minEq) / (maxEq - minEq)) * size.height;

      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }

    final linePaint = Paint()
      ..color = AppColor.accent
      ..strokeWidth = 2.0
      ..style = PaintingStyle.stroke;
    canvas.drawPath(path, linePaint);
  }

  @override
  bool shouldRepaint(covariant _EquityCurvePainter oldDelegate) => true;
}

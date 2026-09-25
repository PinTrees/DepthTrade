import 'package:flutter/material.dart';
import '../../service/auth_service.dart';
import '../../style/app_color.dart';
import '../../widget/galaxy_background.dart';
import '../../widget/glass_container.dart';
import '../../widget/google_glass_button.dart';

class LandingPage extends StatefulWidget {
  const LandingPage({super.key});

  @override
  State<LandingPage> createState() => _LandingPageState();
}

class _LandingPageState extends State<LandingPage> {
  bool _isLoading = false;

  Future<void> _handleGoogleSignIn() async {
    setState(() => _isLoading = true);
    try {
      final cred = await AuthService.instance.signInWithGoogle();
      if (cred != null && mounted) {
        Navigator.pushReplacementNamed(context, '/dashboard');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Google 로그인 실패: $e'),
            backgroundColor: AppColor.shortRed,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final double screenWidth = MediaQuery.of(context).size.width;
    final bool isDesktop = screenWidth > 900;

    return Scaffold(
      backgroundColor: AppColor.background,
      body: GalaxyBackground(
        child: SingleChildScrollView(
          child: Column(
            children: [
              _buildNavBar(isDesktop),
              _buildHeroSection(isDesktop),
              const SizedBox(height: 60),
              _buildStatsSection(isDesktop),
              const SizedBox(height: 80),
              _buildFeaturesSection(isDesktop),
              const SizedBox(height: 80),
              _buildWorkflowSection(isDesktop),
              const SizedBox(height: 80),
              _buildCtaBannerSection(isDesktop),
              const SizedBox(height: 60),
              _buildFooter(),
            ],
          ),
        ),
      ),
    );
  }

  // 1. Navigation Bar
  Widget _buildNavBar(bool isDesktop) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: isDesktop ? 48 : 20,
        vertical: 18,
      ),
      decoration: BoxDecoration(
        color: AppColor.backgroundCard.withValues(alpha: 0.6),
        border: Border(bottom: BorderSide(color: AppColor.glassBorder)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  gradient: AppColor.primaryGradient,
                  borderRadius: BorderRadius.circular(10),
                  boxShadow: [
                    BoxShadow(
                      color: AppColor.primary.withValues(alpha: 0.4),
                      blurRadius: 12,
                    ),
                  ],
                ),
                child: const Icon(Icons.candlestick_chart,
                    color: Colors.white, size: 22),
              ),
              const SizedBox(width: 12),
              const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'DEPTH TRADE',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 1.5,
                      color: AppColor.textPrimary,
                    ),
                  ),
                  Text(
                    'QUANT AUTOMATION',
                    style: TextStyle(
                      fontSize: 9,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 1,
                      color: AppColor.accent,
                    ),
                  ),
                ],
              ),
            ],
          ),
          GoogleGlassButton(
            text: 'Google 로그인',
            height: 42,
            isLoading: _isLoading,
            onPressed: _handleGoogleSignIn,
          ),
        ],
      ),
    );
  }

  // 2. Hero Section
  Widget _buildHeroSection(bool isDesktop) {
    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: isDesktop ? 60 : 20,
        vertical: 40,
      ),
      child: Column(
        children: [
          // Cyber Badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: AppColor.primary.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(30),
              border: Border.all(
                color: AppColor.primary.withValues(alpha: 0.4),
              ),
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.bolt, color: AppColor.accent, size: 16),
                SizedBox(width: 6),
                Text(
                  'BITGET & CRYPTO QUANT DEPTH GRID ENGINE',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: AppColor.accent,
                    letterSpacing: 1,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 28),

          // Main Headline
          Text(
            '인간의 감정을 배제한\n심도(Depth) 기반 그리드 자동매매',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: isDesktop ? 46 : 30,
              fontWeight: FontWeight.w900,
              color: AppColor.textPrimary,
              height: 1.25,
              letterSpacing: -1,
            ),
          ),
          const SizedBox(height: 20),

          // Sub-headline
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 680),
            child: Text(
              '오더북 호가창 깊이 실시간 분석 · 1.74% 동적 이격도 제어 · 마틴게일 피라미딩 승수 · 과거 캔들 백테스트 시뮬레이터까지. 위험 부담 없는 모의투자와 Bitget 실거래를 모두 지원합니다.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: isDesktop ? 16 : 14,
                color: AppColor.textSecondary,
                height: 1.6,
              ),
            ),
          ),
          const SizedBox(height: 36),

          // Primary CTA
          GoogleGlassButton(
            width: isDesktop ? 320 : double.infinity,
            height: 56,
            text: 'Google 계정으로 시작하기',
            isLoading: _isLoading,
            onPressed: _handleGoogleSignIn,
          ),
          const SizedBox(height: 14),
          const Text(
            '별도의 회원가입 없이 Google 계정으로 즉시 연동됩니다.',
            style: TextStyle(fontSize: 12, color: AppColor.textDisabled),
          ),
          const SizedBox(height: 50),

          // Terminal Mockup Card
          _buildTerminalPreview(isDesktop),
        ],
      ),
    );
  }

  // Terminal Preview Card
  Widget _buildTerminalPreview(bool isDesktop) {
    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 960),
      child: GlassContainer(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            // Window Header Bar
            Row(
              children: [
                _dot(const Color(0xFFFF5F56)),
                const SizedBox(width: 8),
                _dot(const Color(0xFFFFBD2E)),
                const SizedBox(width: 8),
                _dot(const Color(0xFF27C93F)),
                const SizedBox(width: 16),
                const Text(
                  'DepthTrade Quantum Grid Terminal — BTC/USDT',
                  style: TextStyle(
                    fontSize: 12,
                    color: AppColor.textSecondary,
                    fontFamily: 'monospace',
                  ),
                ),
                const Spacer(),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                  decoration: BoxDecoration(
                    color: AppColor.longGreen.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.fiber_manual_record,
                          color: AppColor.longGreen, size: 8),
                      SizedBox(width: 6),
                      Text(
                        'LIVE GRID MONITORING',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: AppColor.longGreen,
                          fontFamily: 'monospace',
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const Divider(color: Colors.white10, height: 24),

            // Mockup Content Rows
            Wrap(
              spacing: 16,
              runSpacing: 16,
              children: [
                _previewStat(
                  '실시간 체결가',
                  '68,450.0 USDT',
                  AppColor.accent,
                  isDesktop,
                ),
                _previewStat(
                  '누적 실현손익',
                  '+1,482.35 USDT',
                  AppColor.longGreen,
                  isDesktop,
                ),
                _previewStat(
                  '페어 체결 횟수',
                  '128 회 완료',
                  AppColor.secondary,
                  isDesktop,
                ),
                _previewStat(
                  '동적 이격도',
                  '0.34% / 1.74%',
                  AppColor.textPrimary,
                  isDesktop,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _dot(Color color) {
    return Container(
      width: 11,
      height: 11,
      decoration: BoxDecoration(color: color, shape: BoxShape.circle),
    );
  }

  Widget _previewStat(
      String title, String val, Color color, bool isDesktop) {
    return Container(
      width: isDesktop ? 200 : 140,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.white10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title,
              style:
                  const TextStyle(fontSize: 11, color: AppColor.textSecondary)),
          const SizedBox(height: 4),
          Text(
            val,
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.bold,
              color: color,
              fontFamily: 'monospace',
            ),
          ),
        ],
      ),
    );
  }

  // 3. Stats Section
  Widget _buildStatsSection(bool isDesktop) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: isDesktop ? 80 : 20,
        vertical: 36,
      ),
      decoration: BoxDecoration(
        color: AppColor.backgroundCard.withValues(alpha: 0.5),
        border: Border.symmetric(
          horizontal: BorderSide(color: AppColor.glassBorder),
        ),
      ),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1000),
          child: Wrap(
            alignment: WrapAlignment.spaceAround,
            runSpacing: 24,
            spacing: 24,
            children: [
              _statItem('24/7', '무중단 호가 감시', '서버리스 클라우드 봇 가동'),
              _statItem('0.074%', '정밀 오버랩 필터', '중복 주문 방지 및 리소스 최적화'),
              _statItem('1.74%', '동적 이격 취소', '급변동 시 불필요 주문 즉각 회수'),
              _statItem('100%', '모의투자 지원', '실제 자산 위험 없는 안전 테스트'),
            ],
          ),
        ),
      ),
    );
  }

  Widget _statItem(String num, String title, String sub) {
    return SizedBox(
      width: 200,
      child: Column(
        children: [
          Text(
            num,
            style: const TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.w900,
              color: AppColor.accent,
              letterSpacing: -0.5,
              fontFamily: 'monospace',
            ),
          ),
          const SizedBox(height: 6),
          Text(
            title,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: AppColor.textPrimary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            sub,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 11,
              color: AppColor.textDisabled,
            ),
          ),
        ],
      ),
    );
  }

  // 4. Features Section
  Widget _buildFeaturesSection(bool isDesktop) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: isDesktop ? 60 : 20),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1050),
          child: Column(
            children: [
              const Text(
                '핵심 퀀트 트레이딩 기능',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w800,
                  color: AppColor.textPrimary,
                ),
              ),
              const SizedBox(height: 10),
              const Text(
                '원작 BitgetBot_GridTrade의 검증된 알고리즘을 최신 플러터 웹 기술로 구현했습니다.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 14, color: AppColor.textSecondary),
              ),
              const SizedBox(height: 40),
              Wrap(
                spacing: 20,
                runSpacing: 20,
                children: [
                  _featureCard(
                    icon: Icons.layers,
                    title: '심도 오더북 그리드 (Order Depth)',
                    desc:
                        '시장 호가창 뎁스에 맞추어 매수 주문을 다단계로 정밀 배치하고, 체결 즉시 상단 익절 주문을 자동으로 체결합니다.',
                    isDesktop: isDesktop,
                  ),
                  _featureCard(
                    icon: Icons.auto_mode,
                    title: '동적 이격도 제어 (Dynamic Spread)',
                    desc:
                        '가격이 급등하거나 이탈하여 주문과의 이격이 벌어지면 주문을 즉시 자동 회수하여 슬리피지와 자금 묶임을 방지합니다.',
                    isDesktop: isDesktop,
                  ),
                  _featureCard(
                    icon: Icons.trending_up,
                    title: '피라미딩 & 마틴게일 승수 (Smart Sizing)',
                    desc:
                        '그리드 체결 깊이에 따라 1배, 2배, 4배, 7배, 11배로 주문 수량을 자동 조절하여 반등 시 탈출 확률을 극대화합니다.',
                    isDesktop: isDesktop,
                  ),
                  _featureCard(
                    icon: Icons.science,
                    title: '과거 캔들 백테스트 랩 (Backtest Lab)',
                    desc:
                        '1분봉, 5분봉, 1시간봉 등 다양한 타임프레임의 실제 캔들 데이터를 바탕으로 수익률과 MDD, 승률을 사전 검증합니다.',
                    isDesktop: isDesktop,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _featureCard({
    required IconData icon,
    required String title,
    required String desc,
    required bool isDesktop,
  }) {
    return GlassContainer(
      width: isDesktop ? 490 : double.infinity,
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColor.primary.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: AppColor.accent, size: 24),
          ),
          const SizedBox(height: 18),
          Text(
            title,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: AppColor.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            desc,
            style: const TextStyle(
              fontSize: 13,
              color: AppColor.textSecondary,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  // 5. Workflow Section
  Widget _buildWorkflowSection(bool isDesktop) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: isDesktop ? 60 : 20),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1000),
          child: Column(
            children: [
              const Text(
                '단 3단계로 시작하는 자동매매',
                style: TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.w800,
                  color: AppColor.textPrimary,
                ),
              ),
              const SizedBox(height: 36),
              Wrap(
                spacing: 24,
                runSpacing: 24,
                children: [
                  _stepCard(
                    step: '01',
                    title: 'Google 원클릭 로그인',
                    desc: '복잡한 가입 절차 없이 안전한 Google 계정으로 즉시 접속합니다.',
                    isDesktop: isDesktop,
                  ),
                  _stepCard(
                    step: '02',
                    title: '모의투자 또는 API 연동',
                    desc: '실제 자산 없이 시뮬레이션을 돌리거나, Bitget 선물 API 키를 안전하게 등록합니다.',
                    isDesktop: isDesktop,
                  ),
                  _stepCard(
                    step: '03',
                    title: '24시간 무중단 가동',
                    desc: '그리드 파라미터 적용 후 [START]를 누르면 실시간 자동매매가 진행됩니다.',
                    isDesktop: isDesktop,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _stepCard({
    required String step,
    required String title,
    required String desc,
    required bool isDesktop,
  }) {
    return Container(
      width: isDesktop ? 290 : double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: AppColor.glassBackground,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColor.glassBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            step,
            style: const TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.w900,
              color: AppColor.accent,
              fontFamily: 'monospace',
            ),
          ),
          const SizedBox(height: 12),
          Text(
            title,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: AppColor.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            desc,
            style: const TextStyle(
              fontSize: 13,
              color: AppColor.textSecondary,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  // 6. CTA Banner Section
  Widget _buildCtaBannerSection(bool isDesktop) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: isDesktop ? 60 : 20),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 960),
          child: Container(
            padding: EdgeInsets.symmetric(
              horizontal: isDesktop ? 48 : 24,
              vertical: 48,
            ),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF1E1B4B), Color(0xFF0F172A)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(
                color: AppColor.primary.withValues(alpha: 0.4),
                width: 1.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: AppColor.primary.withValues(alpha: 0.25),
                  blurRadius: 30,
                  spreadRadius: 2,
                ),
              ],
            ),
            child: Column(
              children: [
                const Text(
                  '지금 바로 감정 없는 퀀트 트레이딩을 시작하세요',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.w900,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 12),
                const Text(
                  'Google 계정으로 로그인 후 즉시 무료 모의투자 시뮬레이션을 가동할 수 있습니다.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 14, color: AppColor.textSecondary),
                ),
                const SizedBox(height: 28),
                GoogleGlassButton(
                  width: isDesktop ? 320 : double.infinity,
                  height: 54,
                  text: 'Google 계정으로 바로 가동하기',
                  isLoading: _isLoading,
                  onPressed: _handleGoogleSignIn,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // 7. Footer
  Widget _buildFooter() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 30, horizontal: 24),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.4),
        border: Border(top: BorderSide(color: AppColor.glassBorder)),
      ),
      child: const Column(
        children: [
          Text(
            'DEPTH TRADE · QUANTITATIVE AUTOMATED TRADING SYSTEM',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              letterSpacing: 1,
              color: AppColor.textSecondary,
            ),
          ),
          SizedBox(height: 8),
          Text(
            '면책 고지: 가상자산 및 선물 거래는 높은 변동성으로 인해 원금 손실의 위험이 따릅니다. 본 플랫폼은 투자 보조 도구이며 투자 결과에 대한 최종 책임은 사용자 본인에게 있습니다.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 11, color: AppColor.textDisabled),
          ),
          SizedBox(height: 8),
          Text(
            '© 2026 DepthTrade. All rights reserved.',
            style: TextStyle(fontSize: 11, color: AppColor.textDisabled),
          ),
        ],
      ),
    );
  }
}

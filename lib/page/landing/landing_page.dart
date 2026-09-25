import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../../service/auth_service.dart';
import '../../style/app_color.dart';
import '../../widget/galaxy_background.dart';
import '../../widget/glass_container.dart';
import '../../widget/glow_button.dart';
import '../../widget/google_glass_button.dart';

class LandingPage extends StatefulWidget {
  const LandingPage({super.key});

  @override
  State<LandingPage> createState() => _LandingPageState();
}

class _LandingPageState extends State<LandingPage> {
  bool _isLoading = false;

  // Interactive Calculator State
  double _depositAmount = 1000.0;
  int _selectedDepth = 4;

  // Section Keys for smooth scrolling
  final GlobalKey _featuresKey = GlobalKey();
  final GlobalKey _simulatorKey = GlobalKey();
  final GlobalKey _comparisonKey = GlobalKey();
  final GlobalKey _workflowKey = GlobalKey();
  final GlobalKey _securityKey = GlobalKey();

  Future<void> _handleGoogleSignIn() async {
    setState(() => _isLoading = true);
    try {
      final cred = await AuthService.instance.signInWithGoogle();
      if (cred != null && mounted) {
        Navigator.pushNamed(context, '/dashboard');
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

  void _scrollTo(GlobalKey key) {
    final ctx = key.currentContext;
    if (ctx != null) {
      Scrollable.ensureVisible(
        ctx,
        duration: const Duration(milliseconds: 600),
        curve: Curves.easeInOutCubic,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final double screenWidth = MediaQuery.of(context).size.width;
    final bool isDesktop = screenWidth > 960;

    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, authSnapshot) {
        final User? currentUser = authSnapshot.data;
        final bool isLoggedIn = currentUser != null;

        return Scaffold(
          backgroundColor: AppColor.background,
          body: GalaxyBackground(
            child: SingleChildScrollView(
              child: Column(
                children: [
                  _buildNavBar(isDesktop, isLoggedIn, currentUser),
                  _buildHeroSection(isDesktop, isLoggedIn),
                  const SizedBox(height: 50),
                  _buildStatsSection(isDesktop),
                  const SizedBox(height: 90),
                  _buildFeaturesSection(isDesktop, key: _featuresKey),
                  const SizedBox(height: 90),
                  _buildInteractiveSimulator(isDesktop, key: _simulatorKey),
                  const SizedBox(height: 90),
                  _buildComparisonSection(isDesktop, key: _comparisonKey),
                  const SizedBox(height: 90),
                  _buildWorkflowSection(isDesktop, key: _workflowKey),
                  const SizedBox(height: 90),
                  _buildSecuritySection(isDesktop, key: _securityKey),
                  const SizedBox(height: 90),
                  _buildCtaBannerSection(isDesktop, isLoggedIn),
                  const SizedBox(height: 70),
                  _buildFooter(),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  // 1. Navigation Bar (Borderless Layered Glass)
  Widget _buildNavBar(bool isDesktop, bool isLoggedIn, User? user) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: isDesktop ? 48 : 20,
        vertical: 16,
      ),
      decoration: BoxDecoration(
        color: AppColor.backgroundCard.withValues(alpha: 0.75),
        boxShadow: AppColor.subtleShadow,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Logo & Title
          InkWell(
            onTap: () {},
            hoverColor: Colors.transparent,
            splashColor: Colors.transparent,
            child: Row(
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
                        blurRadius: 14,
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
          ),

          // Desktop Nav Anchor Links
          if (isDesktop)
            Row(
              children: [
                _navLink('특징 & 알고리즘', () => _scrollTo(_featuresKey)),
                _navLink('마틴게일 계산기', () => _scrollTo(_simulatorKey)),
                _navLink('전략 비교', () => _scrollTo(_comparisonKey)),
                _navLink('시작 가이드', () => _scrollTo(_workflowKey)),
                _navLink('보안 및 아키텍처', () => _scrollTo(_securityKey)),
              ],
            ),

          // User Actions (Google Login OR Launch Terminal)
          if (isLoggedIn)
            Row(
              children: [
                // User Profile Chip
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: AppColor.cardSurface,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 12,
                        backgroundColor: AppColor.primary.withValues(alpha: 0.3),
                        backgroundImage: user?.photoURL != null
                            ? NetworkImage(user!.photoURL!)
                            : null,
                        child: user?.photoURL == null
                            ? Text(
                                (user?.displayName?.isNotEmpty == true
                                        ? user!.displayName![0]
                                        : 'U')
                                    .toUpperCase(),
                                style: const TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              )
                            : null,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        user?.displayName ?? 'Trader',
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: AppColor.textPrimary,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                GlowButton(
                  text: '대시보드 시작하기',
                  icon: Icons.rocket_launch,
                  height: 40,
                  onPressed: () => Navigator.pushNamed(context, '/dashboard'),
                ),
                const SizedBox(width: 8),
                IconButton(
                  icon: const Icon(Icons.logout, size: 18, color: AppColor.textSecondary),
                  tooltip: '로그아웃',
                  onPressed: () async {
                    await AuthService.instance.signOut();
                  },
                ),
              ],
            )
          else
            GoogleGlassButton(
              text: 'Google 로그인',
              height: 40,
              isLoading: _isLoading,
              onPressed: _handleGoogleSignIn,
            ),
        ],
      ),
    );
  }

  Widget _navLink(String label, VoidCallback onTap) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: TextButton(
        onPressed: onTap,
        style: TextButton.styleFrom(
          foregroundColor: AppColor.textSecondary,
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        ),
        child: Text(
          label,
          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
        ),
      ),
    );
  }

  // 2. Hero Section
  Widget _buildHeroSection(bool isDesktop, bool isLoggedIn) {
    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: isDesktop ? 60 : 20,
        vertical: 40,
      ),
      child: Column(
        children: [
          // Cyber Badge (Borderless layered pill)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: AppColor.primary.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(30),
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
              fontSize: isDesktop ? 48 : 32,
              fontWeight: FontWeight.w900,
              color: AppColor.textPrimary,
              height: 1.25,
              letterSpacing: -1,
            ),
          ),
          const SizedBox(height: 20),

          // Sub-headline
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 720),
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

          // Primary CTA (Smart awareness based on login state)
          if (isLoggedIn)
            GlowButton(
              width: isDesktop ? 340 : double.infinity,
              height: 56,
              text: '트레이딩 대시보드 바로가기',
              icon: Icons.rocket_launch,
              onPressed: () => Navigator.pushNamed(context, '/dashboard'),
            )
          else
            Column(
              children: [
                GoogleGlassButton(
                  width: isDesktop ? 340 : double.infinity,
                  height: 56,
                  text: 'Google 계정으로 무료 시작하기',
                  isLoading: _isLoading,
                  onPressed: _handleGoogleSignIn,
                ),
                const SizedBox(height: 14),
                const Text(
                  '별도의 복잡한 회원가입 없이 Google 계정으로 즉시 연동됩니다.',
                  style: TextStyle(fontSize: 12, color: AppColor.textDisabled),
                ),
              ],
            ),
          const SizedBox(height: 50),

          // Live Terminal Mockup Card
          _buildTerminalPreview(isDesktop),
        ],
      ),
    );
  }

  // Terminal Preview Card
  Widget _buildTerminalPreview(bool isDesktop) {
    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 980),
      child: GlassContainer(
        padding: const EdgeInsets.all(22),
        color: AppColor.cardSurface,
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
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
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
            const SizedBox(height: 20),

            // Mockup Content Rows
            Wrap(
              spacing: 16,
              runSpacing: 16,
              children: [
                _previewStat('실시간 체결가', '68,450.0 USDT', AppColor.accent, isDesktop),
                _previewStat('누적 실현손익', '+1,482.35 USDT', AppColor.longGreen, isDesktop),
                _previewStat('페어 체결 횟수', '128 회 완료', AppColor.secondary, isDesktop),
                _previewStat('동적 이격도', '0.34% / 1.74%', AppColor.textPrimary, isDesktop),
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

  Widget _previewStat(String title, String val, Color color, bool isDesktop) {
    return Container(
      width: isDesktop ? 210 : 140,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColor.inputSurface,
        borderRadius: BorderRadius.circular(12),
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
        vertical: 40,
      ),
      decoration: BoxDecoration(
        color: AppColor.backgroundCard.withValues(alpha: 0.5),
        boxShadow: AppColor.subtleShadow,
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

  // 4. Core Features Section
  Widget _buildFeaturesSection(bool isDesktop, {Key? key}) {
    return Container(
      key: key,
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
      color: AppColor.cardSurface,
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

  // 5. Interactive Quant Simulator / Calculator
  Widget _buildInteractiveSimulator(bool isDesktop, {Key? key}) {
    // Multipliers from BitgetBot_GridTrade: 1, 2, 4, 7, 11
    final multipliers = [1, 2, 4, 7, 11];
    final activeMultipliers = multipliers.take(_selectedDepth).toList();
    final double totalMultiplier =
        activeMultipliers.fold(0, (sum, m) => sum + m).toDouble();
    final double baseOrderSize = _depositAmount / (totalMultiplier * 1.5);

    return Container(
      key: key,
      padding: EdgeInsets.symmetric(horizontal: isDesktop ? 60 : 20),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1050),
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                decoration: BoxDecoration(
                  color: AppColor.accent.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Text(
                  'INTERACTIVE ALGORITHM SIMULATOR',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: AppColor.accent,
                    letterSpacing: 1,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                '직접 체험하는 마틴게일 심도 계산기',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w800,
                  color: AppColor.textPrimary,
                ),
              ),
              const SizedBox(height: 10),
              const Text(
                '자금과 그리드 단계를 조절하여 알고리즘이 주문 규모를 어떻게 배분하는지 실시간으로 확인해보세요.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 14, color: AppColor.textSecondary),
              ),
              const SizedBox(height: 36),

              // Interactive Container
              GlassContainer(
                padding: const EdgeInsets.all(28),
                color: AppColor.cardSurface,
                child: Column(
                  children: [
                    // Controls Row
                    if (isDesktop)
                      Row(
                        children: [
                          Expanded(child: _depositControl()),
                          const SizedBox(width: 32),
                          Expanded(child: _depthControl()),
                        ],
                      )
                    else ...[
                      _depositControl(),
                      const SizedBox(height: 20),
                      _depthControl(),
                    ],
                    const SizedBox(height: 28),

                    // Visualization Bars
                    Container(
                      padding: const EdgeInsets.all(18),
                      decoration: BoxDecoration(
                        color: AppColor.inputSurface,
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                '단계별 주문 배치 시뮬레이션',
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.bold,
                                  color: AppColor.textPrimary,
                                ),
                              ),
                              Text(
                                '수량 승수: 1x -> 2x -> 4x -> 7x -> 11x',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontFamily: 'monospace',
                                  color: AppColor.accent,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          ...List.generate(activeMultipliers.length, (idx) {
                            final m = activeMultipliers[idx];
                            final orderAmount = (baseOrderSize * m);
                            final pct = orderAmount / _depositAmount;

                            return Padding(
                              padding: const EdgeInsets.symmetric(vertical: 6),
                              child: Row(
                                children: [
                                  SizedBox(
                                    width: 70,
                                    child: Text(
                                      'Depth ${idx + 1}',
                                      style: const TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.bold,
                                        color: AppColor.textSecondary,
                                      ),
                                    ),
                                  ),
                                  Expanded(
                                    child: ClipRRect(
                                      borderRadius: BorderRadius.circular(6),
                                      child: LinearProgressIndicator(
                                        value: (pct * 2.5).clamp(0.05, 1.0),
                                        minHeight: 18,
                                        backgroundColor: AppColor.cardSurface,
                                        valueColor: AlwaysStoppedAnimation(
                                          Color.lerp(AppColor.primary, AppColor.accent, idx / 4)!,
                                        ),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 14),
                                  SizedBox(
                                    width: 100,
                                    child: Text(
                                      '${orderAmount.toStringAsFixed(1)} USDT (${m}x)',
                                      textAlign: TextAlign.right,
                                      style: const TextStyle(
                                        fontSize: 12,
                                        fontFamily: 'monospace',
                                        fontWeight: FontWeight.bold,
                                        color: AppColor.textPrimary,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            );
                          }),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _depositControl() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text('운용 자금 (USDT)',
                style: TextStyle(fontSize: 13, color: AppColor.textSecondary)),
            Text(
              '${_depositAmount.toStringAsFixed(0)} USDT',
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.bold,
                fontFamily: 'monospace',
                color: AppColor.accent,
              ),
            ),
          ],
        ),
        Slider(
          value: _depositAmount,
          min: 200,
          max: 10000,
          divisions: 49,
          activeColor: AppColor.accent,
          inactiveColor: AppColor.inputSurface,
          onChanged: (v) => setState(() => _depositAmount = v),
        ),
      ],
    );
  }

  Widget _depthControl() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text('그리드 심도 레벨 (Depth)',
                style: TextStyle(fontSize: 13, color: AppColor.textSecondary)),
            Text(
              '$_selectedDepth 단계',
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.bold,
                fontFamily: 'monospace',
                color: AppColor.secondary,
              ),
            ),
          ],
        ),
        Slider(
          value: _selectedDepth.toDouble(),
          min: 1,
          max: 5,
          divisions: 4,
          activeColor: AppColor.secondary,
          inactiveColor: AppColor.inputSurface,
          onChanged: (v) => setState(() => _selectedDepth = v.round()),
        ),
      ],
    );
  }

  // 6. Strategy Comparison Section
  Widget _buildComparisonSection(bool isDesktop, {Key? key}) {
    return Container(
      key: key,
      padding: EdgeInsets.symmetric(horizontal: isDesktop ? 60 : 20),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1050),
          child: Column(
            children: [
              const Text(
                '감정적 수동매매 vs DepthTrade 퀀트 자동매매',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w800,
                  color: AppColor.textPrimary,
                ),
              ),
              const SizedBox(height: 10),
              const Text(
                '더 이상 밤새 차트를 보며 불안해하지 마세요. 통계와 수학적 규칙이 시장을 지배합니다.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 14, color: AppColor.textSecondary),
              ),
              const SizedBox(height: 40),

              if (isDesktop)
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(child: _comparisonCardManual()),
                    const SizedBox(width: 24),
                    Expanded(child: _comparisonCardQuant()),
                  ],
                )
              else ...[
                _comparisonCardManual(),
                const SizedBox(height: 20),
                _comparisonCardQuant(),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _comparisonCardManual() {
    return GlassContainer(
      padding: const EdgeInsets.all(26),
      color: AppColor.cardSurface,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColor.shortRed.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.close, color: AppColor.shortRed, size: 20),
              ),
              const SizedBox(width: 12),
              const Text(
                '일반 수동 투자 (Manual)',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppColor.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          _compItem(false, '급락 시 공포에 질려 최저점 패닉셀(손절) 발생'),
          _compItem(false, '24시간 스마트폰 차트 감시로 인한 일상 피로 누적'),
          _compItem(false, '손익비 없는 뇌동매매와 과도한 레버리지 청산 위험'),
          _compItem(false, '주문 취소 및 재주문 지연으로 슬리피지 손실'),
        ],
      ),
    );
  }

  Widget _comparisonCardQuant() {
    return GlassContainer(
      padding: const EdgeInsets.all(26),
      color: AppColor.elevatedSurface,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColor.longGreen.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.check, color: AppColor.longGreen, size: 20),
              ),
              const SizedBox(width: 12),
              const Text(
                'DepthTrade 퀀트 엔진',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppColor.longGreen,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          _compItem(true, '1.74% 동적 이격 제어로 슬리피지 방어 및 무감정 익절'),
          _compItem(true, '클라우드 기반 24시간 365일 무중단 오더북 자동 관리'),
          _compItem(true, '수학적 피라미딩 승수로 반등 시 평균단가 대폭 인하 탈출'),
          _compItem(true, '안전한 모의투자 시뮬레이터로 전략 사전 무제한 검증'),
        ],
      ),
    );
  }

  Widget _compItem(bool isGood, String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            isGood ? Icons.check_circle : Icons.cancel,
            size: 16,
            color: isGood ? AppColor.longGreen : AppColor.shortRed,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                fontSize: 13,
                color: isGood ? AppColor.textPrimary : AppColor.textSecondary,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // 7. Workflow Section
  Widget _buildWorkflowSection(bool isDesktop, {Key? key}) {
    return Container(
      key: key,
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
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColor.cardSurface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: AppColor.subtleShadow,
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

  // 8. Security & Tech Architecture
  Widget _buildSecuritySection(bool isDesktop, {Key? key}) {
    return Container(
      key: key,
      padding: EdgeInsets.symmetric(horizontal: isDesktop ? 60 : 20),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1050),
          child: Column(
            children: [
              const Text(
                '신뢰할 수 있는 보안 및 테크 아키텍처',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w800,
                  color: AppColor.textPrimary,
                ),
              ),
              const SizedBox(height: 10),
              const Text(
                '트레이더의 자산 보안을 최우선으로 설계된 안전한 프라이빗 엔진입니다.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 14, color: AppColor.textSecondary),
              ),
              const SizedBox(height: 36),
              Wrap(
                spacing: 20,
                runSpacing: 20,
                children: [
                  _secCard(
                    Icons.lock,
                    '100% 클라이언트 로컬 보안',
                    'Bitget API Key와 Secret은 외부 서버로 전송되지 않고 브라우저 암호화 저장소에만 보관됩니다.',
                    isDesktop,
                  ),
                  _secCard(
                    Icons.speed,
                    'Bitget v2 웹소켓 초저지연 연동',
                    '밀리초 단위의 호가 변동을 직접 수신하여 슬리피지 없이 최적의 호가에 주문을 체결합니다.',
                    isDesktop,
                  ),
                  _secCard(
                    Icons.shield,
                    '패닉 방어 긴급 청산 프로토콜',
                    '비정상 변동성 발생 시 [전체 주문 취소] 비상 차단기를 통해 즉각 포지션을 보호합니다.',
                    isDesktop,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _secCard(IconData icon, String title, String desc, bool isDesktop) {
    return Container(
      width: isDesktop ? 320 : double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: AppColor.cardSurface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: AppColor.subtleShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: AppColor.accent, size: 28),
          const SizedBox(height: 14),
          Text(
            title,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.bold,
              color: AppColor.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            desc,
            style: const TextStyle(
              fontSize: 12,
              color: AppColor.textSecondary,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  // 9. CTA Banner Section
  Widget _buildCtaBannerSection(bool isDesktop, bool isLoggedIn) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: isDesktop ? 60 : 20),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 980),
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
                if (isLoggedIn)
                  GlowButton(
                    width: isDesktop ? 340 : double.infinity,
                    height: 54,
                    text: '트레이딩 대시보드 바로가기',
                    icon: Icons.rocket_launch,
                    onPressed: () => Navigator.pushNamed(context, '/dashboard'),
                  )
                else
                  GoogleGlassButton(
                    width: isDesktop ? 340 : double.infinity,
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

  // 10. Footer
  Widget _buildFooter() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 36, horizontal: 24),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.4),
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
          SizedBox(height: 10),
          Text(
            '면책 고지: 가상자산 및 선물 거래는 높은 변동성으로 인해 원금 손실의 위험이 따릅니다. 본 플랫폼은 투자 보조 도구이며 투자 결과에 대한 최종 책임은 사용자 본인에게 있습니다.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 11, color: AppColor.textDisabled),
          ),
          SizedBox(height: 8),
          Text(
            '© 2026 DepthTrade. All rights reserved. Powered by BitgetBot_GridTrade Core Engine.',
            style: TextStyle(fontSize: 11, color: AppColor.textDisabled),
          ),
        ],
      ),
    );
  }
}

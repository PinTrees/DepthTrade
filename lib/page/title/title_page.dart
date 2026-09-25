import 'package:flutter/material.dart';
import '../../service/auth_service.dart';
import '../../style/app_color.dart';
import '../../widget/galaxy_background.dart';
import '../../widget/glass_container.dart';
import '../../widget/glass_input_field.dart';
import '../../widget/glow_button.dart';

class TitlePage extends StatefulWidget {
  const TitlePage({super.key});

  @override
  State<TitlePage> createState() => _TitlePageState();
}

class _TitlePageState extends State<TitlePage> {
  final TextEditingController _emailCtrl = TextEditingController();
  final TextEditingController _passCtrl = TextEditingController();

  bool _isSignUp = false;
  bool _isLoading = false;

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passCtrl.dispose();
    super.dispose();
  }

  Future<void> _handleAuth() async {
    final email = _emailCtrl.text.trim();
    final pass = _passCtrl.text.trim();

    if (email.isEmpty || pass.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('이메일과 비밀번호를 입력해주세요.')),
      );
      return;
    }

    setState(() => _isLoading = true);
    try {
      if (_isSignUp) {
        await AuthService.instance.signUpWithEmail(email, pass);
      } else {
        await AuthService.instance.signInWithEmail(email, pass);
      }
      if (mounted) {
        Navigator.pushReplacementNamed(context, '/dashboard');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('로그인 실패: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _handleGuestLogin() async {
    setState(() => _isLoading = true);
    try {
      await AuthService.instance.signInAnonymously();
      if (mounted) {
        Navigator.pushReplacementNamed(context, '/dashboard');
      }
    } catch (e) {
      if (mounted) {
        // Firebase Auth가 비활성화되어 있더라도 웹 즉시 체험 가능하도록 대시보드로 이동
        Navigator.pushReplacementNamed(context, '/dashboard');
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: GalaxyBackground(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Glowing Icon Logo
                Container(
                  width: 76,
                  height: 76,
                  decoration: BoxDecoration(
                    gradient: AppColor.primaryGradient,
                    borderRadius: BorderRadius.circular(22),
                    boxShadow: [
                      BoxShadow(
                        color: AppColor.primary.withValues(alpha: 0.5),
                        blurRadius: 28,
                        spreadRadius: 4,
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.candlestick_chart,
                    color: Colors.white,
                    size: 40,
                  ),
                ),
                const SizedBox(height: 24),

                // Title
                const Text(
                  'DEPTH TRADE',
                  style: TextStyle(
                    fontSize: 34,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 2,
                    color: AppColor.textPrimary,
                  ),
                ),
                const SizedBox(height: 8),

                // Subtitle
                const Text(
                  'Bitget 고빈도 심도 그리드 자동매매 플랫폼',
                  style: TextStyle(
                    fontSize: 15,
                    color: AppColor.textSecondary,
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 36),

                // Auth Box
                GlassContainer(
                  width: 380,
                  padding: const EdgeInsets.all(28),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        _isSignUp ? '계정 만들기 (Sign Up)' : '플랫폼 로그인 (Sign In)',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: AppColor.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 18),

                      GlassInputField(
                        controller: _emailCtrl,
                        label: '이메일 주소',
                        hint: 'trader@depthtrade.com',
                        keyboardType: TextInputType.emailAddress,
                      ),
                      const SizedBox(height: 14),

                      GlassInputField(
                        controller: _passCtrl,
                        label: '비밀번호',
                        hint: '******',
                        obscureText: true,
                      ),
                      const SizedBox(height: 20),

                      // Email Sign In / Sign Up Button
                      GlowButton(
                        text: _isSignUp ? '회원가입 완료' : '로그인',
                        isLoading: _isLoading,
                        onPressed: _handleAuth,
                      ),
                      const SizedBox(height: 12),

                      // Toggle Sign Up / In
                      TextButton(
                        onPressed: () => setState(() => _isSignUp = !_isSignUp),
                        child: Text(
                          _isSignUp
                              ? '이미 계정이 있으신가요? 로그인'
                              : '새 계정이 필요하신가요? 회원가입',
                          style: const TextStyle(
                            fontSize: 12,
                            color: AppColor.accent,
                          ),
                        ),
                      ),

                      const Divider(color: Colors.white10, height: 28),

                      // Guest Instant Access Button
                      OutlinedButton.icon(
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.white,
                          side: BorderSide(color: AppColor.glassBorder),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        onPressed: _handleGuestLogin,
                        icon: const Icon(Icons.flash_on,
                            color: AppColor.warning, size: 18),
                        label: const Text(
                          '게스트 즉시 체험 (No Login)',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 28),

                // Features Chips
                Wrap(
                  spacing: 12,
                  runSpacing: 10,
                  alignment: WrapAlignment.center,
                  children: [
                    _featureBadge('심도 오더북 그리드'),
                    _featureBadge('동적 이격도 취소 (1.74%)'),
                    _featureBadge('마틴게일 수량 승수'),
                    _featureBadge('피보나치 리스크 관리'),
                    _featureBadge('실시간 캔들 백테스트'),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _featureBadge(String title) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: AppColor.glassBackground,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColor.glassBorder),
      ),
      child: Text(
        title,
        style: const TextStyle(fontSize: 12, color: AppColor.textSecondary),
      ),
    );
  }
}

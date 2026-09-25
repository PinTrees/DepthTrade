import 'package:flutter/material.dart';
import '../../../engine/grid_bot_engine.dart';
import '../../../service/bitget_api_service.dart';
import '../../../style/app_color.dart';
import '../../../widget/glass_container.dart';
import '../../../widget/glass_input_field.dart';
import '../../../widget/glow_button.dart';

class ApiSettingView extends StatefulWidget {
  const ApiSettingView({super.key});

  @override
  State<ApiSettingView> createState() => _ApiSettingViewState();
}

class _ApiSettingViewState extends State<ApiSettingView> {
  late TextEditingController _apiKeyCtrl;
  late TextEditingController _secretKeyCtrl;
  late TextEditingController _passphraseCtrl;

  bool _isSimulation = true;
  bool _isTesting = false;
  String _testStatus = '';

  @override
  void initState() {
    super.initState();
    final api = BitgetApiService.instance;
    _apiKeyCtrl = TextEditingController(text: api.apiKey);
    _secretKeyCtrl = TextEditingController(text: api.secretKey);
    _passphraseCtrl = TextEditingController(text: api.passphrase);
    _isSimulation = GridBotEngine.instance.config.isSimulation;
  }

  @override
  void dispose() {
    _apiKeyCtrl.dispose();
    _secretKeyCtrl.dispose();
    _passphraseCtrl.dispose();
    super.dispose();
  }

  Future<void> _testConnection() async {
    setState(() {
      _isTesting = true;
      _testStatus = 'Bitget 서버 연결 상태 확인 중...';
    });

    BitgetApiService.instance.setCredentials(
      key: _apiKeyCtrl.text,
      secret: _secretKeyCtrl.text,
      pass: _passphraseCtrl.text,
    );

    final ok = await BitgetApiService.instance.testConnection();

    if (mounted) {
      setState(() {
        _isTesting = false;
        _testStatus = ok
            ? '✅ Bitget API 인증 성공! 계정 잔고 및 선물 권한이 확인되었습니다.'
            : '❌ 연결 실패: API Key, Secret 또는 Passphrase를 확인하세요.';
      });
    }
  }

  void _saveSettings() {
    BitgetApiService.instance.setCredentials(
      key: _apiKeyCtrl.text,
      secret: _secretKeyCtrl.text,
      pass: _passphraseCtrl.text,
    );

    final cfg = GridBotEngine.instance.config;
    cfg.isSimulation = _isSimulation;
    GridBotEngine.instance.updateConfig(cfg);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(_isSimulation
            ? '모의투자(Simulation) 모드로 설정이 저장되었습니다.'
            : 'Bitget 실제 계좌 거래 모드로 설정이 적용되었습니다.'),
        backgroundColor: _isSimulation ? AppColor.primary : AppColor.longGreen,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 720),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Header
              const Row(
                children: [
                  Icon(Icons.vpn_key, color: AppColor.accent, size: 24),
                  SizedBox(width: 12),
                  Text(
                    'Bitget API & 계정 거래 모드',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: AppColor.textPrimary,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              const Text(
                '실제 Bitget 선물 계좌와 직접 연동하거나 가상 모의투자로 안전하게 시뮬레이션을 진행할 수 있습니다.',
                style: TextStyle(fontSize: 13, color: AppColor.textSecondary),
              ),
              const SizedBox(height: 24),

              // Mode Selector Card
              GlassContainer(
                padding: const EdgeInsets.all(20),
                color: AppColor.cardSurface,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      '운용 모드 선택',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: AppColor.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 14),
                    Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: AppColor.inputSurface,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: InkWell(
                              onTap: () => setState(() => _isSimulation = true),
                              borderRadius: BorderRadius.circular(8),
                              child: Container(
                                padding: const EdgeInsets.symmetric(vertical: 12),
                                decoration: BoxDecoration(
                                  color: _isSimulation
                                      ? AppColor.primary.withValues(alpha: 0.3)
                                      : Colors.transparent,
                                  borderRadius: BorderRadius.circular(8),
                                  boxShadow: _isSimulation ? AppColor.subtleShadow : null,
                                ),
                                alignment: Alignment.center,
                                child: Text(
                                  '🛡️ 모의투자 (안전 시뮬레이션 모드)',
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.bold,
                                    color: _isSimulation ? Colors.white : AppColor.textSecondary,
                                  ),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: InkWell(
                              onTap: () => setState(() => _isSimulation = false),
                              borderRadius: BorderRadius.circular(8),
                              child: Container(
                                padding: const EdgeInsets.symmetric(vertical: 12),
                                decoration: BoxDecoration(
                                  color: !_isSimulation
                                      ? AppColor.shortRed.withValues(alpha: 0.3)
                                      : Colors.transparent,
                                  borderRadius: BorderRadius.circular(8),
                                  boxShadow: !_isSimulation ? AppColor.subtleShadow : null,
                                ),
                                alignment: Alignment.center,
                                child: Text(
                                  '⚡ 실제 Bitget 선물 계좌 거래',
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.bold,
                                    color: !_isSimulation ? Colors.white : AppColor.textSecondary,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // API Key Credentials Card
              GlassContainer(
                padding: const EdgeInsets.all(24),
                color: AppColor.cardSurface,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(
                      children: [
                        Icon(Icons.lock, size: 18, color: AppColor.secondary),
                        SizedBox(width: 8),
                        Text(
                          'Bitget v2 API 인증 정보 (로컬 암호화 저장)',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                            color: AppColor.textPrimary,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'API Key와 Secret은 서버로 절대 전송되지 않으며 현재 브라우저 저장소에만 안전하게 보관됩니다.',
                      style: TextStyle(fontSize: 12, color: AppColor.textDisabled),
                    ),
                    const SizedBox(height: 20),

                    GlassInputField(
                      controller: _apiKeyCtrl,
                      label: 'Bitget API Key',
                      hint: '발급받은 apiKey를 입력하세요',
                    ),
                    const SizedBox(height: 14),
                    GlassInputField(
                      controller: _secretKeyCtrl,
                      label: 'Bitget Secret Key',
                      hint: 'secretKey를 입력하세요',
                      obscureText: true,
                    ),
                    const SizedBox(height: 14),
                    GlassInputField(
                      controller: _passphraseCtrl,
                      label: 'API Passphrase (비밀번호)',
                      hint: 'API 생성 시 지정한 passphrase를 입력하세요',
                      obscureText: true,
                    ),
                    const SizedBox(height: 18),

                    if (_testStatus.isNotEmpty) ...[
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                        decoration: BoxDecoration(
                          color: AppColor.inputSurface,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          _testStatus,
                          style: TextStyle(
                            fontSize: 12,
                            color: _testStatus.startsWith('✅')
                                ? AppColor.longGreen
                                : AppColor.shortRed,
                            fontFamily: 'monospace',
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                    ],

                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColor.inputSurface,
                              foregroundColor: AppColor.accent,
                              elevation: 0,
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                            onPressed: _isTesting ? null : _testConnection,
                            icon: _isTesting
                                ? const SizedBox(
                                    width: 16,
                                    height: 16,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: AppColor.accent,
                                    ),
                                  )
                                : const Icon(Icons.wifi_protected_setup, size: 18),
                            label: const Text('연결 테스트'),
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: GlowButton(
                            text: '설정 저장 및 적용',
                            icon: Icons.save,
                            onPressed: _saveSettings,
                          ),
                        ),
                      ],
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
}

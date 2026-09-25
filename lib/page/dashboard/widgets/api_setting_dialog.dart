import 'package:flutter/material.dart';
import '../../../engine/grid_bot_engine.dart';
import '../../../service/bitget_api_service.dart';
import '../../../style/app_color.dart';
import '../../../widget/glass_input_field.dart';
import '../../../widget/glow_button.dart';

class ApiSettingDialog extends StatefulWidget {
  const ApiSettingDialog({super.key});

  @override
  State<ApiSettingDialog> createState() => _ApiSettingDialogState();
}

class _ApiSettingDialogState extends State<ApiSettingDialog> {
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
      _testStatus = '연결 상태 확인 중...';
    });

    BitgetApiService.instance.setCredentials(
      key: _apiKeyCtrl.text,
      secret: _secretKeyCtrl.text,
      pass: _passphraseCtrl.text,
    );

    final res = await BitgetApiService.instance.getAccountDetail('BTCUSDT');
    setState(() {
      _isTesting = false;
      if (res != null) {
        _testStatus = '✅ Bitget API 연결 성공! 계좌 접근 정상 확인';
      } else {
        _testStatus = '⚠️ 연결 확인 실패: API Key 또는 권한(IP/읽기/주문)을 확인하세요.';
      }
    });
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

    Navigator.pop(context);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          _isSimulation ? '모의투자 모드로 설정되었습니다.' : 'Bitget 실계좌 거래 모드로 활성화되었습니다.',
        ),
        backgroundColor: AppColor.primary,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: AppColor.backgroundCard,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide.none,
      ),
      child: Container(
        width: 500,
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Title
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    const Icon(Icons.vpn_key, color: AppColor.accent, size: 22),
                    const SizedBox(width: 10),
                    Text(
                      'Bitget API & 거래 모드 설정',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: AppColor.textPrimary,
                      ),
                    ),
                  ],
                ),
                IconButton(
                  icon: Icon(Icons.close, color: AppColor.textSecondary),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Mode Selector
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
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        decoration: BoxDecoration(
                          color: _isSimulation
                              ? AppColor.primary.withValues(alpha: 0.3)
                              : Colors.transparent,
                          borderRadius: BorderRadius.circular(8),
                          boxShadow: _isSimulation ? AppColor.subtleShadow : null,
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          '모의투자 (안전 모드)',
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
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        decoration: BoxDecoration(
                          color: !_isSimulation
                              ? AppColor.shortRed.withValues(alpha: 0.3)
                              : Colors.transparent,
                          borderRadius: BorderRadius.circular(8),
                          boxShadow: !_isSimulation ? AppColor.subtleShadow : null,
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          '실제 Bitget 계좌 거래',
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
            const SizedBox(height: 16),

            // API Input Fields
            GlassInputField(
              controller: _apiKeyCtrl,
              label: 'Bitget API Key',
              hint: 'apiKey 입력',
            ),
            const SizedBox(height: 12),
            GlassInputField(
              controller: _secretKeyCtrl,
              label: 'Bitget Secret Key',
              hint: 'secretKey 입력',
              obscureText: true,
            ),
            const SizedBox(height: 12),
            GlassInputField(
              controller: _passphraseCtrl,
              label: 'API Passphrase (비밀번호)',
              hint: 'API 생성 시 지정한 passphrase',
              obscureText: true,
            ),
            const SizedBox(height: 12),

            if (_testStatus.isNotEmpty) ...[
              Text(
                _testStatus,
                style: const TextStyle(
                  fontSize: 12,
                  color: AppColor.secondary,
                  fontFamily: 'monospace',
                ),
              ),
              const SizedBox(height: 10),
            ],

            // Action Buttons
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColor.cardSurface,
                      foregroundColor: AppColor.accent,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    onPressed: _isTesting ? null : _testConnection,
                    child: _isTesting
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: AppColor.accent,
                            ),
                          )
                        : const Text('연결 테스트'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: GlowButton(
                    text: '저장 및 적용',
                    onPressed: _saveSettings,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

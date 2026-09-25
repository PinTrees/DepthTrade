import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../../../engine/grid_bot_engine.dart';
import '../../../models/crypto_symbol.dart';
import '../../../service/auth_service.dart';
import '../../../style/app_color.dart';
import 'coin_selector_dialog.dart';

class DashboardSidebar extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTabSelected;
  final bool isCollapsed;
  final VoidCallback onToggleCollapse;

  const DashboardSidebar({
    super.key,
    required this.currentIndex,
    required this.onTabSelected,
    required this.isCollapsed,
    required this.onToggleCollapse,
  });

  @override
  Widget build(BuildContext context) {
    final double width = isCollapsed ? 76 : 240;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 220),
      curve: Curves.easeInOutCubic,
      width: width,
      decoration: BoxDecoration(
        color: AppColor.backgroundCard.withValues(alpha: 0.95),
        boxShadow: AppColor.subtleShadow,
      ),
      child: Column(
        children: [
          // 1. Sidebar Header (Branding & Collapse Toggle)
          _buildHeader(context),
          const SizedBox(height: 12),

          // 2. Active Coin Selector Tile
          _buildCoinSelectorTile(context),
          const SizedBox(height: 16),

          // 3. Navigation Menu Items
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 10),
              children: [
                _SidebarMenuItem(
                  icon: Icons.candlestick_chart,
                  label: '실시간 터미널',
                  subtitle: '차트 & 오더북 감시',
                  selected: currentIndex == 0,
                  collapsed: isCollapsed,
                  onTap: () => onTabSelected(0),
                ),
                _SidebarMenuItem(
                  icon: Icons.tune,
                  label: '전략 파라미터',
                  subtitle: '심도 그리드 & 수량 승수',
                  selected: currentIndex == 1,
                  collapsed: isCollapsed,
                  onTap: () => onTabSelected(1),
                ),
                _SidebarMenuItem(
                  icon: Icons.science,
                  label: '백테스트 랩',
                  subtitle: '과거 캔들 전략 검증',
                  selected: currentIndex == 2,
                  collapsed: isCollapsed,
                  onTap: () => onTabSelected(2),
                ),
                _SidebarMenuItem(
                  icon: Icons.receipt_long,
                  label: '주문 & 체결 내역',
                  subtitle: '미체결 및 페어 익절 이력',
                  selected: currentIndex == 3,
                  collapsed: isCollapsed,
                  onTap: () => onTabSelected(3),
                ),
                _SidebarMenuItem(
                  icon: Icons.vpn_key,
                  label: 'API & 계정 설정',
                  subtitle: 'Bitget 키 & 거래 모드',
                  selected: currentIndex == 4,
                  collapsed: isCollapsed,
                  onTap: () => onTabSelected(4),
                ),
              ],
            ),
          ),

          // 4. Sidebar Footer (User Account & Action Buttons)
          _buildFooter(context),
        ],
      ),
    );
  }

  // Header
  Widget _buildHeader(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 16, 10, 8),
      child: Row(
        mainAxisAlignment:
            isCollapsed ? MainAxisAlignment.center : MainAxisAlignment.spaceBetween,
        children: [
          if (!isCollapsed)
            InkWell(
              onTap: () => Navigator.pushNamed(context, '/'),
              borderRadius: BorderRadius.circular(10),
              child: Row(
                children: [
                  Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      gradient: AppColor.primaryGradient,
                      borderRadius: BorderRadius.circular(8),
                      boxShadow: [
                        BoxShadow(
                          color: AppColor.primary.withValues(alpha: 0.4),
                          blurRadius: 10,
                        ),
                      ],
                    ),
                    child: const Icon(Icons.show_chart, color: Colors.white, size: 18),
                  ),
                  const SizedBox(width: 10),
                  const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'DEPTH TRADE',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 1.2,
                          color: AppColor.textPrimary,
                        ),
                      ),
                      Text(
                        'QUANT AUTOMATION',
                        style: TextStyle(
                          fontSize: 8,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 0.8,
                          color: AppColor.accent,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          IconButton(
            icon: Icon(
              isCollapsed ? Icons.chevron_right : Icons.chevron_left,
              size: 20,
              color: AppColor.textSecondary,
            ),
            tooltip: isCollapsed ? '사이드바 펼치기' : '사이드바 접기',
            onPressed: onToggleCollapse,
          ),
        ],
      ),
    );
  }

  // Active Coin Selector Tile
  Widget _buildCoinSelectorTile(BuildContext context) {
    return ListenableBuilder(
      listenable: GridBotEngine.instance,
      builder: (context, _) {
        final engine = GridBotEngine.instance;
        final coin = CryptoCoin.findBySymbol(engine.config.symbol);

        if (isCollapsed) {
          return Tooltip(
            message: '${coin.displaySymbol} (${coin.koreanName})\n코인 변경하려면 클릭',
            child: InkWell(
              onTap: () => CoinSelectorDialog.show(context),
              borderRadius: BorderRadius.circular(12),
              child: Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: coin.color.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(coin.icon, color: coin.color, size: 22),
              ),
            ),
          );
        }

        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10),
          child: InkWell(
            onTap: () => CoinSelectorDialog.show(context),
            borderRadius: BorderRadius.circular(12),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: AppColor.cardSurface,
                borderRadius: BorderRadius.circular(12),
                boxShadow: AppColor.subtleShadow,
              ),
              child: Row(
                children: [
                  Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: coin.color.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(coin.icon, color: coin.color, size: 18),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(
                              coin.displaySymbol,
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                                color: AppColor.textPrimary,
                              ),
                            ),
                            const Spacer(),
                            const Icon(Icons.swap_vert, size: 16, color: AppColor.accent),
                          ],
                        ),
                        const SizedBox(height: 2),
                        Text(
                          engine.currentPrice > 0
                              ? '${engine.currentPrice.toStringAsFixed(coin.priceDecimals)} USDT'
                              : coin.koreanName,
                          style: TextStyle(
                            fontSize: 11,
                            fontFamily: 'monospace',
                            color: engine.currentPrice > 0
                                ? AppColor.accent
                                : AppColor.textSecondary,
                            fontWeight: FontWeight.w600,
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
      },
    );
  }

  // Footer (Profile & Home/Logout)
  Widget _buildFooter(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: isCollapsed ? 8 : 12,
        vertical: 12,
      ),
      decoration: BoxDecoration(
        color: AppColor.inputSurface.withValues(alpha: 0.6),
      ),
      child: Column(
        children: [
          if (!isCollapsed && user != null) ...[
            Row(
              children: [
                CircleAvatar(
                  radius: 14,
                  backgroundColor: AppColor.primary.withValues(alpha: 0.3),
                  backgroundImage:
                      user.photoURL != null ? NetworkImage(user.photoURL!) : null,
                  child: user.photoURL == null
                      ? Text(
                          (user.displayName?.isNotEmpty == true
                                  ? user.displayName![0]
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
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        user.displayName ?? 'Trader',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: AppColor.textPrimary,
                        ),
                      ),
                      Text(
                        user.email ?? '',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 10,
                          color: AppColor.textDisabled,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
          ],

          // Action row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              IconButton(
                icon: const Icon(Icons.home_outlined, size: 19, color: AppColor.textSecondary),
                tooltip: '홈 / 랜딩페이지로 이동',
                onPressed: () => Navigator.pushNamed(context, '/'),
              ),
              IconButton(
                icon: const Icon(Icons.logout, size: 18, color: AppColor.textSecondary),
                tooltip: '로그아웃',
                onPressed: () async {
                  await AuthService.instance.signOut();
                  if (context.mounted) {
                    Navigator.pushReplacementNamed(context, '/');
                  }
                },
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Rescene-styled Interactive Sidebar Item with AnimatedScale press response
class _SidebarMenuItem extends StatefulWidget {
  final IconData icon;
  final String label;
  final String? subtitle;
  final bool selected;
  final bool collapsed;
  final VoidCallback onTap;

  const _SidebarMenuItem({
    required this.icon,
    required this.label,
    this.subtitle,
    required this.selected,
    required this.collapsed,
    required this.onTap,
  });

  @override
  State<_SidebarMenuItem> createState() => _SidebarMenuItemState();
}

class _SidebarMenuItemState extends State<_SidebarMenuItem> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Tooltip(
        message: widget.collapsed ? widget.label : '',
        child: AnimatedScale(
          scale: _pressed ? 0.95 : 1.0,
          duration: const Duration(milliseconds: 110),
          curve: Curves.easeOutCubic,
          child: InkWell(
            onTap: widget.onTap,
            onTapDown: (_) => setState(() => _pressed = true),
            onTapUp: (_) => setState(() => _pressed = false),
            onTapCancel: () => setState(() => _pressed = false),
            borderRadius: BorderRadius.circular(12),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 170),
              curve: Curves.easeOutCubic,
              padding: EdgeInsets.symmetric(
                horizontal: widget.collapsed ? 0 : 12,
                vertical: 10,
              ),
              decoration: BoxDecoration(
                color: widget.selected
                    ? AppColor.primary.withValues(alpha: 0.18)
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisAlignment: widget.collapsed
                    ? MainAxisAlignment.center
                    : MainAxisAlignment.start,
                children: [
                  Icon(
                    widget.icon,
                    size: 20,
                    color: widget.selected ? AppColor.accent : AppColor.textSecondary,
                  ),
                  if (!widget.collapsed) ...[
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.label,
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight:
                                  widget.selected ? FontWeight.bold : FontWeight.w600,
                              color: widget.selected
                                  ? AppColor.textPrimary
                                  : AppColor.textSecondary,
                            ),
                          ),
                          if (widget.subtitle != null) ...[
                            const SizedBox(height: 2),
                            Text(
                              widget.subtitle!,
                              style: const TextStyle(
                                fontSize: 10,
                                color: AppColor.textDisabled,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                    if (widget.selected)
                      Container(
                        width: 4,
                        height: 16,
                        decoration: BoxDecoration(
                          color: AppColor.accent,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

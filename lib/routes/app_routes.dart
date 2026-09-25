class AppRoutes {
  static const String root = '/';
  static const String landing = '/landing';

  // Dashboard Sub-routes
  static const String dashboard = '/dashboard';
  static const String terminal = '/dashboard/terminal';
  static const String strategy = '/dashboard/strategy';
  static const String backtest = '/dashboard/backtest';
  static const String orders = '/dashboard/orders';
  static const String settings = '/dashboard/settings';
  static const String apiSettings = '/dashboard/api';

  // Indicator Guide Routes
  static const String indicators = '/indicators';
  static const String dashboardIndicators = '/dashboard/indicators';
  static String indicatorDetail(String id) => '/indicators/$id';

  /// URL 경로로부터 대시보드 탭 인덱스(0~5) 매핑
  static int tabFromRoute(String? route) {
    if (route == null) return 0;
    final path = route.split('?').first.trim().toLowerCase();
    if (path == strategy) return 1;
    if (path == backtest) return 2;
    if (path == orders) return 3;
    if (path == settings || path == apiSettings) return 4;
    if (path.startsWith(indicators) || path.startsWith(dashboardIndicators)) return 5;
    return 0; // default to terminal
  }

  /// 탭 인덱스(0~5)로부터 브라우저 URL 경로 매핑
  static String routeFromTab(int index) {
    switch (index) {
      case 1:
        return strategy;
      case 2:
        return backtest;
      case 3:
        return orders;
      case 4:
        return settings;
      case 5:
        return indicators;
      case 0:
      default:
        return terminal;
    }
  }

  /// 탭 타이틀 명칭
  static String tabTitle(int index) {
    switch (index) {
      case 1:
        return '전략 파라미터 | DepthTrade';
      case 2:
        return '백테스트 랩 | DepthTrade';
      case 3:
        return '주문 & 체결 내역 | DepthTrade';
      case 4:
        return 'API & 계정 설정 | DepthTrade';
      case 5:
        return '보조지표 연구소 & 가이드 | DepthTrade';
      case 0:
      default:
        return '실시간 터미널 | DepthTrade';
    }
  }
}

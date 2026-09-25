import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_web_plugins/url_strategy.dart';
import 'firebase_options.dart';
import 'page/dashboard/dashboard_page.dart';
import 'page/landing/landing_page.dart';
import 'routes/app_routes.dart';
import 'style/style.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // URL에서 '#' 제거 및 Path URL 전략 사용
  usePathUrlStrategy();

  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  } catch (e) {
    debugPrint('Firebase init notice: $e');
  }

  // 테마 서비스 로드 (로컬 저장소 동기화)
  await ThemeService.instance.init();

  runApp(const DepthTradeApp());
}

class DepthTradeApp extends StatefulWidget {
  const DepthTradeApp({super.key});

  @override
  State<DepthTradeApp> createState() => _DepthTradeAppState();
}

class _DepthTradeAppState extends State<DepthTradeApp> {
  @override
  void reassemble() {
    super.reassemble();
    debugPrint("♻️ Hot Reload: Clearing Image Cache");
    PaintingBinding.instance.imageCache.clear();
    PaintingBinding.instance.imageCache.clearLiveImages();
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: ThemeService.instance,
      builder: (context, _) {
        final themeService = ThemeService.instance;

        return MaterialApp(
          title: 'DepthTrade | Automated Grid Trading',
          theme: AppTheme.lightTheme,
          darkTheme: AppTheme.darkTheme,
          themeMode: themeService.themeMode,
          debugShowCheckedModeBanner: false,
          initialRoute: AppRoutes.root,
          routes: {
            AppRoutes.root: (context) => const LandingPage(),
            AppRoutes.landing: (context) => const LandingPage(),
            AppRoutes.dashboard: (context) => const DashboardPage(initialTab: 0),
            AppRoutes.terminal: (context) => const DashboardPage(initialTab: 0),
            AppRoutes.strategy: (context) => const DashboardPage(initialTab: 1),
            AppRoutes.backtest: (context) => const DashboardPage(initialTab: 2),
            AppRoutes.orders: (context) => const DashboardPage(initialTab: 3),
            AppRoutes.settings: (context) => const DashboardPage(initialTab: 4),
            AppRoutes.indicators: (context) => const DashboardPage(initialTab: 5),
            AppRoutes.dashboardIndicators: (context) => const DashboardPage(initialTab: 5),
          },
          onGenerateRoute: (settings) {
            final name = settings.name ?? AppRoutes.root;
            final cleanPath = name.split('?').first.trim().toLowerCase();

            if (cleanPath == AppRoutes.root || cleanPath == AppRoutes.landing) {
              return MaterialPageRoute(
                settings: settings,
                builder: (_) => const LandingPage(),
              );
            }

            if (cleanPath.startsWith('/dashboard') || cleanPath.startsWith('/indicators')) {
              final tabIndex = AppRoutes.tabFromRoute(cleanPath);
              String? indicatorId;
              if (tabIndex == 5) {
                final segments = cleanPath.split('/').where((s) => s.isNotEmpty).toList();
                if (cleanPath.startsWith('/indicators') && segments.length > 1) {
                  indicatorId = segments[1];
                } else if (cleanPath.startsWith('/dashboard/indicators') && segments.length > 2) {
                  indicatorId = segments[2];
                }
              }
              return MaterialPageRoute(
                settings: settings,
                builder: (_) => DashboardPage(
                  initialTab: tabIndex,
                  initialIndicatorId: indicatorId,
                ),
              );
            }

            return MaterialPageRoute(
              settings: settings,
              builder: (_) => const LandingPage(),
            );
          },
          onUnknownRoute: (_) => MaterialPageRoute(
            builder: (_) => const LandingPage(),
          ),
        );
      },
    );
  }
}

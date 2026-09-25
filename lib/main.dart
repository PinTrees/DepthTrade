import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_web_plugins/url_strategy.dart';
import 'firebase_options.dart';
import 'page/dashboard/dashboard_page.dart';
import 'page/landing/landing_page.dart';
import 'routes/app_routes.dart';
import 'style/app_theme.dart';

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
    return MaterialApp(
      title: 'DepthTrade | Automated Grid Trading',
      theme: AppTheme.darkTheme,
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
        AppRoutes.apiSettings: (context) => const DashboardPage(initialTab: 4),
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

        if (cleanPath.startsWith('/dashboard')) {
          final tabIndex = AppRoutes.tabFromRoute(cleanPath);
          return MaterialPageRoute(
            settings: settings,
            builder: (_) => DashboardPage(initialTab: tabIndex),
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
  }
}

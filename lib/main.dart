import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_web_plugins/url_strategy.dart';
import 'firebase_options.dart';
import 'page/dashboard/dashboard_page.dart';
import 'page/title/title_page.dart';
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
    // 핫 리로드 및 재빌드 시 이미지 캐시 정리
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
      initialRoute: '/',
      routes: {
        '/': (context) => const TitlePage(),
        '/dashboard': (context) => const DashboardPage(),
      },
      onGenerateRoute: (settings) {
        if (settings.name == '/dashboard') {
          return MaterialPageRoute(builder: (_) => const DashboardPage());
        }
        return MaterialPageRoute(builder: (_) => const TitlePage());
      },
      onUnknownRoute: (_) => MaterialPageRoute(builder: (_) => const TitlePage()),
    );
  }
}

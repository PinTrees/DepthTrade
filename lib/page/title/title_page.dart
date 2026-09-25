import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../dashboard/dashboard_page.dart';
import '../landing/landing_page.dart';

class TitlePage extends StatelessWidget {
  const TitlePage({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        // Firebase Auth 초기 로딩 대기
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            backgroundColor: Color(0xFF0B0E17),
            body: Center(
              child: CircularProgressIndicator(color: Color(0xFF7C4DFF)),
            ),
          );
        }

        // 로그인된 상태: 트레이딩 대시보드로 이동
        if (snapshot.hasData && snapshot.data != null) {
          return const DashboardPage();
        }

        // 로그인되지 않은 상태: 랜딩 페이지 표시
        return const LandingPage();
      },
    );
  }
}

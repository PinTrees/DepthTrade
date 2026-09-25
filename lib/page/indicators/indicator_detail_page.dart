import 'package:flutter/material.dart';
import '../dashboard/dashboard_page.dart';

/// IndicatorDetailPage is fully unified into the main DashboardPage (Tab 5),
/// sharing the exact same layout, sidebar, top bar, background, and design system.
class IndicatorDetailPage extends StatelessWidget {
  final String initialIndicatorId;

  const IndicatorDetailPage({
    super.key,
    this.initialIndicatorId = 'sma',
  });

  @override
  Widget build(BuildContext context) {
    return DashboardPage(
      initialTab: 5,
      initialIndicatorId: initialIndicatorId,
    );
  }
}

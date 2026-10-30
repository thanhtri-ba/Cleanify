import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../router/app_routes.dart';
import 'app_bottom_nav.dart';
import '../theme/app_tokens.dart';

/// Khung 4 tab chính. Tab Clean mở luồng quét; ba tab còn lại chuyển route.
class TabScaffold extends StatelessWidget {
  const TabScaffold({
    super.key,
    required this.current,
    required this.body,
    required this.onScan,
  });

  final AppTab current;
  final Widget body;
  final VoidCallback onScan;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.tokens.background,
      body: body,
      bottomNavigationBar: AppBottomNav(
        current: current,
        onTap: (tab) {
          if (tab == current) return;
          switch (tab) {
            case AppTab.home:
              context.go(AppRoutes.home);
            case AppTab.scan:
              onScan();
            case AppTab.activity:
              context.go(AppRoutes.activity);
            case AppTab.settings:
              context.go(AppRoutes.settings);
          }
        },
      ),
    );
  }
}

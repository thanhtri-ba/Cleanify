import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../theme/app_text.dart';
import 'app_background.dart';
import 'brand_header.dart';

/// Khung chung của các màn tài khoản: header, tiêu đề, nội dung cuộn được và
/// phần [footer] luôn dính đáy khi nội dung ngắn.
class AuthScaffold extends StatelessWidget {
  const AuthScaffold({
    super.key,
    required this.title,
    required this.subtitle,
    required this.children,
    this.footer,
    this.onBack,
  });

  final String title;
  final String subtitle;
  final List<Widget> children;
  final Widget? footer;
  final VoidCallback? onBack;

  static const double _verticalPadding = 16 + 30;

  @override
  Widget build(BuildContext context) {
    return AppBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: SafeArea(
          child: Column(
            children: [
              BrandHeader(onBack: onBack),
              Expanded(
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    return SingleChildScrollView(
                      keyboardDismissBehavior:
                          ScrollViewKeyboardDismissBehavior.onDrag,
                      padding: const EdgeInsets.fromLTRB(24, 16, 24, 30),
                      child: ConstrainedBox(
                        constraints: BoxConstraints(
                          minHeight: math.max(
                            0,
                            constraints.maxHeight - _verticalPadding,
                          ),
                        ),
                        child: IntrinsicHeight(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Semantics(
                                header: true,
                                child: Text(title, style: AppText.h1),
                              ),
                              const SizedBox(height: 8),
                              Text(subtitle, style: AppText.body),
                              for (final child in children) ...[
                                const SizedBox(height: 20),
                                child,
                              ],
                              const Spacer(),
                              if (footer != null) footer!,
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

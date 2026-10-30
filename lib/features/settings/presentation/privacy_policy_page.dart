import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/l10n/app_strings.dart';
import '../../../core/router/app_routes.dart';
import '../../../core/theme/app_text.dart';
import '../../../core/theme/app_tokens.dart';
import '../../../core/widgets/sub_page_scaffold.dart';

class PrivacyPolicyPage extends StatelessWidget {
  const PrivacyPolicyPage({super.key});

  @override
  Widget build(BuildContext context) {
    return SubPageScaffold(
      title: AppStrings.privacyPolicyTitle,
      onBack: () =>
          context.canPop() ? context.pop() : context.go(AppRoutes.settings),
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: context.tokens.surfaceMuted,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: context.tokens.border),
          ),
          child: Text(
            AppStrings.privacyPolicyBody,
            style: AppText.body.copyWith(height: 1.6),
          ),
        ),
      ],
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/l10n/app_strings.dart';
import '../../../core/theme/app_assets.dart';
import '../../../core/theme/app_text.dart';
import '../../../core/widgets/page_scaffold.dart';
import '../../../core/widgets/secondary_button.dart';
import '../../../core/widgets/state_panel.dart';
import '../../auth/application/auth_session.dart';

/// Tab Settings tạm thời: chỉ có đăng xuất, để vẫn thoát được tài khoản
/// trong lúc các màn cài đặt (lô 7) chưa được dựng.
class SettingsPlaceholderPage extends ConsumerWidget {
  const SettingsPlaceholderPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return PageScaffold(
      title: AppStrings.navSettings,
      showBack: false,
      children: [
        const StatePanel(
          icon: AppAssets.settings,
          caption: AppStrings.comingSoon,
        ),
        Text(
          AppStrings.settingsPlaceholderBody,
          style: AppText.body,
          textAlign: TextAlign.center,
        ),
        SecondaryButton(
          label: AppStrings.signOut,
          onPressed: () => ref.read(authSessionProvider.notifier).signOut(),
        ),
      ],
    );
  }
}

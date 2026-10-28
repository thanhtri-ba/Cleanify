import 'package:flutter/material.dart';

import '../../../core/l10n/app_strings.dart';
import '../../../core/theme/app_assets.dart';
import '../../../core/theme/app_text.dart';
import '../../../core/widgets/page_scaffold.dart';
import '../../../core/widgets/state_panel.dart';

/// Tab Storage chưa được dựng (lô sau).
class StoragePlaceholderPage extends StatelessWidget {
  const StoragePlaceholderPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const PageScaffold(
      title: AppStrings.navStorage,
      showBack: false,
      children: [
        StatePanel(icon: AppAssets.database, caption: AppStrings.comingSoon),
        _Body(AppStrings.storagePlaceholderBody),
      ],
    );
  }
}

class _Body extends StatelessWidget {
  const _Body(this.text);

  final String text;

  @override
  Widget build(BuildContext context) =>
      Text(text, style: AppText.body, textAlign: TextAlign.center);
}

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/router/app_routes.dart';
import '../../../core/widgets/app_bottom_nav.dart';
import '../../../core/widgets/tab_scaffold.dart';
import '../../scan/presentation/scan_actions.dart';
import 'settings_widgets.dart';
import '../../../core/theme/app_tokens.dart';

/// About Cleanify (Figma 127:2487).
class AboutPage extends ConsumerWidget {
  const AboutPage({super.key});

  static const _version = '0.1.0';

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return TabScaffold(
      current: AppTab.settings,
      onScan: () => startScanFlow(context, ref),
      body: ColoredBox(
        color: context.tokens.surface,
        child: SafeArea(
          bottom: false,
          child: Column(
            children: [
              SettingsSubHeader(
                title: 'About Cleanify',
                onBack: () => context.canPop()
                    ? context.pop()
                    : context.go(AppRoutes.settings),
              ),
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 52,
                          height: 52,
                          decoration: const BoxDecoration(
                            color: Color(0xFF555555),
                            shape: BoxShape.circle,
                          ),
                          alignment: Alignment.center,
                          child: Text(
                            'C',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                              color: context.tokens.surface,
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                'Cleanify',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  color: context.tokens.textPrimary,
                                ),
                              ),
                              SizedBox(height: 4),
                              Text(
                                'Installed version $_version',
                                style: TextStyle(fontSize: 13, color: context.tokens.textMuted),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Cleanify helps you understand and manage your phone '
                      'storage so you can keep your device organized and free '
                      'up space when you need it.',
                      style: TextStyle(
                        fontSize: 14,
                        height: 20 / 14,
                        color: context.tokens.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 16),
                    const SettingsDivider(),
                    const SizedBox(height: 16),
                    const SettingsSectionLabel('Links'),
                    const SizedBox(height: 8),
                    SettingsCard(
                      children: [
                        SettingsRow(
                          title: 'Privacy Policy',
                          onTap: () => context.push(AppRoutes.privacyPolicy),
                        ),
                        const SettingsDivider(),
                        SettingsRow(
                          title: 'Terms of Service',
                          onTap: () => _comingSoon(context),
                        ),
                        const SettingsDivider(),
                        SettingsRow(
                          title: 'Contact & Feedback',
                          onTap: () => context.push(AppRoutes.help),
                        ),
                        const SettingsDivider(),
                        SettingsRow(
                          title: 'Licenses',
                          onTap: () => showLicensePage(
                            context: context,
                            applicationName: 'Cleanify',
                            applicationVersion: _version,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    Center(
                      child: Text(
                        'Cleanify v$_version',
                        style: TextStyle(fontSize: 12, color: context.tokens.textMuted),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _comingSoon(BuildContext context) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        const SnackBar(
          content: Text('This isn’t available yet.'),
          duration: Duration(seconds: 2),
        ),
      );
  }
}

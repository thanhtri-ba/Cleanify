import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/l10n/app_strings.dart';
import '../../../core/router/app_routes.dart';
import '../../../core/theme/app_assets.dart';
import '../../../core/theme/app_text.dart';
import '../application/media_access_controller.dart';
import 'photo_permission_parts.dart';
import '../../../core/theme/app_tokens.dart';

/// Màn quyền ảnh bị từ chối (Figma 127:3187).
class PhotoDeniedPage extends ConsumerWidget {
  const PhotoDeniedPage({super.key});

  Future<void> _continueWithout(BuildContext context, WidgetRef ref) async {
    await ref.read(photoAccessPromptSeenProvider.notifier).markSeen();
    if (context.mounted) context.go(AppRoutes.home);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isIos = Theme.of(context).platform == TargetPlatform.iOS;
    final bottomInset = MediaQuery.viewPaddingOf(context).bottom;
    return Scaffold(
      backgroundColor: context.tokens.surface,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            PhotoPermissionHeader(
              onBack: () => context.canPop() ? context.pop() : context.go(AppRoutes.fileAccess),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(24, 24, 24, 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      AppStrings.pmDeniedTitle,
                      style: AppText.custom(26, FontWeight.w700,
                          PhotoPalette.ink,
                          lineHeight: 32, letterSpacing: -0.5),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      AppStrings.pmDeniedBody,
                      style: AppText.custom(14, FontWeight.w400,
                          PhotoPalette.body,
                          lineHeight: 21),
                    ),
                    const SizedBox(height: 24),
                    const PhotoIllustrationCard(
                      icon: AppAssets.imageOff,
                      caption: AppStrings.pmDeniedBadge,
                    ),
                    const SizedBox(height: 20),
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: context.tokens.surface,
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(color: PhotoPalette.border),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          const PhotoInfoRow(
                            icon: AppAssets.images,
                            title: AppStrings.pmDeniedFeatureTitle,
                            body: AppStrings.pmDeniedFeatureBody,
                          ),
                          const SizedBox(height: 18),
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: PhotoPalette.card,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  isIos
                                      ? AppStrings.pmDeniedStepIosTitle
                                      : AppStrings.pmDeniedStepAndroidTitle,
                                  style: AppText.custom(
                                      12, FontWeight.w600, PhotoPalette.ink),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  isIos
                                      ? AppStrings.pmDeniedStepIosBody
                                      : AppStrings.pmDeniedStepAndroidBody,
                                  style: AppText.custom(12, FontWeight.w400,
                                      PhotoPalette.body,
                                      lineHeight: 18),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    const PhotoNoteBox(text: AppStrings.pmDeniedNote),
                  ],
                ),
              ),
            ),
            Padding(
              padding: EdgeInsets.fromLTRB(
                24,
                8,
                24,
                bottomInset > 16 ? bottomInset : 24,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  PhotoButton(
                    label: AppStrings.pmOpenSettings,
                    icon: AppAssets.settings,
                    onPressed: () =>
                        ref.read(mediaAccessProvider.notifier).openSettings(),
                  ),
                  const SizedBox(height: 12),
                  PhotoButton(
                    label: AppStrings.pmContinueWithoutAccess,
                    filled: false,
                    onPressed: () => _continueWithout(context, ref),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

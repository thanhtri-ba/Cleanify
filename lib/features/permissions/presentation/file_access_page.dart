import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/l10n/app_strings.dart';
import '../../../core/router/app_routes.dart';
import '../../../core/theme/app_assets.dart';
import '../../../core/theme/app_text.dart';
import '../../../core/widgets/fade_slide_in.dart';
import '../application/media_access_controller.dart';
import '../domain/media_access.dart';
import 'photo_permission_parts.dart';
import '../../../core/theme/app_tokens.dart';

/// Màn giải thích quyền ảnh/video (Figma 127:3099). Quyền thật xin qua
/// [mediaAccessProvider]; kết quả limited/denied chuyển sang màn tương ứng.
class FileAccessPage extends ConsumerWidget {
  const FileAccessPage({super.key});

  Future<void> _onContinue(BuildContext context, WidgetRef ref) async {
    final state = ref.read(mediaAccessProvider);
    final controller = ref.read(mediaAccessProvider.notifier);
    // Đã bị từ chối thì hệ điều hành không hỏi lại nữa: mở Settings.
    if (state.hasRequested && state.access == MediaAccess.denied) {
      await controller.openSettings();
      return;
    }
    final access = await controller.request();
    await ref.read(photoAccessPromptSeenProvider.notifier).markSeen();
    if (!context.mounted) return;
    context.go(switch (access) {
      MediaAccess.limited => AppRoutes.photoLimited,
      MediaAccess.denied => AppRoutes.photoDenied,
      _ => AppRoutes.home,
    });
  }

  /// Bỏ qua: ghi nhớ đã xem rồi vào Home.
  Future<void> _onSkip(BuildContext context, WidgetRef ref) async {
    await ref.read(photoAccessPromptSeenProvider.notifier).markSeen();
    if (context.mounted) context.go(AppRoutes.home);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(mediaAccessProvider);
    final isIos = Theme.of(context).platform == TargetPlatform.iOS;
    final bottomInset = MediaQuery.viewPaddingOf(context).bottom;

    return Scaffold(
      backgroundColor: context.tokens.surface,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            PhotoPermissionHeader(
              onBack: () => context.canPop() ? context.pop() : context.go(AppRoutes.onboarding3),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(24, 24, 24, 16),
                child: FadeSlideIn(
                  delay: const Duration(milliseconds: 120),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        AppStrings.pmExplainTitle,
                        style: AppText.custom(26, FontWeight.w700,
                            PhotoPalette.ink,
                            lineHeight: 32, letterSpacing: -0.5),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        AppStrings.pmExplainBody,
                        style: AppText.custom(14, FontWeight.w400,
                            PhotoPalette.body,
                            lineHeight: 21),
                      ),
                      const SizedBox(height: 24),
                      const PhotoIllustrationCard(icon: AppAssets.images),
                      const SizedBox(height: 20),
                      const PhotoInfoRow(
                        icon: AppAssets.scanLine,
                        title: AppStrings.pmBenefit1Title,
                        body: AppStrings.pmBenefit1Body,
                      ),
                      const SizedBox(height: 20),
                      const PhotoInfoRow(
                        icon: AppAssets.shieldCheck,
                        title: AppStrings.pmBenefit2Title,
                        body: AppStrings.pmBenefit2Body,
                      ),
                      const SizedBox(height: 20),
                      const PhotoInfoRow(
                        icon: AppAssets.circleCheck,
                        title: AppStrings.pmBenefit3Title,
                        body: AppStrings.pmBenefit3Body,
                      ),
                    ],
                  ),
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
                  Text(
                    isIos ? AppStrings.pmNextIos : AppStrings.pmNextAndroid,
                    textAlign: TextAlign.center,
                    style: AppText.custom(12, FontWeight.w400, PhotoPalette.muted,
                        lineHeight: 18),
                  ),
                  const SizedBox(height: 12),
                  PhotoButton(
                    label: AppStrings.continueLabel,
                    onPressed: state.isRequesting
                        ? null
                        : () => _onContinue(context, ref),
                  ),
                  const SizedBox(height: 12),
                  PhotoButton(
                    label: AppStrings.pmNotNow,
                    filled: false,
                    onPressed: () => _onSkip(context, ref),
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

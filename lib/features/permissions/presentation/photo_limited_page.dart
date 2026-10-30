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

/// Màn quyền ảnh ở chế độ limited (Figma 127:3145).
class PhotoLimitedPage extends ConsumerWidget {
  const PhotoLimitedPage({super.key});

  Future<void> _continue(BuildContext context, WidgetRef ref) async {
    await ref.read(photoAccessPromptSeenProvider.notifier).markSeen();
    if (context.mounted) context.go(AppRoutes.home);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
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
                      AppStrings.pmLimitedTitle,
                      style: AppText.custom(26, FontWeight.w700,
                          PhotoPalette.ink,
                          lineHeight: 32, letterSpacing: -0.5),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      AppStrings.pmLimitedBody,
                      style: AppText.custom(14, FontWeight.w400,
                          PhotoPalette.body,
                          lineHeight: 21),
                    ),
                    const SizedBox(height: 24),
                    const PhotoIllustrationCard(
                      icon: AppAssets.images,
                      caption: AppStrings.pmLimitedBadge,
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
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                AppStrings.pmScopeCardTitle,
                                style: AppText.custom(
                                    14, FontWeight.w600, PhotoPalette.ink),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 10, vertical: 5),
                                decoration: BoxDecoration(
                                  color: PhotoPalette.tile,
                                  borderRadius: BorderRadius.circular(9999),
                                ),
                                child: Text(
                                  AppStrings.pmLimitedStatus,
                                  style: AppText.custom(11, FontWeight.w600,
                                      PhotoPalette.primary),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          const PhotoInfoRow(
                            icon: AppAssets.images,
                            title: AppStrings.pmLimitedScopeTitle,
                            body: AppStrings.pmLimitedScopeBody,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    const PhotoNoteBox(text: AppStrings.pmLimitedNote),
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
                    label: AppStrings.pmManageSelected,
                    icon: AppAssets.plus,
                    onPressed: () =>
                        ref.read(mediaAccessProvider.notifier).manageLimited(),
                  ),
                  const SizedBox(height: 12),
                  PhotoButton(
                    label: AppStrings.pmContinueSelected,
                    filled: false,
                    onPressed: () => _continue(context, ref),
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

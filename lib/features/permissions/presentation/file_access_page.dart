import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/l10n/app_strings.dart';
import '../../../core/router/app_routes.dart';
import '../../../core/theme/app_assets.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text.dart';
import '../../../core/widgets/app_svg.dart';
import '../../../core/widgets/fade_slide_in.dart';
import '../../../core/widgets/primary_button.dart';
import '../../../core/widgets/secondary_button.dart';
import '../application/media_access_controller.dart';
import '../domain/media_access.dart';

/// Màn "Access your files". Quyền thực tế xin qua [mediaAccessProvider]
/// (thư viện ảnh/video), vì app chỉ quét media.
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
    await controller.request();
    await ref.read(photoAccessPromptSeenProvider.notifier).markSeen();
    if (context.mounted) context.go(AppRoutes.home);
  }

  /// Bỏ qua: ghi nhớ đã xem rồi vào Home.
  Future<void> _onSkip(BuildContext context, WidgetRef ref) async {
    await ref.read(photoAccessPromptSeenProvider.notifier).markSeen();
    if (context.mounted) context.go(AppRoutes.home);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(mediaAccessProvider);
    final bottomInset = MediaQuery.viewPaddingOf(context).bottom;
    return Scaffold(
      backgroundColor: AppColors.surface,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            _Header(onBack: context.canPop() ? () => context.pop() : null),
            const Divider(height: 1, thickness: 1, color: AppColors.divider),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(24, 24, 24, 24),
                child: FadeSlideIn(
                  delay: const Duration(milliseconds: 120),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(AppStrings.fileAccessBody, style: AppText.fileIntro),
                      const SizedBox(height: 8),
                      Text(AppStrings.fileAccessScope,
                          style: AppText.fileScope),
                      const SizedBox(height: 20),
                      const _Illustration(),
                      const SizedBox(height: 20),
                      _PermissionRow(
                        access: state.hasRequested ? state.access : null,
                      ),
                      const SizedBox(height: 20),
                      const _NoteBox(),
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
                math.max(24, bottomInset + 8),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  PrimaryButton(
                    label: AppStrings.continueLabel,
                    height: 56,
                    radius: 18,
                    color: Colors.black,
                    labelStyle: AppText.permPrimary,
                    shadows: const [],
                    isLoading: state.isRequesting,
                    onPressed: () => _onContinue(context, ref),
                  ),
                  const SizedBox(height: 12),
                  SecondaryButton(
                    label: AppStrings.skipForNow,
                    height: 56,
                    radius: 18,
                    borderColor: AppColors.borderNeutral,
                    labelStyle: AppText.permSecondary,
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

class _Header extends StatelessWidget {
  const _Header({required this.onBack});

  final VoidCallback? onBack;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 56,
      child: Stack(
        alignment: Alignment.center,
        children: [
          if (onBack != null)
            Positioned(
              left: 24,
              child: Semantics(
                button: true,
                label: AppStrings.back,
                excludeSemantics: true,
                child: Material(
                  color: AppColors.iconTile,
                  shape: const CircleBorder(),
                  child: InkWell(
                    customBorder: const CircleBorder(),
                    onTap: onBack,
                    child: const SizedBox(
                      width: 36,
                      height: 36,
                      child: Center(
                        child: AppSvg(AppAssets.chevronLeft, size: 18),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          Semantics(
            header: true,
            child: Text(AppStrings.fileAccessTitle, style: AppText.pageTitle),
          ),
        ],
      ),
    );
  }
}

class _Illustration extends StatelessWidget {
  const _Illustration();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 200,
      decoration: BoxDecoration(
        color: AppColors.illustrationCard,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.borderNeutral),
      ),
      child: Center(
        child: Container(
          width: 96,
          height: 96,
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: AppColors.borderNeutral),
          ),
          child: Center(
            child: Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: AppColors.iconTile,
                borderRadius: BorderRadius.circular(14),
              ),
              child: const Center(
                child: AppSvg(AppAssets.folder, size: 18),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _PermissionRow extends StatelessWidget {
  const _PermissionRow({required this.access});

  /// null khi chưa xin quyền lần nào.
  final MediaAccess? access;

  String get _status => switch (access) {
        null || MediaAccess.unknown => AppStrings.fileAccessNotRequested,
        MediaAccess.granted => AppStrings.fileAccessAllowed,
        MediaAccess.limited => AppStrings.fileAccessLimited,
        MediaAccess.denied => AppStrings.fileAccessDenied,
      };

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.borderNeutral),
      ),
      child: Row(
        children: [
          Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              color: AppColors.surfaceTint,
              borderRadius: BorderRadius.circular(9),
            ),
            child: const Center(child: AppSvg(AppAssets.folder, size: 18)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(AppStrings.fileAccessRowTitle, style: AppText.permTitle),
                const SizedBox(height: 2),
                Text(AppStrings.fileAccessRowBody, style: AppText.fileScope),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: AppColors.surfaceTint,
              borderRadius: BorderRadius.circular(9999),
            ),
            child: Text(_status, style: AppText.permStatus),
          ),
        ],
      ),
    );
  }
}

class _NoteBox extends StatelessWidget {
  const _NoteBox();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surfaceTint,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.borderNeutral),
      ),
      child: Text(AppStrings.fileAccessNote, style: AppText.fileScope),
    );
  }
}

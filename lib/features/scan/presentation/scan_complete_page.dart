import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/l10n/app_strings.dart';
import '../../../core/theme/app_assets.dart';
import '../../../core/router/app_routes.dart';
import '../../../core/theme/app_text.dart';
import '../../../core/theme/flow_colors.dart';
import '../../../core/theme/app_tokens.dart';
import '../../../core/utils/format_bytes.dart';
import '../../../core/widgets/app_svg.dart';
import '../application/scan_controller.dart';
import '../application/scan_providers.dart';
import '../domain/cleanup_plan.dart';
import '../domain/scan_models.dart';
import 'widgets/category_meta.dart';
import 'widgets/flow_parts.dart';

/// Scan Complete theo Figma node 127:1213.
class ScanCompletePage extends ConsumerWidget {
  const ScanCompletePage({super.key});

  static const _selectedLabel = 'Selected for review';
  static const _safeNote = 'Nothing is deleted until you confirm.';
  static const _backHome = 'Back to Home';

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final outcome = ref.watch(scanControllerProvider).outcome;
    final plan = ref.watch(cleanupPlanProvider);
    final threshold =
        formatBytes(ref.watch(scanConfigProvider).largeVideoBytes);
    final result = outcome?.result;

    void leave() =>
        context.canPop() ? context.pop() : context.go(AppRoutes.home);

    if (result == null || plan == null) {
      return Scaffold(
        backgroundColor: context.tokens.surface,
        body: SafeArea(child: _Header(onBack: leave)),
      );
    }

    final canReview = !plan.isEmpty;
    return Scaffold(
      backgroundColor: context.tokens.surface,
      body: SafeArea(
        child: Column(
          children: [
            _Header(onBack: leave),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
                children: staggered([
                  Column(
                    children: [
                      Text(
                        AppStrings.scanCompleteTitle,
                        textAlign: TextAlign.center,
                        style: AppText.custom(
                            24, FontWeight.w600, context.tokens.textPrimary,
                            lineHeight: 30, letterSpacing: -0.6),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        AppStrings.scanCompleteBody,
                        textAlign: TextAlign.center,
                        style: AppText.custom(
                            14, FontWeight.w400, context.tokens.textSecondary,
                            lineHeight: 20),
                      ),
                    ],
                  ),
                  CountUpBytes(
                    bytes: plan.bytes,
                    builder: (_, bytes) {
                      final b = splitBytes(bytes);
                      return Column(
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.baseline,
                            textBaseline: TextBaseline.alphabetic,
                            children: [
                              Text(
                                b.value,
                                style: AppText.custom(
                                    44, FontWeight.w700, context.tokens.textPrimary,
                                    lineHeight: 48, letterSpacing: -2.2),
                              ),
                              const SizedBox(width: 4),
                              Text(
                                b.unit,
                                style: AppText.custom(
                                    20, FontWeight.w400,
                                    context.tokens.textPrimary,
                                    lineHeight: 26, letterSpacing: -0.3),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            AppStrings.potentialSpace,
                            style: AppText.custom(
                                13, FontWeight.w600, context.tokens.textCaption,
                                lineHeight: 18),
                          ),
                        ],
                      );
                    },
                  ),
                  _SelectedBanner(
                      label: _selectedLabel, value: formatBytes(plan.bytes)),
                  Container(
                    decoration: BoxDecoration(
                      color: context.tokens.surface,
                      borderRadius: BorderRadius.circular(22),
                      border: Border.all(color: context.tokens.border),
                      boxShadow: const [
                        BoxShadow(
                          color: Color(0x0A202020),
                          blurRadius: 20,
                          spreadRadius: -2,
                          offset: Offset(0, 4),
                        ),
                      ],
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: Column(
                      children: [
                        for (final (i, c) in ScanCategory.values.indexed) ...[
                          if (i > 0)
                            Divider(
                                height: 1,
                                thickness: 1,
                                color: context.tokens.iconTile),
                          _row(context, ref, result, plan, c, threshold),
                        ],
                      ],
                    ),
                  ),
                ]),
              ),
            ),
            Container(
              padding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
              decoration: BoxDecoration(
                color: context.tokens.surface,
                border: Border(top: BorderSide(color: context.tokens.border)),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    _safeNote,
                    style: AppText.custom(
                        11, FontWeight.w400, context.tokens.textCaption,
                        lineHeight: 16),
                  ),
                  const SizedBox(height: 8),
                  Opacity(
                    opacity: canReview ? 1 : 0.4,
                    child: Material(
                      color: FlowColors.progress,
                      borderRadius: BorderRadius.circular(16),
                      child: InkWell(
                        borderRadius: BorderRadius.circular(16),
                        onTap: canReview
                            ? () => context.push(AppRoutes.cleanupReview)
                            : null,
                        child: SizedBox(
                          height: 56,
                          width: double.infinity,
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const AppSvg(AppAssets.broom,
                                  size: 15, color: Colors.white),
                              const SizedBox(width: 8),
                              Text(
                                AppStrings.reviewSelection(
                                    formatBytes(plan.bytes)),
                                style: AppText.custom(
                                    14, FontWeight.w600, Colors.white,
                                    lineHeight: 18, letterSpacing: 0.14),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                  TextButton(
                    onPressed: () => context.go(AppRoutes.home),
                    child: Text(
                      _backHome,
                      style: AppText.custom(
                          14, FontWeight.w500, context.tokens.textPrimary,
                          lineHeight: 20),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _row(BuildContext context, WidgetRef ref, ScanResult result, CleanupPlan plan,
      ScanCategory c, String threshold) {
    final scanned = result.completed.contains(c);
    final selectable = plan.selectableIds(c).isNotEmpty;
    final selected = plan.isCategoryFullySelected(c);
    final hint = scanned ? c.resultHint(plan.countFor(c), threshold) : null;

    final Widget trailing;
    if (!scanned) {
      trailing = const _MutedText(AppStrings.notScanned);
    } else if (!selectable) {
      trailing = const _MutedText(AppStrings.noneFound);
    } else {
      trailing = Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            formatBytes(plan.bytesFor(c)),
            style: AppText.custom(14, FontWeight.w500, context.tokens.textPrimary,
                lineHeight: 20),
          ),
          const SizedBox(width: 12),
          _Check(selected: selected),
        ],
      );
    }

    return InkWell(
      onTap: selectable
          ? () => ref.read(cleanupPlanProvider.notifier).toggleCategory(c)
          : null,
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: const BoxDecoration(
                color: Color(0x99E2E2E2),
                shape: BoxShape.circle,
              ),
              child: Center(
                child: AppSvg(c.icon, size: 16.67, color: context.tokens.textPrimary),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    c.label,
                    style: AppText.custom(14, FontWeight.w500, context.tokens.textPrimary,
                        lineHeight: 20),
                  ),
                  if (hint != null)
                    Text(
                      hint,
                      style: AppText.custom(
                          12, FontWeight.w500, context.tokens.textSecondary,
                          lineHeight: 16, letterSpacing: 0.12),
                    ),
                ],
              ),
            ),
            trailing,
          ],
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.onBack});

  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      child: SizedBox(
        height: 44,
        child: Row(
          children: [
            Material(
              color: context.tokens.surfaceMuted,
              shape: const CircleBorder(),
              child: InkWell(
                customBorder: const CircleBorder(),
                onTap: onBack,
                child: SizedBox(
                  width: 36,
                  height: 36,
                  child: Center(
                    child: AppSvg(
                      AppAssets.chevronLeft,
                      size: 14,
                      color: context.tokens.textPrimary,
                    ),
                  ),
                ),
              ),
            ),
            Expanded(
              child: Text(
                AppStrings.scanComplete,
                textAlign: TextAlign.center,
                style: AppText.custom(18, FontWeight.w600, context.tokens.textPrimary,
                    lineHeight: 24, letterSpacing: -0.45),
              ),
            ),
            const SizedBox(width: 36),
          ],
        ),
      ),
    );
  }
}

class _SelectedBanner extends StatelessWidget {
  const _SelectedBanner({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: context.tokens.iconTile,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xB3E8E8E8)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: AppText.custom(14, FontWeight.w600, context.tokens.textPrimary,
                lineHeight: 18, letterSpacing: 0.14),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: context.tokens.surface,
              borderRadius: BorderRadius.circular(9999),
              border: Border.all(color: context.tokens.border),
            ),
            child: Text(
              value,
              style: AppText.custom(14, FontWeight.w700,
                  context.tokens.textPrimary,
                  lineHeight: 20),
            ),
          ),
        ],
      ),
    );
  }
}

class _Check extends StatelessWidget {
  const _Check({required this.selected});

  final bool selected;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 24,
      height: 24,
      decoration: BoxDecoration(
        color: selected ? FlowColors.progress : context.tokens.surface,
        shape: BoxShape.circle,
        border: Border.all(
          color: selected ? FlowColors.progress : context.tokens.borderSoft,
          width: 2,
        ),
      ),
      child: selected
          ? const Icon(Icons.check, size: 14, color: Colors.white)
          : null,
    );
  }
}

class _MutedText extends StatelessWidget {
  const _MutedText(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: AppText.custom(12, FontWeight.w500, context.tokens.textCaption,
          lineHeight: 16),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/l10n/app_strings.dart';
import '../../../core/router/app_routes.dart';
import '../../../core/theme/app_assets.dart';
import '../../../core/theme/app_text.dart';
import '../../../core/theme/app_tokens.dart';
import '../../../core/widgets/app_svg.dart';
import 'scan_actions.dart';

/// Scan Error theo Figma node 127:1395.
class ScanErrorPage extends ConsumerWidget {
  const ScanErrorPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      backgroundColor: context.tokens.surface,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
              child: SizedBox(
                height: 48,
                child: Row(
                  children: [
                    SizedBox(
                      width: 32,
                      child: GestureDetector(
                        onTap: () => context.go(AppRoutes.home),
                        child: AppSvg(
                          AppAssets.chevronLeft,
                          size: 23,
                          color: context.tokens.textPrimary,
                        ),
                      ),
                    ),
                    Expanded(
                      child: Text(
                        AppStrings.storageScan,
                        textAlign: TextAlign.center,
                        style: AppText.custom(18, FontWeight.w700, context.tokens.textPrimary,
                            lineHeight: 22),
                      ),
                    ),
                    const SizedBox(width: 32),
                  ],
                ),
              ),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(20, 24, 20, 24),
                children: [
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: context.tokens.surface,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: context.tokens.border),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              width: 32,
                              height: 32,
                              decoration: BoxDecoration(
                                color: context.tokens.surface,
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: Center(
                                child: AppSvg(AppAssets.warning,
                                    size: 16, color: context.tokens.textPrimary),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                AppStrings.scanErrorTitle,
                                style: AppText.custom(
                                    15, FontWeight.w700, context.tokens.textPrimary,
                                    lineHeight: 20),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Text(
                          AppStrings.scanErrorBody,
                          style: AppText.custom(
                              13, FontWeight.w400, context.tokens.textCaption,
                              lineHeight: 18),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  Material(
                    color: const Color(0xFF434343),
                    borderRadius: BorderRadius.circular(16),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(16),
                      onTap: () => restartScan(context, ref),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        child: Center(
                          child: Text(
                            AppStrings.tryAgain,
                            style: AppText.custom(
                                15, FontWeight.w600, Colors.white,
                                lineHeight: 20),
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    AppStrings.scanErrorSafe,
                    textAlign: TextAlign.center,
                    style: AppText.custom(
                        12, FontWeight.w400, context.tokens.textCaption,
                        lineHeight: 16),
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 12),
              decoration: BoxDecoration(
                color: context.tokens.surface,
                border: Border(top: BorderSide(color: context.tokens.border)),
              ),
              child: Material(
                color: context.tokens.surface,
                borderRadius: BorderRadius.circular(16),
                child: InkWell(
                  borderRadius: BorderRadius.circular(16),
                  onTap: () => context.go(AppRoutes.home),
                  child: Container(
                    height: 49,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: context.tokens.border),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        AppSvg(AppAssets.chevronLeft,
                            size: 18, color: context.tokens.textPrimary),
                        const SizedBox(width: 9),
                        Text(
                          AppStrings.backToScan,
                          style: AppText.custom(
                              14, FontWeight.w600, context.tokens.textPrimary,
                              lineHeight: 20),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

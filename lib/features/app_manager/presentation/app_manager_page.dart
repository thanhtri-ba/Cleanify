import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/l10n/app_strings.dart';
import '../../../core/theme/app_assets.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text.dart';
import '../../../core/utils/format_bytes.dart';
import '../../../core/widgets/primary_button.dart';
import '../../../core/widgets/sub_page_scaffold.dart';
import '../application/albums_provider.dart';

/// App Manager: ảnh và video nhóm theo album nguồn (WhatsApp, Telegram...).
/// Hệ điều hành không cho đọc dung lượng trong từng ứng dụng nên chỉ đếm mục.
class AppManagerPage extends ConsumerWidget {
  const AppManagerPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final albums = ref.watch(albumsProvider);

    return SubPageScaffold(
      title: AppStrings.appManager,
      onBack: () => context.pop(),
      children: albums.when<List<Widget>>(
        loading: () => const [
          Padding(
            padding: EdgeInsets.symmetric(vertical: 64),
            child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
          ),
        ],
        error: (_, __) => [
          const SubEmpty(
            asset: AppAssets.warning,
            title: AppStrings.albumsError,
            body: AppStrings.albumsEmptyBody,
          ),
          PrimaryButton(
            label: AppStrings.retry,
            shadows: const [],
            onPressed: () => ref.invalidate(albumsProvider),
          ),
        ],
        data: (list) {
          if (list.isEmpty) {
            return const [
              SubEmpty(
                asset: AppAssets.folder,
                title: AppStrings.albumsEmptyTitle,
                body: AppStrings.albumsEmptyBody,
              ),
            ];
          }
          final maxCount = list.first.count;
          return [
            SubCard(
              child: Row(
                children: [
                  Expanded(
                    child: SubBigStat(
                      value: formatCount(list.length),
                      unit: '',
                      caption: AppStrings.appManagerCaption,
                    ),
                  ),
                  const SubIconTile(
                      asset: AppAssets.gridDots, size: 48, iconSize: 20),
                ],
              ),
            ),
            const SubSectionLabel(AppStrings.appManagerAlbums),
            for (final a in list)
              _AlbumRow(album: a, fraction: a.count / maxCount),
            const SubHint(AppStrings.appManagerHint),
          ];
        },
      ),
    );
  }
}

class _AlbumRow extends StatelessWidget {
  const _AlbumRow({required this.album, required this.fraction});

  final AlbumInfo album;
  final double fraction;

  @override
  Widget build(BuildContext context) {
    final initial =
        album.name.isEmpty ? '?' : album.name.characters.first.toUpperCase();
    return SubCard(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: AppColors.iconTile,
              borderRadius: BorderRadius.circular(12),
            ),
            alignment: Alignment.center,
            child: Text(
              initial,
              style: AppText.custom(16, FontWeight.w700, AppColors.titleInk),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        album.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppText.custom(
                            14, FontWeight.w600, AppColors.titleInk),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      AppStrings.albumItems(album.count),
                      style: AppText.custom(
                          13, FontWeight.w700, AppColors.titleInk),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                ClipRRect(
                  borderRadius: BorderRadius.circular(9999),
                  child: TweenAnimationBuilder<double>(
                    tween: Tween(begin: 0, end: fraction),
                    duration: const Duration(milliseconds: 800),
                    curve: Curves.easeOutCubic,
                    builder: (context, v, _) => LinearProgressIndicator(
                      value: v,
                      minHeight: 6,
                      backgroundColor: AppColors.iconTile,
                      color: AppColors.primary,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

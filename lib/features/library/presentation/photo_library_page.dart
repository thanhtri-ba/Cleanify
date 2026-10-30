import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/l10n/app_strings.dart';
import '../../../core/router/app_routes.dart';
import '../../../core/theme/app_assets.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text.dart';
import '../../../core/theme/app_tokens.dart';
import '../../../core/utils/format_date.dart';
import '../../../core/widgets/app_svg.dart';
import '../../../core/widgets/primary_button.dart';
import '../../permissions/application/media_access_controller.dart';
import '../../permissions/domain/media_access.dart';
import '../../scan/application/scan_controller.dart';
import '../../scan/domain/media_item.dart';
import '../../scan/domain/scan_models.dart';
import '../../scan/presentation/widgets/media_thumbnail.dart';
import '../../../core/utils/format_bytes.dart';
import '../../../core/theme/app_theme.dart';
import '../application/library_controller.dart';
import 'photo_viewer_page.dart';

/// Thư viện ảnh: lưới mọi ảnh/video trong máy (mới nhất trước), bấm để xem lớn.
class PhotoLibraryPage extends ConsumerStatefulWidget {
  const PhotoLibraryPage({super.key});

  /// Dùng trong test để nhận biết đã vào màn thư viện.
  static const pageKey = Key('photo-library-page');

  @override
  ConsumerState<PhotoLibraryPage> createState() => _PhotoLibraryPageState();
}

class _PhotoLibraryPageState extends ConsumerState<PhotoLibraryPage> {
  static const _columns = 3;
  static const _gap = 8.0;

  final _scroll = ScrollController();

  /// null khi đang kiểm tra quyền.
  bool? _hasAccess;

  /// Ảnh đã chọn bằng vòng tròn trên lưới (Figma 127:1558).
  final Set<String> _selected = {};

  void _toggleSelect(String id) => setState(() {
        if (!_selected.remove(id)) _selected.add(id);
      });

  @override
  void initState() {
    super.initState();
    _scroll.addListener(_onScroll);
    WidgetsBinding.instance.addPostFrameCallback((_) => _open());
  }

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  Future<void> _open() async {
    await ref.read(mediaAccessProvider.notifier).refresh();
    if (!mounted) return;
    final access = ref.read(mediaAccessProvider).access;
    final ok = access == MediaAccess.granted || access == MediaAccess.limited;
    setState(() => _hasAccess = ok);
    if (ok) await ref.read(libraryControllerProvider.notifier).reload();
  }

  void _onScroll() {
    if (!_scroll.hasClients) return;
    // Nạp trước khi chạm đáy để người dùng không thấy khoảng trống.
    if (_scroll.position.extentAfter < 900) {
      ref.read(libraryControllerProvider.notifier).loadMore();
    }
  }

  void _openViewer(int index) {
    Navigator.of(context).push(
      PageRouteBuilder<void>(
        transitionDuration: const Duration(milliseconds: 280),
        reverseTransitionDuration: const Duration(milliseconds: 220),
        pageBuilder: (_, __, ___) => Theme(
          data: AppTheme.dark(),
          child: PhotoViewerPage(initialIndex: index),
        ),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          if (MediaQuery.maybeDisableAnimationsOf(context) ?? false) {
            return child;
          }
          final curve = CurvedAnimation(
            parent: animation,
            curve: Curves.easeOutCubic,
            reverseCurve: Curves.easeInCubic,
          );
          return FadeTransition(
            opacity: CurvedAnimation(
              parent: animation,
              curve: Curves.easeOut,
            ),
            child: ScaleTransition(
              scale: Tween<double>(begin: 1.06, end: 1).animate(curve),
              child: child,
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(libraryControllerProvider);
    final result =
        ref.watch(scanControllerProvider.select((s) => s.outcome?.result));
    // Chỉ ảnh đã có trong kết quả quét mới đưa vào bước xem lại xóa.
    final plannable = <String>{
      for (final g in result?.allGroups ?? const <MediaGroup>[])
        for (final m in g.removable) m.id,
    };
    final reviewable = _selected.where(plannable.contains).toSet();
    var reviewBytes = 0;
    if (result != null) {
      for (final g in result.allGroups) {
        for (final m in g.removable) {
          if (reviewable.contains(m.id)) reviewBytes += m.sizeBytes ?? 0;
        }
      }
    }

    return Scaffold(
      key: PhotoLibraryPage.pageKey,
      backgroundColor: context.tokens.surface,
      body: Column(
        children: [
          _Header(
            subtitle: _hasAccess == true && state.total > 0
                ? AppStrings.libraryCount(state.total)
                : null,
            onBack: () => context.pop(),
            onClear: _selected.isEmpty
                ? null
                : () => setState(_selected.clear),
          ),
          Expanded(child: _body(state)),
          if (_hasAccess == true && state.items.isNotEmpty)
            _SelectionBar(
              count: _selected.length,
              reviewCount: reviewable.length,
              reviewBytes: reviewBytes,
              onReview: reviewable.isEmpty
                  ? null
                  : () {
                      ref
                          .read(cleanupPlanProvider.notifier)
                          .selectOnly(reviewable);
                      context.push(AppRoutes.cleanupReview);
                    },
            ),
        ],
      ),
    );
  }

  Widget _body(LibraryState state) {
    if (_hasAccess == null) return const _Loading();
    if (_hasAccess == false) {
      return _Message(
        title: AppStrings.libraryNoAccessTitle,
        body: AppStrings.libraryNoAccessBody,
        action: PrimaryButton(
          label: AppStrings.continueLabel,
          shadows: const [],
          onPressed: () => context.push(AppRoutes.fileAccess),
        ),
      );
    }
    if (state.failed) {
      return _Message(
        title: AppStrings.libraryErrorTitle,
        body: AppStrings.libraryErrorBody,
        action: PrimaryButton(
          label: AppStrings.tryAgain,
          shadows: const [],
          onPressed: () =>
              ref.read(libraryControllerProvider.notifier).reload(),
        ),
      );
    }
    if (state.isEmpty) {
      return const _Message(
        title: AppStrings.libraryEmptyTitle,
        body: AppStrings.libraryEmptyBody,
      );
    }
    if (state.items.isEmpty) return const _Loading();

    final bottom = MediaQuery.paddingOf(context).bottom;
    return RefreshIndicator(
      onRefresh: () => ref.read(libraryControllerProvider.notifier).reload(),
      child: GridView.builder(
        controller: _scroll,
        physics: const AlwaysScrollableScrollPhysics(),
        padding: EdgeInsets.fromLTRB(_gap, _gap, _gap, _gap + bottom + 12),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: _columns,
          mainAxisSpacing: _gap,
          crossAxisSpacing: _gap,
        ),
        itemCount: state.items.length,
        itemBuilder: (context, index) {
          final item = state.items[index];
          return _Cell(
            item: item,
            selected: _selected.contains(item.id),
            onTap: () => _openViewer(index),
            onSelect: () => _toggleSelect(item.id),
          );
        },
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.subtitle, required this.onBack, this.onClear});

  final String? subtitle;
  final VoidCallback onBack;
  final VoidCallback? onClear;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      bottom: false,
      child: SizedBox(
        height: 64,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: [
              Semantics(
                button: true,
                label: AppStrings.back,
                excludeSemantics: true,
                child: Material(
                  color: context.tokens.surface,
                  shape: CircleBorder(
                    side: BorderSide(color: context.tokens.border),
                  ),
                  child: InkWell(
                    customBorder: const CircleBorder(),
                    onTap: onBack,
                    child: SizedBox(
                      width: 36,
                      height: 36,
                      child: Center(
                        child: AppSvg(
                          AppAssets.chevronLeft,
                          size: 18,
                          color: context.tokens.textPrimary,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Semantics(
                      header: true,
                      child: Text(
                        AppStrings.photoLibrary,
                        style: AppText.custom(18, FontWeight.w600,
                            context.tokens.textPrimary,
                            lineHeight: 24, letterSpacing: -0.18),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (subtitle != null)
                      Text(
                        subtitle!,
                        style: AppText.custom(13, FontWeight.w400,
                            context.tokens.textCaption,
                            lineHeight: 18),
                      ),
                  ],
                ),
              ),
              if (onClear != null)
                GestureDetector(
                  onTap: onClear,
                  child: Text(
                    'Clear selection',
                    style: AppText.custom(13, FontWeight.w500,
                        context.tokens.textPrimary,
                        lineHeight: 18),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Cell extends StatelessWidget {
  const _Cell({
    required this.item,
    required this.selected,
    required this.onTap,
    required this.onSelect,
  });

  final MediaItem item;
  final bool selected;
  final VoidCallback onTap;
  final VoidCallback onSelect;

  @override
  Widget build(BuildContext context) {
    final isVideo = item.kind == MediaKind.video;
    final kind = isVideo ? AppStrings.video : AppStrings.photoLibrary;
    return Semantics(
      button: true,
      label: '$kind, ${formatShortDate(item.createdAt)}',
      selected: selected,
      child: LayoutBuilder(
        builder: (context, box) => Container(
          clipBehavior: Clip.antiAlias,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
          ),
          foregroundDecoration: selected
              ? BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                      color: const Color(0xFF434343), width: 3),
                )
              : null,
          child: Stack(
            children: [
              GestureDetector(
                onTap: onTap,
                child: MediaThumbnail(
                  id: item.id,
                  width: box.maxWidth,
                  height: box.maxHeight,
                  radius: 0,
                  requestSize: 300,
                ),
              ),
              if (isVideo)
                Positioned(
                  left: 6,
                  bottom: 6,
                  child: IgnorePointer(
                    child: Container(
                      padding: const EdgeInsets.all(2),
                      decoration: const BoxDecoration(
                        color: Color(0x99111827),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.play_arrow_rounded,
                        size: 16,
                        color: context.tokens.surface,
                      ),
                    ),
                  ),
                ),
              Positioned(
                top: 8,
                right: 8,
                child: GestureDetector(
                  onTap: onSelect,
                  behavior: HitTestBehavior.opaque,
                  child: Container(
                    width: 22,
                    height: 22,
                    decoration: BoxDecoration(
                      color: selected ? context.tokens.textPrimary : context.tokens.surface,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: selected
                            ? context.tokens.border
                            : context.tokens.borderSoft,
                        width: 2,
                      ),
                    ),
                    child: selected
                        ? const Icon(Icons.check,
                            size: 13, color: Colors.white)
                        : null,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SelectionBar extends StatelessWidget {
  const _SelectionBar({
    required this.count,
    required this.reviewCount,
    required this.reviewBytes,
    required this.onReview,
  });

  final int count;
  final int reviewCount;
  final int reviewBytes;
  final VoidCallback? onReview;

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.paddingOf(context).bottom;
    final unplanned = count - reviewCount;
    return Container(
      padding: EdgeInsets.fromLTRB(20, 12, 20, 12 + bottom),
      decoration: BoxDecoration(
        color: context.tokens.surface,
        border: Border(top: BorderSide(color: context.tokens.border)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            count == 0
                ? 'Tap a photo for details. Use circles to select.'
                : '$count photos selected',
            style: AppText.custom(
                13, FontWeight.w600, context.tokens.textPrimary,
                lineHeight: 18),
          ),
          if (unplanned > 0)
            Padding(
              padding: const EdgeInsets.only(top: 2),
              child: Text(
                'Only photos from your last scan can be reviewed for deletion.',
                textAlign: TextAlign.center,
                style: AppText.custom(
                    11, FontWeight.w400, context.tokens.textCaption,
                    lineHeight: 16),
              ),
            ),
          const SizedBox(height: 8),
          Opacity(
            opacity: onReview == null ? 0.4 : 1,
            child: Material(
              color: const Color(0xFF434343),
              borderRadius: BorderRadius.circular(16),
              child: InkWell(
                borderRadius: BorderRadius.circular(16),
                onTap: onReview,
                child: SizedBox(
                  height: 49,
                  width: double.infinity,
                  child: Center(
                    child: Text(
                      reviewCount == 0
                          ? 'Review deletion'
                          : 'Review deletion ($reviewCount · ${formatBytes(reviewBytes)})',
                      style: AppText.custom(
                          14, FontWeight.w600, Colors.white,
                          lineHeight: 18),
                    ),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Nothing is deleted until you confirm.',
            style: AppText.custom(
                11, FontWeight.w400, context.tokens.textCaption,
                lineHeight: 16),
          ),
        ],
      ),
    );
  }
}

class _Loading extends StatelessWidget {
  const _Loading();

  @override
  Widget build(BuildContext context) => const Center(
        child: SizedBox(
          width: 24,
          height: 24,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            color: AppColors.primary,
          ),
        ),
      );
}

class _Message extends StatelessWidget {
  const _Message({required this.title, required this.body, this.action});

  final String title;
  final String body;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AppSvg(AppAssets.image, size: 28, color: context.tokens.textMuted),
            const SizedBox(height: 16),
            Text(title, textAlign: TextAlign.center, style: AppText.rowTitle),
            const SizedBox(height: 6),
            Text(body, textAlign: TextAlign.center, style: AppText.bodySmall),
            if (action != null) ...[
              const SizedBox(height: 24),
              SizedBox(width: 220, child: action),
            ],
          ],
        ),
      ),
    );
  }
}

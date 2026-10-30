import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/l10n/app_strings.dart';
import '../../../core/router/app_routes.dart';
import '../../../core/theme/app_assets.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text.dart';
import '../../../core/utils/format_date.dart';
import '../../../core/widgets/app_svg.dart';
import '../../../core/widgets/primary_button.dart';
import '../../permissions/application/media_access_controller.dart';
import '../../permissions/domain/media_access.dart';
import '../../scan/domain/media_item.dart';
import '../../scan/presentation/widgets/media_thumbnail.dart';
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
  static const _gap = 2.0;

  final _scroll = ScrollController();

  /// null khi đang kiểm tra quyền.
  bool? _hasAccess;

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
        pageBuilder: (_, __, ___) => PhotoViewerPage(initialIndex: index),
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
    return Scaffold(
      key: PhotoLibraryPage.pageKey,
      backgroundColor: AppColors.surface,
      body: Column(
        children: [
          _Header(
            subtitle: _hasAccess == true && state.total > 0
                ? AppStrings.libraryCount(state.total)
                : null,
            onBack: () => context.pop(),
          ),
          Expanded(child: _body(state)),
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
        itemBuilder: (context, index) => _Cell(
          item: state.items[index],
          onTap: () => _openViewer(index),
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.subtitle, required this.onBack});

  final String? subtitle;
  final VoidCallback onBack;

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
                  color: AppColors.surface,
                  shape: const CircleBorder(
                    side: BorderSide(color: AppColors.borderNeutral),
                  ),
                  child: InkWell(
                    customBorder: const CircleBorder(),
                    onTap: onBack,
                    child: const SizedBox(
                      width: 36,
                      height: 36,
                      child: Center(
                        child: AppSvg(
                          AppAssets.chevronLeft,
                          size: 18,
                          color: AppColors.titleInk,
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
                        style: AppText.pageTitle,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (subtitle != null)
                      Text(subtitle!, style: AppText.rowHint),
                  ],
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
  const _Cell({required this.item, required this.onTap});

  final MediaItem item;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final isVideo = item.kind == MediaKind.video;
    final kind = isVideo ? AppStrings.video : AppStrings.photoLibrary;
    return Semantics(
      button: true,
      label: '$kind, ${formatShortDate(item.createdAt)}',
      excludeSemantics: true,
      child: GestureDetector(
        onTap: onTap,
        child: LayoutBuilder(
          builder: (context, box) => Stack(
            children: [
              MediaThumbnail(
                id: item.id,
                width: box.maxWidth,
                height: box.maxHeight,
                radius: 0,
                requestSize: 300,
              ),
              if (isVideo)
                Positioned(
                  left: 6,
                  bottom: 6,
                  child: Container(
                    padding: const EdgeInsets.all(2),
                    decoration: const BoxDecoration(
                      color: Color(0x99111827),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.play_arrow_rounded,
                      size: 16,
                      color: Colors.white,
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
            const AppSvg(AppAssets.image, size: 28, color: AppColors.textMuted),
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

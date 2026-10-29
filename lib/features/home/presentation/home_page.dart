import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/l10n/app_strings.dart';
import '../../../core/router/app_routes.dart';
import '../../../core/theme/app_assets.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text.dart';
import '../../../core/utils/format_bytes.dart';
import '../../../core/widgets/app_bottom_nav.dart';
import '../../../core/widgets/app_svg.dart';
import '../../../core/widgets/fade_slide_in.dart';
import '../../../core/widgets/primary_button.dart';
import '../../scan/application/scan_controller.dart';
import '../../scan/application/scan_providers.dart';
import '../../scan/domain/device_storage.dart';
import '../../scan/domain/scan_models.dart';
import '../../scan/presentation/scan_actions.dart';
import '../../scan/presentation/widgets/media_thumbnail.dart';

/// Màn Home (thiết kế nâng cấp): dung lượng, Scan for Junk, ảnh trùng,
/// Large Files / App Manager, Storage Analysis.
class HomePage extends ConsumerWidget {
  const HomePage({super.key});

  /// Dùng trong test để nhận biết đã vào Home.
  static const pageKey = Key('home-page');

  /// Các mục chưa có màn đích: báo rõ thay vì để nút "chết".
  static void _comingSoon(BuildContext context) {
    final messenger = ScaffoldMessenger.of(context);
    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(const SnackBar(
        content: Text(AppStrings.comingSoon),
        duration: Duration(seconds: 1),
      ));
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final storage = ref.watch(deviceStorageProvider);
    final breakdown = ref.watch(storageBreakdownProvider);
    final scan = ref.watch(scanControllerProvider);
    final scanning = scan.phase == ScanPhase.running;
    void onSoon() => _comingSoon(context);
    void scanNow() {
      if (!scanning) startScanFlow(context, ref);
    }

    return Scaffold(
      key: pageKey,
      backgroundColor: AppColors.canvas,
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              // Chừa chỗ cho thanh trạng thái vì Home không còn header.
              padding: EdgeInsets.fromLTRB(
                20,
                MediaQuery.paddingOf(context).top + 20,
                20,
                16,
              ),
              child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                FadeSlideIn(
                  delay: const Duration(milliseconds: 60),
                  child: _StorageCard(
                    storage: storage,
                    breakdown: breakdown,
                    onRetry: () => ref.invalidate(deviceStorageProvider),
                  ),
                ),
                const SizedBox(height: 12),
                FadeSlideIn(
                  delay: const Duration(milliseconds: 120),
                  child: _ScanButton(scanning: scanning, onTap: scanNow),
                ),
                const SizedBox(height: 12),
                FadeSlideIn(
                  delay: const Duration(milliseconds: 180),
                  child: _NotificationsRow(
                      onTap: () => context.push(AppRoutes.notifications)),
                ),
                const SizedBox(height: 12),
                FadeSlideIn(
                  delay: const Duration(milliseconds: 240),
                  child: _DuplicatesCard(
                    result: scan.outcome?.result,
                    onReview: () => context.push(AppRoutes.duplicates),
                  ),
                ),
                const SizedBox(height: 12),
                FadeSlideIn(
                  delay: const Duration(milliseconds: 300),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: _LargeFilesCard(
                          threshold:
                              ref.watch(scanConfigProvider).largeVideoBytes,
                          onTap: () => context.push(AppRoutes.largeFiles),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                          child: _AppManagerCard(
                              onTap: () => context.push(AppRoutes.appManager))),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                FadeSlideIn(
                  delay: const Duration(milliseconds: 360),
                  child: _WideLinkCard(
                    onTap: () => context.push(AppRoutes.photoLibrary),
                    title: AppStrings.photoLibrary,
                    subtitle: AppStrings.photoLibrarySubtitle,
                    icon: AppAssets.image,
                  ),
                ),
                const SizedBox(height: 12),
                FadeSlideIn(
                  delay: const Duration(milliseconds: 420),
                  child: _WideLinkCard(
                    onTap: () => context.push(AppRoutes.storageAnalysis),
                    title: AppStrings.storageAnalysis,
                    subtitle: AppStrings.deepAudit,
                    icon: AppAssets.barChart,
                  ),
                ),
              ],
              ),
            ),
          ),
          AppBottomNav(
            current: AppTab.home,
            onTap: (tab) {
              if (tab == AppTab.scan) {
                scanNow();
              } else if (tab != AppTab.home) {
                onSoon();
              }
            },
          ),
        ],
      ),
    );
  }
}

// ───────────────────────── Storage card ─────────────────────────

BoxDecoration _cardDecoration(double radius, {bool shadow = true}) =>
    BoxDecoration(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(radius),
      border: Border.all(color: AppColors.borderNeutral),
      boxShadow: shadow
          ? const [
              BoxShadow(
                color: Color(0x0A111827),
                blurRadius: 24,
                spreadRadius: -8,
                offset: Offset(0, 10),
              ),
            ]
          : null,
    );

class _StorageCard extends StatelessWidget {
  const _StorageCard({
    required this.storage,
    required this.breakdown,
    required this.onRetry,
  });

  final AsyncValue<DeviceStorage> storage;
  final StorageBreakdown? breakdown;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 18),
      decoration: _cardDecoration(28),
      child: storage.when(
        data: (s) => _StorageData(s, breakdown),
        loading: () => _StorageData(null, breakdown),
        error: (_, __) => Column(
          children: [
            _StorageData(null, breakdown),
            const SizedBox(height: 8),
            Text(AppStrings.storageUnavailable, style: AppText.caption),
            TextButton(
              onPressed: onRetry,
              child: Text(AppStrings.retry, style: AppText.linkAccent),
            ),
          ],
        ),
      ),
    );
  }
}

class _Segment {
  const _Segment(this.label, this.bytes, this.color);

  final String label;
  final int bytes;
  final Color color;
}

class _StorageData extends StatelessWidget {
  const _StorageData(this.storage, this.breakdown);

  /// null khi đang tải hoặc không đọc được dung lượng.
  final DeviceStorage? storage;
  final StorageBreakdown? breakdown;

  @override
  Widget build(BuildContext context) {
    final s = storage;
    final used = s == null ? null : splitBytes(s.usedBytes);
    final fraction = s?.usedFraction ?? 0;
    final percent = (fraction * 100).round();
    final b = breakdown;

    // Có breakdown: 3 đoạn (ảnh, video, ảnh chụp màn hình). Chưa có: 2 đoạn Used/Free.
    final segments = b != null
        ? [
            _Segment(AppStrings.legendPhotos, b.photosBytes,
                AppColors.breakdownPhotos),
            _Segment(AppStrings.legendVideos, b.videosBytes,
                AppColors.breakdownVideos),
            _Segment(AppStrings.screenshots, b.screenshotsBytes,
                AppColors.breakdownScreenshots),
          ]
        : [
            _Segment(AppStrings.legendUsed, s?.usedBytes ?? 0,
                AppColors.accentDeep),
            _Segment(
                AppStrings.legendFree, s?.freeBytes ?? 0, AppColors.chip),
          ];

    final labelStyle = AppText.custom(
        11, FontWeight.w600, AppColors.textSecondary,
        lineHeight: 14);
    final smallBlue =
        AppText.custom(11, FontWeight.w600, AppColors.textBlue, lineHeight: 14);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 8,
                        height: 8,
                        decoration: const BoxDecoration(
                          color: AppColors.accentDeep,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(AppStrings.systemCapacity, style: labelStyle),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    textBaseline: TextBaseline.alphabetic,
                    children: [
                      _CountText(
                        bytes: s?.usedBytes,
                        pick: (b) => splitBytes(b).value,
                        fallback: '—',
                        style: AppText.custom(
                            50, FontWeight.w700, AppColors.titleInk,
                            lineHeight: 52, letterSpacing: -1.1),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        used?.unit ?? 'GB',
                        style: AppText.custom(
                            20, FontWeight.w600, AppColors.textSecondary,
                            lineHeight: 26, letterSpacing: -0.3),
                      ),
                      const SizedBox(width: 8),
                      Flexible(
                        child: Text(
                          s == null ? '' : '/ ${formatBytes(s.totalBytes)}',
                          overflow: TextOverflow.ellipsis,
                          style: AppText.custom(
                              14, FontWeight.w400, AppColors.textBlue,
                              lineHeight: 20),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 16),
            SizedBox(
              width: 70,
              height: 70,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  CustomPaint(
                    size: const Size(70, 70),
                    painter: _GaugePainter(fraction),
                  ),
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _CountText(
                        bytes: s == null ? null : percent,
                        pick: (v) => '$v%',
                        fallback: '—',
                        style: AppText.custom(
                            14, FontWeight.w700, AppColors.titleInk,
                            lineHeight: 14),
                      ),
                      const SizedBox(height: 2),
                      Text(AppStrings.used, style: smallBlue),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              AppStrings.storageDistribution,
              style: AppText.custom(14, FontWeight.w500, AppColors.titleInk,
                  lineHeight: 20),
            ),
            if (s != null)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: AppColors.chip,
                  borderRadius: BorderRadius.circular(9999),
                ),
                child: Text(
                  AppStrings.freeHeadroom(formatBytes(s.freeBytes)),
                  style: AppText.custom(
                      11, FontWeight.w500, AppColors.accentDeep,
                      lineHeight: 14),
                ),
              ),
          ],
        ),
        const SizedBox(height: 8),
        _Distribution(
          segments: segments,
          total: b?.totalBytes ?? s?.totalBytes ?? 0,
          hasData: s != null,
        ),
      ],
    );
  }
}

/// Vòng đo dung lượng: nền #ECECFE, phần đã dùng #443E9D, bắt đầu từ đỉnh.
class _GaugePainter extends CustomPainter {
  const _GaugePainter(this.fraction);

  final double fraction;

  @override
  void paint(Canvas canvas, Size size) {
    const stroke = 6.0;
    final rect = Offset.zero & size;
    final arc = rect.deflate(stroke / 2);
    final track = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke
      ..color = AppColors.chip;
    canvas.drawArc(arc, 0, math.pi * 2, false, track);
    if (fraction <= 0) return;
    final progress = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke
      ..strokeCap = StrokeCap.round
      ..color = AppColors.accentDeep;
    canvas.drawArc(arc, -math.pi / 2,
        math.pi * 2 * fraction.clamp(0.0, 1.0), false, progress);
  }

  @override
  bool shouldRepaint(_GaugePainter old) => old.fraction != fraction;
}

/// Thanh phân bổ + chú giải. Chạm một mục để làm nổi đoạn tương ứng, chạm lại
/// để bỏ chọn.
class _Distribution extends StatefulWidget {
  const _Distribution({
    required this.segments,
    required this.total,
    required this.hasData,
  });

  final List<_Segment> segments;
  final int total;
  final bool hasData;

  @override
  State<_Distribution> createState() => _DistributionState();
}

class _DistributionState extends State<_Distribution> {
  int? _selected;

  void _pick(int i) => setState(() => _selected = _selected == i ? null : i);

  @override
  Widget build(BuildContext context) {
    final segs = widget.segments;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          height: 10,
          decoration: BoxDecoration(
            color: AppColors.chip,
            borderRadius: BorderRadius.circular(9999),
          ),
          clipBehavior: Clip.antiAlias,
          child: LayoutBuilder(
            builder: (context, c) => TweenAnimationBuilder<double>(
              tween: Tween(begin: 0, end: 1),
              duration: const Duration(milliseconds: 800),
              curve: Curves.easeOutCubic,
              builder: (context, v, _) => Row(
                children: [
                  for (final (i, seg) in segs.indexed)
                    AnimatedOpacity(
                      duration: const Duration(milliseconds: 220),
                      opacity: _selected == null || _selected == i ? 1 : 0.28,
                      child: Container(
                        width: widget.total <= 0
                            ? 0
                            : math.max(
                                0.0, c.maxWidth * v * seg.bytes / widget.total - 2),
                        margin: const EdgeInsets.only(right: 2),
                        color: seg.color,
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            for (final (i, seg) in segs.indexed)
              Expanded(
                child: Semantics(
                  button: true,
                  selected: _selected == i,
                  label: seg.label,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(8),
                    onTap: () => _pick(i),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: _selected == i
                            ? AppColors.chip
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: _Legend(
                        color: seg.color,
                        label: seg.label,
                        value: widget.hasData ? formatBytes(seg.bytes) : '—',
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ],
    );
  }
}

class _Legend extends StatelessWidget {
  const _Legend({
    required this.color,
    required this.label,
    required this.value,
  });

  final Color color;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 6,
              height: 6,
              decoration: BoxDecoration(color: color, shape: BoxShape.circle),
            ),
            const SizedBox(width: 4),
            Text(
              label,
              style: AppText.custom(11, FontWeight.w600, AppColors.textBlue,
                  lineHeight: 14),
            ),
          ],
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: AppText.custom(12, FontWeight.w600, AppColors.titleInk,
              lineHeight: 16),
        ),
      ],
    );
  }
}

/// Số đếm lên từ 0 tới [bytes] (hoặc giá trị nguyên) khi xuất hiện hoặc đổi.
class _CountText extends StatelessWidget {
  const _CountText({
    required this.bytes,
    required this.pick,
    required this.fallback,
    required this.style,
  });

  final int? bytes;
  final String Function(int value) pick;
  final String fallback;
  final TextStyle style;

  @override
  Widget build(BuildContext context) {
    final v = bytes;
    if (v == null) return Text(fallback, style: style);
    if (MediaQuery.maybeDisableAnimationsOf(context) ?? false) {
      return Text(pick(v), style: style);
    }
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: v.toDouble()),
      duration: const Duration(milliseconds: 1000),
      curve: Curves.easeOutCubic,
      builder: (context, value, _) =>
          Text(pick(value.round()), style: style),
    );
  }
}

// ───────────────────────── Scan button & notifications ─────────────────────────

class _ScanButton extends StatefulWidget {
  const _ScanButton({required this.scanning, required this.onTap});

  final bool scanning;
  final VoidCallback onTap;

  @override
  State<_ScanButton> createState() => _ScanButtonState();
}

class _ScanButtonState extends State<_ScanButton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 4200),
  );

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final reduce = MediaQuery.maybeDisableAnimationsOf(context) ?? false;
    if (reduce) {
      _c.stop();
    } else if (!_c.isAnimating) {
      _c.repeat();
    }
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        PrimaryButton(
          label: AppStrings.scanForJunk,
          height: 58,
          radius: 9999,
          isLoading: widget.scanning,
          leading:
              const AppSvg(AppAssets.scanTarget, size: 18, color: Colors.white),
          labelStyle: AppText.custom(14, FontWeight.w600, Colors.white,
              lineHeight: 18, letterSpacing: 0.14),
          shadows: const [
            BoxShadow(
              color: Color(0x59111827),
              blurRadius: 12,
              offset: Offset(0, 8),
            ),
          ],
          onPressed: widget.onTap,
        ),
        if (!widget.scanning)
          Positioned.fill(
            child: IgnorePointer(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(9999),
                child: AnimatedBuilder(
                  animation: _c,
                  builder: (context, _) {
                    // Quét ngang trong 38% đầu chu kỳ, nghỉ phần còn lại.
                    final t = (_c.value / 0.38).clamp(0.0, 1.0);
                    return LayoutBuilder(
                      builder: (context, box) => Transform.translate(
                        offset: Offset(-80 + (box.maxWidth + 160) * t, 0),
                        child: Align(
                          alignment: Alignment.centerLeft,
                          child: Transform(
                            transform: Matrix4.skewX(-0.3),
                            child: Container(
                              width: 60,
                              decoration: const BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [
                                    Color(0x00FFFFFF),
                                    Color(0x59FFFFFF),
                                    Color(0x00FFFFFF),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
          ),
      ],
    );
  }
}

class _NotificationsRow extends StatelessWidget {
  const _NotificationsRow({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: AppStrings.recentNotifications,
      excludeSemantics: true,
      child: Material(
        color: AppColors.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
          side: const BorderSide(color: AppColors.borderNeutral),
        ),
        child: InkWell(
          borderRadius: BorderRadius.circular(18),
          onTap: onTap,
          child: SizedBox(
            height: 50,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 28,
                        height: 28,
                        decoration: const BoxDecoration(
                          color: AppColors.chip,
                          shape: BoxShape.circle,
                        ),
                        child: const Center(
                          child: AppSvg(
                            AppAssets.bell,
                            size: 14.67,
                            color: AppColors.accentDeep,
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Text(
                        AppStrings.recentNotifications,
                        style: AppText.custom(
                            14, FontWeight.w600, AppColors.accentDeep,
                            lineHeight: 20),
                      ),
                    ],
                  ),
                  const AppSvg(
                    AppAssets.chevronRight,
                    size: 10.67,
                    color: AppColors.titleInk,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ───────────────────────── Cards ─────────────────────────

class _IconCircle extends StatelessWidget {
  const _IconCircle({
    required this.icon,
    required this.size,
    required this.iconSize,
    this.color = AppColors.iconTile,
  });

  final String icon;
  final double size;
  final double iconSize;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(color: color, shape: BoxShape.circle),
      child: Center(
        child: AppSvg(icon, size: iconSize, color: AppColors.accentDeep),
      ),
    );
  }
}

class _Pill extends StatelessWidget {
  const _Pill(this.text, {required this.style, required this.padding});

  final String text;
  final TextStyle style;
  final EdgeInsets padding;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: AppColors.chip,
        borderRadius: BorderRadius.circular(9999),
      ),
      child: Text(text, style: style),
    );
  }
}

class _DuplicatesCard extends StatelessWidget {
  const _DuplicatesCard({required this.result, required this.onReview});

  /// null khi chưa quét lần nào.
  final ScanResult? result;
  final VoidCallback onReview;

  @override
  Widget build(BuildContext context) {
    final groups = result?.allGroups ?? const <MediaGroup>[];
    final shown = groups.take(3).toList();
    final more = groups.length - shown.length;

    final Widget body;
    if (result == null) {
      body = Text(AppStrings.noScanYet, style: AppText.caption);
    } else if (groups.isEmpty) {
      body = Text(AppStrings.noDuplicatesFound, style: AppText.caption);
    } else {
      body = Row(
        children: [
          for (var i = 0; i < 3; i++) ...[
            if (i > 0) const SizedBox(width: 10),
            Expanded(
              child: i < shown.length
                  ? FadeSlideIn(
                      delay: Duration(milliseconds: 150 + i * 110),
                      dy: 0,
                      scaleFrom: 0.92,
                      child: _GroupThumb(group: shown[i]),
                    )
                  : const SizedBox(height: 84),
            ),
          ],
          if (more > 0) ...[
            const SizedBox(width: 10),
            Expanded(child: _MoreTile(text: AppStrings.moreSets(more))),
          ],
        ],
      );
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: _cardDecoration(22),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Row(
                  children: [
                    const _IconCircle(
                        icon: AppAssets.image, size: 40, iconSize: 18.33),
                    const SizedBox(width: 12),
                    Flexible(
                      child: Text(
                        AppStrings.duplicatePhotos,
                        overflow: TextOverflow.ellipsis,
                        style: AppText.custom(
                            18, FontWeight.w600, AppColors.titleInk,
                            lineHeight: 24),
                      ),
                    ),
                  ],
                ),
              ),
              if (groups.isNotEmpty)
                InkWell(
                  borderRadius: BorderRadius.circular(9999),
                  onTap: onReview,
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 16, vertical: 7),
                    decoration: BoxDecoration(
                      color: AppColors.primary,
                      borderRadius: BorderRadius.circular(9999),
                    ),
                    child: Text(
                      AppStrings.review,
                      style: AppText.custom(12, FontWeight.w600, Colors.white,
                          lineHeight: 16),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),
          body,
        ],
      ),
    );
  }
}

class _GroupThumb extends StatelessWidget {
  const _GroupThumb({required this.group});

  final MediaGroup group;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        MediaThumbnail(id: group.keeper.id, height: 84, radius: 14),
        Positioned(
          right: 4,
          bottom: 4,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            decoration: BoxDecoration(
              color: const Color(0xB3191B27),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              '${group.items.length}x',
              style: AppText.custom(9, FontWeight.w400, Colors.white,
                  lineHeight: 13.5),
            ),
          ),
        ),
      ],
    );
  }
}

class _MoreTile extends StatelessWidget {
  const _MoreTile({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 84,
      decoration: BoxDecoration(
        color: AppColors.chip,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const AppSvg(
            AppAssets.moreHorizontal,
            width: 12,
            height: 3,
            color: AppColors.textBlue,
          ),
          const SizedBox(height: 4),
          Text(
            text,
            style: AppText.custom(11, FontWeight.w600, AppColors.textBlue,
                lineHeight: 14),
          ),
        ],
      ),
    );
  }
}

class _TappableCard extends StatelessWidget {
  const _TappableCard({
    required this.onTap,
    required this.semanticLabel,
    required this.radius,
    required this.child,
  });

  final VoidCallback onTap;
  final String semanticLabel;
  final double radius;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: semanticLabel,
      child: Material(
        color: Colors.transparent,
        child: Ink(
          decoration: _cardDecoration(radius),
          child: InkWell(
            borderRadius: BorderRadius.circular(radius),
            onTap: onTap,
            child: Padding(padding: const EdgeInsets.all(16), child: child),
          ),
        ),
      ),
    );
  }
}

/// Thẻ vuông của hàng hai cột: icon + phụ kiện, tiêu đề lớn, link dưới đáy.
class _SquareCard extends StatelessWidget {
  const _SquareCard({
    required this.onTap,
    required this.label,
    required this.icon,
    required this.iconSize,
    required this.accessory,
    required this.linkText,
    required this.linkColor,
  });

  final VoidCallback onTap;
  final String label;
  final String icon;
  final double iconSize;
  final Widget accessory;
  final String linkText;
  final Color linkColor;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: label,
      child: Material(
        color: Colors.transparent,
        child: Ink(
          decoration: _cardDecoration(24),
          child: InkWell(
            borderRadius: BorderRadius.circular(20),
            onTap: onTap,
            child: ConstrainedBox(
              constraints: const BoxConstraints(minHeight: 156),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        _IconCircle(icon: icon, size: 32, iconSize: iconSize),
                        accessory,
                      ],
                    ),
                    const SizedBox(height: 14),
                    Text(
                      label,
                      style: AppText.custom(
                          19, FontWeight.w700, AppColors.titleInk,
                          lineHeight: 26, letterSpacing: -0.3),
                    ),
                    const SizedBox(height: 20),
                    Row(
                      children: [
                        Text(
                          linkText,
                          style: AppText.custom(11, FontWeight.w600, linkColor,
                              lineHeight: 14),
                        ),
                        const SizedBox(width: 8),
                        AppSvg(AppAssets.arrowRight, size: 12, color: linkColor),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _LargeFilesCard extends StatelessWidget {
  const _LargeFilesCard({required this.threshold, required this.onTap});

  final int threshold;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return _SquareCard(
      onTap: onTap,
      label: AppStrings.largeFiles,
      icon: AppAssets.folderPlus,
      iconSize: 15,
      accessory: Flexible(
        child: _Pill(
          AppStrings.filterLabel(formatBytes(threshold)),
          style: AppText.custom(10.5, FontWeight.w600, AppColors.textBlue,
              lineHeight: 14),
          padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
        ),
      ),
      linkText: AppStrings.inspect,
      linkColor: AppColors.accentDeep,
    );
  }
}

class _AppManagerCard extends StatelessWidget {
  const _AppManagerCard({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return _SquareCard(
      onTap: onTap,
      label: AppStrings.appManager,
      icon: AppAssets.gridDots,
      iconSize: 14,
      accessory: Container(
        width: 8,
        height: 8,
        decoration: const BoxDecoration(
          color: AppColors.alertDot,
          shape: BoxShape.circle,
        ),
      ),
      linkText: AppStrings.cleanUp,
      linkColor: AppColors.reviewLink,
    );
  }
}

class _WideLinkCard extends StatelessWidget {
  const _WideLinkCard({
    required this.onTap,
    required this.title,
    required this.subtitle,
    required this.icon,
  });

  final VoidCallback onTap;
  final String title;
  final String subtitle;
  final String icon;

  @override
  Widget build(BuildContext context) {
    return _TappableCard(
      onTap: onTap,
      semanticLabel: title,
      radius: 22,
      child: Row(
        children: [
          _IconCircle(icon: icon, size: 36, iconSize: 16),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: AppText.custom(
                      16, FontWeight.w500, AppColors.titleInk,
                      lineHeight: 24),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: AppText.custom(
                      14, FontWeight.w400, AppColors.textBlue,
                      lineHeight: 20),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Container(
            width: 36,
            height: 36,
            decoration: const BoxDecoration(
              color: AppColors.primary,
              shape: BoxShape.circle,
            ),
            child: const Center(
              child: AppSvg(AppAssets.arrowUpRight, size: 14, color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }
}

import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/l10n/app_strings.dart';
import '../../../core/router/app_routes.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text.dart';
import '../../../core/theme/app_tokens.dart';
import '../../../core/utils/format_bytes.dart';
import '../../../core/widgets/app_bottom_nav.dart';
import '../../../core/widgets/fade_slide_in.dart';
import '../../../core/widgets/primary_button.dart';
import '../../../core/widgets/tab_scaffold.dart';
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

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final storage = ref.watch(deviceStorageProvider);
    final breakdown = ref.watch(storageBreakdownProvider);
    // select: chỉ rebuild khi đúng giá trị này đổi, không rebuild theo từng tiến trình quét.
    final scanning = ref.watch(
        scanControllerProvider.select((s) => s.phase == ScanPhase.running));
    final result =
        ref.watch(scanControllerProvider.select((s) => s.outcome?.result));
    void scanNow() {
      if (!scanning) startScanFlow(context, ref);
    }

    return TabScaffold(
      key: pageKey,
      current: AppTab.home,
      onScan: scanNow,
      body: SingleChildScrollView(
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
              child: _ReclaimCard(
                result: result,
                scanning: scanning,
                storage: storage.valueOrNull,
                onScan: scanNow,
                onReview: () => context.push(AppRoutes.duplicates),
              ),
            ),
            const SizedBox(height: 16),
            FadeSlideIn(
              delay: const Duration(milliseconds: 120),
              child: _StorageCard(
                storage: storage,
                breakdown: breakdown,
                onRetry: () => ref.invalidate(deviceStorageProvider),
              ),
            ),
            const SizedBox(height: 16),
            FadeSlideIn(
              delay: const Duration(milliseconds: 180),
              child: _ShortcutRow(
                onLargeFiles: () => context.push(AppRoutes.largeFiles),
                onAppManager: () => context.push(AppRoutes.appManager),
                onNotifications: () => context.push(AppRoutes.notifications),
              ),
            ),
            const SizedBox(height: 16),
            FadeSlideIn(
              delay: const Duration(milliseconds: 150),
              child: _DuplicatesSection(
                result: result,
                onReview: () => context.push(AppRoutes.duplicates),
                onLargeFiles: () => context.push(AppRoutes.largeFiles),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ───────────────────────── Storage card ─────────────────────────

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
      decoration: BoxDecoration(
        color: context.tokens.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: context.tokens.border),
        boxShadow: const [
          BoxShadow(
            color: Color(0x2E111827),
            blurRadius: 32,
            spreadRadius: -12,
            offset: Offset(0, 18),
          ),
        ],
      ),
      child: storage.when(
        data: (s) => _StorageData(s, breakdown),
        loading: () => _StorageData(null, breakdown),
        error: (_, __) => Column(
          children: [
            _StorageData(null, breakdown),
            const SizedBox(height: 8),
            Text(
              AppStrings.storageUnavailable,
              style: AppText.custom(12, FontWeight.w400, context.tokens.textMuted),
            ),
            TextButton(
              onPressed: onRetry,
              child: Text(
                AppStrings.retry,
                style: AppText.custom(13, FontWeight.w600, context.tokens.textPrimary,
                    lineHeight: 20),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Segment {
  const _Segment(this.label, this.bytes, this.color, {this.gradient});

  final String label;
  final int bytes;
  final Color color;

  /// Khi có, đoạn này tô dải nhiều màu thay vì một màu.
  final Gradient? gradient;
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
            _Segment(
              AppStrings.legendUsed,
              s?.usedBytes ?? 0,
              AppColors.breakdownPhotos,
              gradient: const LinearGradient(
                colors: [
                  AppColors.breakdownPhotos,
                  AppColors.breakdownScreenshots,
                  AppColors.breakdownVideos,
                ],
              ),
            ),
            _Segment(AppStrings.legendFree, s?.freeBytes ?? 0,
                context.tokens.chip),
          ];

    final labelStyle = AppText.custom(
        11, FontWeight.w600, context.tokens.textMuted,
        lineHeight: 14);
    final smallMuted = AppText.custom(
        11, FontWeight.w600, context.tokens.textMuted,
        lineHeight: 14);

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
                        decoration: BoxDecoration(
                          color: context.tokens.textPrimary,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(AppStrings.systemCapacity, style: labelStyle),
                    ],
                  ),
                  const SizedBox(height: 6),
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.centerLeft,
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      textBaseline: TextBaseline.alphabetic,
                      children: [
                        _CountText(
                          bytes: s?.usedBytes,
                          pick: (b) => splitBytes(b).value,
                          fallback: '—',
                          style: AppText.custom(
                              50, FontWeight.w700, context.tokens.textPrimary,
                              lineHeight: 52, letterSpacing: -1.1),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          used?.unit ?? 'GB',
                          style: AppText.custom(
                              20, FontWeight.w600, context.tokens.textSecondary,
                              lineHeight: 26, letterSpacing: -0.3),
                        ),
                        if (s != null) ...[
                          const SizedBox(width: 8),
                          Text(
                            '/ ${formatBytes(s.totalBytes)}',
                            style: AppText.custom(
                                14, FontWeight.w400, context.tokens.textMuted,
                                lineHeight: 20),
                          ),
                        ],
                      ],
                    ),
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
                    painter: _GaugePainter(
                      fraction,
                      track: context.tokens.chip,
                      ink: context.tokens.textPrimary,
                    ),
                  ),
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _CountText(
                        bytes: s == null ? null : percent,
                        pick: (v) => '$v%',
                        fallback: '—',
                        style: AppText.custom(
                            14, FontWeight.w700, context.tokens.textPrimary,
                            lineHeight: 14),
                      ),
                      const SizedBox(height: 2),
                      Text(AppStrings.used, style: smallMuted),
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
              style: AppText.custom(14, FontWeight.w500, context.tokens.textPrimary,
                  lineHeight: 20),
            ),
            if (s != null)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: context.tokens.chip,
                  borderRadius: BorderRadius.circular(9999),
                ),
                child: Text(
                  AppStrings.freeHeadroom(formatBytes(s.freeBytes)),
                  style: AppText.custom(
                      11, FontWeight.w500, context.tokens.textSecondary,
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
          onDark: false,
        ),
      ],
    );
  }
}

/// Vòng đo dung lượng: nền #ECECFE, phần đã dùng #443E9D, bắt đầu từ đỉnh.
class _GaugePainter extends CustomPainter {
  const _GaugePainter(this.fraction, {required this.track, required this.ink});

  final double fraction;
  final Color track;
  final Color ink;

  @override
  void paint(Canvas canvas, Size size) {
    const stroke = 6.0;
    final rect = Offset.zero & size;
    final arc = rect.deflate(stroke / 2);
    final trackPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke
      ..color = track;
    canvas.drawArc(arc, 0, math.pi * 2, false, trackPaint);
    if (fraction <= 0) return;
    final progress = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke
      ..strokeCap = StrokeCap.round
      ..shader = SweepGradient(
        startAngle: -math.pi / 2,
        endAngle: math.pi * 1.5,
        colors: [ink, ink],
      ).createShader(arc);
    canvas.drawArc(arc, -math.pi / 2, math.pi * 2 * fraction.clamp(0.0, 1.0),
        false, progress);
  }

  @override
  bool shouldRepaint(_GaugePainter old) =>
      old.fraction != fraction || old.track != track || old.ink != ink;
}

/// Thanh phân bổ + chú giải. Chạm một mục để làm nổi đoạn tương ứng, chạm lại
/// để bỏ chọn.
class _Distribution extends StatefulWidget {
  const _Distribution({
    required this.segments,
    required this.total,
    required this.hasData,
    this.onDark = false,
  });

  final List<_Segment> segments;
  final int total;
  final bool hasData;
  final bool onDark;

  @override
  State<_Distribution> createState() => _DistributionState();
}

class _DistributionState extends State<_Distribution> {
  int? _selected;

  void _pick(int i) {
    HapticFeedback.selectionClick();
    setState(() => _selected = _selected == i ? null : i);
  }

  @override
  Widget build(BuildContext context) {
    final segs = widget.segments;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          height: 10,
          decoration: BoxDecoration(
            color: widget.onDark ? context.tokens.chip : context.tokens.chip,
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
                            : math.max(0.0,
                                c.maxWidth * v * seg.bytes / widget.total - 2),
                        margin: const EdgeInsets.only(right: 2),
                        decoration: BoxDecoration(
                          color: seg.gradient == null ? seg.color : null,
                          gradient: seg.gradient,
                        ),
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
                            ? (widget.onDark
                                ? context.tokens.chip
                                : context.tokens.chip)
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: _Legend(
                        color: seg.color,
                        label: seg.label,
                        value: widget.hasData ? formatBytes(seg.bytes) : '—',
                        onDark: widget.onDark,
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
    this.onDark = false,
  });

  final Color color;
  final String label;
  final String value;
  final bool onDark;

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
              style: AppText.custom(11, FontWeight.w600,
                  onDark ? context.tokens.textMuted : context.tokens.textMuted,
                  lineHeight: 14),
            ),
          ],
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: AppText.custom(12, FontWeight.w600,
              onDark ? context.tokens.textPrimary : context.tokens.textPrimary,
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
      builder: (context, value, _) => Text(pick(value.round()), style: style),
    );
  }
}

// ───────────────────────── Scan button & notifications ─────────────────────────

/// Thẻ vuông của hàng hai cột: icon + phụ kiện, tiêu đề lớn, link dưới đáy.
/// Khối ảnh trùng dưới thẻ dung lượng: thumbnail nhóm lớn nhất và từng loại có thể dọn.
class _DuplicatesSection extends StatelessWidget {
  const _DuplicatesSection({
    required this.result,
    required this.onReview,
    required this.onLargeFiles,
  });

  final ScanResult? result;
  final VoidCallback onReview;
  final VoidCallback onLargeFiles;

  static int _removable(ScanResult r, ScanCategory c) {
    if (c == ScanCategory.duplicates) {
      return r.duplicateGroups.fold(0, (s, g) => s + g.removable.length);
    }
    if (c == ScanCategory.similar) {
      return r.similarGroups.fold(0, (s, g) => s + g.removable.length);
    }
    return r.count(c);
  }

  static VoidCallback? _onTapFor(
      ScanCategory c, VoidCallback onReview, VoidCallback onLargeFiles) {
    if (c == ScanCategory.duplicates || c == ScanCategory.similar) {
      return onReview;
    }
    if (c == ScanCategory.largeVideos) return onLargeFiles;
    return null;
  }

  static IconData _iconFor(ScanCategory c) {
    switch (c) {
      case ScanCategory.duplicates:
        return Icons.copy_all_rounded;
      case ScanCategory.similar:
        return Icons.auto_awesome_motion_outlined;
      case ScanCategory.largeVideos:
        return Icons.movie_outlined;
      case ScanCategory.screenshots:
        return Icons.screenshot_outlined;
    }
  }

  static String _labelFor(ScanCategory c) {
    switch (c) {
      case ScanCategory.duplicates:
        return AppStrings.duplicatePhotos;
      case ScanCategory.similar:
        return AppStrings.similarPhotos;
      case ScanCategory.largeVideos:
        return AppStrings.largeVideos;
      case ScanCategory.screenshots:
        return AppStrings.screenshots;
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final r = result;

    final Widget content;
    if (r == null) {
      content = _hint(AppStrings.noScanYet, t);
    } else if (r.allGroups.isEmpty && r.totalBytes == 0) {
      content = _hint(AppStrings.noDuplicatesFound, t);
    } else {
      final shown = r.allGroups.take(3).toList();
      final rows = <Widget>[];
      for (final c in ScanCategory.values) {
        final n = _removable(r, c);
        if (n == 0) continue;
        if (rows.isNotEmpty) rows.add(Divider(height: 1, color: t.divider));
        rows.add(_CategoryRow(
          icon: _iconFor(c),
          label: _labelFor(c),
          count: n,
          bytes: r.bytes(c),
          onTap: _onTapFor(c, onReview, onLargeFiles),
        ));
      }
      content = Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (shown.isNotEmpty) ...[
            Row(
              children: [
                for (var i = 0; i < 3; i++) ...[
                  if (i > 0) const SizedBox(width: 10),
                  Expanded(
                    child: i < shown.length
                        ? _GroupThumb(group: shown[i])
                        : const SizedBox(height: 96),
                  ),
                ],
              ],
            ),
            const SizedBox(height: 16),
          ],
          ...rows,
        ],
      );
    }

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: t.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: t.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      AppStrings.duplicatePhotos,
                      overflow: TextOverflow.ellipsis,
                      style: AppText.custom(18, FontWeight.w700, t.textPrimary,
                          lineHeight: 24),
                    ),
                    if (r != null && r.totalBytes > 0) ...[
                      const SizedBox(height: 2),
                      Text(
                        AppStrings.freedSize(formatBytes(r.totalBytes)),
                        style: AppText.custom(13, FontWeight.w500, t.textSecondary,
                            lineHeight: 16),
                      ),
                    ],
                  ],
                ),
              ),
              if (r != null && r.allGroups.isNotEmpty)
                Material(
                  color: t.textPrimary,
                  borderRadius: BorderRadius.circular(999),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(999),
                    onTap: onReview,
                    child: Padding(
                      padding:
                          const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      child: Text(
                        AppStrings.review,
                        style: AppText.custom(13, FontWeight.w600, t.surface,
                            lineHeight: 18),
                      ),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 16),
          content,
        ],
      ),
    );
  }

  static Widget _hint(String text, AppTokens t) => Text(
        text,
        style: AppText.custom(13, FontWeight.w400, t.textMuted, lineHeight: 18),
      );
}

/// Một hàng loại: icon trên nền nhẹ, tên, số mục và dung lượng có thể dọn.
class _CategoryRow extends StatelessWidget {
  const _CategoryRow({
    required this.icon,
    required this.label,
    required this.count,
    required this.bytes,
    this.onTap,
  });

  final IconData icon;
  final String label;
  final int count;
  final int bytes;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    return InkWell(
      borderRadius: BorderRadius.circular(14),
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 10),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: t.iconTile,
                borderRadius: BorderRadius.circular(11),
              ),
              child: Icon(icon, size: 18, color: t.textPrimary),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: AppText.custom(14, FontWeight.w600, t.textPrimary,
                        lineHeight: 18),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    AppStrings.itemsCount(count),
                    style: AppText.custom(12, FontWeight.w400, t.textSecondary,
                        lineHeight: 16),
                  ),
                ],
              ),
            ),
            Text(
              formatBytes(bytes),
              style: AppText.custom(15, FontWeight.w700, t.textPrimary,
                  lineHeight: 18),
            ),
            if (onTap != null) ...[
              const SizedBox(width: 4),
              Icon(Icons.chevron_right_rounded, size: 20, color: t.textMuted),
            ],
          ],
        ),
      ),
    );
  }
}

/// Thumbnail của nhóm (ảnh giữ lại), bo góc, kèm badge số lượng.
class _GroupThumb extends StatelessWidget {
  const _GroupThumb({required this.group});

  final MediaGroup group;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    return Stack(
      children: [
        MediaThumbnail(id: group.keeper.id, height: 96, radius: 16),
        Positioned.fill(
          child: IgnorePointer(
            child: DecoratedBox(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: t.border),
              ),
            ),
          ),
        ),
        Positioned(
          right: 6,
          bottom: 6,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: const Color(0xB3000000),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              '${group.items.length}x',
              style: AppText.custom(11, FontWeight.w600, Colors.white,
                  lineHeight: 14),
            ),
          ),
        ),
      ],
    );
  }
}

int _reclaimBytes(ScanResult r) =>
    r.allGroups.fold<int>(0, (s, g) => s + g.reclaimableBytes) +
    r.largeVideos.fold<int>(0, (s, v) => s + (v.sizeBytes ?? 0)) +
    r.screenshots.fold<int>(0, (s, v) => s + (v.sizeBytes ?? 0));

int _reclaimCount(ScanResult r) =>
    r.allGroups.fold<int>(0, (s, g) => s + g.removable.length) +
    r.largeVideos.length +
    r.screenshots.length;

/// Hero: dung lượng có thể dọn, một hành động chính theo trạng thái, và thanh dung lượng đã dùng.
class _ReclaimCard extends StatelessWidget {
  const _ReclaimCard({
    required this.result,
    required this.scanning,
    required this.storage,
    required this.onScan,
    required this.onReview,
  });

  final ScanResult? result;
  final bool scanning;
  final DeviceStorage? storage;
  final VoidCallback onScan;
  final VoidCallback onReview;

  @override
  Widget build(BuildContext context) {
    final r = result;
    final String value;
    final String caption;
    final String action;
    final VoidCallback? onTap;
    if (scanning) {
      value = '…';
      caption = AppStrings.reclaimScanningBody;
      action = AppStrings.reclaimStartScan;
      onTap = null;
    } else if (r == null) {
      value = '—';
      caption = AppStrings.reclaimNotScannedBody;
      action = AppStrings.reclaimStartScan;
      onTap = onScan;
    } else if (_reclaimCount(r) == 0) {
      value = formatBytes(0);
      caption = AppStrings.reclaimNothingBody;
      action = AppStrings.reclaimScanAgain;
      onTap = onScan;
    } else {
      value = formatBytes(_reclaimBytes(r));
      caption = AppStrings.reclaimItemsReady(_reclaimCount(r));
      action = AppStrings.reclaimReview;
      onTap = onReview;
    }

    final used = (storage?.usedFraction ?? 0).clamp(0.0, 1.0).toDouble();
    final s = storage;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: AppColors.heroGradient,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.heroBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            AppStrings.reclaimLabel.toUpperCase(),
            style: AppText.custom(11, FontWeight.w600, AppColors.onHeroMuted,
                letterSpacing: 0.8),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: AppText.custom(32, FontWeight.w700, AppColors.onHero,
                lineHeight: 36, letterSpacing: -0.8),
          ),
          const SizedBox(height: 4),
          Text(
            caption,
            style: AppText.custom(12, FontWeight.w400, AppColors.onHeroSecondary,
                lineHeight: 16),
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: LinearProgressIndicator(
              value: used,
              minHeight: 4,
              backgroundColor: AppColors.heroTrack,
              valueColor: const AlwaysStoppedAnimation<Color>(AppColors.heroAccent),
            ),
          ),
          const SizedBox(height: 6),
          if (s != null)
            Text(
              AppStrings.storageUsedOf(formatBytes(s.usedBytes), formatBytes(s.totalBytes)),
              style: AppText.custom(11, FontWeight.w500, AppColors.onHeroMuted),
            ),
          const SizedBox(height: 12),
          PrimaryButton(
            label: action,
            height: 40,
            radius: 12,
            isLoading: scanning,
            onPressed: onTap,
            color: Colors.white,
            labelStyle: AppText.custom(14, FontWeight.w600, AppColors.primary),
          ),
        ],
      ),
    );
  }
}

/// Hàng lối tắt gọn cho các màn phụ.
class _ShortcutRow extends StatelessWidget {
  const _ShortcutRow({
    required this.onLargeFiles,
    required this.onAppManager,
    required this.onNotifications,
  });

  final VoidCallback onLargeFiles;
  final VoidCallback onAppManager;
  final VoidCallback onNotifications;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _ShortcutTile(
            icon: Icons.movie_outlined,
            label: AppStrings.largeFiles,
            onTap: onLargeFiles,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _ShortcutTile(
            icon: Icons.apps_rounded,
            label: AppStrings.appManager,
            onTap: onAppManager,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _ShortcutTile(
            icon: Icons.notifications_none_rounded,
            label: AppStrings.shortcutNotifications,
            onTap: onNotifications,
          ),
        ),
      ],
    );
  }
}

class _ShortcutTile extends StatelessWidget {
  const _ShortcutTile({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: context.tokens.surface,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: context.tokens.border),
          ),
          child: Column(
            children: [
              Icon(icon, size: 22, color: context.tokens.textPrimary),
              const SizedBox(height: 8),
              Text(
                label,
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppText.custom(
                    12, FontWeight.w600, context.tokens.textSecondary),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/router/app_routes.dart';
import '../../../core/theme/app_assets.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/format_bytes.dart';
import '../../../core/widgets/app_svg.dart';
import '../../../core/widgets/ring_chart.dart';
import '../../scan/application/scan_controller.dart';
import '../../scan/application/scan_providers.dart';
import '../../scan/domain/device_storage.dart';
import '../../scan/domain/scan_models.dart';
import '../../../core/theme/app_tokens.dart';

const _ink = Color(0xFF181818);
const _muted = Color(0xFF727272);

/// Storage Analysis (Figma 127:1682). Chỉ hiện số liệu có thật: dung lượng
/// máy, phân bổ ảnh/video khi đã quét, và gợi ý từ kết quả quét.
class StorageAnalysisPage extends ConsumerWidget {
  const StorageAnalysisPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final storage = ref.watch(deviceStorageProvider);
    final breakdown = ref.watch(storageBreakdownProvider);
    final result =
        ref.watch(scanControllerProvider.select((s) => s.outcome?.result));
    final dupBytes = result == null
        ? 0
        : result.bytes(ScanCategory.duplicates) +
            result.bytes(ScanCategory.similar);
    final DeviceStorage? device = storage.whenOrNull(data: (s) => s);

    return Scaffold(
      backgroundColor: context.tokens.surface,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            _TopBar(
              title: 'Storage Analysis',
              onBack: () => context.canPop()
                  ? context.pop()
                  : context.go(AppRoutes.storage),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(20, 6, 20, 24),
                children: [
                  if (device != null)
                    _SummaryCard(device: device)
                  else if (storage.hasError)
                    const _Note('Storage information isn’t available.')
                  else
                    const SizedBox(
                      height: 112,
                      child: Center(
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                    ),
                  const SizedBox(height: 18),
                  _Breakdown(device: device, breakdown: breakdown),
                  if (dupBytes > 0) ...[
                    const SizedBox(height: 18),
                    _Insight(bytes: dupBytes),
                  ],
                ],
              ),
            ),
            _StickyBar(
              onTap: () => context.push(AppRoutes.fileSearch),
            ),
          ],
        ),
      ),
    );
  }
}

class _TopBar extends StatelessWidget {
  const _TopBar({required this.title, required this.onBack});

  final String title;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 8),
      child: Row(
        children: [
          GestureDetector(
            onTap: onBack,
            child: SizedBox(
              width: 32,
              height: 32,
              child: Center(
                child: AppSvg(AppAssets.chevronLeft, size: 23, color: context.tokens.textPrimary),
              ),
            ),
          ),
          Expanded(
            child: Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: _ink,
              ),
            ),
          ),
          const SizedBox(width: 32),
        ],
      ),
    );
  }
}

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({required this.device});

  final DeviceStorage device;

  @override
  Widget build(BuildContext context) {
    final total = splitBytes(device.totalBytes);
    final used = splitBytes(device.usedBytes);
    final free = splitBytes(device.freeBytes);
    final fraction = device.totalBytes == 0
        ? 0.0
        : (device.usedBytes / device.totalBytes).clamp(0.0, 1.0).toDouble();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: context.tokens.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: context.tokens.border),
        boxShadow: const [
          BoxShadow(
            color: Color(0x08181818),
            blurRadius: 10,
            offset: Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text.rich(
                  TextSpan(
                    children: [
                      TextSpan(
                        text: '${total.value} ${total.unit}',
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: _ink,
                        ),
                      ),
                      TextSpan(
                        text: ' Total Storage',
                        style: TextStyle(fontSize: 13, color: context.tokens.textSecondary),
                      ),
                    ],
                  ),
                ),
              ),
              Text(
                'ON THIS DEVICE',
                style: TextStyle(fontSize: 10, color: context.tokens.textSecondary),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Expanded(
                child: Text.rich(
                  TextSpan(
                    children: [
                      TextSpan(
                        text: used.value,
                        style: const TextStyle(
                          fontSize: 23,
                          fontWeight: FontWeight.w700,
                          color: _ink,
                        ),
                      ),
                      TextSpan(
                        text: ' ${used.unit} Used',
                        style: TextStyle(fontSize: 12, color: context.tokens.textSecondary),
                      ),
                    ],
                  ),
                ),
              ),
              Text.rich(
                TextSpan(
                  children: [
                    TextSpan(
                      text: '${free.value} ${free.unit}',
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: _ink,
                      ),
                    ),
                    TextSpan(
                      text: ' Available',
                      style: TextStyle(fontSize: 11, color: context.tokens.textSecondary),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(100),
            child: LinearProgressIndicator(
              value: fraction,
              minHeight: 6,
              backgroundColor: context.tokens.iconTile,
              color: _ink,
            ),
          ),
        ],
      ),
    );
  }
}

class _Breakdown extends StatelessWidget {
  const _Breakdown({required this.device, required this.breakdown});

  final DeviceStorage? device;
  final StorageBreakdown? breakdown;

  @override
  Widget build(BuildContext context) {
    final used = device?.usedBytes ?? 0;
    final total = device?.totalBytes ?? 0;
    final percent = total == 0 ? 0 : (used * 100 / total).round();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Storage breakdown',
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w700,
            color: _ink,
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            RingChart(
                size: 148,
                segments: [
                  RingSegment(used.toDouble(), _ink),
                ],
                total: total.toDouble(),
                trackColor: context.tokens.iconTile,
                center: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      '$percent%',
                      style: const TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.w700,
                        color: _ink,
                      ),
                    ),
                    Text(
                      'Used',
                      style: TextStyle(fontSize: 12, color: context.tokens.textSecondary),
                    ),
                  ],
                ),
              ),
            const SizedBox(width: 12),
            Expanded(
              child: breakdown == null
                  ? Text(
                      'Run a scan to see how much space photos and videos use.',
                      style: TextStyle(fontSize: 12, height: 1.4, color: context.tokens.textSecondary),
                    )
                  : Column(
                      children: [
                        _LegendRow(
                          color: AppColors.breakdownPhotos,
                          label: 'Photos',
                          bytes: breakdown!.photosBytes,
                        ),
                        _LegendRow(
                          color: AppColors.breakdownVideos,
                          label: 'Videos',
                          bytes: breakdown!.videosBytes,
                        ),
                        _LegendRow(
                          color: AppColors.breakdownScreenshots,
                          label: 'Screenshots',
                          bytes: breakdown!.screenshotsBytes,
                        ),
                      ],
                    ),
            ),
          ],
        ),
      ],
    );
  }
}

class _LegendRow extends StatelessWidget {
  const _LegendRow({
    required this.color,
    required this.label,
    required this.bytes,
  });

  final Color color;
  final String label;
  final int bytes;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              label,
              style: TextStyle(fontSize: 12, color: context.tokens.textPrimary),
            ),
          ),
          Text(
            formatBytes(bytes),
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: _muted,
            ),
          ),
        ],
      ),
    );
  }
}

class _Insight extends StatelessWidget {
  const _Insight({required this.bytes});

  final int bytes;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
      decoration: BoxDecoration(
        color: context.tokens.surfaceMuted,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFF131313)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.auto_awesome, size: 13, color: context.tokens.textPrimary),
              SizedBox(width: 6),
              Text(
                'SMART INSIGHT',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  color: _ink,
                ),
              ),
            ],
          ),
          const SizedBox(height: 7),
          Text(
            'Duplicate and similar photos use ${formatBytes(bytes)} — you can clean them up right now.',
            style: TextStyle(fontSize: 12, height: 1.35, color: context.tokens.textPrimary),
          ),
          const SizedBox(height: 8),
          GestureDetector(
            onTap: () => context.push(AppRoutes.duplicates),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Review duplicates',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: _ink,
                  ),
                ),
                SizedBox(width: 5),
                AppSvg(AppAssets.arrowRight, size: 12, color: context.tokens.textPrimary),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Note extends StatelessWidget {
  const _Note(this.text);

  final String text;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 16),
        child: Text(text, style: TextStyle(fontSize: 13, color: context.tokens.textSecondary)),
      );
}

class _StickyBar extends StatelessWidget {
  const _StickyBar({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
      decoration: BoxDecoration(
        color: context.tokens.surface,
        border: Border(top: BorderSide(color: context.tokens.border, width: 0.5)),
      ),
      child: Material(
        color: const Color(0xFFBCBCBC),
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: onTap,
          child: SizedBox(
            height: 49,
            width: double.infinity,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.folder_open_outlined, size: 18, color: Colors.white),
                SizedBox(width: 9),
                Text(
                  'Explore Files',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: context.tokens.surface,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

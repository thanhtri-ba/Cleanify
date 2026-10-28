import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text.dart';
import '../../../../core/utils/format_bytes.dart';
import '../../../../core/widgets/app_svg.dart';

/// Số dung lượng lớn kèm đơn vị nhỏ, ví dụ "2.4 GB".
class BigBytes extends StatelessWidget {
  const BigBytes(this.bytes, {super.key});

  final int bytes;

  @override
  Widget build(BuildContext context) {
    final size = splitBytes(bytes);
    return Semantics(
      label: size.toString(),
      excludeSemantics: true,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.baseline,
        textBaseline: TextBaseline.alphabetic,
        children: [
          Text(size.value, style: AppText.bigNumber),
          const SizedBox(width: 6),
          Text(size.unit, style: AppText.bigUnit),
        ],
      ),
    );
  }
}

/// Hàng 2–3 ô số liệu (giá trị + nhãn).
class StatRow extends StatelessWidget {
  const StatRow({super.key, required this.stats});

  final List<({String value, String label})> stats;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        for (var i = 0; i < stats.length; i++) ...[
          if (i > 0) const SizedBox(width: 10),
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
              decoration: BoxDecoration(
                color: AppColors.surfaceTint,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.borderNeutral),
              ),
              child: Column(
                children: [
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(stats[i].value, style: AppText.stat),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    stats[i].label,
                    style: AppText.statLabel,
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ),
        ],
      ],
    );
  }
}

/// Một dòng danh mục: ô icon, tên + mô tả, phần cuối tùy chỉnh.
class CategoryRow extends StatelessWidget {
  const CategoryRow({
    super.key,
    required this.icon,
    required this.title,
    required this.hint,
    required this.trailing,
    this.dimmed = false,
  });

  final String icon;
  final String title;
  final String hint;
  final Widget trailing;
  final bool dimmed;

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: dimmed ? 0.55 : 1,
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: AppColors.categoryTile,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Center(child: AppSvg(icon, size: 20)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: AppText.rowLabel),
                Text(hint, style: AppText.rowHint),
              ],
            ),
          ),
          const SizedBox(width: 8),
          trailing,
        ],
      ),
    );
  }
}

/// Nhãn trạng thái nhỏ ở cuối dòng danh mục.
class StatusText extends StatelessWidget {
  const StatusText(this.text, {super.key, this.color = AppColors.primary});

  final String text;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Text(text, style: AppText.statusLabel.copyWith(color: color));
  }
}

/// Đường kẻ mảnh giữa các dòng trong thẻ.
class RowDivider extends StatelessWidget {
  const RowDivider({super.key});

  @override
  Widget build(BuildContext context) => const Padding(
        padding: EdgeInsets.symmetric(vertical: 12),
        child: Divider(height: 1, thickness: 1, color: AppColors.divider2),
      );
}

/// Dựng danh sách widget xen kẽ [RowDivider].
List<Widget> withDividers(List<Widget> rows) => [
      for (var i = 0; i < rows.length; i++) ...[
        if (i > 0) const RowDivider(),
        rows[i],
      ],
    ];

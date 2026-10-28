import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

/// SVG asset có chỗ trống dự phòng khi file chưa được tải về
/// (chạy `tool/fetch_assets.sh`), nên app và test không bị crash.
class AppSvg extends StatelessWidget {
  const AppSvg(
    this.asset, {
    super.key,
    double? size,
    double? width,
    double? height,
    this.color,
    this.semanticsLabel,
  })  : width = width ?? size,
        height = height ?? size;

  final String asset;
  final double? width;
  final double? height;
  final Color? color;
  final String? semanticsLabel;

  @override
  Widget build(BuildContext context) {
    return SvgPicture.asset(
      asset,
      width: width,
      height: height,
      semanticsLabel: semanticsLabel,
      excludeFromSemantics: semanticsLabel == null,
      colorFilter:
          color == null ? null : ColorFilter.mode(color!, BlendMode.srcIn),
      errorBuilder: (context, error, stackTrace) =>
          SizedBox(width: width, height: height),
    );
  }
}

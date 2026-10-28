import 'package:flutter/foundation.dart';

/// Nội dung hướng dẫn khác nhau giữa iOS và Android.
bool get isIosPlatform => defaultTargetPlatform == TargetPlatform.iOS;

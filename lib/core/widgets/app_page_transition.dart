import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// Chuyển trang mềm: mờ dần kèm trượt nhẹ. Tự tắt khi hệ thống bật
/// "giảm chuyển động" để không gây khó chịu.
CustomTransitionPage<T> fadeSlidePage<T>({
  required LocalKey key,
  required Widget child,
  Offset from = const Offset(0, 0.045),
  Duration duration = const Duration(milliseconds: 320),
}) {
  return CustomTransitionPage<T>(
    key: key,
    child: child,
    transitionDuration: duration,
    reverseTransitionDuration: const Duration(milliseconds: 220),
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
      if (MediaQuery.maybeDisableAnimationsOf(context) ?? false) return child;
      final curved = CurvedAnimation(
        parent: animation,
        curve: Curves.easeOutCubic,
        reverseCurve: Curves.easeInCubic,
      );
      return FadeTransition(
        opacity: curved,
        child: SlideTransition(
          position:
              Tween<Offset>(begin: from, end: Offset.zero).animate(curved),
          child: child,
        ),
      );
    },
  );
}

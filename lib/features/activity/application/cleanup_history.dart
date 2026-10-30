import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/storage/preferences_provider.dart';
import '../domain/cleanup_session.dart';

const _kHistoryKey = 'cleanup_history_v1';
const _kMaxSessions = 200;

/// Lịch sử các lần dọn đã xong, mới nhất đứng đầu. Lưu trong
/// SharedPreferences nên còn sau khi đóng app. Lỗi đọc/ghi không làm hỏng
/// luồng dọn dẹp; khi đó lịch sử chỉ còn trong phiên hiện tại.
class CleanupHistoryNotifier extends Notifier<List<CleanupSession>> {
  @override
  List<CleanupSession> build() {
    try {
      final raw = ref.read(sharedPreferencesProvider).getString(_kHistoryKey);
      if (raw == null || raw.isEmpty) return const [];
      final list = jsonDecode(raw) as List<dynamic>;
      return [
        for (final e in list) CleanupSession.fromJson(e as Map<String, Object?>),
      ];
    } catch (_) {
      return const [];
    }
  }

  void add(CleanupSession session) {
    state = [session, ...state].take(_kMaxSessions).toList();
    _save();
  }

  void _save() {
    try {
      final encoded = jsonEncode([for (final s in state) s.toJson()]);
      ref.read(sharedPreferencesProvider).setString(_kHistoryKey, encoded);
    } catch (_) {
      // Bỏ qua: lịch sử vẫn còn trong bộ nhớ của phiên này.
    }
  }
}

final cleanupHistoryProvider =
    NotifierProvider<CleanupHistoryNotifier, List<CleanupSession>>(
        CleanupHistoryNotifier.new);

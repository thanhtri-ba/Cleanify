import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_assets.dart';
import '../../../core/utils/format_bytes.dart';
import '../../../core/widgets/app_svg.dart';
import '../application/albums_provider.dart';
import '../../../core/theme/app_tokens.dart';

/// App Manager (Figma 127:1788): ảnh/video nhóm theo album nguồn
/// (WhatsApp, Telegram...). Hệ điều hành không cho đọc dung lượng từng app,
/// nên mỗi dòng hiện số mục và tỉ lệ trong thư viện.
class AppManagerPage extends ConsumerStatefulWidget {
  const AppManagerPage({super.key});

  @override
  ConsumerState<AppManagerPage> createState() => _AppManagerPageState();
}

class _AppManagerPageState extends ConsumerState<AppManagerPage> {
  final _search = TextEditingController();
  String _query = '';
  bool _largestFirst = false;

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final albums = ref.watch(albumsProvider);

    return Scaffold(
      backgroundColor: context.tokens.surface,
      body: SafeArea(
        bottom: false,
        child: albums.when<Widget>(
          loading: () => const Center(
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
          error: (_, __) => Center(
            child: TextButton(
              onPressed: () => ref.invalidate(albumsProvider),
              child: const Text('Couldn’t load apps. Tap to retry.'),
            ),
          ),
          data: (list) {
            final total = list.fold<int>(0, (s, a) => s + a.count);
            final q = _query.trim().toLowerCase();
            final ordered = _largestFirst
                ? ([...list]..sort((a, b) => b.count.compareTo(a.count)))
                : list;
            final shown = q.isEmpty
                ? ordered
                : ordered.where((a) => a.name.toLowerCase().contains(q)).toList();

            return ListView(
              padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
              children: [
                Align(
                  alignment: Alignment.centerLeft,
                  child: Material(
                  color: context.tokens.surfaceMuted,
                  shape: const CircleBorder(),
                  child: InkWell(
                    customBorder: const CircleBorder(),
                    onTap: () => Navigator.of(context).maybePop(),
                    child: SizedBox(
                      width: 40,
                      height: 40,
                      child: Icon(Icons.arrow_back_ios_new,
                          size: 16, color: context.tokens.textPrimary),
                    ),
                  ),
                ),
                ),
                const SizedBox(height: 8),
                Text(
                  'App Manager',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.w700,
                    color: context.tokens.textPrimary,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  '${list.length} app albums',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: context.tokens.textSecondary,
                  ),
                ),
                const SizedBox(height: 6),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.baseline,
                  textBaseline: TextBaseline.alphabetic,
                  children: [
                    Text(
                      '$total',
                      style: TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.w700,
                        color: context.tokens.textPrimary,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'photos and videos',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                        color: context.tokens.textSecondary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                _SearchField(
                  controller: _search,
                  onChanged: (v) => setState(() => _query = v),
                  onClear: () {
                    _search.clear();
                    setState(() => _query = '');
                  },
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    _Tab(
                      label: 'All',
                      selected: !_largestFirst,
                      onTap: () => setState(() => _largestFirst = false),
                    ),
                    const SizedBox(width: 8),
                    _Tab(
                      label: 'Largest',
                      selected: _largestFirst,
                      onTap: () => setState(() => _largestFirst = true),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                if (list.isEmpty)
                  const _Note('No app albums found on this device.')
                else if (shown.isEmpty)
                  const _Note('No apps match your search.')
                else
                  for (final a in shown)
                    _AppRow(
                      name: a.name,
                      count: a.count,
                      share: total == 0 ? 0 : a.count / total,
                    ),
                const SizedBox(height: 12),
                const _InfoCard(),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _SearchField extends StatelessWidget {
  const _SearchField({
    required this.controller,
    required this.onChanged,
    required this.onClear,
  });

  final TextEditingController controller;
  final ValueChanged<String> onChanged;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 48,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: context.tokens.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: context.tokens.border),
      ),
      child: Row(
        children: [
          AppSvg(AppAssets.search, size: 20, color: context.tokens.textSecondary),
          const SizedBox(width: 12),
          Expanded(
            child: TextField(
              controller: controller,
              onChanged: onChanged,
              decoration: InputDecoration(
                hintText: 'Search apps',
                hintStyle: TextStyle(color: context.tokens.textMuted, fontSize: 15),
                border: InputBorder.none,
                isCollapsed: true,
              ),
              style: TextStyle(fontSize: 15, color: context.tokens.textPrimary),
            ),
          ),
          if (controller.text.isNotEmpty)
            GestureDetector(
              onTap: onClear,
              child: Icon(Icons.close_rounded,
                  size: 18, color: context.tokens.textSecondary),
            ),
        ],
      ),
    );
  }
}

class _Tab extends StatelessWidget {
  const _Tab({required this.label, required this.selected, required this.onTap});

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? context.tokens.textPrimary : context.tokens.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: selected ? context.tokens.textPrimary : context.tokens.border,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 14,
            fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
            color: selected ? context.tokens.surface : context.tokens.textMuted,
          ),
        ),
      ),
    );
  }
}

class _AppRow extends StatelessWidget {
  const _AppRow({required this.name, required this.count, required this.share});

  final String name;
  final int count;
  final double share;

  @override
  Widget build(BuildContext context) {
    final initial = name.isEmpty ? '?' : name.characters.first.toUpperCase();
    final percent = (share * 100).round();
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: context.tokens.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: context.tokens.border),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: context.tokens.surfaceMuted,
              borderRadius: BorderRadius.circular(12),
            ),
            alignment: Alignment.center,
            child: Text(
              initial,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: context.tokens.textPrimary,
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: context.tokens.textPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '$percent% of your library',
                  style: TextStyle(fontSize: 13, color: context.tokens.textSecondary),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                formatCount(count),
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: context.tokens.textPrimary,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                'items',
                style: TextStyle(fontSize: 12, color: context.tokens.textSecondary),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _InfoCard extends StatelessWidget {
  const _InfoCard();

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(Icons.info_outline_rounded, size: 16, color: context.tokens.textSecondary),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            'Apps don’t report how much space they use, so each row counts the photos and videos saved from that app.',
            style: TextStyle(fontSize: 13, height: 1.5, color: context.tokens.textSecondary),
          ),
        ),
      ],
    );
  }
}

class _Note extends StatelessWidget {
  const _Note(this.text);

  final String text;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 24),
        child: Center(
          child: Text(
            text,
            style: TextStyle(fontSize: 13, color: context.tokens.textSecondary),
          ),
        ),
      );
}

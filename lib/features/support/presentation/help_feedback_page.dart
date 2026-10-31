import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/router/app_routes.dart';
import '../../../core/theme/app_assets.dart';
import '../../../core/theme/app_text.dart';
import '../../../core/widgets/app_svg.dart';
import '../../../core/theme/app_tokens.dart';

const _ink = Color(0xFF181818);

/// Help & Feedback theo Figma 127:2565 và 127:2616 (trạng thái lỗi nhập liệu).
/// Chưa có dịch vụ nhận phản hồi nên Gửi chỉ kiểm tra dữ liệu rồi báo chưa kết nối.
class HelpFeedbackPage extends StatefulWidget {
  const HelpFeedbackPage({super.key});

  @override
  State<HelpFeedbackPage> createState() => _HelpFeedbackPageState();
}

class _HelpFeedbackPageState extends State<HelpFeedbackPage> {
  final _subject = TextEditingController();
  final _message = TextEditingController();
  bool _attempted = false;

  @override
  void initState() {
    super.initState();
    _subject.addListener(_onChanged);
    _message.addListener(_onChanged);
  }

  @override
  void dispose() {
    _subject.dispose();
    _message.dispose();
    super.dispose();
  }

  void _onChanged() => setState(() {});

  String? get _subjectError => _attempted && _subject.text.trim().isEmpty
      ? 'Subject is required.'
      : null;

  String? get _messageError => _attempted && _message.text.trim().isEmpty
      ? 'Message is required.'
      : null;

  void _back() =>
      context.canPop() ? context.pop() : context.go(AppRoutes.settings);

  void _showSnack(String text) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(text)));
  }

  void _send() {
    setState(() => _attempted = true);
    if (_subjectError != null || _messageError != null) return;
    _showSnack('Feedback sending isn’t connected yet.');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.tokens.surfaceMuted,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24, 24, 24, 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  _BackButton(onTap: _back),
                  const SizedBox(width: 12),
                  Text(
                    'Help & Feedback',
                    style: AppText.custom(24, FontWeight.w700, context.tokens.textPrimary,
                        lineHeight: 30, letterSpacing: -0.4),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              Text(
                'Report an issue or share an idea to help improve Cleanify.',
                style: AppText.custom(15, FontWeight.w400,
                    context.tokens.textPrimary,
                    lineHeight: 22),
              ),
              const SizedBox(height: 8),
              Text(
                'Design preview — feedback sending is not connected.',
                style: AppText.custom(13, FontWeight.w400, context.tokens.textSecondary,
                    lineHeight: 20),
              ),
              const SizedBox(height: 24),
              _ActionCard(
                icon: AppAssets.alertCircle,
                title: 'Report a Problem',
                subtitle: 'Tell us about an issue with the app.',
                onTap: () => _subject.text = 'Problem report',
              ),
              const SizedBox(height: 12),
              _ActionCard(
                icon: AppAssets.sparkles,
                title: 'Suggest a Feature',
                subtitle: 'Share an idea for a future update.',
                onTap: () => _subject.text = 'Feature suggestion',
              ),
              const SizedBox(height: 12),
              _ActionCard(
                icon: AppAssets.headphones,
                title: 'Contact Support',
                subtitle: 'Support channel not connected yet.',
                showChevron: false,
                onTap: () => _showSnack('Support channel isn’t connected yet.'),
              ),
              const SizedBox(height: 24),
              Text(
                'Send Feedback',
                style: AppText.custom(18, FontWeight.w700, context.tokens.textPrimary, lineHeight: 24),
              ),
              const SizedBox(height: 16),
              _Field(
                label: 'Subject',
                hint: 'Enter subject',
                controller: _subject,
                error: _subjectError,
              ),
              const SizedBox(height: 16),
              _Field(
                label: 'Message',
                hint: 'Describe your feedback or issue in detail...',
                controller: _message,
                error: _messageError,
                multiline: true,
              ),
              const SizedBox(height: 16),
              // Figma vẽ nút ở 45% độ đục; vẫn bấm được để hiện lỗi nhập liệu.
              Opacity(
                opacity: 0.45,
                child: Material(
                  color: _ink,
                  borderRadius: BorderRadius.circular(12),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(12),
                    onTap: _send,
                    child: SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: Center(
                        child: Text(
                          'Send Feedback',
                          style: AppText.custom(16, FontWeight.w600,
                              Colors.white,
                              lineHeight: 22),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'Sending will be available when a feedback service is connected.',
                style: AppText.custom(12, FontWeight.w400, context.tokens.textSecondary,
                    lineHeight: 18),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _BackButton extends StatelessWidget {
  const _BackButton({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: context.tokens.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: context.tokens.border),
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: onTap,
          child: Center(
            child: AppSvg(AppAssets.arrowLeft, size: 20, color: context.tokens.textPrimary),
          ),
        ),
      ),
    );
  }
}

/// Thẻ hành động: icon ô vuông nhạt, tiêu đề và mô tả ngắn.
class _ActionCard extends StatelessWidget {
  const _ActionCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.showChevron = true,
  });

  final String icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  final bool showChevron;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: context.tokens.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: context.tokens.border),
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: context.tokens.surfaceMuted,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Center(
                    child: AppSvg(icon, size: 20, color: context.tokens.textPrimary),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: AppText.custom(16, FontWeight.w600, context.tokens.textPrimary,
                            lineHeight: 20),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        subtitle,
                        style: AppText.custom(13, FontWeight.w400, context.tokens.textSecondary,
                            lineHeight: 18),
                      ),
                    ],
                  ),
                ),
                if (showChevron)
                  AppSvg(AppAssets.chevronRight,
                      size: 16, color: context.tokens.textSecondary),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Ô nhập có nhãn; khi có [error] viền đổi sang xám đậm và hiện dòng lỗi.
class _Field extends StatelessWidget {
  const _Field({
    required this.label,
    required this.hint,
    required this.controller,
    this.error,
    this.multiline = false,
  });

  final String label;
  final String hint;
  final TextEditingController controller;
  final String? error;
  final bool multiline;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: AppText.custom(14, FontWeight.w600, context.tokens.textPrimary,
              lineHeight: 20),
        ),
        const SizedBox(height: 8),
        AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          width: double.infinity,
          constraints: BoxConstraints(minHeight: multiline ? 140 : 0),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            color: context.tokens.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
                color: error == null ? context.tokens.border : const Color(0xFF4D4D4D)),
          ),
          child: TextField(
            controller: controller,
            maxLines: multiline ? null : 1,
            style: AppText.custom(15, FontWeight.w400, context.tokens.textPrimary, lineHeight: 22),
            decoration: InputDecoration(
              isCollapsed: true,
              border: InputBorder.none,
              hintText: hint,
              hintStyle: AppText.custom(15, FontWeight.w400,
                  context.tokens.textMuted,
                  lineHeight: 22),
            ),
          ),
        ),
        if (error != null) ...[
          const SizedBox(height: 8),
          Text(
            error!,
            style: AppText.custom(12, FontWeight.w400, context.tokens.textPrimary,
                lineHeight: 18),
          ),
        ],
      ],
    );
  }
}

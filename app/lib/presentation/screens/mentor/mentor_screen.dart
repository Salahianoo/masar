import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:masar/presentation/state/providers.dart';
import 'package:masar/domain/entities/entities.dart';
import 'package:masar/presentation/navigation/routes.dart';
import 'package:masar/presentation/themes/app_theme.dart';
import 'package:masar/presentation/components/widgets.dart';
import 'package:masar/presentation/screens/mentor/mentor_typing_bubble.dart';
import 'package:masar/presentation/screens/mentor/rafeeq_concept_sheet.dart';
import 'package:masar/presentation/screens/mentor/rafeeq_welcome.dart';

class MentorScreen extends ConsumerStatefulWidget {
  const MentorScreen({super.key, this.subjectId, this.conceptId});
  final String? subjectId;
  final String? conceptId;

  @override
  ConsumerState<MentorScreen> createState() => _MentorScreenState();
}

class _MentorScreenState extends ConsumerState<MentorScreen> {
  final _input = TextEditingController();
  final _scroll = ScrollController();
  final List<ChatMessage> _messages = [];
  bool _sending = false;
  String? _selectedSubjectId;

  /// The concept picked from «اشرحلي موضوع من المادة»; grounds the rest of the chat.
  String? _topicConceptId;

  @override
  void initState() {
    super.initState();
    if (widget.subjectId != null && widget.conceptId != null) {
      _input.text = 'اشرحلي هاد المفهوم ببساطة، وليش غلطت فيه؟';
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _send(widget.subjectId!);
      });
    }
  }

  @override
  void dispose() {
    _input.dispose();
    _scroll.dispose();
    super.dispose();
  }

  /// Sends the input field, or [text] when a suggestion card sends it.
  Future<void> _send(String subjectId, {String? text, String? conceptId}) async {
    final value = (text ?? _input.text).trim();
    if (value.isEmpty || _sending) return;
    setState(() {
      _messages.add(ChatMessage(role: ChatMessage.userRole, text: value));
      if (text == null) _input.clear();
      if (conceptId != null) _topicConceptId = conceptId;
      _sending = true;
    });
    _toBottom();
    try {
      final reply = await ref.read(masarRepositoryProvider).askMentor(
        subjectId: subjectId,
        conceptId: _topicConceptId ?? widget.conceptId,
        messages: _messages.length <= 12
            ? List.of(_messages)
            : _messages.sublist(_messages.length - 12),
      );
      if (mounted) {
        setState(() => _messages.add(ChatMessage(role: ChatMessage.mentorRole, text: reply)));
      }
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(friendlyError(error))));
      }
    } finally {
      if (mounted) { setState(() => _sending = false); _toBottom(); }
    }
  }

  Future<void> _explainTopic(String subjectId) async {
    final concept = await showRafeeqConceptSheet(context, subjectId: subjectId);
    if (concept == null || !mounted) return;
    await _send(subjectId, text: 'اشرحلي ${concept.name}', conceptId: concept.id);
  }

  void _toBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scroll.hasClients) {
        _scroll.animateTo(
          _scroll.position.maxScrollExtent,
          duration: const Duration(milliseconds: 250), curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final config = ref.watch(configProvider);
    final enrollments = ref.watch(enrollmentsProvider);
    final mentorName = config.value?.mentorName ?? 'رفيق';
    final enabled = config.value?.mentorEnabled ?? false;
    final subjects = ref.watch(subjectsProvider).value ?? [];
    final enrolled = enrollments.value ?? [];
    final subjectId = widget.subjectId ??
        (_selectedSubjectId != null && enrolled.any((e) => e.subjectId == _selectedSubjectId)
          ? _selectedSubjectId : enrolled.firstOrNull?.subjectId);
    return Scaffold(
      body: SafeArea(child: Column(children: [
        _MentorHeader(mentorName: mentorName),
        if (widget.subjectId == null && enrolled.length > 1) Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: DropdownButtonFormField<String>(
            initialValue: subjectId,
            items: [for (final e in enrolled) DropdownMenuItem(
              value: e.subjectId,
              child: Text(subjects.where((s) => s.id == e.subjectId).firstOrNull?.name ?? e.subjectId))],
            onChanged: (value) => setState(() {
              _selectedSubjectId = value;
              _messages.clear();
              _topicConceptId = null;
            }),
          ),
        ),
        Expanded(child: subjectId == null
          ? const Center(child: Text('سجّل مادة أولاً عشان تحكي مع رفيق'))
          : !enabled
            ? const Center(child: Text('رفيق مش متاح حالياً'))
            : ListView(
                controller: _scroll,
                padding: const EdgeInsets.all(AppSpacing.screen),
                children: [
                  if (_messages.isEmpty) RafeeqWelcome(
                    mentorName: mentorName,
                    onAsk: (text) => _send(subjectId, text: text),
                    onPractice: () => context.push(AppRoutes.practice(subjectId, mode: 'plan')),
                    onExplainTopic: () => _explainTopic(subjectId),
                  ),
                  for (final message in _messages)
                    message.isUser
                        ? Align(
                            alignment: Alignment.centerRight,
                            child: Container(
                              margin: const EdgeInsets.only(bottom: AppSpacing.md),
                              constraints: const BoxConstraints(maxWidth: 300),
                              padding: const EdgeInsets.all(AppSpacing.md),
                              decoration: BoxDecoration(
                                color: AppColors.primarySoft,
                                borderRadius: BorderRadius.circular(AppRadius.lg),
                              ),
                              child: Text(message.text, style: AppText.body),
                            ),
                          )
                        : _MentorReply(text: message.text),
                  if (_sending) MentorTypingBubble(mentorName: mentorName),
                ],
              )),
        if (subjectId != null && enabled) Padding(
          padding: const EdgeInsets.fromLTRB(AppSpacing.screen, AppSpacing.sm, AppSpacing.screen, AppSpacing.md),
          child: Row(children: [
            Expanded(child: TextField(
              controller: _input,
              enabled: !_sending,
              maxLength: 2000,
              maxLines: 3,
              minLines: 1,
              decoration: const InputDecoration(hintText: 'اسأل رفيق عن مادتك',
                counterText: ''),
              onSubmitted: (_) => _send(subjectId),
            )),
            const SizedBox(width: AppSpacing.sm),
            ValueListenableBuilder<TextEditingValue>(
              valueListenable: _input,
              builder: (context, value, _) => _SendButton(
                active: !_sending && value.text.trim().isNotEmpty,
                onPressed: () => _send(subjectId),
              ),
            ),
          ]),
        ),
      ])),
    );
  }
}

/// رفيق's answer as a white card, his face beside its bottom corner, the
/// way هاشمي's answers look in Khazna.
class _MentorReply extends StatelessWidget {
  const _MentorReply({required this.text});

  final String text;

  /// The model marks key words with **…**; show them bold, never the stars.
  static TextSpan _bold(String text) {
    final parts = text.split('**');
    return TextSpan(style: AppText.body.copyWith(height: 1.7), children: [
      for (var i = 0; i < parts.length; i++)
        if (parts[i].isNotEmpty)
          TextSpan(text: parts[i], style: i.isOdd && i < parts.length - 1 ? AppText.bodyBold : null),
    ]);
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.lg),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          const MentorBadge(size: 44, ring: true),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Container(
              padding: const EdgeInsets.all(AppSpacing.lg),
              decoration: BoxDecoration(
                color: AppColors.surface,
                border: Border.all(color: AppColors.border),
                borderRadius: const BorderRadiusDirectional.only(
                  topStart: Radius.circular(AppRadius.lg),
                  topEnd: Radius.circular(AppRadius.lg),
                  bottomEnd: Radius.circular(AppRadius.lg),
                  bottomStart: Radius.circular(4),
                ).resolve(Directionality.of(context)),
                boxShadow: [BoxShadow(color: AppPalette.navy.withValues(alpha: .05), blurRadius: 12, offset: const Offset(0, 4))],
              ),
              child: Text.rich(_bold(text)),
            ),
          ),
        ],
      ),
    );
  }
}

/// رفيق's face, name and what he's for, on a soft navy-to-teal wash.
class _MentorHeader extends StatelessWidget {
  const _MentorHeader({required this.mentorName});

  final String mentorName;

  @override
  Widget build(BuildContext context) {
    final canPop = Navigator.of(context).canPop();
    return Container(
      padding: const EdgeInsetsDirectional.fromSTEB(AppSpacing.screen, AppSpacing.md, AppSpacing.md, AppSpacing.md),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: AlignmentDirectional.topStart,
          end: AlignmentDirectional.bottomEnd,
          colors: [AppColors.accentSoft, AppColors.primarySoft, AppColors.background],
          stops: const [0, .55, 1],
        ),
      ),
      child: Row(children: [
        const MentorBadge(size: 56, ring: true),
        const SizedBox(width: AppSpacing.md),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(mentorName, style: AppText.title.copyWith(color: AppColors.brand, fontSize: 26)),
            Text('مرشدك بمواد مسار', style: AppText.label),
          ]),
        ),
        if (canPop)
          IconButton.filledTonal(
            tooltip: 'رجوع',
            onPressed: () => Navigator.of(context).maybePop(),
            icon: const Icon(Icons.arrow_forward_ios_rounded, size: 18),
          ),
      ]),
    );
  }
}

/// Grey while there's nothing to send; lights up teal once there is.
class _SendButton extends StatelessWidget {
  const _SendButton({required this.active, required this.onPressed});

  final bool active;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      width: 48,
      height: 48,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: active ? AppColors.accent : AppColors.track,
        boxShadow: active
            ? [BoxShadow(color: AppColors.accent.withValues(alpha: .45), blurRadius: 12, offset: const Offset(0, 4))]
            : const [],
      ),
      child: IconButton(
        tooltip: 'إرسال',
        onPressed: active ? onPressed : null,
        icon: Icon(Icons.send_rounded, color: active ? Colors.white : AppColors.textMuted),
      ),
    );
  }
}

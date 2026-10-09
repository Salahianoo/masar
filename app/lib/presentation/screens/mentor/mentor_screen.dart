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
      appBar: AppBar(title: Text(mentorName)),
      body: SafeArea(child: Column(children: [
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
                    Align(
                      alignment: message.isUser ? Alignment.centerRight : Alignment.centerLeft,
                      child: Container(
                        margin: const EdgeInsets.only(bottom: AppSpacing.md),
                        constraints: const BoxConstraints(maxWidth: 300),
                        padding: const EdgeInsets.all(AppSpacing.md),
                        decoration: BoxDecoration(
                          color: message.isUser ? AppColors.primarySoft : AppColors.surfaceMuted,
                          borderRadius: BorderRadius.circular(AppRadius.lg),
                        ),
                        child: Text(message.text, style: AppText.body),
                      ),
                    ),
                  if (_sending) MentorTypingBubble(mentorName: mentorName),
                ],
              )),
        if (subjectId != null && enabled) Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
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
            IconButton.filled(
              tooltip: 'إرسال',
              onPressed: _sending ? null : () => _send(subjectId),
              icon: const Icon(Icons.send_rounded),
            ),
          ]),
        ),
      ])),
    );
  }
}

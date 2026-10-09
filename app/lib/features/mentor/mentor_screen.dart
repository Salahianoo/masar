import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/data/providers.dart';
import '../../core/models/models.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/widgets.dart';

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

  Future<void> _send(String subjectId) async {
    final value = _input.text.trim();
    if (value.isEmpty || _sending) return;
    setState(() {
      _messages.add(ChatMessage(role: ChatMessage.userRole, text: value));
      _input.clear();
      _sending = true;
    });
    _toBottom();
    try {
      final reply = await ref.read(masarRepositoryProvider).askMentor(
        subjectId: subjectId,
        conceptId: widget.conceptId,
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
                  if (_messages.isEmpty) Column(children: [
                    const MentorAvatar(pose: MentorPose.wave, size: 88),
                    const SizedBox(height: AppSpacing.md),
                    Text('أهلاً، أنا $mentorName. شو بتحب نشرح اليوم؟',
                      style: AppText.body, textAlign: TextAlign.center),
                    const SizedBox(height: AppSpacing.sm),
                    Text('بجاوب من مادة امتحانك وأسئلتها السابقة.',
                      style: AppText.caption, textAlign: TextAlign.center),
                  ]),
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
                  if (_sending) const Align(
                    alignment: Alignment.centerLeft,
                    child: CircularProgressIndicator(),
                  ),
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

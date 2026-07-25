import 'package:flutter/material.dart';

import '../../core/network/api_client.dart';
import '../../data/repositories/meeting_repository.dart';
import '../../models/meeting.dart';

class MeetingEditPage extends StatefulWidget {
  const MeetingEditPage({
    super.key,
    required this.meeting,
    required this.meetingRepository,
  });

  final Meeting meeting;
  final MeetingRepository meetingRepository;

  @override
  State<MeetingEditPage> createState() => _MeetingEditPageState();
}

class _MeetingEditPageState extends State<MeetingEditPage> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _titleController;
  late final TextEditingController _descriptionController;
  late final TextEditingController _capacityController;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.meeting.title);
    _descriptionController =
        TextEditingController(text: widget.meeting.description);
    _capacityController =
        TextEditingController(text: widget.meeting.capacity.toString());
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _capacityController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate() || _saving) return;
    setState(() => _saving = true);
    try {
      final updated = await widget.meetingRepository.updateMeetingDetails(
        widget.meeting.id!,
        title: _titleController.text,
        description: _descriptionController.text,
        capacity: int.parse(_capacityController.text),
      );
      if (mounted) Navigator.of(context).pop(updated);
    } on Exception catch (error) {
      if (!mounted) return;
      setState(() => _saving = false);
      final message = error is ApiException ? error.message : '모임을 수정하지 못했습니다.';
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(message)));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('모임 수정')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            TextFormField(
              controller: _titleController,
              maxLength: 50,
              decoration: const InputDecoration(
                labelText: '모임 제목',
                border: OutlineInputBorder(),
              ),
              validator: (value) =>
                  value == null || value.trim().isEmpty ? '제목을 입력해 주세요.' : null,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _descriptionController,
              maxLength: 1000,
              maxLines: 8,
              decoration: const InputDecoration(
                labelText: '모임 소개',
                border: OutlineInputBorder(),
              ),
              validator: (value) => value == null || value.trim().isEmpty
                  ? '모임 소개를 입력해 주세요.'
                  : null,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _capacityController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: '모집 정원',
                border: OutlineInputBorder(),
              ),
              validator: (value) {
                final capacity = int.tryParse(value ?? '');
                if (capacity == null || capacity < widget.meeting.joined) {
                  return '현재 참여 인원 이상으로 입력해 주세요.';
                }
                if (capacity > 100) return '정원은 100명 이하여야 합니다.';
                return null;
              },
            ),
            const SizedBox(height: 24),
            FilledButton(
              onPressed: _saving ? null : _save,
              child: Text(_saving ? '저장 중...' : '저장'),
            ),
          ],
        ),
      ),
    );
  }
}

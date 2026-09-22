import 'package:flutter/material.dart';

import '../../core/network/api_client.dart';
import '../../data/repositories/moderation_repository.dart';
import '../../models/moderation.dart';

Future<bool> showReportSheet(
  BuildContext context, {
  required ModerationRepository repository,
  required ReportTargetType targetType,
  required int targetId,
}) async {
  final input = await showModalBottomSheet<_ReportInput>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (_) => const _ReportSheet(),
  );
  if (input == null || !context.mounted) return false;
  try {
    await repository.createReport(
      targetType: targetType,
      targetId: targetId,
      reason: input.reason,
      otherDescription: input.description,
    );
    if (context.mounted) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('신고가 접수되었습니다.')));
    }
    return true;
  } on Exception catch (error) {
    if (context.mounted) {
      final message = error is ApiException ? error.message : '신고를 접수하지 못했습니다.';
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(message)));
    }
    return false;
  }
}

class _ReportInput {
  const _ReportInput(this.reason, this.description);
  final ReportReason reason;
  final String? description;
}

class _ReportSheet extends StatefulWidget {
  const _ReportSheet();
  @override
  State<_ReportSheet> createState() => _ReportSheetState();
}

class _ReportSheetState extends State<_ReportSheet> {
  ReportReason _reason = ReportReason.spam;
  final _descriptionController = TextEditingController();

  @override
  void dispose() {
    _descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isOther = _reason == ReportReason.other;
    return SafeArea(
      child: SingleChildScrollView(
        padding: EdgeInsets.fromLTRB(
          20,
          0,
          20,
          20 + MediaQuery.viewInsetsOf(context).bottom,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('신고 사유',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900)),
            const SizedBox(height: 8),
            ...ReportReason.values.map((reason) => RadioListTile<ReportReason>(
                  key: ValueKey('report-reason-${reason.name}'),
                  value: reason,
                  groupValue: _reason,
                  contentPadding: EdgeInsets.zero,
                  title: Text(reason.label),
                  onChanged: (value) => setState(() => _reason = value!),
                )),
            if (isOther)
              TextField(
                key: const Key('report-other-description'),
                controller: _descriptionController,
                onChanged: (_) => setState(() {}),
                maxLength: 500,
                maxLines: 3,
                decoration: const InputDecoration(
                    labelText: '간단한 설명', border: OutlineInputBorder()),
              ),
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                key: const Key('submit-report'),
                onPressed: isOther && _descriptionController.text.trim().isEmpty
                    ? null
                    : () => Navigator.of(context).pop(_ReportInput(
                          _reason,
                          isOther ? _descriptionController.text.trim() : null,
                        )),
                child: const Text('신고하기'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

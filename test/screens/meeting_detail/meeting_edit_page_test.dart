import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:meetple/data/repositories/category_repository.dart';
import 'package:meetple/data/repositories/meeting_repository.dart';
import 'package:meetple/data/repositories/mock_image_upload_repository.dart';
import 'package:meetple/data/repositories/mock_location_repository.dart';
import 'package:meetple/data/repositories/mock_meeting_repository.dart';
import 'package:meetple/models/meeting.dart';
import 'package:meetple/models/meeting_category.dart';
import 'package:meetple/screens/meeting_detail/meeting_edit_page.dart';

void main() {
  testWidgets('prefills the create form and submits every editable value',
      (tester) async {
    await tester.binding.setSurfaceSize(const Size(390, 1200));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final repository = _CapturingMeetingRepository();

    await tester.pumpWidget(
      MaterialApp(
        home: _EditPageLauncher(repository: repository),
      ),
    );

    await tester.tap(find.text('수정 열기'));
    await tester.pumpAndSettle();

    expect(find.text('모임 수정'), findsOneWidget);
    expect(
      _controllerText(tester, const Key('create_meeting_title')),
      '기존 러닝 모임',
    );
    expect(
      _controllerText(tester, const Key('create_meeting_schedule')),
      '2026.08.10 19:30',
    );
    expect(
      _controllerText(tester, const Key('create_meeting_end_schedule')),
      '2026.08.10 21:30',
    );
    expect(
      _controllerText(tester, const Key('create_meeting_location_name')),
      '여의도공원',
    );
    expect(
      _controllerText(tester, const Key('create_meeting_capacity')),
      '10',
    );
    expect(
      _controllerText(tester, const Key('create_meeting_description')),
      '기존 모임 소개',
    );

    await tester.enterText(
      _textField(const Key('create_meeting_title')),
      '수정된 러닝 모임',
    );
    await tester.tap(
      find.byKey(const Key('create_meeting_end_time_unknown')),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('create_meeting_submit')));
    await tester.pumpAndSettle();

    final input = repository.updatedInput;
    expect(input, isNotNull);
    expect(input!.title, '수정된 러닝 모임');
    expect(input.category, '운동');
    expect(input.locationName, '여의도공원');
    expect(input.address, '서울 영등포구 여의공원로 68');
    expect(input.latitude, 37.5268);
    expect(input.longitude, 126.9228);
    expect(input.scheduledAt, DateTime(2026, 8, 10, 19, 30));
    expect(input.endsAt, isNull);
    expect(input.capacity, 10);
    expect(input.description, '기존 모임 소개');
    expect(input.imageUrls, isNull);
    expect(find.text('수정 완료: 수정된 러닝 모임'), findsOneWidget);
  });

  testWidgets('does not allow capacity below the current member count',
      (tester) async {
    await tester.binding.setSurfaceSize(const Size(390, 1200));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final repository = _CapturingMeetingRepository();

    await tester.pumpWidget(
      MaterialApp(
        home: _EditPageLauncher(repository: repository),
      ),
    );
    await tester.tap(find.text('수정 열기'));
    await tester.pumpAndSettle();

    await tester.enterText(
      _textField(const Key('create_meeting_capacity')),
      '5',
    );
    await tester.tap(find.byKey(const Key('create_meeting_submit')));
    await tester.pumpAndSettle();

    expect(
      find.text('현재 참여 인원 이상, 100명 이하로 입력해주세요.'),
      findsOneWidget,
    );
    expect(repository.updatedInput, isNull);
  });
}

String _controllerText(WidgetTester tester, Key key) {
  return tester.widget<TextFormField>(_textField(key)).controller!.text;
}

Finder _textField(Key key) {
  return find.descendant(
    of: find.byKey(key),
    matching: find.byType(TextFormField),
  );
}

class _EditPageLauncher extends StatefulWidget {
  const _EditPageLauncher({required this.repository});

  final _CapturingMeetingRepository repository;

  @override
  State<_EditPageLauncher> createState() => _EditPageLauncherState();
}

class _EditPageLauncherState extends State<_EditPageLauncher> {
  Meeting? _updated;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: _updated == null
            ? FilledButton(
                onPressed: () async {
                  final updated = await Navigator.of(context).push<Meeting>(
                    MaterialPageRoute(
                      builder: (_) => MeetingEditPage(
                        meeting: _meeting,
                        meetingRepository: widget.repository,
                        categoryRepository: const _CategoryRepository(),
                        locationRepository: const MockLocationRepository(),
                        imageUploadRepository:
                            const MockImageUploadRepository(),
                      ),
                    ),
                  );
                  if (updated != null && mounted) {
                    setState(() => _updated = updated);
                  }
                },
                child: const Text('수정 열기'),
              )
            : Text('수정 완료: ${_updated!.title}'),
      ),
    );
  }
}

final _meeting = Meeting(
  id: 10,
  hostId: 1,
  title: '기존 러닝 모임',
  category: '운동',
  tags: ['운동'],
  area: '여의도공원',
  address: '서울 영등포구 여의공원로 68',
  latitude: 37.5268,
  longitude: 126.9228,
  date: '8/10',
  time: '19:30',
  distance: '1km',
  capacity: 10,
  joined: 6,
  host: '모임장',
  description: '기존 모임 소개',
  fee: '무료',
  rating: 0,
  reviewCount: 0,
  thumbnailImageUrl: 'https://cdn.example.com/meeting-thumbnail.png',
  scheduledAt: DateTime(2026, 8, 10, 19, 30),
  endsAt: DateTime(2026, 8, 10, 21, 30),
);

class _CategoryRepository implements CategoryRepository {
  const _CategoryRepository();

  @override
  Future<List<MeetingCategory>> findAll() async {
    return const [
      MeetingCategory(id: 1, name: '운동'),
      MeetingCategory(id: 2, name: '취미'),
    ];
  }
}

class _CapturingMeetingRepository extends MockMeetingRepository {
  UpdateMeetingInput? updatedInput;

  @override
  Future<Meeting> updateMeetingDetails(
    int meetingId,
    UpdateMeetingInput input,
  ) async {
    updatedInput = input;
    return _meeting.copyWith(
      title: input.title,
      category: input.category,
      tags: [input.category],
      area: input.locationName,
      address: input.address,
      latitude: input.latitude,
      longitude: input.longitude,
      scheduledAt: input.scheduledAt,
      endsAt: input.endsAt,
      clearEndsAt: input.endsAt == null,
      capacity: input.capacity,
      description: input.description,
      imageUrls: input.imageUrls ?? _meeting.imageUrls,
    );
  }
}

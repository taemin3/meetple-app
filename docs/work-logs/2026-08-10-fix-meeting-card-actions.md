# 작업 로그: fix/meeting-card-actions

## 기본 정보

- 날짜: 2026-08-10
- 브랜치: `fix/meeting-card-actions`
- 작업자: Codex
- 관련 PR: 생성 전

## 사용자 요청

- 홈과 찜한 모임에서 사용하는 카드의 찜 아이콘을 오른쪽 아래로 옮긴다.
- 내가 만든 모임과 참여 중인 모임 카드의 오른쪽 화살표를 제거한다.
- 같은 브랜치에서 Flutter 파일 구조와 repository 책임을 정리한다.

## 작업 목표와 흐름

1. 최신 `main`에서 공통 `MeetingListCard` 사용 구조를 확인했다.
2. 공통 trailing 영역을 카드 콘텐츠 하단에 정렬했다.
3. 내 모임 목록에서 기본 화살표를 제거하고, 명시적인 trailing만 표시하도록 변경했다.
4. 아이콘 위치와 화살표 제거 테스트를 추가하고 전체 회귀 테스트를 실행했다.
5. 알림 목록·읽음 처리를 `NotificationRepository`로 분리하고 앱 조립부에 연결했다.
6. 사용되지 않는 하드코딩 신청 화면을 제거하고 모임 상세 하단 바를 기능 폴더의 위젯 파일로 분리했다.

## 변경 파일 요약

- `meeting_list_card.dart`: trailing을 카드 오른쪽 아래에 정렬
- `my_meetings_page.dart`: 기본 chevron 제거
- `data/repositories`: 알림 전용 API·Mock·인터페이스 repository 추가
- `app`, `home`, `profile`, `notifications`: 알림 repository 의존성 전달 및 사용
- `meeting_detail/widgets`: 상세 화면 하단 액션 바 분리
- 미사용 `requests_page.dart` 제거
- 관련 위젯 테스트 추가 및 갱신

## 검증

```powershell
flutter analyze
flutter test
```

결과:

- `flutter analyze`: 이슈 없음
- 전체 190개 테스트 통과

## 이슈와 결정 사항

- 홈과 찜한 모임은 같은 공통 카드의 trailing을 사용하므로 한 곳에서 위치를 통일했다.
- 카드 자체의 상세 이동은 유지되므로 별도의 이동 화살표 없이 카드 전체 탭으로 이동한다.
- 알림 API는 모임 API와 별도 도메인이므로 `MeetingRepository`에서 분리했다.
- 큰 화면은 전면 이동하지 않고 독립적인 하단 액션 바부터 기능 폴더 아래로 분리했다.

## 후속 작업

- 실제 기기에서 긴 제목과 태그가 있는 카드의 하단 아이콘 정렬을 확인한다.
- 나머지 대형 화면도 기능 수정 시 독립 위젯부터 단계적으로 분리한다.

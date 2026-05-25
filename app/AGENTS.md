# AGENTS.md

이 문서는 Codex가 `meetple/app` Flutter 앱을 다시 열었을 때 바로 이어서 작업하기 위한 기준이다.

## 앱 개요

`meetple/app`은 사용자가 운동, 스터디, 취미 모임을 탐색하고 만들고 참여 신청할 수 있는 Flutter 모바일 앱이다.

현재 단계:

- Flutter 화면 목업 구현 및 정리
- 백엔드 API 직접 연동 전
- 목업 데이터 기반 화면 흐름 검증
- 보라색 지도/카드형 UI 방향 유지
- iOS/Android 우선, Web은 프리뷰와 리뷰 용도

## 작업 루트

Flutter 명령은 항상 `app/`에서 실행한다.

```bash
cd app
dart format lib test
flutter analyze
flutter test
flutter build web --pwa-strategy=none
```

웹 빌드 프리뷰가 필요하면 빌드 후 아래 도구를 사용한다.

```bash
node tools/serve_web_build.js
```

## 현재 패키지 구조

```text
lib/
  main.dart
  app/
    app_shell.dart
    meetup_mock_app.dart
  core/
    theme/
      app_colors.dart
      app_theme.dart
    ui/
      meetup_style.dart
  data/
    mock/
      mock_meetups.dart
  models/
    meetup.dart
  screens/
    home/
    discover/
    meetup_detail/
    create_meetup/
    chat/
    profile/
    requests/
    notifications/
  widgets/
```

구조 기준 문서:

- `../docs/package-structure.md`
- `../docs/ui-design-spec.md`
- `../docs/project-plan.md`

## 개발 원칙

- 백엔드 연동 전에는 화면 흐름, 목업 UX, 모바일 사용성을 우선한다.
- 새 기능은 기존 폴더 구조와 네이밍을 따른다.
- 화면에서 공통으로 쓰이는 UI는 `lib/widgets/`로 분리한다.
- 전역 색상과 테마는 `lib/core/theme/`의 `AppColors`, `AppTheme` 기준을 우선 사용한다.
- 화면 전용 스타일 변환은 `lib/core/ui/meetup_style.dart`에 둔다.
- `main.dart`에는 앱 실행 진입점 이상의 화면/데이터 로직을 넣지 않는다.
- 도메인 모델에는 Flutter UI 타입을 직접 넣지 않는다.
- 플랫폼 폴더(`android/`, `ios/`, `web/`, `macos/`, `linux/`, `windows/`)는 실제 설정 변경이 필요할 때만 수정한다.
- 새 패키지와 플러그인은 꼭 필요할 때만 추가하고, 추가하면 `pubspec.yaml`과 `pubspec.lock`을 함께 확인한다.
- 사용자가 만든 변경은 되돌리지 않는다.

## 목업 데이터와 연동 준비

현재 목업 데이터는 `lib/data/mock/mock_meetups.dart`에 있다.

다음 구조 정리의 우선순위:

1. `lib/data/repositories/` 추가
2. `MockMeetupRepository` 추가
3. 화면에서 `mockMeetups` 직접 참조 제거
4. 라우팅 구조 정리
5. API 명세 확정 후 `ApiMeetingRepository` 추가

백엔드 API가 붙기 전에도 화면은 repository 인터페이스를 통해 데이터를 받도록 점진적으로 바꾼다.

## UI 기준

- 보라색 포인트 컬러, 흰색 카드, 부드러운 그림자를 유지한다.
- 지도 중심 탐색, 지도 핀, 하단 바텀시트, 사진형 모임 카드를 핵심 시각 요소로 둔다.
- 하단 탭은 `홈 / 탐색 / 모임 만들기 / 채팅 / 마이` 구성을 유지한다.
- 모바일 화면에서 텍스트가 넘치거나 버튼/카드가 깨지지 않게 확인한다.
- 화면 구현은 `../docs/ui-design-spec.md`의 토큰과 화면별 명세를 우선 참고한다.
- 레퍼런스 이미지는 루트 `AGENTS.md`에 적힌 로컬 이미지 경로를 기준으로 한다.

## 테스트와 검증

작업 후 가능한 범위에서 아래 순서로 검증한다.

```bash
dart format lib test
flutter analyze
flutter test
```

UI 레이아웃이나 웹 프리뷰에 영향이 있으면 추가로 확인한다.

```bash
flutter build web --pwa-strategy=none
node tools/serve_web_build.js
```

## 한글 인코딩 주의

PowerShell 출력에서 한글이 깨져 보일 수 있다. 콘솔 출력만 보고 소스나 문서의 한글을 임의로 고치지 않는다. 실제 파일 내용은 에디터, Flutter 테스트, 브라우저 렌더링 결과를 기준으로 판단한다.

## PR Review Language

- 모든 PR 리뷰 요약과 코멘트는 한국어로 작성한다.
- 코드 식별자, 파일명, 클래스명, 메서드명은 원문 영어를 유지한다.
- 리뷰는 짧고 명확하게 작성하고, 중요한 버그/보안/테스트 누락을 먼저 지적한다.

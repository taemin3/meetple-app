# AGENTS.md

이 문서는 Codex가 `meetple-app` Flutter 앱 저장소를 다시 열었을 때 바로 이어서 작업하기 위한 기준이다.

## 앱 개요

`meetple-app`은 사용자가 운동, 스터디, 취미 모임을 탐색하고 만들고 참여 신청할 수 있는 Flutter 모바일 앱이다.

현재 단계:

- Flutter 앱 기본 구조와 화면 흐름 정리
- 백엔드 API가 준비된 기능부터 API repository 연동 진행
- MockRepository는 테스트, 오프라인 프리뷰, 아직 API가 없는 화면 보조용으로만 사용
- 보라색 지도/카드형 UI 방향 유지
- iOS/Android 우선, Web은 프리뷰와 리뷰 용도

## 작업 루트

Flutter 명령은 항상 `pubspec.yaml`이 있는 저장소 루트에서 실행한다.

```bash
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
    app_navigation.dart
    app_route_names.dart
    app_routes.dart
    app_shell.dart
    meetple_app.dart
  core/
    config/
      app_config.dart
    network/
      api_client.dart
    theme/
      app_colors.dart
      app_theme.dart
    ui/
      meeting_style.dart
  data/
    mock/
      mock_auth.dart
      mock_meetings.dart
    repositories/
      api_meeting_repository.dart
      auth_repository.dart
      meeting_repository.dart
      mock_auth_repository.dart
      mock_meeting_repository.dart
  models/
    auth_session.dart
    auth_user.dart
    meeting.dart
  screens/
    auth/
    home/
    discover/
    meeting_detail/
    create_meeting/
    chat/
    profile/
    requests/
    notifications/
  widgets/
```

구조 기준 문서:

- `README.md`
- `CONTRIBUTING.md`

## 개발 원칙

- 백엔드 API가 준비된 기능은 API repository를 우선 구현한다.
- MockRepository는 테스트, 오프라인 프리뷰, API 미구현 화면 보조용으로만 사용한다.
- 새 기능은 가능하면 백엔드 API contract 기준으로 구현하고, mock은 같은 repository 인터페이스를 따르는 최소 구현만 둔다.
- 새 기능은 기존 폴더 구조와 네이밍을 따른다.
- 화면에서 공통으로 쓰이는 UI는 `lib/widgets/`로 분리한다.
- 전역 색상과 테마는 `lib/core/theme/`의 `AppColors`, `AppTheme` 기준을 우선 사용한다.
- 화면 전용 스타일 변환은 `lib/core/ui/meeting_style.dart`에 둔다.
- `main.dart`에는 앱 실행 진입점 이상의 화면/데이터 로직을 넣지 않는다.
- 도메인 모델에는 Flutter UI 타입을 직접 넣지 않는다.
- 플랫폼 폴더(`android/`, `ios/`, `web/`, `macos/`, `linux/`, `windows/`)는 실제 설정 변경이 필요할 때만 수정한다.
- 새 패키지와 플러그인은 꼭 필요할 때만 추가하고, 추가하면 `pubspec.yaml`과 `pubspec.lock`을 함께 확인한다.
- 사용자가 만든 변경은 되돌리지 않는다.

## Git 작업 규칙

- 브랜치 이름은 `type/<short-kebab-summary>` 형식을 사용한다.
- 브랜치 type은 작업 성격에 맞춰 `feat`, `fix`, `docs`, `refactor`, `test`, `chore`, `style`, `ci` 중에서 고른다.
- 예시: `feat/home-recommendations`
- 예시: `fix/discover-overflow`
- 예시: `docs/branch-naming-rules`
- 커밋 메시지는 Conventional Commits 형식을 사용하고, 요약은 한국어로 작성한다.
- 커밋 메시지 형식은 `type: 한국어 요약`이다.
- 주로 사용하는 type은 `feat`, `fix`, `docs`, `refactor`, `test`, `chore`, `style`, `ci`이다.
- 예시: `feat: 홈 추천 모임 섹션 추가`
- 예시: `fix: 탐색 화면 오버플로우 수정`
- 예시: `docs: 앱 작업 규칙 추가`
- Codex가 브랜치를 파서 작업한 경우, 필요한 검증 후 커밋하고 원격 브랜치까지 푸시한다.
- PR 생성과 머지는 사용자가 직접 한다.
- Codex는 PR을 직접 만들지 않고, 푸시 후 사용자가 PR에 넣을 제목과 본문 초안을 한국어로 제공한다.
- PR 본문 초안에는 `변경 사항`, `검증`, `참고 사항`을 포함한다.
- 관련 없는 파일이나 사용자가 만든 변경은 스테이징하거나 커밋하지 않는다.

## API 연동과 Mock 사용 기준

화면은 mock 데이터를 직접 참조하지 않고 repository 인터페이스를 통해 데이터를 받는다.

- 실제 기능 개발의 기본 방향은 `Api*Repository` 구현이다.
- `Mock*Repository`는 테스트, 프리뷰, 백엔드 서버 없이 화면을 확인하는 용도다.
- API가 준비된 기능은 mock 화면을 먼저 확장하지 말고 API contract에 맞춰 repository를 붙인다.
- API가 아직 없는 기능만 mock을 최소 범위로 추가한다.

다음 구조 정리의 우선순위:

1. 인증 토큰 저장소와 `HttpApiClient` token provider 연결
2. `ApiAuthRepository` 추가 후 로그인/회원가입 API 연동
3. 모임 만들기 화면 입력 상태와 검증 흐름 정리
4. 백엔드 meeting API 연동 검증

API와 mock 구현체는 같은 repository 인터페이스를 유지해 화면 코드가 데이터 출처에 직접 의존하지 않게 한다.

## UI 기준

- 보라색 포인트 컬러, 흰색 카드, 부드러운 그림자를 유지한다.
- 지도 중심 탐색, 지도 핀, 하단 바텀시트, 사진형 모임 카드를 핵심 시각 요소로 둔다.
- 하단 탭은 `홈 / 탐색 / 모임 만들기 / 채팅 / 마이` 구성을 유지한다.
- 모바일 화면에서 텍스트가 넘치거나 버튼/카드가 깨지지 않게 확인한다.
- 화면 구현은 기존 `lib/core/theme`, `lib/core/ui`, `lib/widgets` 패턴을 우선 참고한다.

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

## 작업 로그 규칙

Codex가 브랜치 단위로 파일을 수정하고 커밋/푸시하는 작업을 수행하면 가능하면 `docs/work-logs/`에 작업 로그를 남긴다.

작업 로그는 `docs/work-logs/TEMPLATE.md`를 기준으로 작성한다.

로그에는 다음 내용을 포함한다.

- 사용자 요청 요약
- 브랜치명
- 작업 목표와 작업 흐름
- 사용한 도구
- 실행한 주요 명령
- 변경 파일 요약
- 검증 명령과 결과
- 작업 중 발견한 이슈와 결정 사항
- 후속 작업

민감한 값은 기록하지 않는다.

- access token, refresh token, API key, 비밀번호, 개인 정보는 남기지 않는다.
- 긴 명령 출력은 전체를 붙이지 말고 핵심 결과만 요약한다.
- 실패한 명령은 원인 추적에 필요한 경우 명령과 실패 이유를 요약한다.
- PR 본문은 짧게 유지하고, 자세한 작업 흐름은 작업 로그에 남긴다.

파일 이름은 날짜와 브랜치명을 사용한다.

```text
docs/work-logs/YYYY-MM-DD-branch-name.md
```

예시:

```text
docs/work-logs/2026-05-26-feat-app-icon-splash.md
```

## PR Review Language

- 모든 PR 리뷰 요약과 코멘트는 한국어로 작성한다.
- 코드 식별자, 파일명, 클래스명, 메서드명은 원문 영어를 유지한다.
- 리뷰는 짧고 명확하게 작성하고, 중요한 버그/보안/테스트 누락을 먼저 지적한다.

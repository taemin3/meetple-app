# Meetple Flutter App

`meetple-app`은 모임 탐색, 모임 만들기, 참여 신청, 채팅 흐름을 검증하기 위한 Flutter 모바일 앱이다. 현재는 백엔드 API 연동 전 단계이며, 목업 데이터로 화면과 사용자 흐름을 먼저 다듬는다.

## 현재 상태

- Flutter 기반 화면 목업
- iOS/Android 우선 개발
- Web은 리뷰와 프리뷰 용도
- 백엔드 API 직접 연동 없음
- 보라색 지도/카드형 UI 방향 적용 중

## 실행 준비

Flutter SDK가 설치되어 있어야 한다. 모든 Flutter 명령은 `pubspec.yaml`이 있는 저장소 루트에서 실행한다.

```bash
flutter --version
flutter pub get
```

## 개발 실행

연결된 디바이스나 에뮬레이터에서 실행한다.

```bash
flutter run
```

웹으로 빠르게 확인할 때는 아래 명령을 사용할 수 있다.

```bash
flutter run -d chrome
```

## 검증 명령

작업 후 가능한 경우 아래 순서로 확인한다.

```bash
dart format lib test
flutter analyze
flutter test
```

웹 빌드까지 확인해야 하는 UI 변경이면 아래 명령도 실행한다.

```bash
flutter build web --pwa-strategy=none
```

빌드된 웹 결과를 로컬에서 볼 때는 다음 도구를 사용한다.

```bash
node tools/serve_web_build.js
```

## 주요 구조

```text
lib/
  main.dart
  app/
    app_navigation.dart
    app_routes.dart
    app_shell.dart
    meetple_app.dart
  core/
    config/
    network/
    theme/
    ui/
  data/
    mock/
    repositories/
  models/
  screens/
  widgets/
```

역할 기준:

- `main.dart`: 앱 실행 진입점
- `app/`: `MaterialApp`, 앱 shell, 탭/상세 화면 라우팅 연결
- `core/config/`: 빌드 환경별 설정값
- `core/network/`: HTTP API 클라이언트
- `core/theme/`: 전역 색상과 테마
- `core/ui/`: 화면 표현용 공통 변환 규칙
- `data/mock/`: 현재 목업 데이터
- `data/repositories/`: 목업/API 데이터 접근 구현체
- `models/`: 화면과 API가 공유할 데이터 모델
- `screens/`: 사용자 화면 단위 구현
- `widgets/`: 여러 화면에서 쓰는 공통 위젯

## 관련 문서

- `AGENTS.md`: 앱 전용 Codex 작업 기준
- `.github/copilot-instructions.md`: 앱 PR 리뷰 기준
- `CONTRIBUTING.md`: Git/GitHub 작업 규칙

## 개발 원칙

- 백엔드 연동 전에는 화면 흐름과 목업 UX를 우선한다.
- 화면에서 목업 데이터를 직접 참조하는 부분은 점진적으로 repository 계층으로 이동한다.
- 공통 UI는 `widgets/`, 전역 스타일은 `core/` 기준으로 정리한다.
- 새 패키지는 꼭 필요할 때만 추가한다.
- 플랫폼 폴더는 실제 설정 변경이 필요한 경우에만 수정한다.
- PowerShell에서 한글이 깨져 보여도 콘솔 출력만 보고 소스나 문서를 임의로 고치지 않는다.

## 다음 작업 후보

1. 인증 토큰을 `HttpApiClient`에 주입하는 구조 정리
2. 개발 환경에서 `ApiMeetingRepository`로 교체하는 진입점 추가
3. 화면별 로딩/에러/빈 상태 UI 다듬기
4. 백엔드 meeting API 연동 검증

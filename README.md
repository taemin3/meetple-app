# Meetple App

> 주변 모임을 탐색하고 만들고 참여하며, 실시간 채팅으로 이어지는 Flutter 모바일 클라이언트

Meetple 전체 구성과 저장소 링크는 [프로젝트 허브](https://github.com/taemin3/meetple)에서 확인할 수 있습니다.

## 주요 기능

- 이메일 인증 기반 회원가입·로그인·비밀번호 재설정과 안전한 토큰 갱신
- 지도와 카테고리를 이용한 주변 모임 탐색 및 일반 모임 검색
- 모임 생성·수정, 다중 이미지 업로드, 참여 신청과 승인·거절·취소
- STOMP WebSocket 기반 실시간 채팅과 재연결 후 누락 메시지 복구
- Firebase 푸시 알림과 앱 내 알림 목록
- 사용자·모임·채팅 신고, 사용자 차단, 계정 삭제

## 기술 구성

| 구분 | 기술 |
| --- | --- |
| UI | Flutter, Dart, Material 3, Pretendard |
| 통신 | HTTP API, STOMP WebSocket |
| 지도 | Naver Map |
| 알림 | Firebase Messaging, Local Notifications |
| 로컬 보안 | Flutter Secure Storage |
| 테스트 | Flutter Test |

## 애플리케이션 구조

```text
lib/
  app/                 앱 초기화, 라우팅, 의존성 연결
  core/                설정, 네트워크, 푸시, 테마, 공통 UI 규칙
  data/
    repositories/      API와 mock 데이터 접근 구현
    realtime/          STOMP 실시간 연결
  models/              화면과 API가 공유하는 모델
  screens/             기능별 화면
  widgets/             공통 UI 컴포넌트
```

화면은 데이터 출처를 직접 참조하지 않고 repository 인터페이스에 의존합니다. API가 준비된 기능은 `Api*Repository`를 사용하며, `Mock*Repository`는 테스트와 오프라인 프리뷰를 위한 보조 구현입니다.

## 실행

Flutter SDK를 준비한 뒤 저장소 루트에서 의존성을 설치합니다.

```powershell
flutter pub get
```

기본 실행은 백엔드 없이 화면을 확인할 수 있는 mock 모드입니다.

```powershell
flutter run
```

로컬 백엔드에 연결할 때는 API 사용 여부와 주소를 명시합니다. Android Emulator에서는 호스트 PC를 `10.0.2.2`로 접근합니다.

```powershell
flutter run `
  --dart-define=MEETPLE_USE_API=true `
  --dart-define=MEETPLE_API_BASE_URL=http://10.0.2.2:8080 `
  --dart-define=MEETPLE_NAVER_MAP_CLIENT_ID=<client-id>
```

staging API에 연결할 때는 공개 가능한 API 설정 파일과 지도 Client ID를 분리해 전달합니다.

```powershell
flutter run `
  --dart-define-from-file=config/staging.json `
  --dart-define=MEETPLE_NAVER_MAP_CLIENT_ID=<client-id>
```

Android에서 Firebase 푸시를 사용할 때는 Firebase Console에서 받은 `google-services.json`을 `android/app/google-services.json`에 둡니다. 환경별 Firebase 설정과 실제 Client ID는 Git에 커밋하지 않습니다.

## 검증

```powershell
dart format lib test
flutter analyze
flutter test
```

웹 프리뷰에 영향을 주는 변경은 빌드도 확인합니다.

```powershell
flutter build web --pwa-strategy=none
node tools/serve_web_build.js
```

## 관련 저장소

- [Meetple Backend](https://github.com/taemin3/meetple-backend)
- [Meetple AI](https://github.com/taemin3/meetple-ai)
- [Meetple Admin](https://github.com/taemin3/meetple-admin)

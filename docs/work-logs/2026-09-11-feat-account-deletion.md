# 작업 로그: feat/account-deletion

## 기본 정보

- 날짜: 2026-09-11
- 브랜치: `feat/account-deletion`
- 작업자: Codex
- 관련 PR: 생성하지 않음

## 사용자 요청

- `마이 → 설정`에서 찾을 수 있는 회원 탈퇴 화면과 API 연동 구현
- 비밀번호 확인, 최종 동의, 중복 요청 방지, 오류 구분, 성공 후 세션 정리

## 작업 목표

- 탈퇴 영향을 충분히 안내하고 명시적 확인 뒤 백엔드 탈퇴 API를 호출한다.
- 성공 시 Push 등록과 로컬 인증 상태를 제거하고 이전 인증 화면으로 돌아갈 수 없게 한다.
- repository 및 widget 회귀 테스트를 추가한다.

## 작업 흐름

1. 기존 인증 저장소와 로그아웃/Push 해제 흐름을 조사했다.
2. AuthRepository 계약과 ApiAuthRepository 오류 매핑을 확장했다.
3. 탈퇴 전용 화면, 설정 메뉴, 인증 루트 전환과 테스트를 구현했다.

## 사용한 도구

- PowerShell
- `apply_patch`
- Dart, Flutter

## 실행한 주요 명령

```powershell
dart format lib test
flutter analyze
flutter test --reporter compact
```

## 변경 파일 요약

- `lib/core/network`: 본문을 포함한 DELETE 지원
- `lib/data/repositories`: 탈퇴 계약, API 구현, 오류 유형, 로컬 정리
- `lib/screens/profile`: 설정 메뉴와 탈퇴 전용 화면
- `test`: repository, 탈퇴 화면, 프로필 메뉴와 인증 fake 보강

## 검증

```powershell
dart format lib test
flutter analyze
flutter test --reporter compact
git diff --check
```

결과:

- `flutter analyze`: 문제 없음
- 전체 285개 테스트 성공
- `git diff --check` 성공

## 이슈와 결정

- 잘못된 비밀번호는 세션을 유지하고, 401 세션 만료는 로컬 인증을 제거한다.
- 서버 성공 이후 기존 로그아웃과 동일한 Push 해제 및 로컬 토큰 정리를 실행한다.
- 처리 중에는 제출 버튼과 뒤로가기를 차단한다.

## 후속 작업

- 로컬 테스트용 메일/계정 인프라가 준비되면 실기기 앱 탈퇴 E2E를 추가 확인한다.
- 공개 웹 삭제 페이지가 운영 배포된 뒤 앱 스토어 등록 정보를 갱신한다.

## PR #62 리뷰 반영

- 탈퇴 API가 `401`을 반환하면 탈퇴 화면을 닫고 인증 루트의 로그아웃 흐름을 실행한다.
- 서버 탈퇴 성공 뒤 secure storage 정리가 실패해도 삭제 성공을 네트워크 오류로 바꾸지 않는다.
- 공백만 입력한 비밀번호는 원문을 변경하지 않고 필수 입력 오류로 처리한다.

# Contributing

meetple 앱 저장소의 Git/GitHub 작업 규칙입니다.

## 기본 원칙

- `main` 브랜치에 직접 push하지 않습니다.
- 모든 작업은 기능 브랜치에서 진행하고 Pull Request로 병합합니다.
- PR 병합은 기본적으로 `Squash and merge`를 사용합니다.
- 하나의 PR은 하나의 목적만 다룹니다.
- `.env`, 로컬 설정, 개인 토큰, 비밀번호는 커밋하지 않습니다.

## 브랜치 규칙

브랜치 이름은 `type/short-description` 형식을 사용합니다.

```text
feat/home-screen
feat/meeting-detail
fix/bottom-navigation
docs/git-workflow
refactor/theme-colors
chore/flutter-config
```

주요 type:

```text
feat      새 기능
fix       버그 수정
docs      문서 수정
test      테스트 추가/수정
refactor  동작 변화 없는 구조 개선
style     포맷팅만 변경
chore     빌드, 설정, 잡일
ci        GitHub Actions 같은 CI 설정
```

## 커밋 메시지 규칙

Conventional Commits 스타일을 사용합니다.

```text
feat: 홈 화면 추천 모임 섹션 추가
fix: 탐색 탭 스크롤 오버플로우 수정
docs: Git 작업 규칙 추가
test: 위젯 테스트 케이스 추가
refactor: 공통 카드 위젯 분리
chore: Flutter 설정 정리
```

형식:

```text
type: 변경 내용 요약
```

요약은 짧게 쓰고, 무엇을 바꿨는지 바로 알 수 있게 작성합니다.

## 작업 흐름

```bash
git checkout main
git pull origin main
git checkout -b feat/example

# 작업 후
git status
git add .
git commit -m "feat: example 기능 추가"
git push -u origin feat/example
```

GitHub에서 PR을 생성하고, 확인 후 `main`으로 병합합니다.

## PR 체크리스트

- 변경 목적이 PR 제목과 설명에 드러나는가?
- 화면 변경이 있으면 직접 실행해 확인했는가?
- 관련 테스트 또는 `flutter analyze`를 실행했는가?
- 불필요한 빌드 산출물, IDE 파일, 로그가 포함되지 않았는가?
- 백엔드 API 변경과 맞물리는 경우 API 계약을 확인했는가?

## 앱 검증 명령

가능한 경우 아래 순서로 확인합니다.

```bash
dart format lib test
flutter analyze
flutter test
flutter build web --pwa-strategy=none
```

# 작업 로그: feat/home-nearby-discovery

## 기본 정보

- 날짜: 2026-08-10
- 브랜치: `feat/home-nearby-discovery`
- 작업자: Codex
- 관련 PR: 미생성

## 사용자 요청

- 홈 추천 모임을 내 주변 거리 우선으로 구성한다.
- 홈 검색, 카테고리, 추천 모임 전체보기가 실제 탐색 기능으로 이어지게 한다.

## 작업 목표

- 현재 위치 기준 5km 이내의 모집 중 모임을 거리순으로 최대 3개 노출한다.
- 위치를 확인할 수 없으면 기존 일정순 모임 목록을 대체 데이터로 사용한다.
- 홈 검색과 카테고리 선택 상태를 탐색 탭에 전달한다.

## 작업 흐름

1. 기존 주변 모임 API가 모집 중 상태와 거리 오름차순을 보장하는지 확인했다.
2. Naver 위치 추적기를 사용하는 현재 위치 제공자를 플랫폼별로 분리했다.
3. 홈 검색, 서버 카테고리, 전체보기를 탐색 탭의 초기 검색 상태와 연결했다.
4. 현재 위치 조회와 홈에서 탐색으로 이동하는 흐름을 위젯 테스트로 보강했다.

## 사용한 도구

- `shell_command`
- `apply_patch`
- Flutter 분석, 테스트, 웹 빌드

## 실행한 주요 명령

```bash
dart format lib test
flutter analyze
flutter test test/widget_test.dart test/discover_page_test.dart
flutter test
flutter build web --pwa-strategy=none
```

## 변경 파일 요약

- `lib/core/map/nearby_location*`: 플랫폼별 현재 위치 제공자와 좌표 계약 추가
- `lib/screens/home/home_page.dart`: 거리순 추천 조회와 홈 검색·카테고리·전체보기 동작 추가
- `lib/app/app_navigation.dart`, `lib/app/app_shell.dart`: 탐색 탭 진입 요청 전달
- `lib/screens/discover/discover_page.dart`: 초기 카테고리와 검색 포커스 적용
- `lib/widgets/section_title.dart`: 섹션 액션 버튼 콜백 지원
- `test/widget_test.dart`: 현재 위치 추천과 홈→탐색 동작 검증

## 검증

```bash
flutter analyze
flutter test
flutter build web --pwa-strategy=none
```

결과:

- 정적 분석: 오류 없음
- 전체 테스트: 193개 통과
- 웹 빌드: 성공

## 이슈와 결정

- 백엔드 주변 조회가 이미 `RECRUITING` 상태와 거리 오름차순을 적용하므로 추천 전용 API는 추가하지 않았다.
- 홈 추천 반경은 탐색 화면 기본값과 같은 5km로 맞췄다.
- 위치 권한이 없거나 위치를 얻지 못하면 홈이 비어 보이지 않도록 기존 모임 목록을 사용한다.
- 검색은 현재 탐색 반경에서 불러온 모임의 제목, 장소, 카테고리를 대상으로 한다.

## 후속 작업

- 검색 범위를 전체 모임으로 넓히려면 백엔드 주변 조회 요청에 검색어 조건을 추가한다.
- 운영 데이터로 추천 반경과 홈 카드 클릭률을 확인한 뒤 반경 또는 정렬 가중치를 조정한다.

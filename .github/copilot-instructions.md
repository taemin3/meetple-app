# GitHub Copilot Instructions

When performing a pull request code review, respond in Korean.

Review Flutter app changes with these project rules:

- Keep comments concise and actionable.
- Prioritize functional bugs, navigation regressions, broken state flows, UI overflow, missing validation, missing tests, and unnecessary package additions.
- Prefer API repository integration when the backend API contract is available; use mock repositories only for tests, offline preview, or features whose API is not ready yet.
- Keep screens dependent on repository interfaces rather than direct mock data or direct API clients.
- Follow the existing structure under `lib/app`, `lib/core`, `lib/data`, `lib/models`, `lib/screens`, and `lib/widgets`.
- Use existing theme and UI helpers such as `AppColors`, `AppTheme`, and `MeetupStyle` before adding new styling patterns.
- Keep shared UI in `lib/widgets`; keep one-screen-only widgets close to the screen that owns them.
- Do not add business logic, mock data, API calls, or routing decisions to `main.dart`.
- Avoid putting Flutter UI types directly into domain models.
- Check that mobile layouts handle long Korean text without overflow.
- Check that bottom tabs remain `홈 / 탐색 / 모임 만들기 / 채팅 / 마이`.
- Check that changes respect the purple map/card UI direction already used by the existing screens.
- If `pubspec.yaml` changes, verify that the dependency is necessary and `pubspec.lock` is consistent.
- Avoid changing generated platform folders unless the app behavior or platform configuration requires it.
- Preserve user changes and avoid broad refactors that are not needed for the requested app work.


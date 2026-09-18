# HIScore

모든 기기에서 쓰는 악보 뷰어. iOS, iPadOS, Android(폰/태블릿), Windows, macOS 를 하나의 Flutter 코드베이스로 지원한다.

## 개발 환경

- Flutter 3.44.3 stable / Dart 3.12
- Windows 빌드: Visual Studio 2026
- Android 빌드: Android SDK 36
- iOS / macOS 빌드: Mac 필요

```
flutter pub get
dart run build_runner build
flutter run -d windows
```

drift 테이블을 고친 뒤에는 `dart run build_runner build` 를 다시 돌린다.

## 폴더 구조

```
lib/
  core/
    db/        drift 테이블 정의와 데이터베이스
    layout/    반응형 껍데기(폰 하단탭 / 태블릿·데스크톱 레일)
    routing/   go_router 경로
    theme/     색과 타이포
  features/
    library/     악보 목록, 태그, 메타데이터
    viewer/      악보 보기, 페이지 넘김
    annotation/  필기 (iOS 는 PencilKit, 그 외는 CustomPainter)
    setlist/     세트리스트
    tools/       메트로놈, 튜너, 건반, 녹음기, 플레이어
    importer/    파일·카메라·클라우드·IMSLP 가져오기
    settings/    설정과 백업
```

각 기능은 `data` / `domain` / `presentation` 로 나눈다.

## 테스트

```
flutter test
```

`test/fixtures/score.pdf` 는 8쪽짜리 합성 악보다. 렌더 파이프라인과 뷰어
위젯 테스트가 이 파일을 실제로 열어 확인한다. 페이지 굽기는 진짜 비동기라
위젯 테스트에서 `pumpAndSettle` 대신 `settleWithRender` 를 쓴다.

## 설계 원칙

- **원본 PDF 는 고치지 않는다.** 페이지 순서, 크롭, 회전, 필기는 전부 DB 에만 기록하고 내보낼 때만 합성한다.
- **필기는 벡터로 보관한다.** 래스터로 굽지 않아야 취소/재실행과 확대가 깨지지 않는다.
- **페이지 넘김 입력은 한 곳으로 모은다.** 탭, 스와이프, 블루투스 페달, 얼굴 제스처, 원격 기기가 모두 같은 명령 계층을 거친다.
- **결제 기능은 넣지 않는다.** 모든 기능을 제한 없이 제공한다.

## 개발 단계

| 단계 | 내용 | 상태 |
|---|---|---|
| 0 | 프로젝트 골격, DB 스키마, 반응형 셸 | 완료 |
| 1 | PDF 뷰어 핵심 (렌더링, 레이아웃 4종, 자동 스크롤, 퍼포먼스 모드) | 완료 |
| 2 | 라이브러리 관리 (정렬, 검색, 태그, 세트리스트, 메타데이터) | 완료 |
| 3 | 필기 (PencilKit 하이브리드, 스탬프, 텍스트, 도형) | |
| 4 | 페이지 도구 (북마크, 크롭, 순서 편집, 점프 버튼) | |
| 5 | 가져오기 확장 (카메라, 클라우드, IMSLP) | |
| 6 | 음악 도구 (메트로놈, 튜너, 건반, 녹음기, 플레이어) | |
| 7 | 핸즈프리 넘김 (페달, 얼굴 제스처, 원격, 기기 동기화) | |
| 8 | 내보내기와 백업 | |
| 9 | 다국어, 접근성, 6개 플랫폼 빌드 검증 | |

# HIScore

모든 기기에서 쓰는 악보 뷰어. iOS, iPadOS, Android(폰/태블릿), Windows, macOS 를 하나의 Flutter 코드베이스로 지원한다.

## 개발 환경

- Flutter 3.44.3 stable / Dart 3.12
- Windows 빌드: Visual Studio 2026
- Android 빌드: Android SDK 36, JDK 21 (Android Studio 동봉)
- iOS / macOS 빌드: Mac 필요

```
flutter pub get
dart run build_runner build
flutter run -d windows
```

drift 테이블을 고친 뒤에는 `dart run build_runner build` 를 다시 돌린다.

### 빌드 확인 현황 (2026-09-18)

| 플랫폼 | 상태 |
|---|---|
| Windows | 디버그 빌드 통과. 한국어 코드페이지에서 플러그인 C4819 경고가 오류로 승격되는 문제는 `windows/CMakeLists.txt` 에서 `/utf-8` 로 막았다 |
| Android | 디버그 APK 빌드 통과 |
| iOS / macOS | Mac 이 없어 미검증. PencilKit 플러그인, Open In(SceneDelegate), URL 스킴, 사용 설명 문구는 작성돼 있다 |

## 폴더 구조

```
lib/
  core/
    db/        drift 테이블·DAO (악보, 페이지, 태그, 세트리스트, 필기, 북마크, 점프, 녹음, 설정)
    i18n/      tr() 번역. 한국어 원문이 키, assets/i18n/{en,ja}.json 이 번역
    layout/    반응형 껍데기(폰 하단탭 / 태블릿·데스크톱 레일)
    routing/   go_router 경로
    storage/   앱 문서 폴더 경로 (DB 에는 상대 경로만 저장)
    theme/     색과 타이포
  features/
    library/     악보 목록, 태그, 메타데이터, 표지
    viewer/      악보 보기, 페이지 넘김, 북마크, 크롭, 순서 편집, 점프 버튼, 얼굴 제스처, 넘김 입력 허브
    annotation/  필기 (iOS 는 PencilKit, 그 외는 CustomPainter), 스탬프, 텍스트, 도형, 실행 취소
    setlist/     세트리스트, 구간 지정, 공유(텍스트/순서만/악보 포함)
    tools/       메트로놈, 튜너, 건반, 녹음기, 플레이어 (flutter_soloud 하나로 소리)
    importer/    파일·카메라·Google Drive·Dropbox·IMSLP·감시 폴더·Open In
    sync/        기기 간 동기화(리드/팔로우), 리모컨
    export/      필기 포함 PDF 내보내기, 인쇄, 공유
    backup/      전체 백업/복원
    settings/    설정
ios/Runner/PencilKitPlugin.swift   PencilKit 플랫폼 뷰와 정적 렌더 채널
android/.../MainActivity.kt        Open In (ACTION_VIEW / SEND) 수신
```

각 기능은 `data` / `domain` / `presentation` 로 나눈다.

## 설계 원칙

- **원본 PDF 는 고치지 않는다.** 페이지 순서, 크롭, 회전, 필기는 전부 DB 에만 기록하고 내보낼 때만 합성한다.
- **필기는 벡터로 보관한다.** 좌표는 원본 페이지 기준 0~1 비율이라 크롭과 기기가 달라져도 같은 자리에 남는다. iOS PencilKit 그림은 "폭 1000pt 기준 공간" 으로 정규화해 같은 표에 둔다.
- **페이지 넘김 입력은 한 곳으로 모은다.** 탭, 스와이프, 키보드/페달, 얼굴 제스처, 리모컨, 리드 기기가 모두 `TurnInputHub` 를 거쳐 열린 뷰어에 닿는다.
- **넘김 속도가 핵심이다.** 페이지를 미리 굽고(앞 2장, 뒤 1장) LRU 로 12장까지 든다. 목표 폭은 128px 구간으로 반올림해 창 크기 변화에 다시 굽지 않는다.
- **결제 기능은 넣지 않는다.** 모든 기능을 제한 없이 제공한다.

## 테스트

```
flutter test
```

`test/fixtures/score.pdf` 는 8쪽짜리 합성 악보다. 렌더 파이프라인과 뷰어 위젯 테스트가 이 파일을 실제로 열어 확인한다. 페이지 굽기는 진짜 비동기라 위젯 테스트에서 `pumpAndSettle` 대신 `settleWithRender` 를 쓴다.

기기 동기화 테스트는 리드와 팔로워를 같은 프로세스에서 localhost 로 붙여 위치 전파와 파일 전송을 확인한다. i18n 테스트는 코드의 모든 `tr('…')` 키가 번역 표에 있는지 검사한다.

## 다국어

소스 코드의 한국어 문자열이 곧 키다. `tr('악보')` 는 현재 언어가 한국어면 그대로, 영어·일본어면 `assets/i18n/` 의 JSON 에서 찾는다. 새 문장을 추가하면 두 JSON 에 같은 키를 넣어야 `i18n_test` 가 통과한다. 자리표시자는 `{0}`, `{1}` 순서다.

## 외부 서비스 설정

- **Google Drive / Dropbox**: OAuth 2.0 PKCE 공개 클라이언트다. 설정 화면에 클라이언트 ID 를 넣는다. 리디렉션 URI 는 데스크톱 `http://127.0.0.1`, 모바일 `hiscore://oauth`. 토큰은 secure storage 에 둔다.
- **IMSLP**: 공식 API 가 없어 MediaWiki API 와 HTML 을 읽는다. 사이트 구조가 바뀌면 `ImslpClient.parseFiles` 부터 깨진다. 실패하면 브라우저로 안내한다.

## 아직 손으로 확인하지 못한 것

- iOS/iPadOS 전체(PencilKit 필기, Apple Pencil 손가락 넘김, Open In, 카메라 촬영, 얼굴 제스처). Mac 에서 빌드해 봐야 한다.
- 실제 블루투스 페달, 실제 클라우드 로그인(클라이언트 ID 필요), 실제 IMSLP 다운로드.
- 세로 스크롤 보기의 핀치 확대는 넣지 않았다. 스크롤과 확대 제스처 충돌을 따로 설계해야 한다.

## 개발 단계

| 단계 | 내용 | 상태 |
|---|---|---|
| 0 | 프로젝트 골격, DB 스키마, 반응형 셸 | 완료 |
| 1 | PDF 뷰어 핵심 (렌더링, 레이아웃 4종, 자동 스크롤, 퍼포먼스 모드) | 완료 |
| 2 | 라이브러리 관리 (정렬, 검색, 태그, 세트리스트, 메타데이터) | 완료 |
| 3 | 필기 (PencilKit 하이브리드, 스탬프, 텍스트, 도형) | 완료 (iOS 미검증) |
| 4 | 페이지 도구 (북마크, 크롭, 순서 편집, 점프 버튼) | 완료 |
| 5 | 가져오기 확장 (카메라, 클라우드, IMSLP, 감시 폴더, Open In) | 완료 |
| 6 | 음악 도구 (메트로놈, 튜너, 건반, 녹음기, 플레이어) | 완료 |
| 7 | 핸즈프리 넘김 (페달, 얼굴 제스처, 원격, 기기 동기화) | 완료 (얼굴 제스처는 모바일 미검증) |
| 8 | 내보내기와 백업 | 완료 |
| 9 | 다국어(한/영/일), 테마, 접근성, 빌드 검증 | 완료 (Windows·Android 확인, iOS·macOS 미확인) |

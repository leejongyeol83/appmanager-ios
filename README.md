# AppManager SDK for iOS

Links, Guard, Push, Table 4개 서비스를 하나의 SDK로 통합한 iOS 플랫폼 패키지.
1회 초기화로 딥링크(Links), 보안 탐지(Guard), 푸시 알림(Push), 데이터 테이블(Table) 서비스를 모두 사용할 수 있다.

## 요구사항

- iOS 13.0+
- Swift 5.9+
- Xcode 15.0+

## 설치 (Swift Package Manager)

Xcode > File > Add Package Dependencies:

```
https://github.com/leejongyeol83/appmanager-ios.git
```

Version: `v1.0.0` 이상

필요한 모듈만 선택하여 추가한다:

| 모듈 | 용도 | 필수 여부 |
|------|------|-----------|
| `AppManagerCore` | 공통 Config, Logger, HttpClient | 필수 |
| `AppManagerLinks` | 딥링크 서비스 (Universal Link, Deferred Deep Link) | 선택 |
| `AppManagerGuard` | 보안 탐지 서비스 (탈옥, 디버거, 후킹 등 9종) | 선택 |
| `AppManagerPush` | 푸시 알림 서비스 (APNs, 메시지함, 수신/열람 통계) | 선택 |

> `AppManagerCore`는 모든 서비스의 기반이므로 반드시 포함해야 한다.
> 서비스 모듈은 필요한 것만 선택하면 된다 (예: Links만, Guard + Push만 등).

## Quick Start

### 전체 서비스 사용

```swift
import AppManagerCore
import AppManagerLinks
import AppManagerGuard
import AppManagerPush

// AppDelegate.application(_:didFinishLaunchingWithOptions:) 또는 App.init()에서 호출
AppManager.shared.configure(config: AppManagerConfig(
    apiKey: "pk_your_api_key",
    serverUrl: "https://your-platform.com",
    logLevel: .debug,
    guard: GuardOptions(
        enableJailbreakDetection: true,
        enableSimulatorDetection: true,
        detectionInterval: 60
    )
))

// Links — 딥링크 핸들러 등록
AppManager.shared.linksSDK.setDeepLinkHandler { result in
    print("딥링크 수신: \(result.url), 디퍼드: \(result.isDeferred)")
}

// Guard — 보안 탐지 시작
AppManager.shared.guardSDK.initialize(callback: self)
// onReady 콜백 수신 후 또는 즉시 시작 가능
AppManager.shared.guardSDK.startDetection()

// Push — 디바이스 등록
AppManager.shared.pushSDK.setDeviceToken(apnsTokenString)
AppManager.shared.pushSDK.register(userId: "user123")
AppManager.shared.pushSDK.setPushHandler { message in
    print("푸시 탭: \(message.title ?? "")")
}
```

### Links만 사용

```swift
import AppManagerCore
import AppManagerLinks

AppManager.shared.configure(config: AppManagerConfig(
    apiKey: "pk_your_api_key",
    serverUrl: "https://your-platform.com"
))

AppManager.shared.linksSDK.setDeepLinkHandler { result in
    print("딥링크: \(result.url)")
}
```

### Guard만 사용

```swift
import AppManagerCore
import AppManagerGuard

AppManager.shared.configure(config: AppManagerConfig(
    apiKey: "pk_your_api_key",
    serverUrl: "https://your-platform.com",
    guard: GuardOptions(
        enableJailbreakDetection: true,
        enableDebuggerDetection: true,
        enableHookingDetection: true
    )
))

AppManager.shared.guardSDK.initialize(callback: self)
AppManager.shared.guardSDK.startDetection()
```

### Push만 사용

```swift
import AppManagerCore
import AppManagerPush

AppManager.shared.configure(config: AppManagerConfig(
    apiKey: "pk_your_api_key",
    serverUrl: "https://your-platform.com"
))

AppManager.shared.pushSDK.setDeviceToken(apnsTokenString)
AppManager.shared.pushSDK.register(userId: "user123")
AppManager.shared.pushSDK.setPushHandler { message in
    print("푸시 탭: \(message.title ?? "")")
}
```

## API 요약

### AppManagerConfig

```swift
AppManagerConfig(
    apiKey: String,              // API 키 (pk_ 접두사)
    serverUrl: String,           // 서버 URL
    logLevel: LogLevel = .none,  // 로그 레벨 (.none, .error, .warn, .info, .debug)
    guard: GuardOptions = GuardOptions()  // Guard 옵션
)
```

### Links API

| 메서드 | 설명 |
|--------|------|
| `setDeepLinkHandler(_ handler:)` | 통합 딥링크 핸들러 등록 |
| `handleUniversalLink(_ url:)` | Universal Link 처리 |
| `handleDeepLink(_ url:)` | Custom Scheme 딥링크 처리 |
| `checkDeferredDeepLink()` | 디퍼드 딥링크 수동 체크 |

자세한 내용: [docs/LINKS.md](docs/LINKS.md)

### Guard API

| 메서드 | 설명 |
|--------|------|
| `initialize(callback:)` | Guard 초기화 (서버 정책 + 동적 시그니처 fetch) |
| `setCallback(_:)` | Guard 콜백 설정 |
| `startDetection()` | 주기적 보안 탐지 시작 |
| `stopDetection()` | 주기적 탐지 중지 (Guard 유지) |
| `runDetection()` | 즉시 1회 탐지 실행 |
| `stop()` | Guard 완전 종료 및 리소스 해제 |

자세한 내용: [docs/GUARD.md](docs/GUARD.md)

### Push API

| 메서드 | 설명 |
|--------|------|
| `setDeviceToken(_:)` | APNs 토큰 설정 |
| `register(userId:)` | 디바이스 서버 등록 |
| `setPushHandler(_:)` | 푸시 알림 탭 핸들러 등록 |
| `handleNotification(_:)` | 알림 탭 처리 (열람 확인 + 핸들러 호출) |
| `setAllowPush(allow:)` | 전체 푸시 수신 허용/거부 |
| `setDND(enabled:startTime:endTime:)` | 방해금지 시간 설정 |
| `getInbox(page:size:completion:)` | 메시지함 조회 |
| `getBadgeCount(completion:)` | 미열람 메시지 수 조회 |
| `logout(disablePush:)` | 로그아웃 |

자세한 내용: [docs/PUSH.md](docs/PUSH.md)

### Table API

| 메서드 | 설명 |
|--------|------|
| `get(_ tableName:) async` | 테이블 데이터 조회 (async/await) |
| `get(_ tableName:, completion:)` | 테이블 데이터 조회 (콜백, 메인 스레드) |

```swift
// 사용 예시
let result = await AppManager.shared.tableSDK.get("app_version")
if case .success(let table) = result {
    let version = table.rows.first?["version"]?.stringValue  // "1.0.1"
}
```

> Table은 core에 내장되어 있어 `AppManagerCore`만으로 사용 가능 (별도 모듈 불필요).
> SDK는 조회 전용이며, 데이터 등록/수정/삭제는 대시보드에서 수행한다.

자세한 내용: [docs/TABLE.md](docs/TABLE.md)

## 서비스 접근 방법

각 서비스 매니저는 `AppManager.shared`의 프로퍼티로 접근한다:

```swift
AppManager.shared.linksSDK   // LinksManager
AppManager.shared.guardSDK   // GuardManager
AppManager.shared.pushSDK    // PushManager
AppManager.shared.tableSDK   // TableManager (core 내장)
```

> `configure()` 호출 전에 접근하면 `fatalError`가 발생한다.
> Links/Guard/Push는 최초 접근 시 자동 생성되며, Table은 `configure()` 시 자동 생성된다.

## 라이선스

Copyright (c) 2026. All rights reserved.

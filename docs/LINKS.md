# Links SDK 가이드 (iOS)

딥링크(Universal Link) 및 디퍼드 딥링크 처리를 위한 Links 서비스 상세 가이드.

## 목차

- [설치 및 초기화](#설치-및-초기화)
- [Xcode 프로젝트 설정](#xcode-프로젝트-설정)
- [딥링크 수신 처리](#딥링크-수신-처리)
- [SwiftUI 앱에서 딥링크 처리](#swiftui-앱에서-딥링크-처리)
- [동작 흐름](#동작-흐름)
- [DeepLinkResult 모델](#deeplinkresult-모델)
- [API 레퍼런스](#api-레퍼런스)

---

## 설치 및 초기화

SPM에서 `AppManagerCore` + `AppManagerLinks` 모듈을 추가한다.

```swift
import AppManagerCore
import AppManagerLinks

// AppDelegate.application(_:didFinishLaunchingWithOptions:) 에서 호출
AppManager.shared.configure(config: AppManagerConfig(
    apiKey: "pk_your_api_key",
    serverUrl: "https://your-platform.com",
    logLevel: .debug
))

// 딥링크 핸들러 등록
AppManager.shared.linksSDK.setDeepLinkHandler { result in
    print("딥링크 URL: \(result.url)")
    print("디퍼드 여부: \(result.isDeferred)")
    
    // URL path/query에 따라 화면 이동 처리
    let components = URLComponents(url: result.url, resolvingAgainstBaseURL: false)
    if let path = components?.path {
        // 라우팅 처리
    }
}
```

> `setDeepLinkHandler`는 가능한 빨리 등록해야 한다.
> 초기화 시 디퍼드 딥링크 매칭이 자동으로 실행되며, 핸들러 미등록 시 결과를 보관했다가 등록 즉시 전달한다.

---

## Xcode 프로젝트 설정

### Associated Domains (Universal Link용)

1. Xcode > Target > Signing & Capabilities > **+ Capability** > **Associated Domains**
2. 도메인 추가:
   ```
   applinks:your-platform.com
   ```

> 서버의 `/.well-known/apple-app-site-association` 파일이 올바르게 설정되어 있어야 한다.

### URL Scheme (커스텀 스키마용)

1. Xcode > Target > Info > **URL Types**
2. 새 URL Type 추가:
   - **Identifier**: `com.yourapp.deeplink`
   - **URL Schemes**: `yourapp` (원하는 스키마명)

설정 후 `yourapp://path?param=value` 형태의 딥링크를 수신할 수 있다.

---

## 딥링크 수신 처리

### SceneDelegate를 사용하는 경우 (권장)

iOS 13 이상에서 SceneDelegate를 사용하는 경우, 3개 메서드에서 딥링크를 처리한다.

#### 1. Cold Start (앱이 종료된 상태에서 딥링크로 실행)

```swift
// SceneDelegate.swift
func scene(_ scene: UIScene,
           willConnectTo session: UISceneSession,
           options connectionOptions: UIScene.ConnectionOptions) {
    
    // Universal Link (cold start)
    if let userActivity = connectionOptions.userActivities.first,
       userActivity.activityType == NSUserActivityTypeBrowsingWeb,
       let url = userActivity.webpageURL {
        AppManager.shared.linksSDK.handleUniversalLink(url)
    }
    
    // Custom Scheme (cold start)
    if let urlContext = connectionOptions.urlContexts.first {
        AppManager.shared.linksSDK.handleDeepLink(urlContext.url)
    }
}
```

#### 2. Custom Scheme (앱이 이미 실행 중)

```swift
func scene(_ scene: UIScene, openURLContexts URLContexts: Set<UIOpenURLContext>) {
    guard let url = URLContexts.first?.url else { return }
    AppManager.shared.linksSDK.handleDeepLink(url)
}
```

#### 3. Universal Link (앱이 이미 실행 중)

```swift
func scene(_ scene: UIScene, continue userActivity: NSUserActivity) {
    guard userActivity.activityType == NSUserActivityTypeBrowsingWeb,
          let url = userActivity.webpageURL else { return }
    AppManager.shared.linksSDK.handleUniversalLink(url)
}
```

### AppDelegate만 사용하는 경우

SceneDelegate를 사용하지 않는 프로젝트에서는 AppDelegate에서 처리한다.

```swift
// AppDelegate.swift

// Universal Link
func application(_ application: UIApplication,
                 continue userActivity: NSUserActivity,
                 restorationHandler: @escaping ([UIUserActivityRestoring]?) -> Void) -> Bool {
    guard userActivity.activityType == NSUserActivityTypeBrowsingWeb,
          let url = userActivity.webpageURL else { return false }
    return AppManager.shared.linksSDK.handleUniversalLink(url)
}

// Custom Scheme
func application(_ app: UIApplication,
                 open url: URL,
                 options: [UIApplication.OpenURLOptionsKey: Any] = [:]) -> Bool {
    return AppManager.shared.linksSDK.handleDeepLink(url)
}
```

---

## SwiftUI 앱에서 딥링크 처리

SwiftUI의 `@main` App 구조체에서 modifier를 사용하여 처리한다.

```swift
import SwiftUI
import AppManagerCore
import AppManagerLinks

@main
struct MyApp: App {
    
    init() {
        AppManager.shared.configure(config: AppManagerConfig(
            apiKey: "pk_your_api_key",
            serverUrl: "https://your-platform.com",
            logLevel: .debug
        ))
        
        AppManager.shared.linksSDK.setDeepLinkHandler { result in
            // 딥링크 처리 (화면 이동 등)
            print("딥링크: \(result.url), 디퍼드: \(result.isDeferred)")
        }
    }
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                // Custom Scheme 딥링크 수신
                .onOpenURL { url in
                    AppManager.shared.linksSDK.handleDeepLink(url)
                }
                // Universal Link 수신
                .onContinueUserActivity(NSUserActivityTypeBrowsingWeb) { userActivity in
                    if let url = userActivity.webpageURL {
                        AppManager.shared.linksSDK.handleUniversalLink(url)
                    }
                }
        }
    }
}
```

---

## 동작 흐름

### 앱이 설치된 상태 (일반 딥링크)

```
사용자가 링크 클릭
  -> iOS가 앱 실행 (Universal Link 또는 Custom Scheme)
  -> SceneDelegate/AppDelegate에서 URL 수신
  -> handleUniversalLink(url) 또는 handleDeepLink(url) 호출
  -> SDK가 인입 통계를 서버에 보고
  -> setDeepLinkHandler에 등록된 핸들러에 DeepLinkResult 전달
     (isDeferred = false)
  -> 앱에서 URL path/query에 따라 화면 이동
```

### 앱 미설치 상태 (디퍼드 딥링크)

```
사용자가 링크 클릭
  -> 웹 페이지에서 디바이스 핑거프린트 수집 + 서버에 저장
  -> App Store로 리다이렉트
  -> 앱 설치 후 첫 실행
  -> SDK 초기화 시 자동으로 checkDeferredDeepLink() 실행
  -> 서버에 핑거프린트 기반 매칭 요청
  -> 매칭 성공 시 setDeepLinkHandler에 DeepLinkResult 전달
     (isDeferred = true)
  -> 앱에서 딥링크 URL에 따라 화면 이동 (설치 전 클릭한 링크 복원)
```

> 디퍼드 딥링크는 앱 최초 설치 후 1회만 체크된다.
> 핸들러가 아직 등록되지 않았을 때 디퍼드 결과가 도착하면, SDK가 결과를 보관했다가 핸들러 등록 시 즉시 전달한다.

---

## DeepLinkResult 모델

```swift
public struct DeepLinkResult {
    /// 딥링크 URL
    public let url: URL
    
    /// 디퍼드 딥링크 여부
    public let isDeferred: Bool
    
    /// 연결된 링크 ID (디퍼드 매칭 시)
    public let linkId: String?
    
    /// 추가 데이터 (디퍼드 매칭 시 deepLink, webUrl 등)
    public let data: [String: Any]?
}
```

| 프로퍼티 | 타입 | 설명 |
|----------|------|------|
| `url` | `URL` | 딥링크 URL. 커스텀 스키마의 경우 `_sc` 파라미터가 자동 제거된 클린 URL |
| `isDeferred` | `Bool` | `true`이면 디퍼드 딥링크 (앱 미설치 -> 설치 후 복원) |
| `linkId` | `String?` | 서버의 링크 ID (디퍼드 매칭 성공 시) |
| `data` | `[String: Any]?` | 추가 데이터. 디퍼드 매칭 시 `deepLink`, `webUrl` 키 포함 |

---

## API 레퍼런스

`AppManager.shared.linksSDK`를 통해 접근한다.

| 메서드 | 반환 | 설명 |
|--------|------|------|
| `setDeepLinkHandler(_ handler: @escaping (DeepLinkResult) -> Void)` | `Void` | 통합 딥링크 핸들러 등록. 일반/디퍼드 딥링크 모두 이 핸들러로 전달 |
| `handleUniversalLink(_ url: URL, shortCode: String?) -> Bool` | `@discardableResult Bool` | Universal Link 처리. 인입 통계를 자동 보고하고 핸들러에 결과 전달 |
| `handleDeepLink(_ url: URL, shortCode: String?) -> Bool` | `@discardableResult Bool` | Custom Scheme 딥링크 처리. URL의 `_sc` 파라미터를 제거한 클린 URL을 핸들러에 전달 |
| `checkDeferredDeepLink()` | `Void` | 디퍼드 딥링크를 수동으로 체크. 초기화 시 자동 호출되므로 일반적으로 직접 호출할 필요 없음 |

### 프로퍼티

| 프로퍼티 | 타입 | 설명 |
|----------|------|------|
| `isConfigured` | `Bool` | Links 초기화 완료 여부 |

# Push SDK 가이드 (iOS)

APNs 기반 푸시 알림 서비스 상세 가이드.
디바이스 등록, 알림 수신/열람 확인, 메시지함, 뱃지, 알림 설정 등을 지원한다.

## 목차

- [설치 및 초기화](#설치-및-초기화)
- [Xcode 프로젝트 설정](#xcode-프로젝트-설정)
- [Notification Service Extension 설정](#notification-service-extension-설정)
- [Quick Start](#quick-start)
- [APNs 토큰 수신](#apns-토큰-수신)
- [UNUserNotificationCenterDelegate 처리](#unusernotificationcenterdelegate-처리)
- [SwiftUI에서 알림 권한 요청](#swiftui에서-알림-권한-요청)
- [setPushHandler + handleNotification 패턴](#setpushhandler--handlenotification-패턴)
- [actionType 동작 분기](#actiontype-동작-분기)
- [APNs Payload 구조](#apns-payload-구조)
- [Notification Service Extension 연동](#notification-service-extension-연동)
- [미확인 메시지 자동 복구](#미확인-메시지-자동-복구)
- [PushMessage 모델](#pushmessage-모델)
- [API 레퍼런스](#api-레퍼런스)

---

## 설치 및 초기화

SPM에서 `AppManagerCore` + `AppManagerPush` 모듈을 추가한다.

```swift
import AppManagerCore
import AppManagerPush

AppManager.shared.configure(config: AppManagerConfig(
    apiKey: "pk_your_api_key",
    serverUrl: "https://your-platform.com",
    logLevel: .debug
))
```

> apiKey와 serverUrl은 Keychain에 자동 저장된다.
> Notification Service Extension에서 사용하려면 Keychain Sharing 설정이 필요하다.

---

## Xcode 프로젝트 설정

### 1. Push Notifications Capability

Target > Signing & Capabilities > **+ Capability** > **Push Notifications**

### 2. Background Modes

Target > Signing & Capabilities > **+ Capability** > **Background Modes** > **Remote notifications** 체크

### 3. Keychain Sharing (Extension 사용 시)

메인 앱과 Notification Service Extension이 apiKey/serverUrl을 공유하기 위해 Keychain Sharing을 설정한다.

1. 메인 앱 Target > Signing & Capabilities > **+ Capability** > **Keychain Sharing**
2. Keychain Group 추가 (예: `com.yourapp.shared`)
3. Extension Target에도 동일한 Keychain Group 추가

> 양쪽 Target에 같은 Keychain Group이 첫 번째로 등록되어 있어야 한다.

---

## Notification Service Extension 설정

이미지 푸시, 수신 확인 등의 기능을 위해 Notification Service Extension을 추가한다.

### 1. Extension Target 생성

Xcode > File > New > Target > **Notification Service Extension**
- Product Name: `NotificationServiceExtension`
- Finish

### 2. SPM 의존성 추가

Extension Target에도 `AppManagerCore`와 `AppManagerPush`를 추가한다:
- Project > Package Dependencies에서 이미 추가한 appmanager-ios 패키지 확인
- Extension Target > General > Frameworks and Libraries > `AppManagerCore`, `AppManagerPush` 추가

### 3. Extension 코드 구현

```swift
// NotificationServiceExtension/NotificationService.swift
import UserNotifications
import AppManagerCore
import AppManagerPush

class NotificationService: UNNotificationServiceExtension {
    
    var contentHandler: ((UNNotificationContent) -> Void)?
    var bestAttemptContent: UNMutableNotificationContent?
    private var pushManager: PushManager?
    
    override func didReceive(
        _ request: UNNotificationRequest,
        withContentHandler contentHandler: @escaping (UNNotificationContent) -> Void
    ) {
        self.contentHandler = contentHandler
        bestAttemptContent = (request.content.mutableCopy() as? UNMutableNotificationContent)
        
        guard let content = bestAttemptContent else {
            contentHandler(request.content)
            return
        }
        
        let userInfo = content.userInfo
        
        // Keychain에서 SDK 설정 복원
        pushManager = PushManager.configureFromSharedStorage()
        
        // 미확인 메시지로 마킹 (앱 미실행 시 복구용)
        if let appPush = userInfo["appPush"] as? [String: Any],
           let messageId = appPush["messageId"] as? String {
            pushManager?.markUnconfirmed(messageId: messageId)
        }
        
        // 수신 확인 전송
        pushManager?.sendReceiveConfirm(notification: userInfo) {
            // 수신 확인 완료 후 미확인 해제
            if let appPush = userInfo["appPush"] as? [String: Any],
               let messageId = appPush["messageId"] as? String {
                self.pushManager?.removeUnconfirmed(messageId: messageId)
            }
        }
        
        // 이미지 푸시 처리
        if let appPush = userInfo["appPush"] as? [String: Any],
           let imageUrl = appPush["imageUrl"] as? String,
           let url = URL(string: imageUrl) {
            downloadImage(url: url) { attachment in
                if let attachment = attachment {
                    content.attachments = [attachment]
                }
                contentHandler(content)
            }
        } else {
            contentHandler(content)
        }
    }
    
    override func serviceExtensionTimeWillExpire() {
        if let contentHandler = contentHandler,
           let content = bestAttemptContent {
            contentHandler(content)
        }
    }
    
    private func downloadImage(url: URL, completion: @escaping (UNNotificationAttachment?) -> Void) {
        URLSession.shared.downloadTask(with: url) { tempUrl, response, error in
            guard let tempUrl = tempUrl, error == nil else {
                completion(nil)
                return
            }
            let fileUrl = tempUrl.appendingPathExtension("jpg")
            try? FileManager.default.moveItem(at: tempUrl, to: fileUrl)
            let attachment = try? UNNotificationAttachment(identifier: "image", url: fileUrl, options: nil)
            completion(attachment)
        }.resume()
    }
}
```

---

## Quick Start

```swift
// AppDelegate.swift
import UIKit
import UserNotifications
import AppManagerCore
import AppManagerPush

@main
class AppDelegate: UIResponder, UIApplicationDelegate, UNUserNotificationCenterDelegate {
    
    func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
    ) -> Bool {
        
        // 1. SDK 초기화
        AppManager.shared.configure(config: AppManagerConfig(
            apiKey: "pk_your_api_key",
            serverUrl: "https://your-platform.com"
        ))
        
        // 2. 푸시 알림 탭 핸들러 등록
        AppManager.shared.pushSDK.setPushHandler { message in
            print("푸시 탭: \(message.title ?? ""), messageId: \(message.messageId)")
            
            // actionType에 따른 화면 이동 처리
            if let data = message.data,
               let actionType = (data["actionType"]?.value as? Int) ?? 
                                Int(data["actionType"]?.value as? String ?? "") {
                switch actionType {
                case 1: // 웹 URL 열기
                    if let webUrl = data["webUrl"]?.value as? String {
                        // 웹뷰 또는 Safari 열기
                    }
                case 2: // 특정 메뉴 이동
                    if let menuId = data["menuId"]?.value as? String {
                        // 해당 메뉴로 이동
                    }
                case 3: // 팝업 이미지 표시
                    if let popupImgUrl = data["popupImgUrl"]?.value as? String {
                        let popupUrl = data["popupUrl"]?.value as? String
                        // 팝업 이미지 표시, popupUrl이 있으면 이미지 탭 시 해당 URL로 이동
                    }
                default: // 0: 앱 실행만
                    break
                }
            }
        }
        
        // 3. UNUserNotificationCenter 델리게이트 설정
        UNUserNotificationCenter.current().delegate = self
        
        // 4. 알림 권한 요청
        UNUserNotificationCenter.current().requestAuthorization(
            options: [.alert, .badge, .sound]
        ) { _, _ in }
        
        // 5. APNs 토큰 등록 (권한과 무관하게 토큰 발급)
        application.registerForRemoteNotifications()
        
        return true
    }
    
    // 6. APNs 토큰 수신 -> SDK에 전달 + 서버 등록
    func application(
        _ application: UIApplication,
        didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data
    ) {
        let token = deviceToken.map { String(format: "%02.2hhx", $0) }.joined()
        AppManager.shared.pushSDK.setDeviceToken(token)
        AppManager.shared.pushSDK.register(userId: "user123")
    }
    
    func application(
        _ application: UIApplication,
        didFailToRegisterForRemoteNotificationsWithError error: Error
    ) {
        print("APNs 등록 실패: \(error.localizedDescription)")
    }
    
    // MARK: - UNUserNotificationCenterDelegate
    
    // 7. 포그라운드에서 알림 수신 시 표시 방법
    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification,
        withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
    ) {
        completionHandler([.banner, .badge, .sound])
    }
    
    // 8. 알림 탭 시 처리
    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        didReceive response: UNNotificationResponse,
        withCompletionHandler completionHandler: @escaping () -> Void
    ) {
        let userInfo = response.notification.request.content.userInfo
        AppManager.shared.pushSDK.handleNotification(userInfo)
        completionHandler()
    }
}
```

---

## APNs 토큰 수신

APNs에서 발급한 디바이스 토큰을 SDK에 전달한다.

```swift
func application(
    _ application: UIApplication,
    didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data
) {
    // Data -> hex String 변환
    let token = deviceToken.map { String(format: "%02.2hhx", $0) }.joined()
    
    // SDK에 토큰 설정
    AppManager.shared.pushSDK.setDeviceToken(token)
    
    // 서버에 디바이스 등록 (userId 지정 가능, 미지정 시 deviceId 사용)
    AppManager.shared.pushSDK.register(userId: "user123")
}
```

> `setDeviceToken()`은 반드시 `register()` 전에 호출해야 한다.
> 토큰 미설정 상태에서 `register()`를 호출하면 등록이 실패한다.

---

## UNUserNotificationCenterDelegate 처리

### willPresent (포그라운드 알림 표시)

앱이 포그라운드에 있을 때 알림을 어떻게 표시할지 결정한다.

```swift
func userNotificationCenter(
    _ center: UNUserNotificationCenter,
    willPresent notification: UNNotification,
    withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
) {
    // 배너 + 뱃지 + 사운드 표시
    completionHandler([.banner, .badge, .sound])
}
```

### didReceive (알림 탭 처리)

사용자가 알림을 탭했을 때 호출된다.

```swift
func userNotificationCenter(
    _ center: UNUserNotificationCenter,
    didReceive response: UNNotificationResponse,
    withCompletionHandler completionHandler: @escaping () -> Void
) {
    let userInfo = response.notification.request.content.userInfo
    
    // SDK가 열람 확인 전송 + pushHandler 호출
    AppManager.shared.pushSDK.handleNotification(userInfo)
    
    completionHandler()
}
```

---

## SwiftUI에서 알림 권한 요청

```swift
import SwiftUI
import AppManagerCore
import AppManagerPush

@main
struct MyApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .onAppear {
                    requestNotificationPermission()
                }
        }
    }
    
    private func requestNotificationPermission() {
        UNUserNotificationCenter.current().requestAuthorization(
            options: [.alert, .badge, .sound]
        ) { _, _ in }
        
        UIApplication.shared.registerForRemoteNotifications()
    }
}
```

> SwiftUI에서도 APNs 토큰 수신은 `UIApplicationDelegate`의 `didRegisterForRemoteNotificationsWithDeviceToken`을 통해 처리한다.
> `@UIApplicationDelegateAdaptor`를 사용하여 AppDelegate를 연결한다.

---

## setPushHandler + handleNotification 패턴

`setPushHandler`와 `handleNotification`은 알림 탭 시 동작을 처리하는 핵심 패턴이다.

### 동작 흐름

```
사용자가 알림 탭
  -> didReceive에서 handleNotification(userInfo) 호출
  -> SDK가 userInfo에서 appPush 데이터 추출
  -> 열람 확인(open) 서버 전송
  -> PushMessage 객체 생성
  -> setPushHandler에 등록된 핸들러에 PushMessage 전달 (메인 스레드)
  -> 앱에서 actionType에 따라 화면 이동 처리
```

### 사용 예시

```swift
// 초기화 시 1회 등록
AppManager.shared.pushSDK.setPushHandler { message in
    // message.data에서 actionType, webUrl, menuId 등 추출하여 처리
    print("푸시 메시지: \(message.title ?? ""), ID: \(message.messageId)")
}

// didReceive에서 호출
func userNotificationCenter(
    _ center: UNUserNotificationCenter,
    didReceive response: UNNotificationResponse,
    withCompletionHandler completionHandler: @escaping () -> Void
) {
    AppManager.shared.pushSDK.handleNotification(
        response.notification.request.content.userInfo
    )
    completionHandler()
}
```

> `handleNotification`은 `appPush` 키가 없는 알림에 대해 `false`를 반환하고 무시한다.
> 반환값을 사용하면 SDK 알림과 다른 알림을 구분할 수 있다.

---

## actionType 동작 분기

서버에서 전송하는 `actionType` 값에 따라 알림 탭 시 동작을 분기한다.

| actionType | 동작 | data 키 |
|------------|------|---------|
| `0` | 앱 실행만 (기본) | - |
| `1` | 웹 URL 열기 | `webUrl` |
| `2` | 특정 메뉴/화면 이동 | `menuId` |
| `3` | 팝업 이미지 표시 | `popupImgUrl`, `popupUrl` (선택) |

```swift
AppManager.shared.pushSDK.setPushHandler { message in
    guard let data = message.data else { return }
    
    let actionType = (data["actionType"]?.value as? Int)
        ?? Int(data["actionType"]?.value as? String ?? "")
        ?? 0
    
    switch actionType {
    case 0:
        // 앱 실행만 — 별도 처리 불필요
        break
        
    case 1:
        // 웹 URL 열기
        if let webUrl = data["webUrl"]?.value as? String,
           let url = URL(string: webUrl) {
            // 인앱 웹뷰 또는 Safari로 열기
        }
        
    case 2:
        // 특정 메뉴로 이동
        if let menuId = data["menuId"]?.value as? String {
            // menuId에 해당하는 화면으로 이동
        }
        
    case 3:
        // 팝업 이미지 표시
        if let popupImgUrl = data["popupImgUrl"]?.value as? String {
            // 팝업 이미지 표시
            // popupUrl이 있으면 이미지 탭 시 해당 URL로 이동
            let popupUrl = data["popupUrl"]?.value as? String
        }
        
    default:
        break
    }
}
```

---

## APNs Payload 구조

서버에서 전송하는 APNs payload 구조:

```json
{
    "aps": {
        "alert": {
            "title": "알림 제목",
            "body": "알림 본문"
        },
        "badge": 1,
        "sound": "default",
        "mutable-content": 1
    },
    "appPush": {
        "messageId": "msg_abc123",
        "title": "알림 제목",
        "body": "알림 본문",
        "imageUrl": "https://example.com/image.jpg",
        "messageType": "marketing",
        "actionType": 1,
        "webUrl": "https://example.com/promotion"
    }
}
```

| 키 | 타입 | 설명 |
|----|------|------|
| `aps` | Object | APNs 표준 payload |
| `appPush.messageId` | String | 메시지 고유 ID (수신/열람 확인에 사용) |
| `appPush.title` | String | 알림 제목 |
| `appPush.body` | String | 알림 본문 |
| `appPush.imageUrl` | String | 이미지 URL (Extension에서 첨부) |
| `appPush.messageType` | String | 메시지 유형 코드 |
| `appPush.actionType` | Int | 동작 유형 (0: 앱 실행, 1: 웹 URL, 2: 메뉴, 3: 팝업) |
| `appPush.webUrl` | String | actionType 1에서 열 웹 URL |
| `appPush.menuId` | String | actionType 2에서 이동할 메뉴 ID |
| `appPush.popupImgUrl` | String | actionType 3에서 표시할 팝업 이미지 URL |
| `appPush.popupUrl` | String | actionType 3에서 이미지 탭 시 이동 URL |

> `mutable-content: 1`은 Notification Service Extension이 알림을 수정할 수 있게 한다.

---

## Notification Service Extension 연동

### configureFromSharedStorage

Extension은 메인 앱과 프로세스가 다르므로, Keychain Sharing을 통해 SDK 설정을 복원한다.

```swift
// Extension에서 PushManager 복원
let pushManager = PushManager.configureFromSharedStorage()
```

> 메인 앱에서 `AppManager.shared.configure()`를 호출하면, SDK가 자동으로 `apiKey`와 `serverUrl`을 Keychain에 저장한다.
> Extension에서 `configureFromSharedStorage()`를 호출하면 Keychain에서 설정을 복원하여 PushManager 인스턴스를 생성한다.
> Keychain Sharing이 활성화되어 있어야 Extension에서 접근 가능하다.

### Extension에서 수신 확인 전송

```swift
// Extension에서 수신 확인 (completion 콜백 지원)
pushManager?.sendReceiveConfirm(notification: userInfo) {
    // 완료 후 contentHandler 호출
    contentHandler(content)
}
```

---

## 미확인 메시지 자동 복구

Extension에서 수신 확인 전송에 실패한 경우 (네트워크 오류 등), 미확인 메시지로 마킹하여 메인 앱 실행 시 자동 복구한다.

### 동작 흐름

```
Extension에서 알림 수신
  -> markUnconfirmed(messageId:) 호출
  -> 수신 확인 전송 시도
  -> 성공 시: removeUnconfirmed(messageId:) 호출
  -> 실패 시: 미확인 상태 유지
  
메인 앱에서 register() 성공 시
  -> 미확인 메시지 목록 조회
  -> 각 메시지에 대해 수신 확인 재전송
  -> 완료된 메시지를 미확인 목록에서 제거
```

### Extension 코드

```swift
// 미확인 마킹
pushManager?.markUnconfirmed(messageId: messageId)

// 수신 확인 전송
pushManager?.sendReceiveConfirm(notification: userInfo) {
    // 성공 시 미확인 해제
    self.pushManager?.removeUnconfirmed(messageId: messageId)
}
```

---

## PushMessage 모델

```swift
public struct PushMessage: Codable, Sendable, Identifiable {
    public let messageId: String           // 메시지 고유 ID
    public let title: String?              // 알림 제목
    public let body: String?               // 알림 본문
    public let imageUrl: String?           // 이미지 URL
    public let data: [String: AnyCodable]? // 커스텀 데이터 (actionType, webUrl, menuId 등)
    public let messageType: String?        // 메시지 유형 코드
    public let status: String?             // 메시지 상태 (인박스 조회 시)
    public let sentAt: String?             // 발송 시각 (인박스 조회 시)
    public let openedAt: String?           // 열람 시각 (인박스 조회 시)
    
    public var id: String { messageId }
}
```

### data 필드의 주요 키

| 키 | 타입 | 설명 |
|----|------|------|
| `actionType` | `Int` 또는 `String` | 동작 유형 (0~3) |
| `webUrl` | `String` | 웹 URL (actionType 1) |
| `menuId` | `String` | 메뉴 ID (actionType 2) |
| `popupImgUrl` | `String` | 팝업 이미지 URL (actionType 3) |
| `popupUrl` | `String` | 팝업 이미지 탭 시 이동 URL (actionType 3) |

> `data`의 값은 `AnyCodable` 타입이므로, `.value` 프로퍼티로 `Any` 값에 접근한 후 캐스팅한다.

### InboxResponse 모델

```swift
public struct InboxResponse: Codable, Sendable {
    public let messages: [PushMessage]
    public let page: Int
    public let size: Int
    public let total: Int
    public let hasMore: Bool
}
```

---

## API 레퍼런스

`AppManager.shared.pushSDK`를 통해 접근한다.

### 초기화

| 메서드 | 설명 |
|--------|------|
| `setDeviceToken(_ token: String)` | APNs 디바이스 토큰 설정. hex 문자열로 변환하여 전달 |
| `register(userId: String?)` | 디바이스를 서버에 등록. userId 미지정 시 로컬 deviceId 사용 |
| `configureFromSharedStorage() -> PushManager?` | (static) Keychain에서 설정 복원. Extension에서 사용 |

### 푸시 핸들러

| 메서드 | 설명 |
|--------|------|
| `setPushHandler(_ handler: (PushMessage) -> Void)` | 알림 탭 핸들러 등록. handleNotification에서 추출한 PushMessage 전달 |
| `handleNotification(_ userInfo: [AnyHashable: Any]) -> Bool` | 알림 탭 처리. 열람 확인 전송 + pushHandler 호출. appPush 키 없으면 false 반환 |

### 알림 설정

| 메서드 | 설명 |
|--------|------|
| `setAllowPush(allow: Bool)` | 전체 푸시 수신 허용/거부 |
| `setDND(enabled: Bool, startTime: String?, endTime: String?)` | 방해금지 시간 설정. startTime/endTime 형식: `"HH:mm"`. 둘 다 nil이면 해제 |
| `setAllowType(messageTypeCode: String, enabled: Bool)` | 메시지 유형별 수신 허용/거부 |

### 수신/열람 확인

| 메서드 | 설명 |
|--------|------|
| `sendReceiveConfirm(notification:)` | 수신 확인 전송 (fire-and-forget) |
| `sendReceiveConfirm(notification:completion:)` | 수신 확인 전송 + 완료 콜백 (Extension용) |
| `open(messageId: String)` | 메시지 열람 확인 전송 |
| `openAll()` | 전체 메시지 열람 처리 |

### 메시지함/뱃지

| 메서드 | 설명 |
|--------|------|
| `getInbox(page: Int, size: Int, completion: (InboxResponse) -> Void)` | 메시지함 조회. 기본값: page=1, size=20 |
| `getMessageDetail(messageId: String, completion: (PushMessage?) -> Void)` | 메시지 상세 조회 |
| `getBadgeCount(completion: (Int) -> Void)` | 미열람 메시지 수 조회 |

### 미확인 메시지 관리

| 메서드 | 설명 |
|--------|------|
| `markUnconfirmed(messageId: String)` | 미확인 메시지로 마킹 (Extension에서 호출) |
| `removeUnconfirmed(messageId: String)` | 미확인 메시지 해제 (수신 확인 성공 후) |

### 계정

| 메서드 | 설명 |
|--------|------|
| `logout(disablePush: Bool)` | 로그아웃. disablePush=true이면 푸시 수신 비활성화 후 deviceId로 재등록 |

### 프로퍼티

| 프로퍼티 | 타입 | 설명 |
|----------|------|------|
| `isConfigured` | `Bool` | Push 초기화 완료 여부 |
| `currentUserId` | `String` | 현재 userId (미설정 시 deviceId) |

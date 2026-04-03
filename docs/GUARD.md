# Guard SDK 가이드 (iOS)

앱 보안 위협 탐지를 위한 Guard 서비스 상세 가이드.
탈옥, 디버거, 후킹, 무결성, 시뮬레이터, VPN, USB 디버그, 서명 검증, 화면 캡처 등 9종의 보안 위협을 탐지한다.

## 목차

- [설치 및 초기화](#설치-및-초기화)
- [Quick Start](#quick-start)
- [초기화 방식](#초기화-방식)
- [정책 우선순위](#정책-우선순위)
- [초기화 2단계](#초기화-2단계)
- [GuardCallback 프로토콜](#guardcallback-프로토콜)
- [Detection Types (9종)](#detection-types-9종)
- [GuardOptions 옵션](#guardoptions-옵션)
- [API 레퍼런스](#api-레퍼런스)

---

## 설치 및 초기화

SPM에서 `AppManagerCore` + `AppManagerGuard` 모듈을 추가한다.

```swift
import AppManagerCore
import AppManagerGuard

AppManager.shared.configure(config: AppManagerConfig(
    apiKey: "pk_your_api_key",
    serverUrl: "https://your-platform.com",
    logLevel: .debug,
    guard: GuardOptions(
        enableJailbreakDetection: true,
        enableDebuggerDetection: true,
        enableHookingDetection: true,
        detectionInterval: 60
    )
))
```

---

## Quick Start

### 권장 패턴: initialize -> onReady -> startDetection

```swift
class ViewController: UIViewController, GuardCallback {
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // 1. 콜백과 함께 초기화 (서버 정책 + 동적 시그니처 fetch)
        AppManager.shared.guardSDK.initialize(callback: self)
    }
    
    // MARK: - GuardCallback
    
    func onReady(policySource: PolicySource) {
        // 2. 서버 정책 수신 완료 (또는 캐시/기본 폴백)
        print("Guard 준비 완료 (정책: \(policySource.rawValue))")
        
        // 3. 주기적 탐지 시작
        AppManager.shared.guardSDK.startDetection()
    }
    
    func onDetection(result: DetectionResult) {
        // 4. 개별 위협 탐지 시
        print("위협 탐지: \(result.type.rawValue), 액션: \(result.action.rawValue)")
        
        if result.action == .block {
            // 앱 종료 또는 기능 차단 처리
        } else if result.action == .warn {
            // 경고 팝업 표시
        }
    }
    
    func onDetectionBatch(results: [DetectionResult], action: DetectAction) {
        // 5. 탐지 사이클 완료 시 전체 결과 + 최고 우선순위 액션
        print("탐지 완료: \(results.count)건, 최종 액션: \(action.rawValue)")
        
        switch action {
        case .block:
            // 앱 사용 차단
            break
        case .warn:
            // 경고 표시
            break
        case .log, .none:
            // 정상 동작 유지
            break
        }
    }
    
    func onError(error: SdkError) {
        // 6. SDK 내부 오류 (네트워크 등)
        print("Guard 오류: \(error.localizedDescription)")
    }
}
```

---

## 초기화 방식

Guard는 두 가지 방식으로 사용할 수 있다.

### 방식 1: initialize() 호출 (권장)

서버에서 보안 정책과 동적 시그니처를 받아온 후 `onReady` 콜백을 호출한다.

```swift
AppManager.shared.guardSDK.initialize(callback: self)
```

- 서버 연결 성공: 서버 정책 적용 -> `onReady(policySource: .server)`
- 서버 연결 실패 + 캐시 있음: 캐시 정책 적용 -> `onReady(policySource: .cached)`
- 서버 연결 실패 + 캐시 없음: GuardOptions 기본 정책 -> `onReady(policySource: .config)`

### 방식 2: initialize() 없이 바로 startDetection/runDetection

서버 정책 없이 `GuardOptions` 설정값과 캐시(있는 경우)로만 동작한다.

```swift
// initialize() 없이 바로 탐지 시작
AppManager.shared.guardSDK.setCallback(self)
AppManager.shared.guardSDK.startDetection()
```

> 내부 초기화(`ensureInitialized`)가 자동으로 실행되어 GuardOptions/캐시 기반 정책을 적용한다.
> 서버 정책은 받아오지 않으므로 동적 시그니처나 서버에서 변경한 정책은 반영되지 않는다.

---

## 정책 우선순위

Guard는 다음 우선순위에 따라 보안 정책을 적용한다:

```
서버 정책 (최우선) > 캐시된 정책 > GuardOptions 설정 > 기본값 (모든 탐지 비활성)
```

| 우선순위 | 출처 | 적용 시점 | PolicySource |
|----------|------|-----------|--------------|
| 1 (최상) | 서버 | `initialize()` 호출 후 서버 응답 수신 시 | `.server` |
| 2 | 캐시 | 내부 초기화 시 저장된 정책이 있으면 자동 적용 | `.cached` |
| 3 | GuardOptions | 내부 초기화 시 config 설정값으로 기본 정책 생성 | `.config` |
| 4 (최하) | 기본값 | GuardOptions를 지정하지 않은 경우 모든 탐지 비활성 | `.config` |

> 서버 정책에는 탐지 유형별 활성화 여부뿐 아니라 액션(block/warn/log)도 포함된다.
> GuardOptions 기반 정책의 기본 액션은 모두 `log`이다.

---

## 초기화 2단계

Guard 초기화는 내부적으로 2단계로 진행된다.

### Phase 1: 로컬 초기화 (즉시)

`startDetection()`, `runDetection()`, 또는 `initialize()` 호출 시 자동 실행:

1. PolicyCache 초기화
2. PolicyEngine 생성 + 탐지기 9개 등록
3. GuardOptions 기반 초기 정책 적용
4. 캐시된 정책이 있으면 덮어쓰기 (GuardOptions보다 우선)
5. GuardApiClient 초기화
6. DetectionReporter 초기화 (배치 전송 + 재시도 + 오프라인 저장)

### Phase 2: 서버 동기화 (비동기, initialize() 호출 시만)

1. 서버에 SDK 초기화 요청 전송 (디바이스 정보 포함)
2. 서버 보안 정책 수신 및 PolicyEngine에 적용
3. 동적 시그니처 수신 및 탐지기에 적용 (탈옥 경로, 후킹 프레임워크 목록 등)
4. 수신한 정책을 로컬 캐시에 저장 (다음 실행 시 폴백용)
5. `onReady` 콜백 호출

---

## GuardCallback 프로토콜

```swift
public protocol GuardCallback: AnyObject {
    
    /// 서버 정책 수신 완료 시 1회 호출 (서버 실패 시 캐시/기본 폴백)
    func onReady(policySource: PolicySource)
    
    /// 개별 보안 위협 탐지 시 호출
    func onDetection(result: DetectionResult)
    
    /// 탐지 사이클 완료 시 전체 결과 + 최고 우선순위 액션 전달
    func onDetectionBatch(results: [DetectionResult], action: DetectAction)
    
    /// SDK 내부 오류 발생 시 호출
    func onError(error: SdkError)
}
```

### PolicySource

| 값 | 설명 |
|----|------|
| `.server` | 서버에서 새로 수신한 정책 적용 |
| `.cached` | 캐시된 서버 정책 적용 (오프라인 폴백) |
| `.config` | GuardOptions 기본값 적용 |

### DetectAction

| 값 | 설명 | 우선순위 |
|----|------|----------|
| `.block` | 앱 종료 또는 기능 차단 | 최상 |
| `.warn` | 호스트 앱에서 경고 UI 표시 | 상 |
| `.log` | 서버에 리포팅만 수행, 앱 동작에 영향 없음 | 하 |
| `.none` | 아무 동작 없음 | 최하 |

### DetectionResult

```swift
public struct DetectionResult {
    public let type: DetectionType      // 탐지 유형
    public let detected: Bool           // 위협 탐지 여부
    public let confidence: Float        // 탐지 신뢰도 (0.0 ~ 1.0)
    public let details: [String: String] // 상세 정보
    public let timestamp: Date          // 탐지 시점
    public let action: DetectAction     // 정책 기반 액션
}
```

---

## Detection Types (9종)

### 1. Jailbreak 탐지 (`DetectionType.jailbreak`)

탈옥된 디바이스를 탐지한다. Cydia, Sileo, checkra1n 등 탈옥 관련 파일/경로/앱 존재 여부를 검사한다.

| 항목 | 값 |
|------|------|
| rawValue | `"root"` |
| GuardOptions | `enableJailbreakDetection` |
| 탐지 방법 | 탈옥 앱/파일 경로 검사, sandbox 무결성 검사, 심볼릭 링크 검사 |

> 서버에서 동적 시그니처로 탐지 경로 목록을 업데이트할 수 있다.

### 2. Simulator 탐지 (`DetectionType.simulator`)

Xcode 시뮬레이터 환경에서 실행 중인지 탐지한다.

| 항목 | 값 |
|------|------|
| rawValue | `"emulator"` |
| GuardOptions | `enableSimulatorDetection` |
| 탐지 방법 | 아키텍처 검사, 시뮬레이터 전용 환경 변수/경로 검사 |

### 3. Debugger 탐지 (`DetectionType.debugger`)

디버거가 연결되어 있는지 탐지한다.

| 항목 | 값 |
|------|------|
| rawValue | `"debugger"` |
| GuardOptions | `enableDebuggerDetection` |
| 탐지 방법 | `sysctl` P_TRACED 플래그, exception ports 검사 |

### 4. Integrity (무결성) 검사 (`DetectionType.integrity`)

앱 바이너리가 변조되었는지 검증한다.

| 항목 | 값 |
|------|------|
| rawValue | `"integrity"` |
| GuardOptions | `enableIntegrityCheck` |
| 탐지 방법 | 바이너리 해시 비교 (서버에서 수신한 `codeHash` 기준) |

> 서버에서 `expectedBinaryHash`를 제공해야 정확한 검증이 가능하다.

### 5. Hooking 탐지 (`DetectionType.hooking`)

Frida, Cycript, Substrate 등 후킹 프레임워크가 로드되었는지 탐지한다.

| 항목 | 값 |
|------|------|
| rawValue | `"hooking"` |
| GuardOptions | `enableHookingDetection` |
| 탐지 방법 | dylib 목록 검사, 후킹 프레임워크 파일/포트 검사 |

> 서버에서 동적 시그니처로 탐지할 후킹 프레임워크 목록을 업데이트할 수 있다.

### 6. Signature (서명) 검증 (`DetectionType.signature`)

코드 서명 인증서가 변조되었는지 검증한다.

| 항목 | 값 |
|------|------|
| rawValue | `"signature"` |
| GuardOptions | `enableSignatureCheck` |
| 탐지 방법 | 인증서 해시 비교 (서버에서 수신한 `signatureHashes` 기준) |

> 서버에서 `expectedSignatureHash`를 제공해야 정확한 검증이 가능하다.

### 7. USB Debug 탐지 (`DetectionType.usbDebug`)

USB 디버깅이 가능한 환경인지 탐지한다.

| 항목 | 값 |
|------|------|
| rawValue | `"usb_debug"` |
| GuardOptions | `enableUsbDebugDetection` |
| 탐지 방법 | 디버그 환경 및 개발자 모드 관련 검사 |

### 8. VPN 탐지 (`DetectionType.vpn`)

VPN 연결이 활성화되어 있는지 탐지한다.

| 항목 | 값 |
|------|------|
| rawValue | `"vpn"` |
| GuardOptions | `enableVpnDetection` |
| 탐지 방법 | 네트워크 인터페이스(`utun`, `ipsec`, `ppp`) 검사 |

### 9. Screen Capture 탐지 (`DetectionType.screenCapture`)

화면 녹화, 미러링, 스크린샷을 감지한다.

| 항목 | 값 |
|------|------|
| rawValue | `"screen_capture"` |
| GuardOptions | `enableScreenCaptureBlock` |
| 탐지 방법 | `UIScreen.isCaptured` 모니터링, 스크린샷 Notification 감지 |

> iOS에서는 스크린샷을 사전 차단할 수 없으므로, 촬영 사후에 감지하여 서버에 리포트한다.
> 화면 녹화/미러링은 실시간으로 감지되며, `onDetection` 콜백으로 즉시 전달된다.

---

## GuardOptions 옵션

`AppManagerConfig`의 `guard` 파라미터로 전달한다.

```swift
AppManager.shared.configure(config: AppManagerConfig(
    apiKey: "pk_your_api_key",
    serverUrl: "https://your-platform.com",
    guard: GuardOptions(
        enableJailbreakDetection: true,
        enableDebuggerDetection: true,
        enableHookingDetection: true,
        enableVpnDetection: true,
        detectionInterval: 30
    )
))
```

| 옵션 | 타입 | 기본값 | 설명 |
|------|------|--------|------|
| `enableJailbreakDetection` | `Bool` | `false` | 탈옥 탐지 활성화 |
| `enableSimulatorDetection` | `Bool` | `false` | 시뮬레이터 탐지 활성화 |
| `enableDebuggerDetection` | `Bool` | `false` | 디버거 탐지 활성화 |
| `enableIntegrityCheck` | `Bool` | `false` | 무결성 검사 활성화 |
| `enableHookingDetection` | `Bool` | `false` | 후킹 탐지 활성화 |
| `enableSignatureCheck` | `Bool` | `false` | 서명 검사 활성화 |
| `enableUsbDebugDetection` | `Bool` | `false` | USB 디버그 탐지 활성화 |
| `enableVpnDetection` | `Bool` | `false` | VPN 탐지 활성화 |
| `enableScreenCaptureBlock` | `Bool` | `false` | 화면 캡처 탐지 활성화 |
| `detectionInterval` | `TimeInterval` | `60` (초) | 주기적 탐지 간격 (최소 10초) |
| `connectTimeoutSec` | `TimeInterval` | `10` (초) | HTTP 연결 타임아웃 |
| `readTimeoutSec` | `TimeInterval` | `15` (초) | HTTP 읽기 타임아웃 |

> GuardOptions의 탐지 활성화 설정은 `initialize()` 없이 사용할 때의 기본 정책이다.
> `initialize()`로 서버 정책을 수신하면 서버 설정이 우선 적용된다.

---

## API 레퍼런스

`AppManager.shared.guardSDK`를 통해 접근한다.

### 초기화/종료

| 메서드 | 설명 |
|--------|------|
| `initialize(callback:)` | Guard 초기화. 서버에서 정책 + 동적 시그니처를 받아온다. callback은 선택 사항으로, 미전달 시 기존 설정된 콜백 사용 |
| `setCallback(_:)` | Guard 콜백을 설정한다 (약한 참조) |
| `stop()` | Guard를 완전히 종료하고 리소스를 해제한다. 다시 `startDetection()`/`runDetection()` 호출 시 자동 재초기화 |

### 탐지 제어

| 메서드 | 설명 |
|--------|------|
| `startDetection()` | 주기적 보안 탐지를 시작한다. `detectionInterval` 주기로 반복 실행. 즉시 1회 탐지 후 타이머 시작 |
| `stopDetection()` | 주기적 탐지만 중지한다. Guard 초기화 상태는 유지되어 `startDetection()`으로 재개 가능 |
| `runDetection()` | 즉시 1회 탐지를 실행한다. 결과는 `onDetection`/`onDetectionBatch` 콜백으로 전달 |

### 프로퍼티

| 프로퍼티 | 타입 | 설명 |
|----------|------|------|
| `isInitialized` | `Bool` | 로컬 초기화 완료 여부 (Phase 1) |
| `isReady` | `Bool` | 서버 정책 수신 완료 여부 (Phase 2, 또는 폴백) |
| `isDetecting` | `Bool` | 주기적 탐지 실행 중 여부 |
| `policySource` | `PolicySource` | 현재 적용된 정책 출처 (`.server`, `.cached`, `.config`) |
| `callback` | `GuardCallback?` | 현재 설정된 콜백 (약한 참조) |

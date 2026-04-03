# Table 서비스 (iOS)

서버에 등록된 커스텀 테이블 데이터를 조회한다. SDK는 **조회 전용**이며, 데이터 등록/수정/삭제는 대시보드에서 수행한다.

> Table은 core에 내장되어 있어 별도 모듈 import 없이 `AppManagerCore`만으로 사용 가능하다.

## 사용법

### async/await

```swift
import AppManagerCore

let result = await AppManager.shared.tableSDK.get("app_version")

switch result {
case .success(let table):
    print("테이블: \(table.name)")
    print("컬럼: \(table.columns)")  // ["platform", "version", "force_update"]
    
    for row in table.rows {
        let id = row["id"]?.intValue       // 1
        let platform = row["platform"]?.stringValue  // "android"
        let version = row["version"]?.stringValue    // "1.0.1"
        print("\(id ?? 0): \(platform ?? "") \(version ?? "")")
    }
    
case .error(let code, let message):
    print("에러(\(code)): \(message)")
    
case .networkError(let error):
    print("네트워크 에러: \(error.localizedDescription)")
}
```

### 콜백 (메인 스레드)

```swift
AppManager.shared.tableSDK.get("app_version") { result in
    // 메인 스레드에서 실행 — UI 갱신 바로 가능
    switch result {
    case .success(let table):
        self.versionLabel.text = table.rows.first?["version"]?.stringValue
    case .error(_, let message):
        self.showAlert(message)
    case .networkError:
        self.showAlert("네트워크 오류")
    }
}
```

## API

### `tableSDK.get(_ tableName: String) async -> ApiResult<TableResponse>`

테이블 데이터를 비동기로 조회한다.

- **tableName**: 대시보드에서 생성한 테이블 이름 (예: `"app_version"`, `"notice"`)
- **Returns**: `ApiResult<TableResponse>`

### `tableSDK.get(_ tableName: String, completion: @escaping (ApiResult<TableResponse>) -> Void)`

콜백 방식으로 조회한다. 콜백은 **메인 스레드**에서 실행된다.

## 응답 모델

### TableResponse

| 프로퍼티 | 타입 | 설명 |
|----------|------|------|
| `name` | `String` | 테이블 이름 |
| `columns` | `[String]` | 컬럼 이름 목록 (순서 보장) |
| `rows` | `[[String: AnyCodable]]` | Row 목록 (서버 JSON 그대로) |

### Row 접근

각 Row는 `[String: AnyCodable]` 딕셔너리이며, 컬럼명을 키로 접근한다:

```swift
let row = table.rows[0]
row["id"]?.intValue        // Int? — Row ID (auto increment)
row["platform"]?.stringValue   // String — 컬럼 값
row["version"]?.stringValue    // String — 컬럼 값
```

- `intValue`: Int 타입 반환 (id 접근용)
- `stringValue`: String 타입 반환 (모든 값을 문자열로 변환)
- `value`: Any 타입 원본 값

## 에러 처리

| 상황 | ApiResult | code |
|------|-----------|------|
| 정상 조회 | `.success(TableResponse)` | - |
| 테이블 없음 | `.error(404, "테이블을 찾을 수 없습니다")` | 404 |
| API Key 없음/유효하지 않음 | `.error(401, ...)` | 401 |
| 요청 초과 | `.error(429, ...)` | 429 |
| 네트워크 오류 | `.networkError(Error)` | - |

## 참고

- SDK는 조회 전용 (insert/update/delete 불가)
- 서버에서 Redis 캐싱 적용 (5분 TTL, 대시보드 변경 시 즉시 갱신)
- `columns` 목록으로 어떤 컬럼이 있는지 확인 가능
- 미입력 컬럼은 빈 문자열(`""`)로 내려옴

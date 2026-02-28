# test_api.sh スクリプト解説

## 概要

`test_api.sh` は、Todo APIの全CRUD操作とバリデーションを詳細にテストする包括的なテストスクリプトです。

**smoke_test.shとの違い**:
- より多くのテストケース（12項目）
- 複数のTodoを作成してテスト
- バリデーションテスト（不正データ）
- 詳細なレスポンス表示（jq対応）
- テスト結果のカウント（成功/失敗の統計）

## 実行方法

```bash
# Quarkus（ポート8081）をテスト
./bench/test_api.sh

# Spring Boot（ポート8082）をテスト
./bench/test_api.sh 8082
```

**実行時間**: 約5秒

## テスト内容

全12項目のテスト：

### 1. CREATE（POST） - 3項目
- Todo 1を作成
- Todo 2を作成
- Todo 3を作成（completedがtrue）

### 2. READ（GET） - 2項目
- 全Todo取得
- ID指定取得

### 3. UPDATE（PUT） - 1項目
- 全フィールド更新

### 4. PARTIAL UPDATE（PATCH） - 1項目
- 部分更新（completedのみ）

### 5. DELETE - 2項目
- 削除
- 削除確認（404チェック）

### 6. VALIDATION TESTS - 3項目
- 空のtitleでエラー（400）
- titleなしでエラー（400）
- 存在しないID（404）

---

## スクリプトの全体構造

```
1. パラメータ処理
2. カラーコード定義
3. テストカウンタ初期化
4. check_server() 関数定義
5. test_endpoint() 関数定義
6. CREATE テスト（3個のTodo）
7. READ テスト
8. UPDATE テスト（PUT）
9. PARTIAL UPDATE テスト（PATCH）
10. DELETE テスト + 確認
11. VALIDATION テスト
12. テストサマリー表示
```

---

## 詳細解説

### 1. 初期設定（1-27行目）

```bash
#!/bin/bash

PORT=${1:-8081}
BASE_URL="http://localhost:$PORT"
API_URL="$BASE_URL/api/todos"
```

**smoke_test.shと同じ**: ポート番号のデフォルト値設定

```bash
# Color codes for output
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color
```

**追加のカラー**: `YELLOW` （警告メッセージ用）

```bash
# Test counter
TESTS_PASSED=0
TESTS_FAILED=0
```

**テストカウンタ**:
- 成功したテストの数をカウント
- 失敗したテストの数をカウント
- 最後にサマリーを表示

---

### 2. check_server() 関数（29-46行目）

```bash
check_server() {
    echo "Checking if server is running..."
    if curl -s -f "$BASE_URL/q/health/ready" > /dev/null 2>&1 || \
       curl -s -f "$BASE_URL/actuator/health" > /dev/null 2>&1; then
        echo -e "${GREEN}✓${NC} Server is ready"
        echo ""
        return 0
    else
        echo -e "${RED}✗${NC} Server is not running on port $PORT"
        echo ""
        echo "Start the server first:"
        echo "  Quarkus Native: ./quarkus-todo/target/quarkus-todo-1.0.0-SNAPSHOT-runner"
        echo "  Quarkus JVM:    java -jar quarkus-todo/target/quarkus-app/quarkus-run.jar"
        echo "  Spring Boot:    java -jar spring-todo/target/spring-todo-0.0.1-SNAPSHOT.jar"
        exit 1
    fi
}
```

**関数化の利点**:
- コードの再利用
- 可読性の向上
- メンテナンス性の向上

**return vs exit**:
- `return 0`: 関数から正常終了（スクリプトは継続）
- `exit 1`: スクリプト全体を異常終了

**ユーザーフレンドリー**:
- サーバーが起動していない場合、起動コマンドを表示
- ユーザーが次に何をすべきか明確

---

### 3. test_endpoint() 関数（48-83行目）⭐ 核心部分

```bash
test_endpoint() {
    local test_name="$1"
    local method="$2"
    local url="$3"
    local data="$4"
    local expected_status="$5"

    echo "Test: $test_name"

    if [ -n "$data" ]; then
        response=$(curl -s -w "\n%{http_code}" -X "$method" "$url" \
            -H "Content-Type: application/json" \
            -d "$data")
    else
        response=$(curl -s -w "\n%{http_code}" -X "$method" "$url")
    fi

    http_code=$(echo "$response" | tail -n1)
    body=$(echo "$response" | sed '$d')

    if [ "$http_code" = "$expected_status" ]; then
        echo -e "${GREEN}✓${NC} Status: $http_code (expected $expected_status)"
        TESTS_PASSED=$((TESTS_PASSED + 1))
        echo "$body" | jq . 2>/dev/null || echo "$body"
        echo ""
        echo "$body"
        return 0
    else
        echo -e "${RED}✗${NC} Status: $http_code (expected $expected_status)"
        TESTS_FAILED=$((TESTS_FAILED + 1))
        echo "Response: $body"
        echo ""
        return 1
    fi
}
```

**関数のパラメータ**:
1. `$1` (`test_name`): テストの名前（例: "Create Todo 1"）
2. `$2` (`method`): HTTPメソッド（GET, POST, PUT, PATCH, DELETE）
3. `$3` (`url`): リクエスト先URL
4. `$4` (`data`): リクエストボディ（オプション）
5. `$5` (`expected_status`): 期待されるHTTPステータスコード

**local変数**:
```bash
local test_name="$1"
```
- `local`: 関数内のローカル変数
- 関数外の変数と名前が衝突しない

**データの有無で分岐**:
```bash
if [ -n "$data" ]; then
    # データあり（POST, PUT, PATCH）
    response=$(curl -s -w "\n%{http_code}" -X "$method" "$url" \
        -H "Content-Type: application/json" \
        -d "$data")
else
    # データなし（GET, DELETE）
    response=$(curl -s -w "\n%{http_code}" -X "$method" "$url")
fi
```

**`[ -n "$data" ]`**: 文字列の長さが0より大きいかチェック

**レスポンス処理**:
```bash
http_code=$(echo "$response" | tail -n1)
body=$(echo "$response" | sed '$d')
```
- smoke_test.shと同じパターン

**テストカウンタの更新**:
```bash
TESTS_PASSED=$((TESTS_PASSED + 1))
```

**算術演算**:
- `$((式))`: 算術式の評価
- `TESTS_PASSED + 1`: 1を加算

**jqによる整形表示**:
```bash
echo "$body" | jq . 2>/dev/null || echo "$body"
```

**動作**:
1. `jq .`: JSONを整形して表示
2. `2>/dev/null`: jqのエラーメッセージを抑制
3. `|| echo "$body"`: jqが失敗したら（インストールされていない）、そのまま表示

**レスポンスボディの重複出力**:
```bash
echo "$body" | jq . 2>/dev/null || echo "$body"
echo ""
echo "$body"
```

**理由**: 関数の戻り値として使用するため
- `echo "$body"`: 関数の戻り値（変数に格納される）
- `jq .`: ユーザーへの表示

---

### 4. CREATE テスト（88-118行目）

```bash
echo "========================================="
echo "  1. CREATE (POST)"
echo "========================================="
echo ""

TODO1=$(test_endpoint \
    "Create Todo 1" \
    "POST" \
    "$API_URL" \
    '{"title":"Buy groceries","description":"Milk, eggs, bread"}' \
    "201")

TODO1_ID=$(echo "$TODO1" | jq -r '.id // empty' 2>/dev/null)
```

**関数呼び出しの戻り値**:
```bash
TODO1=$(test_endpoint ...)
```
- `test_endpoint` 関数が `echo "$body"` で出力した値が `TODO1` に格納される

**jqによるID抽出**:
```bash
TODO1_ID=$(echo "$TODO1" | jq -r '.id // empty' 2>/dev/null)
```

**jqオプション**:
- `-r`: Raw出力（ダブルクォートなし）
- `.id`: idフィールドを抽出
- `// empty`: idがない場合は空文字列

**例**:
```bash
# 入力
{"id":"1a2b3c4d-...","title":"Buy groceries",...}

# 出力
1a2b3c4d-e5f6-7890-abcd-ef1234567890
```

**3つのTodoを作成**:
```bash
TODO1=$(test_endpoint "Create Todo 1" ...)
TODO1_ID=$(echo "$TODO1" | jq -r '.id // empty' 2>/dev/null)

TODO2=$(test_endpoint "Create Todo 2" ...)
TODO2_ID=$(echo "$TODO2" | jq -r '.id // empty' 2>/dev/null)

TODO3=$(test_endpoint "Create Todo 3 (completed)" ...)
TODO3_ID=$(echo "$TODO3" | jq -r '.id // empty' 2>/dev/null)
```

**異なるデータでテスト**:
- Todo 1: 通常のTodo
- Todo 2: レポート作成（後でPUTテストに使用）
- Todo 3: **completedがtrue**（後でDELETEテストに使用）

---

### 5. READ テスト（120-139行目）

```bash
echo "========================================="
echo "  2. READ (GET)"
echo "========================================="
echo ""

test_endpoint \
    "Get all todos" \
    "GET" \
    "$API_URL" \
    "" \
    "200"
```

**データパラメータが空文字列**:
- GETリクエストにはボディがない
- `test_endpoint` 関数内で `[ -n "$data" ]` が false となり、`-d` オプションなしでcurlを実行

**ID指定取得**:
```bash
if [ -n "$TODO1_ID" ]; then
    test_endpoint \
        "Get Todo 1 by ID" \
        "GET" \
        "$API_URL/$TODO1_ID" \
        "" \
        "200"
fi
```

**IDの存在チェック**:
- `[ -n "$TODO1_ID" ]`: TODO1_IDが空でない場合
- CREATEが失敗した場合（IDが取得できなかった場合）はスキップ

---

### 6. UPDATE テスト - PUT（141-153行目）

```bash
echo "========================================="
echo "  3. UPDATE (PUT - Full Replace)"
echo "========================================="
echo ""

if [ -n "$TODO2_ID" ]; then
    test_endpoint \
        "Update Todo 2 (PUT)" \
        "PUT" \
        "$API_URL/$TODO2_ID" \
        '{"title":"Write Q4 report","description":"Updated: Q4 performance and metrics report","completed":false}' \
        "200"
fi
```

**PUTによる全更新**:
- 全フィールドを指定
- タイトルと説明を変更
- `completed` も明示的に指定

**変更内容**:
```
変更前: "Write report" / "Q4 performance report"
変更後: "Write Q4 report" / "Updated: Q4 performance and metrics report"
```

---

### 7. PARTIAL UPDATE テスト - PATCH（155-167行目）

```bash
echo "========================================="
echo "  4. PARTIAL UPDATE (PATCH)"
echo "========================================="
echo ""

if [ -n "$TODO1_ID" ]; then
    test_endpoint \
        "Mark Todo 1 as completed (PATCH)" \
        "PATCH" \
        "$API_URL/$TODO1_ID" \
        '{"completed":true}' \
        "200"
fi
```

**PATCHによる部分更新**:
- `completed` フィールドのみ指定
- タイトルや説明は変更されない

**PUTとPATCHの違いを明確にテスト**:
- PUT: 全フィールド指定（全更新）
- PATCH: 一部フィールド指定（部分更新）

---

### 8. DELETE テスト（169-195行目）

```bash
echo "========================================="
echo "  5. DELETE"
echo "========================================="
echo ""

if [ -n "$TODO3_ID" ]; then
    test_endpoint \
        "Delete Todo 3" \
        "DELETE" \
        "$API_URL/$TODO3_ID" \
        "" \
        "204"

    # Verify deletion
    echo "Verify Todo 3 is deleted"
    response=$(curl -s -w "\n%{http_code}" -X "GET" "$API_URL/$TODO3_ID")
    http_code=$(echo "$response" | tail -n1)

    if [ "$http_code" = "404" ]; then
        echo -e "${GREEN}✓${NC} Todo 3 is deleted (404 as expected)"
        TESTS_PASSED=$((TESTS_PASSED + 1))
    else
        echo -e "${RED}✗${NC} Todo 3 still exists (got $http_code, expected 404)"
        TESTS_FAILED=$((TESTS_FAILED + 1))
    fi
    echo ""
fi
```

**2段階のテスト**:

#### ステップ1: 削除実行
```bash
test_endpoint \
    "Delete Todo 3" \
    "DELETE" \
    "$API_URL/$TODO3_ID" \
    "" \
    "204"
```
- 期待されるステータスコード: **204 No Content**

#### ステップ2: 削除確認
```bash
echo "Verify Todo 3 is deleted"
response=$(curl -s -w "\n%{http_code}" -X "GET" "$API_URL/$TODO3_ID")
http_code=$(echo "$response" | tail -n1)

if [ "$http_code" = "404" ]; then
    echo -e "${GREEN}✓${NC} Todo 3 is deleted (404 as expected)"
    TESTS_PASSED=$((TESTS_PASSED + 1))
else
    echo -e "${RED}✗${NC} Todo 3 still exists (got $http_code, expected 404)"
    TESTS_FAILED=$((TESTS_FAILED + 1))
fi
```

**削除されたリソースへのGET**:
- 期待されるステータスコード: **404 Not Found**
- 削除が確実に実行されたことを確認

**手動でテストカウンタを更新**:
- `test_endpoint` 関数を使用していないため
- `TESTS_PASSED` または `TESTS_FAILED` を直接更新

---

### 9. VALIDATION テスト（197-221行目）

```bash
echo "========================================="
echo "  6. VALIDATION TESTS"
echo "========================================="
echo ""

test_endpoint \
    "Invalid: Empty title" \
    "POST" \
    "$API_URL" \
    '{"title":"","description":"Should fail"}' \
    "400"

test_endpoint \
    "Invalid: Missing title" \
    "POST" \
    "$API_URL" \
    '{"description":"Should fail"}' \
    "400"

test_endpoint \
    "Invalid: Get non-existent todo" \
    "GET" \
    "$API_URL/00000000-0000-0000-0000-000000000000" \
    "" \
    "404"
```

**バリデーションテスト**:

#### テスト1: 空のtitle
```json
{"title":"","description":"Should fail"}
```
- 期待: **400 Bad Request**
- 理由: titleは必須で、空文字列は不可

#### テスト2: titleなし
```json
{"description":"Should fail"}
```
- 期待: **400 Bad Request**
- 理由: titleフィールドが存在しない

#### テスト3: 存在しないID
```bash
"$API_URL/00000000-0000-0000-0000-000000000000"
```
- 期待: **404 Not Found**
- 理由: このUUIDのTodoは存在しない

**エラーケースのテストの重要性**:
- 正常系だけでなく、異常系も確認
- バリデーションが正しく機能しているか検証
- APIの堅牢性を確認

---

### 10. テストサマリー（223-237行目）

```bash
echo "========================================="
echo "  Test Summary"
echo "========================================="
echo ""
echo -e "Tests Passed: ${GREEN}$TESTS_PASSED${NC}"
echo -e "Tests Failed: ${RED}$TESTS_FAILED${NC}"
echo ""

if [ $TESTS_FAILED -eq 0 ]; then
    echo -e "${GREEN}All tests passed! ✓${NC}"
    exit 0
else
    echo -e "${RED}Some tests failed ✗${NC}"
    exit 1
fi
```

**テスト結果のカウント表示**:
```
Tests Passed: 12
Tests Failed: 0
```

**終了コードの決定**:
- `TESTS_FAILED -eq 0`: 失敗が0なら `exit 0`（成功）
- それ以外: `exit 1`（失敗）

**CI/CDでの利用**:
- 終了コードで成功/失敗を判定
- 失敗したテストがあればビルドを失敗させる

---

## 実行時の出力例

### 成功時

```
=========================================
  Todo API Test Suite
  Testing: http://localhost:8081
=========================================

Checking if server is running...
✓ Server is ready

=========================================
  1. CREATE (POST)
=========================================

Test: Create Todo 1
✓ Status: 201 (expected 201)
{
  "id": "1a2b3c4d-e5f6-7890-abcd-ef1234567890",
  "title": "Buy groceries",
  "description": "Milk, eggs, bread",
  "completed": false,
  "createdAt": "2026-02-27T10:30:00",
  "updatedAt": "2026-02-27T10:30:00"
}

Test: Create Todo 2
✓ Status: 201 (expected 201)
...

Test: Create Todo 3 (completed)
✓ Status: 201 (expected 201)
...

=========================================
  2. READ (GET)
=========================================

Test: Get all todos
✓ Status: 200 (expected 200)
[
  {...},
  {...},
  {...}
]

Test: Get Todo 1 by ID
✓ Status: 200 (expected 200)
...

=========================================
  3. UPDATE (PUT - Full Replace)
=========================================

Test: Update Todo 2 (PUT)
✓ Status: 200 (expected 200)
...

=========================================
  4. PARTIAL UPDATE (PATCH)
=========================================

Test: Mark Todo 1 as completed (PATCH)
✓ Status: 200 (expected 200)
...

=========================================
  5. DELETE
=========================================

Test: Delete Todo 3
✓ Status: 204 (expected 204)

Verify Todo 3 is deleted
✓ Todo 3 is deleted (404 as expected)

=========================================
  6. VALIDATION TESTS
=========================================

Test: Invalid: Empty title
✓ Status: 400 (expected 400)
...

Test: Invalid: Missing title
✓ Status: 400 (expected 400)
...

Test: Invalid: Get non-existent todo
✓ Status: 404 (expected 404)

=========================================
  Test Summary
=========================================

Tests Passed: 12
Tests Failed: 0

All tests passed! ✓
```

### 失敗時（バリデーションが機能していない）

```
...
=========================================
  6. VALIDATION TESTS
=========================================

Test: Invalid: Empty title
✗ Status: 201 (expected 400)
Response: {"id":"...","title":"","description":"Should fail"}

Test: Invalid: Missing title
✗ Status: 201 (expected 400)
Response: {"id":"...","description":"Should fail"}

Test: Invalid: Get non-existent todo
✓ Status: 404 (expected 404)

=========================================
  Test Summary
=========================================

Tests Passed: 10
Tests Failed: 2

Some tests failed ✗
```

**終了コード**: 1（失敗）

---

## スクリプトの特徴

### 1. 包括的

**12項目のテスト**:
- CRUD全操作
- バリデーション
- 削除確認

### 2. 関数による抽象化

**test_endpoint() 関数**:
- コードの重複を排除
- テストケースの追加が容易
- 一貫性のあるテスト実行

**使用例**:
```bash
test_endpoint \
    "テスト名" \
    "HTTPメソッド" \
    "URL" \
    "リクエストボディ（オプション）" \
    "期待されるステータスコード"
```

### 3. 詳細なレスポンス表示

**jq による整形**:
- JSONが見やすく表示される
- jqがない環境でも動作（フォールバック）

### 4. テスト結果の追跡

**カウンタ機能**:
- 成功/失敗の数を表示
- 全体の品質を一目で把握

### 5. エラーでも継続

**smoke_test.shとの違い**:
- smoke_test.sh: 1つでも失敗したら即座に終了
- test_api.sh: 失敗しても全テストを実行
- 全体像を把握できる

---

## よくある問題と解決方法

### 問題1: jqがインストールされていない

**症状**: JSONが整形されず、1行で表示される

**影響**: 動作には問題なし（見た目のみ）

**解決方法**:
```bash
# macOS
brew install jq

# Ubuntu/Debian
sudo apt-get install jq
```

### 問題2: バリデーションテストが失敗する

**症状**:
```
Test: Invalid: Empty title
✗ Status: 201 (expected 400)
```

**原因**: API実装のバリデーションが機能していない

**確認方法**:
```bash
# Entityクラスのバリデーションアノテーションを確認
cat quarkus-todo/src/main/java/com/demo/entity/Todo.java | grep -A 5 "title"
```

**期待される実装**:
```java
@NotBlank(message = "Title is required")
private String title;
```

### 問題3: テストが途中で止まる

**症状**: 特定のテストで応答がない

**原因**: サーバーがハングしている

**確認方法**:
```bash
# プロセスを確認
ps aux | grep -E "quarkus|spring"

# ログを確認
tail -f logs/quarkus.log
```

**対処法**:
```bash
# プロセスを強制終了
pkill -f quarkus-todo
pkill -f spring-todo

# 再起動
./quarkus-todo/target/quarkus-todo-1.0.0-SNAPSHOT-runner
```

---

## smoke_test.sh との比較

| 項目 | smoke_test.sh | test_api.sh |
|-----|--------------|-------------|
| **実行時間** | 約2秒 | 約5秒 |
| **テスト数** | 6項目 | 12項目 |
| **Todo作成数** | 1個 | 3個 |
| **バリデーションテスト** | なし | 3項目 |
| **削除確認** | なし | あり（404チェック） |
| **レスポンス表示** | なし | jq整形表示 |
| **テストカウンタ** | なし | あり |
| **関数化** | なし | check_server(), test_endpoint() |
| **エラー時の動作** | 即座に終了 | 継続実行 |
| **用途** | 素早い動作確認 | 詳細な機能テスト |
| **CI/CD** | スモークテスト | 統合テスト |

---

## 使用例

### 開発中のAPI検証

```bash
# アプリを起動
java -jar quarkus-todo/target/quarkus-app/quarkus-run.jar &

# 詳細テスト実行
./bench/test_api.sh

# ログ確認
cat logs/quarkus.log
```

### CI/CDパイプライン

```yaml
# .github/workflows/test.yml
- name: Build
  run: ./build_all.sh

- name: Start Application
  run: java -jar quarkus-todo/target/quarkus-app/quarkus-run.jar &

- name: Wait for Startup
  run: sleep 5

- name: Run API Tests
  run: ./bench/test_api.sh
```

### 両方のテストを実行

```bash
# まずスモークテスト（素早く基本確認）
./bench/smoke_test.sh

# 成功したら詳細テスト
./bench/test_api.sh
```

---

## 拡張のアイデア

このスクリプトをベースに、以下のような拡張が可能です：

### 1. 検索機能のテスト

```bash
test_endpoint \
    "Search by completed=false" \
    "GET" \
    "$API_URL?completed=false" \
    "" \
    "200"
```

### 2. 大量データのテスト

```bash
for i in {1..100}; do
    test_endpoint \
        "Create Todo $i" \
        "POST" \
        "$API_URL" \
        "{\"title\":\"Todo $i\"}" \
        "201"
done
```

### 3. パフォーマンステスト

```bash
start=$(date +%s%3N)
test_endpoint "Performance test" "GET" "$API_URL" "" "200"
end=$(date +%s%3N)
echo "Response time: $((end - start))ms"
```

---

## まとめ

`test_api.sh` は、以下を実現する包括的なAPIテストスクリプトです：

✅ **包括的**（全CRUD + バリデーション）
✅ **関数化**（test_endpoint で抽象化）
✅ **詳細表示**（jq による整形）
✅ **統計機能**（成功/失敗のカウント）
✅ **継続実行**（エラーでも全テストを実行）
✅ **CI/CD対応**（終了コードで判定）

smoke_test.shで基本動作を確認し、test_api.shで詳細な機能テストを行うのが推奨される使い方です。

# smoke_test.sh スクリプト解説

## 概要

`smoke_test.sh` は、Todo APIの基本的な動作を短時間（約2秒）で確認するクイックテストスクリプトです。

**スモークテストとは？**
- ソフトウェアの基本機能が動作するかを素早く確認するテスト
- 詳細なテストの前に「煙が出ていないか（基本的に動くか）」をチェック
- ビルド後やデプロイ後の動作確認に最適

## 実行方法

```bash
# Quarkus（ポート8081）をテスト
./bench/smoke_test.sh

# Spring Boot（ポート8082）をテスト
./bench/smoke_test.sh 8082
```

**実行時間**: 約2秒

## テスト内容

6つの基本的なCRUD操作をテストします：

1. ✅ Health check - サーバーが起動しているか
2. ✅ Create todo - Todo作成（POST）
3. ✅ List todos - 一覧取得（GET）
4. ✅ Get by ID - ID指定取得（GET）
5. ✅ Update todo - 更新（PATCH）
6. ✅ Delete todo - 削除（DELETE）

---

## スクリプトの全体構造

```
1. パラメータ処理（ポート番号）
2. カラーコード定義
3. Health check
4. Create - POST
5. List - GET (all)
6. Get - GET (by ID)
7. Update - PATCH
8. Delete - DELETE
9. 成功メッセージ
```

---

## 詳細解説

### 1. 初期設定（1-21行目）

```bash
#!/bin/bash

PORT=${1:-8081}
BASE_URL="http://localhost:$PORT"
API_URL="$BASE_URL/api/todos"
```

**パラメータのデフォルト値設定**:
```bash
PORT=${1:-8081}
```

**Bash構文の説明**:
- `${1:-8081}`: 第1引数が存在すればその値、なければ8081を使用
- これは以下と同じ意味：
  ```bash
  if [ -n "$1" ]; then
      PORT=$1
  else
      PORT=8081
  fi
  ```

**URL構築**:
```bash
BASE_URL="http://localhost:$PORT"
# 結果: http://localhost:8081 または http://localhost:8082

API_URL="$BASE_URL/api/todos"
# 結果: http://localhost:8081/api/todos
```

**カラーコードの定義**:
```bash
GREEN='\033[0;32m'
RED='\033[0;31m'
NC='\033[0m'  # No Color
```

**ANSI エスケープシーケンス**:
- `\033[0;32m`: 緑色
- `\033[0;31m`: 赤色
- `\033[0m`: 色をリセット

**使用例**:
```bash
echo -e "${GREEN}✓${NC}"  # 緑色の✓を表示
echo -e "${RED}✗${NC}"    # 赤色の✗を表示
```

**`-e`オプション**: エスケープシーケンスを解釈する

---

### 2. Health Check（23-31行目）

```bash
echo -n "1. Health check... "
if curl -s -f "$BASE_URL/q/health/ready" > /dev/null 2>&1 || \
   curl -s -f "$BASE_URL/actuator/health" > /dev/null 2>&1; then
    echo -e "${GREEN}✓${NC}"
else
    echo -e "${RED}✗ Server not running${NC}"
    exit 1
fi
```

**`echo -n`の意味**:
- `-n`: 改行を出力しない
- 結果が同じ行に表示される
  ```
  1. Health check... ✓
  ```

**2つのエンドポイントをチェック**:
```bash
curl -s -f "$BASE_URL/q/health/ready" > /dev/null 2>&1 || \
curl -s -f "$BASE_URL/actuator/health" > /dev/null 2>&1
```

**論理演算子 `||`**:
- 最初のcurlが**成功**すれば、2つ目は実行されない
- 最初のcurlが**失敗**したら、2つ目を実行
- どちらか一方が成功すればOK

**curlオプション**:
- `-s`: サイレントモード（進捗表示なし）
- `-f`: HTTPエラー時に失敗コードを返す（404、500など）

**リダイレクト**:
- `> /dev/null`: 標準出力を破棄
- `2>&1`: 標準エラー出力も標準出力にリダイレクト（結果的に破棄）

**なぜ2つのエンドポイント？**
- Quarkus: `/q/health/ready`
- Spring Boot: `/actuator/health`
- フレームワークに依存せず動作

---

### 3. Todo作成（33-47行目）

```bash
echo -n "2. Create todo... "
CREATE_RESPONSE=$(curl -s -w "\n%{http_code}" -X POST "$API_URL" \
    -H "Content-Type: application/json" \
    -d '{"title":"Smoke test","description":"Quick test"}')
CREATE_CODE=$(echo "$CREATE_RESPONSE" | tail -n1)
CREATE_BODY=$(echo "$CREATE_RESPONSE" | sed '$d')

if [ "$CREATE_CODE" = "201" ]; then
    TODO_ID=$(echo "$CREATE_BODY" | grep -o '"id":"[^"]*"' | cut -d'"' -f4)
    echo -e "${GREEN}✓${NC} (ID: ${TODO_ID:0:8}...)"
else
    echo -e "${RED}✗ (HTTP $CREATE_CODE)${NC}"
    exit 1
fi
```

**レスポンスとステータスコードを同時に取得**:

```bash
CREATE_RESPONSE=$(curl -s -w "\n%{http_code}" -X POST "$API_URL" \
    -H "Content-Type: application/json" \
    -d '{"title":"Smoke test","description":"Quick test"}')
```

**curlオプション**:
- `-w "\n%{http_code}"`: HTTPステータスコードを最後の行に追加
- `-X POST`: POSTメソッド
- `-H "Content-Type: application/json"`: ヘッダー指定
- `-d '...'`: リクエストボディ

**レスポンス例**:
```
{"id":"1a2b3c4d-...","title":"Smoke test",...}
201
```

**ステータスコードの抽出**:
```bash
CREATE_CODE=$(echo "$CREATE_RESPONSE" | tail -n1)
# 結果: 201
```

**`tail -n1`**: 最後の1行を取得

**ボディの抽出**:
```bash
CREATE_BODY=$(echo "$CREATE_RESPONSE" | sed '$d')
```

**`sed '$d'`**: 最後の行を削除

**IDの抽出**:
```bash
TODO_ID=$(echo "$CREATE_BODY" | grep -o '"id":"[^"]*"' | cut -d'"' -f4)
```

**ステップバイステップ**:

1. `grep -o '"id":"[^"]*"'`
   - `-o`: マッチした部分のみ出力
   - `"id":"[^"]*"`: `"id":"xxxxx"` の形式にマッチ
   - 結果: `"id":"1a2b3c4d-e5f6-7890-abcd-ef1234567890"`

2. `cut -d'"' -f4`
   - `-d'"'`: ダブルクォートで分割
   - `-f4`: 4番目のフィールドを取得
   - 分割結果: `["", "id", "", "1a2b3c4d-...", ""]`
   - 4番目: `1a2b3c4d-e5f6-7890-abcd-ef1234567890`

**IDの短縮表示**:
```bash
echo -e "${GREEN}✓${NC} (ID: ${TODO_ID:0:8}...)"
```

**`${TODO_ID:0:8}`**: 文字列の0文字目から8文字を抽出
- 結果: `1a2b3c4d...` （長いUUIDを短く表示）

---

### 4. 一覧取得（49-57行目）

```bash
echo -n "3. List todos... "
LIST_CODE=$(curl -s -o /dev/null -w "%{http_code}" "$API_URL")
if [ "$LIST_CODE" = "200" ]; then
    echo -e "${GREEN}✓${NC}"
else
    echo -e "${RED}✗ (HTTP $LIST_CODE)${NC}"
    exit 1
fi
```

**ステータスコードのみ取得**:
```bash
LIST_CODE=$(curl -s -o /dev/null -w "%{http_code}" "$API_URL")
```

**curlオプション**:
- `-o /dev/null`: レスポンスボディを破棄
- `-w "%{http_code}"`: ステータスコードのみ出力

**レスポンスボディが不要な場合はこの方法が効率的**

---

### 5. ID指定取得（59-67行目）

```bash
echo -n "4. Get by ID... "
GET_CODE=$(curl -s -o /dev/null -w "%{http_code}" "$API_URL/$TODO_ID")
if [ "$GET_CODE" = "200" ]; then
    echo -e "${GREEN}✓${NC}"
else
    echo -e "${RED}✗ (HTTP $GET_CODE)${NC}"
    exit 1
fi
```

**URL構築**:
```bash
"$API_URL/$TODO_ID"
# 結果: http://localhost:8081/api/todos/1a2b3c4d-e5f6-7890-abcd-ef1234567890
```

**前のステップで取得したIDを使用**

---

### 6. 更新（69-79行目）

```bash
echo -n "5. Update todo... "
UPDATE_CODE=$(curl -s -o /dev/null -w "%{http_code}" -X PATCH "$API_URL/$TODO_ID" \
    -H "Content-Type: application/json" \
    -d '{"completed":true}')
if [ "$UPDATE_CODE" = "200" ]; then
    echo -e "${GREEN}✓${NC}"
else
    echo -e "${RED}✗ (HTTP $UPDATE_CODE)${NC}"
    exit 1
fi
```

**PATCHメソッド**:
- 部分更新（completedフラグのみ変更）
- PUTは全フィールド更新、PATCHは指定フィールドのみ更新

**リクエストボディ**:
```json
{"completed":true}
```

**期待されるステータスコード**: 200 OK

---

### 7. 削除（81-89行目）

```bash
echo -n "6. Delete todo... "
DELETE_CODE=$(curl -s -o /dev/null -w "%{http_code}" -X DELETE "$API_URL/$TODO_ID")
if [ "$DELETE_CODE" = "204" ]; then
    echo -e "${GREEN}✓${NC}"
else
    echo -e "${RED}✗ (HTTP $DELETE_CODE)${NC}"
    exit 1
fi
```

**DELETEメソッド**:
- リクエストボディなし
- 期待されるステータスコード: **204 No Content**

**204 No Content**:
- 成功したが、返すべきコンテンツがない
- DELETEの標準的なレスポンス

---

### 8. 成功メッセージ（91-93行目）

```bash
echo ""
echo -e "${GREEN}All smoke tests passed! ✓${NC}"
echo ""
```

**全テスト成功時のみここに到達**:
- 途中でエラーがあれば `exit 1` で終了
- `set -e` は使用していない（明示的なエラーチェック）

---

## 実行時の出力例

### 成功時

```
=========================================
  Quick Smoke Test
  Testing: http://localhost:8081
=========================================

1. Health check... ✓
2. Create todo... ✓ (ID: 1a2b3c4d...)
3. List todos... ✓
4. Get by ID... ✓
5. Update todo... ✓
6. Delete todo... ✓

All smoke tests passed! ✓

```

### 失敗時（サーバーが起動していない）

```
=========================================
  Quick Smoke Test
  Testing: http://localhost:8081
=========================================

1. Health check... ✗ Server not running
```

**終了コード**: 1（エラー）

### 失敗時（API実装にバグ）

```
=========================================
  Quick Smoke Test
  Testing: http://localhost:8081
=========================================

1. Health check... ✓
2. Create todo... ✗ (HTTP 400)
```

**終了コード**: 1（エラー）

---

## スクリプトの特徴

### 1. 高速

**実行時間**: 約2秒
- 最小限のテスト（6項目のみ）
- レスポンスボディを破棄（必要な場合のみ取得）
- 1つのTodoのみ作成

### 2. シンプル

**依存なし**:
- 他のスクリプトを呼び出さない
- `curl` コマンドのみ使用
- `jq` がなくても動作（`grep`, `cut`, `sed` で代替）

### 3. フレームワーク非依存

**2つのヘルスチェックエンドポイント**:
- Quarkus: `/q/health/ready`
- Spring Boot: `/actuator/health`
- どちらでも動作

### 4. 即座に失敗

**Fail Fast**:
- 1つのテストが失敗したら即座に終了
- 全テストの完了を待たない
- CI/CDで素早くエラーを検出

### 5. 視覚的に分かりやすい

**カラー出力**:
- ✓ 成功: 緑色
- ✗ 失敗: 赤色

**進捗表示**:
```
1. Health check... ✓
2. Create todo... ✓
...
```

---

## よくある問題と解決方法

### 問題1: "Server not running"

**症状**:
```
1. Health check... ✗ Server not running
```

**原因**: アプリが起動していない

**解決方法**:
```bash
# アプリを起動
./quarkus-todo/target/quarkus-todo-1.0.0-SNAPSHOT-runner

# または
java -jar quarkus-todo/target/quarkus-app/quarkus-run.jar
```

### 問題2: HTTP 400 エラー

**症状**:
```
2. Create todo... ✗ (HTTP 400)
```

**原因**: リクエストボディのバリデーションエラー

**確認方法**:
```bash
# 手動でリクエストを送信してレスポンスを確認
curl -v -X POST http://localhost:8081/api/todos \
  -H "Content-Type: application/json" \
  -d '{"title":"Smoke test","description":"Quick test"}'
```

### 問題3: HTTP 500 エラー

**症状**:
```
2. Create todo... ✗ (HTTP 500)
```

**原因**: サーバー内部エラー

**確認方法**:
```bash
# アプリのログを確認
tail -f logs/quarkus-native.log
tail -f logs/quarkus.log
tail -f logs/spring.log
```

### 問題4: カラーが表示されない

**症状**: `✓` や `✗` が緑/赤ではなく、エスケープシーケンスが表示される

**原因**: ターミナルがANSI カラーコードに対応していない

**対処法**: 最新のターミナルを使用（macOS Terminal、iTerm2、VS Code統合ターミナルなど）

---

## test_api.sh との違い

| 項目 | smoke_test.sh | test_api.sh |
|-----|--------------|-------------|
| **実行時間** | 約2秒 | 約5秒 |
| **テスト数** | 6項目 | 12項目 |
| **作成するTodo** | 1個 | 3個 |
| **バリデーションテスト** | なし | あり（3項目） |
| **詳細なレスポンス確認** | なし | あり（jqで整形表示） |
| **テスト結果カウント** | なし | あり（成功/失敗の数） |
| **用途** | 素早い動作確認 | 詳細な機能テスト |

---

## 使用例

### ビルド後の動作確認

```bash
# ビルド
./build_all.sh

# Nativeを起動
./quarkus-todo/target/quarkus-todo-1.0.0-SNAPSHOT-runner &

# スモークテスト実行
./bench/smoke_test.sh

# 成功したら本格的なテストへ
./bench/test_api.sh
```

### CI/CDパイプライン

```yaml
# .github/workflows/test.yml
- name: Build
  run: ./build_all.sh

- name: Start Quarkus Native
  run: ./quarkus-todo/target/quarkus-todo-1.0.0-SNAPSHOT-runner &

- name: Wait for startup
  run: sleep 3

- name: Smoke Test
  run: ./bench/smoke_test.sh

- name: Detailed Test
  run: ./bench/test_api.sh
```

### 複数モードのテスト

```bash
# Quarkus Nativeをテスト
./quarkus-todo/target/quarkus-todo-1.0.0-SNAPSHOT-runner &
sleep 2
./bench/smoke_test.sh 8081
pkill -f quarkus-todo

# Quarkus JVMをテスト
java -jar quarkus-todo/target/quarkus-app/quarkus-run.jar &
sleep 2
./bench/smoke_test.sh 8081
pkill -f quarkus-run

# Spring Bootをテスト
java -jar spring-todo/target/spring-todo-0.0.1-SNAPSHOT.jar &
sleep 2
./bench/smoke_test.sh 8082
pkill -f spring-todo
```

**または自動化**:
```bash
./bench/test_all_modes.sh
```

---

## まとめ

`smoke_test.sh` は、以下を実現する軽量テストスクリプトです：

✅ **高速**（約2秒で完了）
✅ **シンプル**（依存なし、curl のみ）
✅ **視覚的**（カラー出力、明確な進捗）
✅ **フレームワーク非依存**（Quarkus/Spring両対応）
✅ **Fail Fast**（即座にエラー検出）
✅ **CI/CD対応**（終了コードで成功/失敗を判定）

ビルド後やデプロイ後の「基本機能が動くか」を素早く確認するのに最適です。

# 手動APIテストガイド

このガイドでは、アプリを起動して自分でAPIを叩いてテストする方法を説明します。

## 📋 目次

1. [アプリの起動](#1-アプリの起動)
2. [基本的なCRUD操作](#2-基本的なcrud操作)
3. [実践的なシナリオ](#3-実践的なシナリオ)
4. [Swagger UIを使う](#4-swagger-uiを使う)
5. [Health & Metricsの確認](#5-health--metricsの確認)
6. [トラブルシューティング](#6-トラブルシューティング)

---

## 1. アプリの起動

テストしたいモードを選んで起動します。

### Quarkus Native（推奨）

```bash
./quarkus-todo/target/quarkus-todo-1.0.0-SNAPSHOT-runner
```

- **ポート**: 8081
- **起動時間**: 約1-20ms
- **メモリ**: 約50-70MB

### Quarkus JVM

```bash
java -Xms128m -Xmx512m -jar quarkus-todo/target/quarkus-app/quarkus-run.jar
```

- **ポート**: 8081
- **起動時間**: 約50-200ms
- **メモリ**: 約200-300MB

### Spring Boot JVM

```bash
java -Xms128m -Xmx512m -jar spring-todo/target/spring-todo-0.0.1-SNAPSHOT.jar
```

- **ポート**: 8082
- **起動時間**: 約500-1500ms
- **メモリ**: 約300-450MB

### 起動確認

アプリが起動したら、別のターミナルで確認：

```bash
# Quarkusの場合
curl http://localhost:8081/q/health/ready

# Spring Bootの場合
curl http://localhost:8082/actuator/health
```

正常なら `{"status":"UP"}` などが返ります。

---

## 2. 基本的なCRUD操作

以下、Quarkus（ポート8081）の例です。Spring Boot（ポート8082）でテストする場合はポート番号を変更してください。

### 2.1 CREATE - Todoを作成（POST）

```bash
curl -X POST http://localhost:8081/api/todos \
  -H "Content-Type: application/json" \
  -d '{
    "title": "買い物",
    "description": "牛乳、卵、パンを買う",
    "completed": false
  }'
```

**レスポンス例**:
```json
{
  "id": "a1b2c3d4-e5f6-7890-abcd-ef1234567890",
  "title": "買い物",
  "description": "牛乳、卵、パンを買う",
  "completed": false,
  "createdAt": "2026-02-22T10:30:00",
  "updatedAt": "2026-02-22T10:30:00"
}
```

**重要**: 返ってきた`id`をメモしてください。次のステップで使います。

### 2.2 READ - 全Todoを取得（GET）

```bash
curl http://localhost:8081/api/todos
```

**レスポンス例**:
```json
[
  {
    "id": "a1b2c3d4-e5f6-7890-abcd-ef1234567890",
    "title": "買い物",
    "description": "牛乳、卵、パンを買う",
    "completed": false,
    "createdAt": "2026-02-22T10:30:00",
    "updatedAt": "2026-02-22T10:30:00"
  }
]
```

**見やすく表示** (jqがある場合):
```bash
curl http://localhost:8081/api/todos | jq .
```

### 2.3 READ - 特定のTodoを取得（GET by ID）

```bash
# IDを実際の値に置き換えてください
curl http://localhost:8081/api/todos/a1b2c3d4-e5f6-7890-abcd-ef1234567890
```

**レスポンス例**:
```json
{
  "id": "a1b2c3d4-e5f6-7890-abcd-ef1234567890",
  "title": "買い物",
  "description": "牛乳、卵、パンを買う",
  "completed": false,
  "createdAt": "2026-02-22T10:30:00",
  "updatedAt": "2026-02-22T10:30:00"
}
```

### 2.4 UPDATE - 全フィールドを更新（PUT）

```bash
# IDを実際の値に置き換えてください
curl -X PUT http://localhost:8081/api/todos/a1b2c3d4-e5f6-7890-abcd-ef1234567890 \
  -H "Content-Type: application/json" \
  -d '{
    "title": "買い物（更新）",
    "description": "牛乳、卵、パン、バターを買う",
    "completed": false
  }'
```

**レスポンス例**:
```json
{
  "id": "a1b2c3d4-e5f6-7890-abcd-ef1234567890",
  "title": "買い物（更新）",
  "description": "牛乳、卵、パン、バターを買う",
  "completed": false,
  "createdAt": "2026-02-22T10:30:00",
  "updatedAt": "2026-02-22T10:35:00"
}
```

### 2.5 PARTIAL UPDATE - 部分更新（PATCH）

completedフラグだけを変更：

```bash
# IDを実際の値に置き換えてください
curl -X PATCH http://localhost:8081/api/todos/a1b2c3d4-e5f6-7890-abcd-ef1234567890 \
  -H "Content-Type: application/json" \
  -d '{
    "completed": true
  }'
```

**レスポンス例**:
```json
{
  "id": "a1b2c3d4-e5f6-7890-abcd-ef1234567890",
  "title": "買い物（更新）",
  "description": "牛乳、卵、パン、バターを買う",
  "completed": true,
  "createdAt": "2026-02-22T10:30:00",
  "updatedAt": "2026-02-22T10:40:00"
}
```

### 2.6 DELETE - Todoを削除（DELETE）

```bash
# IDを実際の値に置き換えてください
curl -X DELETE http://localhost:8081/api/todos/a1b2c3d4-e5f6-7890-abcd-ef1234567890
```

**レスポンス**: 通常、レスポンスボディはなし（204 No Content）

**削除確認**:
```bash
# 削除したIDで取得を試みる
curl http://localhost:8081/api/todos/a1b2c3d4-e5f6-7890-abcd-ef1234567890

# 404 Not Foundが返ることを確認
```

---

## 3. 実践的なシナリオ

### シナリオ1: タスク管理（基本）

```bash
# 1. 3つのタスクを作成
curl -X POST http://localhost:8081/api/todos \
  -H "Content-Type: application/json" \
  -d '{"title":"レポート作成","description":"Q4レポート","completed":false}'

curl -X POST http://localhost:8081/api/todos \
  -H "Content-Type: application/json" \
  -d '{"title":"コードレビュー","description":"PR #123","completed":false}'

curl -X POST http://localhost:8081/api/todos \
  -H "Content-Type: application/json" \
  -d '{"title":"ミーティング","description":"週次MTG","completed":true}'

# 2. 全タスクを確認
curl http://localhost:8081/api/todos | jq .

# 3. 1つ目のタスクを完了にする（IDは実際の値に置き換え）
curl -X PATCH http://localhost:8081/api/todos/<ID> \
  -H "Content-Type: application/json" \
  -d '{"completed":true}'

# 4. 完了したタスクを確認
curl http://localhost:8081/api/todos | jq '.[] | select(.completed==true)'
```

### シナリオ2: バリデーションテスト

**エラーケース1: 空のtitle**

```bash
curl -X POST http://localhost:8081/api/todos \
  -H "Content-Type: application/json" \
  -d '{"title":"","description":"これは失敗するはず"}'
```

**期待される結果**: 400 Bad Request

**エラーケース2: titleなし**

```bash
curl -X POST http://localhost:8081/api/todos \
  -H "Content-Type: application/json" \
  -d '{"description":"titleがない"}'
```

**期待される結果**: 400 Bad Request

**エラーケース3: 存在しないID**

```bash
curl http://localhost:8081/api/todos/00000000-0000-0000-0000-000000000000
```

**期待される結果**: 404 Not Found

### シナリオ3: HTTPステータスコードの確認

```bash
# ステータスコードも表示
curl -i http://localhost:8081/api/todos

# またはステータスコードのみ表示
curl -o /dev/null -s -w "%{http_code}\n" http://localhost:8081/api/todos
```

**主なステータスコード**:
- `200 OK` - 取得、更新成功
- `201 Created` - 作成成功
- `204 No Content` - 削除成功
- `400 Bad Request` - バリデーションエラー
- `404 Not Found` - リソースが見つからない
- `500 Internal Server Error` - サーバーエラー

---

## 4. Swagger UIを使う

ブラウザベースのインタラクティブなAPIテストツールです。

### Quarkusの場合

ブラウザで以下を開く：
```
http://localhost:8081/swagger-ui
```

### Spring Bootの場合

ブラウザで以下を開く：
```
http://localhost:8082/swagger-ui
```

### Swagger UIの使い方

1. **エンドポイントを選択**
   - GET `/api/todos` などをクリック

2. **Try it out をクリック**

3. **パラメータを入力**（必要な場合）

4. **Execute をクリック**

5. **レスポンスを確認**
   - Response body: 返ってきたJSON
   - Response headers: HTTPヘッダー
   - Response code: HTTPステータスコード

**メリット**:
- curlコマンドを書かなくていい
- リクエスト/レスポンスが見やすい
- バリデーションルールが表示される

---

## 5. Health & Metricsの確認

### 5.1 Quarkusの場合

#### Liveness（生存確認）

```bash
curl http://localhost:8081/q/health/live
```

**レスポンス例**:
```json
{
  "status": "UP",
  "checks": []
}
```

#### Readiness（準備完了確認）

```bash
curl http://localhost:8081/q/health/ready
```

**レスポンス例**:
```json
{
  "status": "UP",
  "checks": [
    {
      "name": "Database connections health check",
      "status": "UP"
    }
  ]
}
```

#### Metrics（メトリクス）

```bash
curl http://localhost:8081/q/metrics
```

**メモリ使用量を確認**:
```bash
curl http://localhost:8081/q/metrics | grep jvm_memory_used_bytes
```

### 5.2 Spring Bootの場合

#### Health Check

```bash
curl http://localhost:8082/actuator/health
```

**レスポンス例**:
```json
{
  "status": "UP",
  "components": {
    "db": {
      "status": "UP"
    },
    "diskSpace": {
      "status": "UP"
    }
  }
}
```

#### Metrics

```bash
curl http://localhost:8082/actuator/prometheus
```

**メモリ使用量を確認**:
```bash
curl http://localhost:8082/actuator/prometheus | grep jvm_memory_used_bytes
```

---

## 6. トラブルシューティング

### 問題1: "Connection refused"

**症状**:
```
curl: (7) Failed to connect to localhost port 8081: Connection refused
```

**原因**: アプリが起動していない

**解決方法**:
```bash
# アプリを起動
./quarkus-todo/target/quarkus-todo-1.0.0-SNAPSHOT-runner

# または
java -jar quarkus-todo/target/quarkus-app/quarkus-run.jar
```

### 問題2: "404 Not Found" が返る

**症状**:
```bash
curl http://localhost:8081/api/todos
# => 404 Not Found
```

**原因1**: URLが間違っている

**確認**:
```bash
# Quarkusの場合
curl http://localhost:8081/api/todos  # ✓ 正しい
curl http://localhost:8081/todos      # ✗ 間違い

# Spring Bootの場合
curl http://localhost:8082/api/todos  # ✓ 正しい（ポート番号注意）
```

**原因2**: ポート番号が間違っている

**確認**:
- Quarkus: ポート 8081
- Spring Boot: ポート 8082

### 問題3: "400 Bad Request" が返る

**症状**:
```bash
curl -X POST http://localhost:8081/api/todos \
  -H "Content-Type: application/json" \
  -d '{"title":""}'
# => 400 Bad Request
```

**原因**: バリデーションエラー

**必須フィールド**:
- `title`: 必須、空文字列不可

**正しい例**:
```bash
curl -X POST http://localhost:8081/api/todos \
  -H "Content-Type: application/json" \
  -d '{
    "title": "有効なタイトル",
    "description": "説明（オプション）",
    "completed": false
  }'
```

### 問題4: JSONが見づらい

**解決方法1**: jqを使う

```bash
curl http://localhost:8081/api/todos | jq .
```

**解決方法2**: pythonを使う

```bash
curl http://localhost:8081/api/todos | python -m json.tool
```

**解決方法3**: Swagger UIを使う

```
http://localhost:8081/swagger-ui
```

### 問題5: データベースが壊れた

**症状**: 変なエラーが出る、起動しない

**解決方法**:
```bash
# アプリを停止
# Ctrl+C

# データベースファイルを削除
rm -rf data/

# アプリを再起動
./quarkus-todo/target/quarkus-todo-1.0.0-SNAPSHOT-runner
```

---

## 7. 便利なTips

### 7.1 環境変数で管理

```bash
# Quarkus用
export BASE_URL="http://localhost:8081"

# Spring Boot用
# export BASE_URL="http://localhost:8082"

# 以降、こう書ける
curl $BASE_URL/api/todos
```

### 7.2 スクリプト化

**todo_create.sh**:
```bash
#!/bin/bash
curl -X POST http://localhost:8081/api/todos \
  -H "Content-Type: application/json" \
  -d "{\"title\":\"$1\",\"description\":\"$2\"}"
```

**使い方**:
```bash
chmod +x todo_create.sh
./todo_create.sh "タイトル" "説明文"
```

### 7.3 レスポンスをファイルに保存

```bash
# 全Todoを保存
curl http://localhost:8081/api/todos > todos.json

# 見る
cat todos.json | jq .
```

### 7.4 パフォーマンス測定

```bash
# レスポンス時間を測定
curl -w "@-" -o /dev/null -s http://localhost:8081/api/todos <<'EOF'
    time_namelookup:  %{time_namelookup}s\n
       time_connect:  %{time_connect}s\n
    time_appconnect:  %{time_appconnect}s\n
   time_pretransfer:  %{time_pretransfer}s\n
      time_redirect:  %{time_redirect}s\n
 time_starttransfer:  %{time_starttransfer}s\n
                    ----------\n
         time_total:  %{time_total}s\n
EOF
```

---

## 8. チートシート

### クイックリファレンス

```bash
# 環境設定（お好みで）
export API="http://localhost:8081/api/todos"

# CREATE
curl -X POST $API -H "Content-Type: application/json" \
  -d '{"title":"タスク","description":"説明"}'

# READ (全件)
curl $API

# READ (1件) - IDを置き換え
curl $API/<YOUR-ID>

# UPDATE (全体)
curl -X PUT $API/<YOUR-ID> -H "Content-Type: application/json" \
  -d '{"title":"新タイトル","description":"新説明","completed":false}'

# UPDATE (部分)
curl -X PATCH $API/<YOUR-ID> -H "Content-Type: application/json" \
  -d '{"completed":true}'

# DELETE
curl -X DELETE $API/<YOUR-ID>

# Health Check
curl http://localhost:8081/q/health/ready

# Swagger UI
open http://localhost:8081/swagger-ui
```

---

## まとめ

**推奨フロー**:

1. **アプリを起動**
   ```bash
   ./quarkus-todo/target/quarkus-todo-1.0.0-SNAPSHOT-runner
   ```

2. **Health Checkで確認**
   ```bash
   curl http://localhost:8081/q/health/ready
   ```

3. **Swagger UIでインタラクティブにテスト**
   ```
   http://localhost:8081/swagger-ui
   ```

4. **または curlで詳細テスト**
   - 上記のコマンド例をコピペして実行

5. **問題があればログ確認**
   - アプリ起動中のターミナルを見る

**次のステップ**:
- 自動テストスクリプトを使う: [bench/TEST_README.md](bench/TEST_README.md)
- ベンチマークを実行: `./bench/run_benchmark.sh`
- 詳細なガイド: [demo_exe.md](demo_exe.md)

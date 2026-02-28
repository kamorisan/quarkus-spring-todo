# Quarkus Todo Application

Quarkusで実装したシンプルなTodo管理REST APIアプリケーションです。

## 概要

このアプリケーションは、Quarkusフレームワークを使用して構築されたCRUD操作を提供するREST APIです。JVMモードとNative Imageモードの両方で実行可能です。

### 主な特徴

- ✅ **高速起動** - JVMモードで50-200ms、Nativeモードで1-20ms
- ✅ **省メモリ** - JVMモードで200-300MB、Nativeモードで50-70MB
- ✅ **REST API** - 完全なCRUD操作をサポート
- ✅ **OpenAPI/Swagger** - APIドキュメント自動生成
- ✅ **Health Check** - Kubernetes対応のヘルスチェック
- ✅ **Metrics** - Prometheus形式のメトリクス出力

## 技術スタック

| 技術 | バージョン | 用途 |
|-----|----------|------|
| Quarkus | 3.17.0 | フレームワーク |
| Java | 21 | 言語 |
| Hibernate ORM | - | O/Rマッパー |
| H2 Database | - | 組み込みDB |
| RESTEasy Reactive | - | REST API |
| SmallRye OpenAPI | - | API仕様 |
| Micrometer | - | メトリクス |

## プロジェクト構造

```
quarkus-todo/
├── src/
│   ├── main/
│   │   ├── java/com/demo/
│   │   │   ├── controller/
│   │   │   │   └── TodoController.java       # REST APIエンドポイント
│   │   │   ├── dto/
│   │   │   │   ├── CreateTodoRequest.java    # 作成リクエスト
│   │   │   │   ├── UpdateTodoRequest.java    # 更新リクエスト（PUT）
│   │   │   │   ├── PatchTodoRequest.java     # 部分更新リクエスト（PATCH）
│   │   │   │   └── TodoResponse.java         # レスポンス
│   │   │   ├── entity/
│   │   │   │   └── Todo.java                 # エンティティ
│   │   │   ├── health/
│   │   │   │   ├── HealthController.java     # カスタムヘルスチェック
│   │   │   │   └── ReadinessService.java     # 起動時間記録
│   │   │   ├── repository/
│   │   │   │   └── TodoRepository.java       # リポジトリ
│   │   │   └── service/
│   │   │       └── TodoService.java          # ビジネスロジック
│   │   └── resources/
│   │       └── application.properties        # 設定ファイル
│   └── test/
│       └── java/
├── pom.xml                                    # Maven設定
└── README.md                                  # このファイル
```

## ビルド方法

### JVMモード（開発向け）

```bash
# プロジェクトルートから
cd quarkus-todo
mvn clean package -DskipTests
```

**成果物**:
- `target/quarkus-app/quarkus-run.jar`
- `target/quarkus-app/lib/` （依存ライブラリ）

### Nativeモード（本番向け）

#### 方法1: ローカルでビルド（GraalVM必須）

```bash
# GraalVM環境変数を設定
export JAVA_HOME=/Library/Java/JavaVirtualMachines/graalvm-21.jdk/Contents/Home
export PATH=$JAVA_HOME/bin:$PATH

# Nativeビルド
mvn clean package -Pnative \
  -Djava.home="$JAVA_HOME" \
  -Dquarkus.native.java-home="$JAVA_HOME"
```

**成果物**:
- `target/quarkus-todo-1.0.0-SNAPSHOT-runner` （実行可能バイナリ）

#### 方法2: プロジェクトルートのスクリプトを使用（推奨）

```bash
# プロジェクトルートから
./build_all.sh
```

このスクリプトはJVMとNativeの両方をビルドし、両方の成果物を保持します。

## 実行方法

### JVMモード

```bash
# 基本実行
java -jar target/quarkus-app/quarkus-run.jar

# メモリ設定を指定（ベンチマーク用）
java -Xms128m -Xmx512m -jar target/quarkus-app/quarkus-run.jar
```

**起動確認**:
```bash
curl http://localhost:8081/q/health/ready
```

### Nativeモード

```bash
# 直接実行（JVMオプション不要）
./target/quarkus-todo-1.0.0-SNAPSHOT-runner
```

**起動確認**:
```bash
curl http://localhost:8081/q/health/ready
```

## API仕様

### ベースURL

```
http://localhost:8081
```

### エンドポイント一覧

| メソッド | パス | 説明 | リクエストボディ |
|---------|------|------|-----------------|
| GET | `/api/todos` | 全Todo取得 | - |
| GET | `/api/todos/{id}` | 特定Todo取得 | - |
| POST | `/api/todos` | Todo作成 | CreateTodoRequest |
| PUT | `/api/todos/{id}` | Todo全更新 | UpdateTodoRequest |
| PATCH | `/api/todos/{id}` | Todo部分更新 | PatchTodoRequest |
| DELETE | `/api/todos/{id}` | Todo削除 | - |

### リクエスト/レスポンス例

#### Todo作成（POST）

**リクエスト**:
```bash
curl -X POST http://localhost:8081/api/todos \
  -H "Content-Type: application/json" \
  -d '{
    "title": "買い物",
    "description": "牛乳、卵、パンを買う",
    "completed": false
  }'
```

**レスポンス（201 Created）**:
```json
{
  "id": "1a2b3c4d-e5f6-7890-abcd-ef1234567890",
  "title": "買い物",
  "description": "牛乳、卵、パンを買う",
  "completed": false,
  "createdAt": "2026-02-28T10:30:00",
  "updatedAt": "2026-02-28T10:30:00"
}
```

#### 全Todo取得（GET）

**リクエスト**:
```bash
curl http://localhost:8081/api/todos
```

**レスポンス（200 OK）**:
```json
[
  {
    "id": "1a2b3c4d-e5f6-7890-abcd-ef1234567890",
    "title": "買い物",
    "description": "牛乳、卵、パンを買う",
    "completed": false,
    "createdAt": "2026-02-28T10:30:00",
    "updatedAt": "2026-02-28T10:30:00"
  }
]
```

#### Todo更新（PATCH）

**リクエスト**:
```bash
curl -X PATCH http://localhost:8081/api/todos/{id} \
  -H "Content-Type: application/json" \
  -d '{"completed": true}'
```

**レスポンス（200 OK）**:
```json
{
  "id": "1a2b3c4d-e5f6-7890-abcd-ef1234567890",
  "title": "買い物",
  "description": "牛乳、卵、パンを買う",
  "completed": true,
  "createdAt": "2026-02-28T10:30:00",
  "updatedAt": "2026-02-28T11:00:00"
}
```

#### Todo削除（DELETE）

**リクエスト**:
```bash
curl -X DELETE http://localhost:8081/api/todos/{id}
```

**レスポンス（204 No Content）**:
- レスポンスボディなし

### バリデーション

- `title`: 必須、空文字列不可
- `description`: オプション
- `completed`: オプション（デフォルト: false）

**バリデーションエラー例**:
```json
{
  "title": "Validation failed",
  "status": 400,
  "detail": "Title is required"
}
```

## Health & Metrics

### Liveness（生存確認）

```bash
curl http://localhost:8081/q/health/live
```

**レスポンス**:
```json
{
  "status": "UP",
  "checks": []
}
```

### Readiness（準備完了確認）

```bash
curl http://localhost:8081/q/health/ready
```

**レスポンス**:
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

### Metrics（Prometheus形式）

```bash
curl http://localhost:8081/q/metrics
```

**主なメトリクス**:
- `jvm_memory_used_bytes` - メモリ使用量
- `http_server_requests_seconds` - HTTPリクエスト時間
- `process_cpu_usage` - CPU使用率

## Swagger UI

APIドキュメントをブラウザで確認：

```
http://localhost:8081/swagger-ui
```

インタラクティブにAPIをテストできます。

## データベース

### H2 Database（組み込み）

**設定**:
- **種類**: ファイルベース
- **場所**: `./data/todo-db.mv.db`
- **モード**: PostgreSQL互換
- **スキーマ**: 起動時に自動生成（drop-and-create）

**データクリーンアップ**:
```bash
rm -rf data/
```

### スキーマ

```sql
CREATE TABLE todo (
    id UUID PRIMARY KEY,
    title VARCHAR(255) NOT NULL,
    description TEXT,
    completed BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMP,
    updated_at TIMESTAMP
);
```

## 設定

### application.properties

主な設定項目：

```properties
# HTTPポート
quarkus.http.port=8081

# データベース
quarkus.datasource.db-kind=h2
quarkus.datasource.jdbc.url=jdbc:h2:file:./data/todo-db;MODE=PostgreSQL
quarkus.datasource.username=sa
quarkus.datasource.password=

# Hibernate
quarkus.hibernate-orm.database.generation=drop-and-create
quarkus.hibernate-orm.log.sql=false

# ログ
quarkus.log.level=INFO

# OpenAPI
quarkus.swagger-ui.always-include=true
quarkus.swagger-ui.path=/swagger-ui

# Metrics
quarkus.micrometer.export.prometheus.enabled=true
```

### ポート変更

```bash
# 環境変数で上書き
QUARKUS_HTTP_PORT=9000 java -jar target/quarkus-app/quarkus-run.jar
```

## テスト

### 自動テスト

プロジェクトルートから：

```bash
# スモークテスト（約2秒）
./bench/smoke_test.sh

# 詳細テスト（約5秒）
./bench/test_api.sh
```

### 手動テスト

```bash
# Health check
curl http://localhost:8081/q/health/ready

# Todo作成
curl -X POST http://localhost:8081/api/todos \
  -H "Content-Type: application/json" \
  -d '{"title":"テスト"}'

# 一覧取得
curl http://localhost:8081/api/todos
```

## パフォーマンス

### 典型的な値

| モード | 起動時間 | メモリ（RSS） | CPU（アイドル） |
|-------|---------|-------------|---------------|
| **Native** | 1-20ms | 50-70 MB | 0.0-0.2% |
| **JVM** | 50-200ms | 200-300 MB | 0.5-2.0% |

### ベンチマーク実行

プロジェクトルートから：

```bash
./bench/run_benchmark.sh
```

詳細なベンチマーク結果とSpring Bootとの比較が表示されます。

## トラブルシューティング

### 問題1: ポートが既に使用されている

**症状**:
```
Port 8081 is already in use
```

**解決方法**:
```bash
# ポート確認
lsof -i :8081

# プロセス停止
kill <PID>

# または別のポートで起動
QUARKUS_HTTP_PORT=9000 java -jar target/quarkus-app/quarkus-run.jar
```

### 問題2: データベースエラー

**症状**:
```
Database error: ...
```

**解決方法**:
```bash
# データベースファイルを削除
rm -rf data/

# アプリを再起動
```

### 問題3: Nativeビルドが失敗

**症状**:
```
Error: GraalVM not found
```

**解決方法**:
```bash
# GraalVMをインストール
brew install --cask graalvm-jdk21

# 環境変数を設定
export JAVA_HOME=/Library/Java/JavaVirtualMachines/graalvm-21.jdk/Contents/Home
export PATH=$JAVA_HOME/bin:$PATH

# 再ビルド
mvn clean package -Pnative
```

## 開発

### 開発モード（ホットリロード）

```bash
mvn quarkus:dev
```

**特徴**:
- コード変更を自動検出
- 自動再コンパイル
- Dev UI: http://localhost:8081/q/dev

### テストの実行

```bash
# 全テスト実行
mvn test

# 特定のテストクラス
mvn test -Dtest=TodoServiceTest
```

## Spring Boot版との違い

| 項目 | Quarkus | Spring Boot |
|-----|---------|-------------|
| **起動時間** | 50-200ms | 500-1500ms |
| **メモリ** | 200-300 MB | 300-450 MB |
| **ポート** | 8081 | 8082 |
| **Health Check** | `/q/health/ready` | `/actuator/health` |
| **Metrics** | `/q/metrics` | `/actuator/prometheus` |
| **Swagger UI** | `/swagger-ui` | `/swagger-ui` |
| **Dev UI** | `/q/dev` | なし |

## 参考リンク

- [Quarkus公式サイト](https://quarkus.io/)
- [Quarkus Guides](https://quarkus.io/guides/)
- [RESTEasy Reactive](https://quarkus.io/guides/resteasy-reactive)
- [Hibernate ORM with Panache](https://quarkus.io/guides/hibernate-orm-panache)

## ライセンス

このプロジェクトはデモンストレーション用です。

# Spring Boot Todo Application

Spring Bootで実装したシンプルなTodo管理REST APIアプリケーションです。

## 概要

このアプリケーションは、Spring Bootフレームワークを使用して構築されたCRUD操作を提供するREST APIです。Quarkus版との性能比較のために実装されています。

### 主な特徴

- ✅ **安定性** - 実績のあるSpring Bootフレームワーク
- ✅ **豊富なエコシステム** - Spring生態系との統合
- ✅ **REST API** - 完全なCRUD操作をサポート
- ✅ **OpenAPI/Swagger** - APIドキュメント自動生成
- ✅ **Actuator** - 本番環境向けの監視機能
- ✅ **Metrics** - Prometheus形式のメトリクス出力

## 技術スタック

| 技術 | バージョン | 用途 |
|-----|----------|------|
| Spring Boot | 3.2.0 | フレームワーク |
| Java | 21 | 言語 |
| Spring Data JPA | - | データアクセス |
| Hibernate | - | O/Rマッパー |
| H2 Database | - | 組み込みDB |
| Spring Web | - | REST API |
| SpringDoc OpenAPI | - | API仕様 |
| Micrometer | - | メトリクス |

## プロジェクト構造

```
spring-todo/
├── src/
│   ├── main/
│   │   ├── java/com/demo/
│   │   │   ├── SpringTodoApplication.java    # メインクラス
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

### 標準ビルド

```bash
# プロジェクトルートから
cd spring-todo
mvn clean package -DskipTests
```

**成果物**:
- `target/spring-todo-0.0.1-SNAPSHOT.jar` （実行可能JARファイル）

### プロジェクトルートのスクリプトを使用（推奨）

```bash
# プロジェクトルートから
./build_all.sh
```

このスクリプトはQuarkus（JVM + Native）とSpring Bootを一括ビルドします。

## 実行方法

### 基本実行

```bash
# 標準実行
java -jar target/spring-todo-0.0.1-SNAPSHOT.jar

# メモリ設定を指定（ベンチマーク用）
java -Xms128m -Xmx512m -jar target/spring-todo-0.0.1-SNAPSHOT.jar
```

**起動確認**:
```bash
curl http://localhost:8082/actuator/health
```

### バックグラウンド実行

```bash
# バックグラウンドで起動
java -jar target/spring-todo-0.0.1-SNAPSHOT.jar &

# PIDを保存
echo $! > spring.pid

# 停止
kill $(cat spring.pid)
```

## API仕様

### ベースURL

```
http://localhost:8082
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
curl -X POST http://localhost:8082/api/todos \
  -H "Content-Type: application/json" \
  -d '{
    "title": "レポート作成",
    "description": "Q4パフォーマンスレポート",
    "completed": false
  }'
```

**レスポンス（201 Created）**:
```json
{
  "id": "9f8e7d6c-5b4a-3210-fedc-ba9876543210",
  "title": "レポート作成",
  "description": "Q4パフォーマンスレポート",
  "completed": false,
  "createdAt": "2026-02-28T10:30:00",
  "updatedAt": "2026-02-28T10:30:00"
}
```

#### 全Todo取得（GET）

**リクエスト**:
```bash
curl http://localhost:8082/api/todos
```

**レスポンス（200 OK）**:
```json
[
  {
    "id": "9f8e7d6c-5b4a-3210-fedc-ba9876543210",
    "title": "レポート作成",
    "description": "Q4パフォーマンスレポート",
    "completed": false,
    "createdAt": "2026-02-28T10:30:00",
    "updatedAt": "2026-02-28T10:30:00"
  }
]
```

#### Todo更新（PATCH）

**リクエスト**:
```bash
curl -X PATCH http://localhost:8082/api/todos/{id} \
  -H "Content-Type: application/json" \
  -d '{"completed": true}'
```

**レスポンス（200 OK）**:
```json
{
  "id": "9f8e7d6c-5b4a-3210-fedc-ba9876543210",
  "title": "レポート作成",
  "description": "Q4パフォーマンスレポート",
  "completed": true,
  "createdAt": "2026-02-28T10:30:00",
  "updatedAt": "2026-02-28T11:00:00"
}
```

#### Todo削除（DELETE）

**リクエスト**:
```bash
curl -X DELETE http://localhost:8082/api/todos/{id}
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
  "timestamp": "2026-02-28T10:30:00",
  "status": 400,
  "error": "Bad Request",
  "message": "Title is required",
  "path": "/api/todos"
}
```

## Spring Boot Actuator

### Health Check

#### 基本ヘルスチェック

```bash
curl http://localhost:8082/actuator/health
```

**レスポンス**:
```json
{
  "status": "UP",
  "components": {
    "db": {
      "status": "UP",
      "details": {
        "database": "H2",
        "validationQuery": "isValid()"
      }
    },
    "diskSpace": {
      "status": "UP"
    },
    "ping": {
      "status": "UP"
    }
  }
}
```

#### Liveness（Kubernetes用）

```bash
curl http://localhost:8082/health/live
```

#### Readiness（Kubernetes用）

```bash
curl http://localhost:8082/health/ready
```

### Metrics（Prometheus形式）

```bash
curl http://localhost:8082/actuator/prometheus
```

**主なメトリクス**:
- `jvm_memory_used_bytes` - メモリ使用量
- `http_server_requests_seconds` - HTTPリクエスト時間
- `process_cpu_usage` - CPU使用率
- `system_cpu_usage` - システムCPU使用率

### その他のActuatorエンドポイント

```bash
# 全エンドポイント一覧
curl http://localhost:8082/actuator

# 環境情報
curl http://localhost:8082/actuator/env

# Bean一覧
curl http://localhost:8082/actuator/beans
```

## Swagger UI

APIドキュメントをブラウザで確認：

```
http://localhost:8082/swagger-ui
```

OpenAPI仕様書：

```
http://localhost:8082/openapi
```

## データベース

### H2 Database（組み込み）

**設定**:
- **種類**: ファイルベース
- **場所**: `./data/todo-db.mv.db`
- **モード**: PostgreSQL互換
- **スキーマ**: 起動時に自動生成（create-drop）

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
# サーバーポート
server.port=8082

# データベース
spring.datasource.url=jdbc:h2:file:./data/todo-db;MODE=PostgreSQL
spring.datasource.username=sa
spring.datasource.password=

# JPA/Hibernate
spring.jpa.hibernate.ddl-auto=create-drop
spring.jpa.show-sql=false

# ログ
logging.level.root=INFO

# Actuator
management.endpoints.web.exposure.include=health,prometheus
management.endpoint.health.show-details=always
management.metrics.export.prometheus.enabled=true

# OpenAPI
springdoc.api-docs.path=/openapi
springdoc.swagger-ui.path=/swagger-ui
```

### ポート変更

```bash
# 環境変数で上書き
SERVER_PORT=9000 java -jar target/spring-todo-0.0.1-SNAPSHOT.jar

# またはコマンドライン引数
java -jar target/spring-todo-0.0.1-SNAPSHOT.jar --server.port=9000
```

### プロファイル

```bash
# 本番環境用プロファイル
java -jar target/spring-todo-0.0.1-SNAPSHOT.jar --spring.profiles.active=prod
```

## テスト

### 自動テスト

プロジェクトルートから：

```bash
# スモークテスト（約2秒）
./bench/smoke_test.sh 8082

# 詳細テスト（約5秒）
./bench/test_api.sh 8082
```

### 手動テスト

```bash
# Health check
curl http://localhost:8082/actuator/health

# Todo作成
curl -X POST http://localhost:8082/api/todos \
  -H "Content-Type: application/json" \
  -d '{"title":"テスト"}'

# 一覧取得
curl http://localhost:8082/api/todos
```

## パフォーマンス

### 典型的な値

| モード | 起動時間 | メモリ（RSS） | CPU（アイドル） |
|-------|---------|-------------|---------------|
| **Spring Boot JVM** | 500-1500ms | 300-450 MB | 0.5-2.0% |

### Quarkusとの比較

| 指標 | Spring Boot JVM | Quarkus JVM | Quarkus Native |
|-----|----------------|------------|---------------|
| **起動時間** | 500-1500ms | 50-200ms | 1-20ms |
| **メモリ** | 300-450 MB | 200-300 MB | 50-70 MB |
| **起動時間比** | 1.0x (ベースライン) | 約10-14倍高速 | 約40-70倍高速 |
| **メモリ比** | 1.0x (ベースライン) | 約70% | 約15-20% |

### ベンチマーク実行

プロジェクトルートから：

```bash
./bench/run_benchmark.sh
```

3モード（Quarkus Native、Quarkus JVM、Spring Boot JVM）の詳細な比較が表示されます。

## トラブルシューティング

### 問題1: ポートが既に使用されている

**症状**:
```
Port 8082 is already in use
```

**解決方法**:
```bash
# ポート確認
lsof -i :8082

# プロセス停止
kill <PID>

# または別のポートで起動
java -jar target/spring-todo-0.0.1-SNAPSHOT.jar --server.port=9000
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

### 問題3: 起動が遅い

**症状**: 起動に1分以上かかる

**原因**:
- メモリ不足
- 大量のAuto-Configuration
- ログレベルがDEBUG

**解決方法**:
```bash
# メモリを増やす
java -Xms512m -Xmx1g -jar target/spring-todo-0.0.1-SNAPSHOT.jar

# ログレベルを変更
java -jar target/spring-todo-0.0.1-SNAPSHOT.jar \
  --logging.level.root=WARN
```

## 開発

### 開発モード（Spring Boot DevTools）

```bash
# DevToolsを有効にしてビルド
mvn spring-boot:run
```

**特徴**:
- クラスパスの変更を自動検出
- 自動再起動
- LiveReload対応

### テストの実行

```bash
# 全テスト実行
mvn test

# 特定のテストクラス
mvn test -Dtest=TodoServiceTest

# カバレッジレポート
mvn test jacoco:report
```

### デバッグ

```bash
# デバッグモードで起動
java -agentlib:jdwp=transport=dt_socket,server=y,suspend=n,address=*:5005 \
  -jar target/spring-todo-0.0.1-SNAPSHOT.jar
```

IDEから`localhost:5005`にリモートデバッグ接続。

## Quarkus版との違い

### アーキテクチャ

| 項目 | Spring Boot | Quarkus |
|-----|------------|---------|
| **DI コンテナ** | Spring Container | CDI (ArC) |
| **Web フレームワーク** | Spring MVC | RESTEasy Reactive |
| **ORM** | Hibernate | Hibernate + Panache |
| **設定** | application.properties/yml | application.properties |

### エンドポイント

| 機能 | Spring Boot | Quarkus |
|-----|------------|---------|
| **ポート** | 8082 | 8081 |
| **Health Check** | `/actuator/health` | `/q/health/ready` |
| **Metrics** | `/actuator/prometheus` | `/q/metrics` |
| **Swagger UI** | `/swagger-ui` | `/swagger-ui` |
| **API Docs** | `/openapi` | `/openapi` |

### パフォーマンス

| 指標 | Spring Boot | Quarkus JVM | 差 |
|-----|------------|------------|-----|
| **起動時間** | 700-1200ms | 50-200ms | 約10-14倍 |
| **メモリ** | 300-450 MB | 200-300 MB | 約30% |
| **CPU（アイドル）** | 0.5-2.0% | 0.5-2.0% | ほぼ同じ |

### 選択基準

**Spring Bootを選ぶ場合**:
- ✅ 既存のSpringアプリケーションとの統合
- ✅ Spring生態系（Spring Security、Spring Cloud等）を使用
- ✅ チームがSpringに精通している
- ✅ 大規模な既存Springプロジェクト

**Quarkusを選ぶ場合**:
- ✅ Kubernetes/コンテナ環境
- ✅ サーバーレス（AWS Lambda等）
- ✅ 高速起動が重要
- ✅ メモリ使用量を削減したい
- ✅ Native Imageを使用したい

## 参考リンク

- [Spring Boot公式サイト](https://spring.io/projects/spring-boot)
- [Spring Boot Reference Documentation](https://docs.spring.io/spring-boot/docs/current/reference/html/)
- [Spring Data JPA](https://spring.io/projects/spring-data-jpa)
- [Spring Boot Actuator](https://docs.spring.io/spring-boot/docs/current/reference/html/actuator.html)

## ライセンス

このプロジェクトはデモンストレーション用です。

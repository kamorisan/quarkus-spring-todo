# Todo UI Application

QuarkusベースのシンプルなTodo管理UIアプリケーションです。バックエンドのTodo API（QuarkusまたはSpring Boot）と連携して、Todoの作成、表示、更新、削除を行います。

## 概要

このアプリケーションは、Quarkus 3.17.0とJava 21で構築されており、以下の機能を提供します。

- **Todo CRUD操作**: Todoの作成、読み取り、更新、削除
- **バックエンド連携**: QuarkusまたはSpring BootのTodo APIと連携
- **レスポンシブUI**: モダンでシンプルなWebインターフェース
- **ヘルスチェック**: バックエンドの状態を自動確認
- **バックエンドタイプ識別**: QuarkusとSpringで異なるAPIエンドポイントに対応

## 技術スタック

- **Framework**: Quarkus 3.17.0
- **Java**: OpenJDK 21
- **REST Client**: MicroProfile REST Client Reactive
- **Frontend**: HTML5, CSS3, Vanilla JavaScript
- **Health Check**: SmallRye Health

## 環境変数

| 環境変数 | 説明 | デフォルト値 | 必須 |
|---------|------|------------|------|
| `BACKEND_URL` | バックエンドTodo APIのURL | `http://localhost:8081` | OpenShift環境では必須 |
| `BACKEND_TYPE` | バックエンドのタイプ (`quarkus` or `spring`) | `quarkus` | OpenShift環境では必須 |

### バックエンドタイプによる違い

アプリケーションは、バックエンドのタイプに応じて適切なヘルスチェックエンドポイントを使用します。

| バックエンド | ヘルスチェックエンドポイント |
|------------|---------------------------|
| Quarkus | `/q/health/ready` |
| Spring Boot | `/actuator/health/readiness` |

## ローカル開発

### 前提条件

- Java 21
- Maven 3.9+
- バックエンドTodo API (Quarkus または Spring Boot)

### バックエンドAPIの起動

まず、バックエンドのTodo APIを起動します。

**Quarkusの場合:**
```bash
cd quarkus-todo
./mvnw quarkus:dev -Dquarkus.http.port=8081
```

**Spring Bootの場合:**
```bash
cd spring-todo
./mvnw spring-boot:run -Dserver.port=8081
```

### Todo UIの起動

#### 開発モード（ホットリロード有効）

```bash
cd todo-ui

# Quarkusバックエンドと連携
export BACKEND_URL=http://localhost:8081
export BACKEND_TYPE=quarkus
./mvnw quarkus:dev

# または Spring Bootバックエンドと連携
export BACKEND_URL=http://localhost:8081
export BACKEND_TYPE=spring
./mvnw quarkus:dev
```

アプリケーションは [http://localhost:8080](http://localhost:8080) で起動します。

#### JVMモードでビルドして実行

```bash
./mvnw package
java -DBACKEND_URL=http://localhost:8081 -DBACKEND_TYPE=quarkus -jar target/quarkus-app/quarkus-run.jar
```

#### Nativeモードでビルドして実行

```bash
./mvnw package -Pnative
BACKEND_URL=http://localhost:8081 BACKEND_TYPE=quarkus ./target/todo-ui-1.0.0-SNAPSHOT-runner
```

## 使い方

### Webインターフェース

1. ブラウザで [http://localhost:8080](http://localhost:8080) にアクセス
2. ヘッダーにバックエンドのタイプとステータスが表示されます
3. 左側のフォームからTodoを作成・編集
4. 右側のリストでTodoを表示・管理

### API エンドポイント

Todo UIは以下のエンドポイントを提供します（すべてバックエンドAPIへプロキシされます）。

| メソッド | エンドポイント | 説明 |
|---------|--------------|------|
| GET | `/api/todos` | 全Todoリストを取得 |
| GET | `/api/todos/{id}` | 特定のTodoを取得 |
| POST | `/api/todos` | 新しいTodoを作成 |
| PUT | `/api/todos/{id}` | Todoを更新 |
| DELETE | `/api/todos/{id}` | Todoを削除 |
| GET | `/api/backend/info` | バックエンド情報を取得 |
| GET | `/api/backend/health` | バックエンドのヘルスチェック |

### ヘルスチェック

```bash
# Todo UI自体のヘルスチェック
curl http://localhost:8080/q/health

# バックエンドのヘルスチェック（プロキシ経由）
curl http://localhost:8080/api/backend/health

# バックエンド情報の取得
curl http://localhost:8080/api/backend/info
```

## テスト

### Todoの作成

```bash
curl -X POST http://localhost:8080/api/todos \
  -H 'Content-Type: application/json' \
  -d '{
    "title": "Test Todo",
    "description": "This is a test todo",
    "completed": false
  }'
```

### Todoリストの取得

```bash
curl http://localhost:8080/api/todos
```

### Todoの更新

```bash
curl -X PUT http://localhost:8080/api/todos/1 \
  -H 'Content-Type: application/json' \
  -d '{
    "title": "Updated Todo",
    "description": "This todo has been updated",
    "completed": true
  }'
```

### Todoの削除

```bash
curl -X DELETE http://localhost:8080/api/todos/1
```

## プロジェクト構成

```
todo-ui/
├── pom.xml                           # Maven設定
├── README.md                         # このファイル
└── src/
    └── main/
        ├── java/
        │   └── com/example/todoui/
        │       ├── client/
        │       │   └── TodoClient.java          # バックエンドAPIクライアント
        │       ├── model/
        │       │   └── Todo.java                # Todoモデル
        │       └── resource/
        │           ├── TodoUIResource.java      # Todoプロキシエンドポイント
        │           └── HealthProxyResource.java # ヘルスチェックエンドポイント
        └── resources/
            ├── application.properties    # アプリケーション設定
            └── META-INF/
                └── resources/
                    ├── index.html        # メインHTML
                    ├── styles.css        # スタイルシート
                    └── app.js            # JavaScriptロジック
```

## OpenShiftへのデプロイ

OpenShift環境へのデプロイについては、[openshift/todo-ui/README.md](../openshift/todo-ui/README.md) を参照してください。

デプロイスクリプトの使用例:

```bash
cd openshift/todo-ui

# Quarkusバックエンドと連携
./deploy.sh https://quarkus-todo-jvm-demo-apps.apps.cluster.example.com quarkus

# Spring Bootバックエンドと連携
./deploy.sh https://spring-todo-jvm-demo-apps.apps.cluster.example.com spring
```

## トラブルシューティング

### バックエンドに接続できない

1. `BACKEND_URL`が正しく設定されているか確認
2. バックエンドAPIが起動しているか確認
3. CORS設定が正しいか確認（バックエンド側）

### バックエンドのヘルスチェックが失敗する

1. `BACKEND_TYPE`が正しく設定されているか確認（`quarkus` or `spring`）
2. バックエンドのヘルスチェックエンドポイントが有効か確認
   - Quarkus: `/q/health/ready`
   - Spring: `/actuator/health/readiness`

### UIが表示されない

1. ブラウザのコンソールでエラーを確認
2. ネットワークタブでAPIリクエストのステータスを確認
3. バックエンドのログでエラーを確認

## 開発ガイド

### 新機能の追加

1. バックエンドAPIに新しいエンドポイントを追加
2. `TodoClient.java`にメソッドを追加
3. `TodoUIResource.java`にエンドポイントを追加
4. `app.js`にフロントエンドロジックを追加
5. `index.html`と`styles.css`でUIを更新

### ホットリロードの活用

開発モード（`./mvnw quarkus:dev`）では、以下の変更が自動的に反映されます。

- Javaコードの変更
- `application.properties`の変更
- 静的リソース（HTML, CSS, JS）の変更

## パフォーマンス

### JVMモード

- 起動時間: 数秒
- メモリ使用量: 約200-300MB
- 推奨環境: 開発環境、本番環境

### Nativeモード

- 起動時間: 数百ms
- メモリ使用量: 約50-100MB
- 推奨環境: コンテナ環境、Serverless環境

## ライセンス

このプロジェクトのライセンスについては、リポジトリのルートディレクトリを参照してください。

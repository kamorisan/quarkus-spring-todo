# Quarkus vs Spring Boot JVM 比較デモ

このプロジェクトは、QuarkusとSpring Bootで同等機能のTodo CRUDアプリケーションを実装し、起動時間、メモリ使用量、CPU使用率を比較するデモです。

## 📋 目次

- [前提条件](#前提条件)
- [プロジェクト構成](#プロジェクト構成)
- [ビルド方法](#ビルド方法)
- [手動実行](#手動実行)
- [ベンチマーク実行](#ベンチマーク実行)
- [比較項目](#比較項目)
- [API仕様](#api仕様)

## 🔧 前提条件

- OpenJDK 21
- Maven 3.8+
- curl（ベンチマーク用）
- bc（計算用）

### JDKバージョン確認

```bash
java -version
# openjdk version "21.x.x" が表示されることを確認
```

## 📁 プロジェクト構成

```
.
├── quarkus-todo/          # Quarkus実装
│   ├── src/
│   └── pom.xml
├── spring-todo/           # Spring Boot実装
│   ├── src/
│   └── pom.xml
├── bench/                 # ベンチマークスクリプト
│   ├── run_benchmark.sh   # 自動ベンチマーク実行
│   ├── run_quarkus.sh     # Quarkus起動
│   ├── run_spring.sh      # Spring Boot起動
│   ├── wait_ready.sh      # Ready待機
│   ├── measure_idle.sh    # メトリクス計測
│   ├── load_test.sh       # 負荷テスト
│   └── summary.sh         # 結果サマリー
├── results/               # 計測結果（CSV）
└── logs/                  # アプリケーションログ
```

## 🏗️ ビルド方法

### 両方のアプリケーションをビルド

```bash
# Quarkus
cd quarkus-todo
mvn clean package -DskipTests
cd ..

# Spring Boot
cd spring-todo
mvn clean package -DskipTests
cd ..
```

ビルド成果物：
- Quarkus: `quarkus-todo/target/quarkus-app/quarkus-run.jar`
- Spring Boot: `spring-todo/target/spring-todo-0.0.1-SNAPSHOT.jar`

## 🚀 手動実行

### Quarkusを起動

```bash
cd quarkus-todo
java -Xms128m -Xmx512m -jar target/quarkus-app/quarkus-run.jar
```

- ポート: 8081
- Health: http://localhost:8081/health/ready
- Swagger UI: http://localhost:8081/swagger-ui
- Metrics: http://localhost:8081/q/metrics

### Spring Bootを起動

```bash
cd spring-todo
java -Xms128m -Xmx512m -jar target/spring-todo-0.0.1-SNAPSHOT.jar
```

- ポート: 8082
- Health: http://localhost:8082/health/ready
- Swagger UI: http://localhost:8082/swagger-ui
- Metrics: http://localhost:8082/actuator/prometheus

## 📊 ベンチマーク実行

自動ベンチマークスクリプトを実行すると、Quarkus と Spring Boot を順番に起動し、起動時間・メモリ・CPUを計測します。

```bash
./bench/run_benchmark.sh
```

### 実行内容

1. データディレクトリのクリーンアップ
2. Quarkusの起動・計測・停止
   - 起動時間計測
   - 60秒間のアイドルメトリクス計測（RSS、CPU）
3. Spring Bootの起動・計測・停止
   - 起動時間計測
   - 60秒間のアイドルメトリクス計測（RSS、CPU）
4. 結果サマリーの表示

### 結果ファイル

- `results/quarkus_idle.csv` - Quarkusのアイドルメトリクス
- `results/spring_idle.csv` - Spring Bootのアイドルメトリクス
- `logs/quarkus.log` - Quarkusのログ
- `logs/spring.log` - Spring Bootのログ

### サマリー表示

```bash
./bench/summary.sh
```

出力例：
```
=========================================
  Quarkus vs Spring Boot Benchmark Summary
=========================================

Quarkus Startup Time: 1234ms
Spring Boot Startup Time: 3456ms

-----------------------------------------
Memory Usage (Idle)
-----------------------------------------
Quarkus Max RSS: 245760 KB (240 MB)
Quarkus Avg RSS: 235520 KB (230 MB)
Spring Boot Max RSS: 368640 KB (360 MB)
Spring Boot Avg RSS: 358400 KB (350 MB)

-----------------------------------------
CPU Usage (Idle)
-----------------------------------------
Quarkus Max CPU: 0.5%
Quarkus Avg CPU: 0.2%
Spring Boot Max CPU: 0.8%
Spring Boot Avg CPU: 0.3%

=========================================
```

## 📈 比較項目

| 項目 | 説明 | 計測方法 |
|------|------|----------|
| 起動時間 | プロセス起動からReady応答まで | `/health/ready`が200を返すまでの時間 |
| メモリ (RSS) | 常駐メモリサイズ | `ps`コマンドで1秒ごとに60秒計測 |
| CPU使用率 | プロセスCPU使用率 | `ps`コマンドで1秒ごとに60秒計測 |

### 統一されたJVMオプション

両アプリケーションで同じJVMオプションを使用して公平な比較を実現：

```bash
-Xms128m -Xmx512m -Dfile.encoding=UTF-8
```

## 🔌 API仕様

両アプリケーションで完全に同じAPIを提供します。

### エンドポイント一覧

| メソッド | パス | 説明 |
|---------|------|------|
| POST | `/api/todos` | Todo作成 |
| GET | `/api/todos` | 一覧取得 |
| GET | `/api/todos/{id}` | 単体取得 |
| PUT | `/api/todos/{id}` | 全更新 |
| PATCH | `/api/todos/{id}` | 部分更新 |
| DELETE | `/api/todos/{id}` | 削除 |

### クエリパラメータ（一覧取得）

- `completed` (Boolean): 完了状態でフィルタ
- `q` (String): タイトル部分一致検索
- `page` (int): ページ番号（default: 0）
- `size` (int): ページサイズ（default: 20）
- `sort` (String): ソート順（default: "updatedAt,desc"）

### リクエスト例

```bash
# Todoを作成
curl -X POST http://localhost:8081/api/todos \
  -H "Content-Type: application/json" \
  -d '{
    "title": "サンプルTodo",
    "description": "説明文",
    "completed": false,
    "dueDate": "2026-03-01"
  }'

# 一覧取得
curl http://localhost:8081/api/todos

# 検索
curl "http://localhost:8081/api/todos?completed=false&q=サンプル"
```

### Health & Metrics

#### Health Endpoints

- **Liveness**: `/health/live` - 常に200を返す
- **Readiness**: `/health/ready` - 初期化完了後に200を返す

```bash
# Quarkus
curl http://localhost:8081/health/ready

# Spring Boot
curl http://localhost:8082/health/ready
```

#### Metrics

- **Quarkus**: `/q/metrics`
- **Spring Boot**: `/actuator/prometheus`

### OpenAPI / Swagger UI

両アプリケーションでSwagger UIが利用可能：

- **Quarkus**: http://localhost:8081/swagger-ui
- **Spring Boot**: http://localhost:8082/swagger-ui

## 🗄️ データベース

両アプリケーションでH2ファイルデータベースを使用：

- URL: `jdbc:h2:file:./data/todo-db`
- Mode: PostgreSQL互換
- スキーマ: 起動時に自動生成（drop-and-create）

データのクリーンアップ：
```bash
rm -rf data/
```

## 🎯 設計のポイント

### 公平な比較のための工夫

1. **同一機能**: 両アプリで完全に同じREST API、バリデーション、DB永続化を実装
2. **同一実行モデル**: ブロッキングI/O同士で比較（Spring MVC vs Quarkus imperative REST）
3. **同一JVMオプション**: ヒープサイズ等を統一
4. **同一計測方法**: 外部からのHTTPヘルスチェックで起動時間を計測

### 実装の特徴

- **Entity**: JPA標準アノテーションで実装
- **Validation**: Jakarta Bean Validation使用
- **DTO**: Request/Response分離
- **Health**: 独自エンドポイントで起動時間ログ出力

## 📝 ライセンス

このプロジェクトはデモ目的で作成されています。

## 🤝 貢献

バグ報告や改善提案は Issue でお願いします。

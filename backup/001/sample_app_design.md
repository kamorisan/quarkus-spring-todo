# 設計ドキュメント：Quarkus vs Spring Boot JVM 比較デモ（Todo CRUD）

## 1. 目的
- Java フレームワーク **Quarkus** と **Spring Boot** で **同等機能のサンプルアプリ**を実装し、以下を比較する：
  - 起動時間（プロセス起動〜Ready応答まで）
  - 常駐メモリ（RSS）
  - CPU（アイドル時 / 軽負荷時のCPU使用率）
- 比較が **フェア**になるよう、アプリ機能・DB・JVMオプション・計測手順を統一する。

## 2. 前提 / 制約
- **OpenJDK 21**
- **コンテナ利用なし**（ローカルで `java -jar` による JVM 起動）
- Kafka / OpenShift など外部基盤は使わない
- DBは外部に依存しない構成（H2埋め込み）を基本とする

## 3. 成果物（リポジトリ構成）
```
bench-quarkus-vs-spring/
  quarkus-todo/          # Quarkus 実装
  spring-todo/           # Spring Boot 実装
  bench/                 # 計測スクリプト、結果出力
  README.md              # 手順と比較結果の見せ方
```

## 4. 共通仕様（両アプリで完全一致させる）
### 4.1 機能要件（同一）
- Todo CRUD のREST API（JSON）
- 入力バリデーション（必須・最大長など）
- DB永続化（H2 + JPA/Hibernate）
- OpenAPI（Swagger UI）
- Health（liveness/readiness）
- Metrics（Prometheus形式での出力を可能にする）
- アプリ起動完了を判定できる **Ready エンドポイント**（計測用に必須）

### 4.2 非機能要件（同一）
- ログレベルは INFO（過度なログ差でノイズを出さない）
- 同一JVMオプションで起動する（後述）
- 同一ポート（例：Quarkus: 8081 / Spring: 8082）で衝突しないよう固定
- DBはH2の**ファイル永続化**（起動ごとに初期化できるようにする）
  - 例：`./data/todo-db` に保存
  - 起動前に `data/` を削除すれば初期状態になる

---

## 5. API設計（共通）
### 5.1 エンドポイント一覧
Base Path：`/api`

- `POST /api/todos`：Todo作成
- `GET /api/todos`：一覧取得（簡易フィルタあり）
  - Query:
    - `completed` (true/false 任意)
    - `q` (title 部分一致 任意)
    - `page` (default 0)
    - `size` (default 20)
    - `sort` (default `updatedAt,desc`)
- `GET /api/todos/{id}`：単体取得
- `PUT /api/todos/{id}`：全更新
- `PATCH /api/todos/{id}`：部分更新（completedのみ等）
- `DELETE /api/todos/{id}`：削除

### 5.2 Health/Ready（計測用に共通のパスを用意）
- `GET /health/live` → 常に 200（プロセス生存確認）
- `GET /health/ready` → **アプリ初期化完了後に 200**
  - 起動直後は 503、Ready後は 200
  - Ready判定は「アプリ起動イベント受領 + DB接続確認（簡単なSELECT 1）」を条件にする

### 5.3 OpenAPI
- OpenAPI JSON：`/openapi`（もしくはフレームワーク標準でも良いが README で明記）
- Swagger UI：`/swagger-ui`

### 5.4 Metrics
- Prometheus形式で出力できること（パスはフレームワーク標準でもOK）
  - Quarkus: `/q/metrics` 等
  - Spring: `/actuator/prometheus` 等
- デモでは「出せる」ことが目的で、比較計測の主要指標にはしない（ノイズ回避）

---

## 6. データモデル（共通）
### 6.1 Entity: Todo
- `id`: UUID（PK）
- `title`: String（必須、1..120）
- `description`: String（任意、最大 1000）
- `completed`: boolean（default false）
- `dueDate`: LocalDate（任意）
- `createdAt`: Instant（作成時）
- `updatedAt`: Instant（更新時）

### 6.2 DTO
- `CreateTodoRequest`
- `UpdateTodoRequest`
- `PatchTodoRequest`
- `TodoResponse`

### 6.3 バリデーション要件（共通）
- title: not blank, max 120
- description: max 1000
- dueDate: 過去日禁止（任意。入れるなら両者で同じ制約）

---

## 7. 実装方針（フレームワーク別）

### 7.1 Quarkus 実装（`quarkus-todo/`）
- Build: Maven
- 主要依存（例）
  - REST（imperative）: `quarkus-rest`
  - JSON: `quarkus-rest-jackson`（または `quarkus-jackson`）
  - JPA: `quarkus-hibernate-orm`
  - H2: `quarkus-jdbc-h2`
  - Validation: `quarkus-hibernate-validator`
  - OpenAPI: `quarkus-smallrye-openapi`
  - Metrics: `quarkus-micrometer` + `quarkus-micrometer-registry-prometheus`
  - Health: `quarkus-smallrye-health`
- Ready実装
  - `StartupEvent` を observe して “初期化開始” を記録
  - DB接続確認後に `ready=true`
  - `/health/ready` は `ready` フラグで 200/503 を返す

### 7.2 Spring Boot 実装（`spring-todo/`）
- Build: Maven（Spring Initializr ベース）
- 主要依存（例）
  - Web: Spring MVC（Tomcat）
  - Data JPA（Hibernate）
  - H2
  - Validation
  - Actuator（health/metrics）
  - Micrometer Prometheus
  - OpenAPI: `springdoc-openapi-starter-webmvc-ui`
- Ready実装
  - `ApplicationReadyEvent` で `ready=true`
  - 併せてDB接続確認（簡単なクエリ）を実施して ready 化
  - `/health/ready` は `ready` フラグで 200/503 を返す

> 注：Spring Actuator の readiness/liveness を使っても良いが、Quarkusと“同じURL/同じ判定ロジック”にするため、**アプリ独自エンドポイント**を作る。

---

## 8. 設定（共通の意図）
### 8.1 ポート
- Quarkus: `8081`
- Spring: `8082`

### 8.2 DB（H2 ファイル）
- DB URL 例（両者で揃える）
  - `jdbc:h2:file:./data/todo-db;MODE=PostgreSQL;DATABASE_TO_LOWER=TRUE;DEFAULT_NULL_ORDERING=HIGH`
- スキーマ生成
  - デモ簡略化のため **起動時に自動生成**
  - Quarkus: `quarkus.hibernate-orm.database.generation=drop-and-create`（または `update`）
  - Spring: `spring.jpa.hibernate.ddl-auto=create-drop`（または `update`）
- 比較のたびに `rm -rf data/` で初期化できること

### 8.3 ログ
- INFO
- アクセスログはOFF（差分ノイズ回避）

---

## 9. 起動時間の計測設計（必須）
### 9.1 アプリ内タイムスタンプ（補助）
- OS計測が本筋だが、補助としてアプリ内でも測る：
  - プロセス開始時刻（main開始）
  - Ready 到達時刻（Readyフラグが true になった瞬間）
- ログに `APP_READY_MS=<millis>` を **必ず出力**（比較表に使える）

### 9.2 OS側のReady到達測定（本命）
- `java -jar ...` 実行直後から、`/health/ready` が 200 を返すまでの経過時間を測る。
- この方式で、Quarkus/Spring ともに同じ尺度になる。

---

## 10. CPU・メモリ計測設計
### 10.1 指標
- メモリ：RSS（Resident Set Size）
- CPU：%CPU（プロセスCPU使用率）
- 追加（任意）：ヒープ使用量（`jcmd GC.heap_info` 等）

### 10.2 状態別に測る
1) **アイドル**（起動完了後60秒放置）  
2) **軽負荷**（例：一定時間のHTTPリクエスト）

負荷ツールは `wrk` か `hey` を使用（両者同じ条件）。

---

## 11. ベンチ用スクリプト要件（`bench/` 配下に作る）
### 11.1 共通スクリプト
- `bench/run_quarkus.sh`
- `bench/run_spring.sh`
  - 共通JVMオプションを付与して起動
  - PIDをファイルに保存（例：`bench/quarkus.pid`）
- `bench/wait_ready.sh <url>`
  - Ready 200 になるまでポーリングし、経過時間を出力
- `bench/measure_idle.sh <pid>`
  - 60秒間、1秒ごとに RSS と %CPU を採取してCSV出力
- `bench/load_test.sh <baseUrl>`
  - 例：`POST`で初期データ投入→`GET /todos` を一定時間叩く
- `bench/summary.sh`
  - 起動時間、最大RSS、平均CPU等を要約して表示

### 11.2 CSV出力形式（例）
- `results/quarkus_idle.csv`
- `results/spring_idle.csv`
- 列：
  - timestamp, rss_kb, cpu_percent

---

## 12. JVM起動条件（比較のため必ず統一）
- 両者とも以下オプションで起動（例）
  - `-Xms128m -Xmx512m`
  - `-Dfile.encoding=UTF-8`
  - （任意）`-XX:+UseG1GC`（JDK21のデフォルトだが明示しても良い）
- コマンド例
  - Quarkus: `java -Xms128m -Xmx512m -jar target/quarkus-app/quarkus-run.jar`
  - Spring: `java -Xms128m -Xmx512m -jar target/spring-todo-0.0.1-SNAPSHOT.jar`

---

## 13. デモ手順（READMEに記載する内容）
1. build
   - `mvn -q -DskipTests package`（両者）
2. DB初期化
   - `rm -rf data/`
3. 起動（Quarkus→計測→停止、Spring→計測→停止 の順）
4. Ready到達時間を表示
5. アイドル計測（60秒）
6. 軽負荷計測（30秒〜60秒）
7. 結果を `bench/summary.sh` で比較表示

---

## 14. 受け入れ条件（Doneの定義）
- Quarkus/Spring 両方で以下が動く：
  - CRUD API が正常動作（最低限：create/list/get/update/delete）
  - `/health/ready` が起動直後503→Ready後200に遷移
  - OpenAPI/Swagger UI が表示できる
  - Prometheus形式のメトリクスが取得できる
- `bench/` の計測で以下が自動取得できる：
  - Ready到達時間（秒 or ms）
  - アイドル時RSSの最大/平均
  - 軽負荷時CPUの平均/最大
- READMEに、結果を見せるためのコマンドと解釈ポイントがまとまっている

---

## 15. 実装上の注意（比較の公平性）
- Quarkus側だけ極端に機能を減らしたり、Spring側だけ機能を盛ったりしない
- SpringをWebFluxにするならQuarkusもReactiveにするなど、**実行モデルを揃える**
  - 今回は説明しやすいので **ブロッキング同士（Spring MVC / Quarkus imperative）** を基本とする
- Devモードは使わない（本番相当のjar起動で比較）

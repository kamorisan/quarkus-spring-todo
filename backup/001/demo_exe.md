# Quarkus vs Spring Boot デモ実行ガイド

## 📋 デモの概要

このデモでは、QuarkusとSpring Bootで**完全に同じ機能**を持つTodo管理アプリケーションを実装し、以下の項目を比較します：

| 比較項目 | 説明 | 重要性 |
|---------|------|--------|
| **起動時間** | JVMプロセス起動からアプリケーションReady応答までの時間 | ⭐⭐⭐ |
| **メモリ使用量** | アイドル時の常駐メモリサイズ (RSS) | ⭐⭐⭐ |
| **CPU使用率** | アイドル時のCPU使用率 | ⭐⭐ |

### デモの目的

1. **公平な比較**: 同一機能・同一JVMオプションで実行環境を統一
2. **実測値の提示**: 実際に計測した数値で客観的に比較
3. **再現性**: 誰でも同じ環境で同じ結果を得られる

---

## 🔧 前提条件

### 必須環境

```bash
# Java 21確認
java -version
# 出力例: openjdk version "21.0.x" ...

# Maven確認
mvn -version
# 出力例: Apache Maven 3.x.x

# curl確認（ベンチマーク用）
curl --version

# bc確認（計算用）
bc --version
```

### システム要件

- **OS**: macOS, Linux, Windows (WSL)
- **メモリ**: 最低2GB以上の空きメモリ
- **ディスク**: 500MB以上の空き容量

---

## 🏗️ セットアップ（初回のみ）

### 1. プロジェクトの確認

```bash
cd /Users/kamori/vscode/customer/subaru
ls -la
```

以下のディレクトリが存在することを確認：
- `quarkus-todo/` - Quarkus実装
- `spring-todo/` - Spring Boot実装
- `bench/` - ベンチマークスクリプト

### 2. ビルド

```bash
# Quarkusをビルド
cd quarkus-todo
mvn clean package -DskipTests
cd ..

# Spring Bootをビルド
cd spring-todo
mvn clean package -DskipTests
cd ..
```

**ビルド時間の目安**:
- Quarkus: 約30-60秒
- Spring Boot: 約30-60秒

**ビルド成果物の確認**:
```bash
ls -lh quarkus-todo/target/quarkus-app/quarkus-run.jar
ls -lh spring-todo/target/spring-todo-0.0.1-SNAPSHOT.jar
```

出力例：
```
-rw-r--r--  1 user  staff   693B  quarkus-todo/target/quarkus-app/quarkus-run.jar
-rw-r--r--  1 user  staff    57M  spring-todo/target/spring-todo-0.0.1-SNAPSHOT.jar
```

> **注**: Quarkusは thin JAR、Spring Bootは fat JAR形式のため、JARサイズが大きく異なります。

---

## 🚀 デモ実行方法

### 方法1: 自動ベンチマーク実行（推奨）

最も簡単な方法です。全ての計測を自動で実行します。

```bash
# ベンチマーク実行
./bench/run_benchmark.sh
```

**実行内容**:
1. データディレクトリのクリーンアップ
2. Quarkusアプリ起動 → Ready待機 → 60秒間メトリクス計測 → 停止
3. データディレクトリのクリーンアップ
4. Spring Bootアプリ起動 → Ready待機 → 60秒間メトリクス計測 → 停止
5. 結果サマリーの自動表示

**実行時間**: 約3-4分

### 方法2: 手動で個別実行

各ステップを手動で実行する場合：

#### Step 1: Quarkusの計測

```bash
# データをクリーンアップ
rm -rf data/

# Quarkus起動
./bench/run_quarkus.sh

# Ready待機（起動時間を計測）
./bench/wait_ready.sh http://localhost:8081/health/ready

# メトリクス計測（60秒間）
QUARKUS_PID=$(cat bench/quarkus.pid)
./bench/measure_idle.sh $QUARKUS_PID 60 results/quarkus_idle.csv

# 停止
kill $(cat bench/quarkus.pid)
```

#### Step 2: Spring Bootの計測

```bash
# データをクリーンアップ
rm -rf data/

# Spring Boot起動
./bench/run_spring.sh

# Ready待機（起動時間を計測）
./bench/wait_ready.sh http://localhost:8082/health/ready

# メトリクス計測（60秒間）
SPRING_PID=$(cat bench/spring.pid)
./bench/measure_idle.sh $SPRING_PID 60 results/spring_idle.csv

# 停止
kill $(cat bench/spring.pid)
```

#### Step 3: 結果確認

```bash
# サマリー表示
./bench/summary.sh
```

---

## 📊 期待される結果

### 起動時間の比較

ベンチマーク実行後、以下のような結果が表示されます：

```
=========================================
  Quarkus vs Spring Boot Benchmark Summary
=========================================

Quarkus Startup Time: 53ms
Spring Boot Startup Time: 731ms

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

### 典型的な結果の範囲

環境により変動しますが、一般的には以下の範囲になります：

| 項目 | Quarkus | Spring Boot | Quarkusの優位性 |
|------|---------|-------------|----------------|
| **起動時間** | 50-200ms | 500-1500ms | **約5-10倍高速** |
| **メモリ使用量** | 200-300MB | 300-450MB | **約30-40%削減** |
| **CPU使用率** | 0.1-0.5% | 0.2-1.0% | **約半分** |

### 結果ファイル

計測結果は以下のファイルに保存されます：

```bash
# 結果CSV
results/quarkus_idle.csv
results/spring_idle.csv

# アプリケーションログ
logs/quarkus.log
logs/spring.log
```

**CSV形式**:
```csv
timestamp,rss_kb,cpu_percent
1708589400,245760,0.3
1708589401,246080,0.2
...
```

---

## 🔬 比較方法の詳細

### 1. 起動時間の計測

**計測方法**:
- 外部から `/health/ready` エンドポイントをポーリング
- 200 OKが返るまでの時間を計測

**フェアな比較のポイント**:
- 同じJVMオプション: `-Xms128m -Xmx512m`
- 同じ計測方法: HTTPヘルスチェック
- 同じ初期化処理: DB接続確認を含む

**アプリ内ログでも確認可能**:
```bash
# Quarkusログから
grep "APP_READY_MS" logs/quarkus.log
# 出力例: APP_READY_MS=53

# Spring Bootログから
grep "APP_READY_MS" logs/spring.log
# 出力例: APP_READY_MS=731
```

### 2. メモリ使用量の計測

**計測方法**:
- `ps`コマンドで RSS (Resident Set Size) を取得
- 1秒ごとに60秒間計測
- 最大値と平均値を算出

**RSS とは**:
- プロセスが実際に使用している物理メモリ量
- ヒープ + ネイティブメモリ + メタスペースを含む

**CSV確認**:
```bash
# Quarkusのメモリ推移
cat results/quarkus_idle.csv

# 最大値を確認
tail -n +2 results/quarkus_idle.csv | cut -d, -f2 | sort -n | tail -1
```

### 3. CPU使用率の計測

**計測方法**:
- `ps`コマンドで %CPU を取得
- アイドル状態（リクエストなし）で60秒間計測

**解釈**:
- 0.5%未満: 非常に低い（ほぼアイドル）
- 0.5-1.0%: 低い（バックグラウンド処理が軽微）
- 1.0%以上: GCやバックグラウンドタスクが動作中

### 4. 統一された実行条件

両アプリケーションで完全に統一されている項目：

| 項目 | 設定内容 |
|------|---------|
| **JVMバージョン** | OpenJDK 21 |
| **ヒープサイズ** | -Xms128m -Xmx512m |
| **データベース** | H2 (file:./data/todo-db) |
| **ログレベル** | INFO |
| **API機能** | Todo CRUD (完全同一) |
| **ポート** | Quarkus:8081, Spring:8082 |

---

## 🧪 機能確認（オプション）

ベンチマーク以外に、実際にAPIを叩いて動作を確認することもできます。

### Quarkusアプリの起動と確認

```bash
# 起動
cd quarkus-todo
java -Xms128m -Xmx512m -jar target/quarkus-app/quarkus-run.jar
```

別のターミナルで：

```bash
# Health確認
curl http://localhost:8081/health/ready

# Todo作成
curl -X POST http://localhost:8081/api/todos \
  -H "Content-Type: application/json" \
  -d '{
    "title": "Quarkusテスト",
    "description": "デモ用のTodo",
    "completed": false
  }'

# 一覧取得
curl http://localhost:8081/api/todos

# Swagger UI（ブラウザで開く）
# http://localhost:8081/swagger-ui

# Prometheus Metrics
curl http://localhost:8081/q/metrics
```

### Spring Bootアプリの起動と確認

```bash
# 起動（新しいターミナルで）
cd spring-todo
java -Xms128m -Xmx512m -jar target/spring-todo-0.0.1-SNAPSHOT.jar
```

別のターミナルで：

```bash
# Health確認
curl http://localhost:8082/health/ready

# Todo作成
curl -X POST http://localhost:8082/api/todos \
  -H "Content-Type: application/json" \
  -d '{
    "title": "Spring Bootテスト",
    "description": "デモ用のTodo",
    "completed": false
  }'

# 一覧取得
curl http://localhost:8082/api/todos

# Swagger UI（ブラウザで開く）
# http://localhost:8082/swagger-ui

# Prometheus Metrics
curl http://localhost:8082/actuator/prometheus
```

---

## 📈 結果の分析と解釈

### 起動時間の差が生じる理由

**Quarkusが高速な理由**:
1. **ビルド時最適化**: 多くの処理をビルド時に実行（メタデータ処理、リフレクション解析）
2. **クラスパススキャン削減**: 実行時のクラスパススキャンを最小化
3. **遅延初期化**: 必要な機能だけを初期化
4. **最適化されたDI**: Quarkus Arc（軽量CDI実装）

**Spring Bootの起動時間**:
1. クラスパススキャン
2. Bean定義の解析と登録
3. AOP プロキシ生成
4. AutoConfiguration の評価

### メモリ使用量の差が生じる理由

**Quarkusがメモリ効率的な理由**:
1. **ビルド時処理**: メタデータをビルド時に処理し、実行時のメモリ使用を削減
2. **軽量DI**: Arc（CDI実装）はSpringコンテナより軽量
3. **最適化されたバイトコード**: GraalVM最適化を意識した設計

### いつQuarkusを選ぶべきか

Quarkusが特に有利なケース：
- ✅ コンテナ環境（Kubernetes等）
- ✅ サーバーレス環境（AWS Lambda等）
- ✅ マイクロサービスアーキテクチャ
- ✅ 頻繁なスケールイン/アウトが必要
- ✅ リソース制約がある環境

Spring Bootが適しているケース：
- ✅ 既存のSpringエコシステムとの統合
- ✅ 大規模な既存Springアプリケーション
- ✅ Springの豊富なライブラリを活用したい
- ✅ チームがSpringに精通している

---

## 🔍 トラブルシューティング

### ビルドエラー

**エラー**: `mvn package` が失敗する

**解決策**:
```bash
# Javaバージョン確認
java -version  # 21.x.xであることを確認

# Mavenキャッシュをクリア
mvn clean
rm -rf ~/.m2/repository

# 再ビルド
mvn clean package -DskipTests
```

### 起動エラー

**エラー**: `Address already in use`

**原因**: ポートが既に使用されている

**解決策**:
```bash
# ポート使用状況確認
lsof -i :8081  # Quarkus
lsof -i :8082  # Spring Boot

# プロセスを停止
kill <PID>
```

### ベンチマークスクリプトエラー

**エラー**: `wait_ready.sh` がタイムアウトする

**解決策**:
```bash
# ログを確認
tail -f logs/quarkus.log
tail -f logs/spring.log

# 手動で起動して問題を特定
cd quarkus-todo
java -Xms128m -Xmx512m -jar target/quarkus-app/quarkus-run.jar
```

### メトリクス計測の問題

**エラー**: `ps: No such process`

**原因**: プロセスが既に停止している

**解決策**:
```bash
# プロセスが実行中か確認
ps -p $(cat bench/quarkus.pid)

# PIDファイルをクリーンアップ
rm bench/*.pid
```

---

## 📝 デモのポイント（プレゼンテーション用）

### 1. デモ開始前

「これから、QuarkusとSpring Bootで**完全に同じTodoアプリ**を作成し、起動時間とメモリ使用量を比較します。」

**強調ポイント**:
- 同じAPI（REST、バリデーション、DB永続化）
- 同じJVMオプション
- 同じ計測方法

### 2. ベンチマーク実行中

```bash
./bench/run_benchmark.sh
```

「自動計測スクリプトが、Quarkus、Spring Bootの順に起動し、60秒間メトリクスを収集します。」

**観察ポイント**:
- 起動ログの速度差
- Ready到達までの時間

### 3. 結果表示

```bash
./bench/summary.sh
```

「結果をご覧ください。」

**強調する数値**:
- 起動時間: Quarkusは **約10倍高速**
- メモリ: Quarkusは **約30-40%削減**

### 4. 実アプリで確認

ブラウザで Swagger UI を開く：
- Quarkus: http://localhost:8081/swagger-ui
- Spring Boot: http://localhost:8082/swagger-ui

「両方とも完全に同じAPIを提供しています。」

### 5. まとめ

「Quarkusは、Kubernetes環境やサーバーレス環境で特に有利です。起動が速く、メモリ効率が良いため、コンテナ数を削減でき、コスト削減につながります。」

---

## 🎯 ベンチマーク結果のサマリーシート

以下の表を埋めて、結果を記録してください：

| 項目 | Quarkus | Spring Boot | 差分 |
|------|---------|-------------|------|
| 起動時間 (ms) | _________ | _________ | _________ |
| 最大メモリ (MB) | _________ | _________ | _________ |
| 平均メモリ (MB) | _________ | _________ | _________ |
| 平均CPU (%) | _________ | _________ | _________ |
| JARサイズ (MB) | ~0.7 | ~57 | - |

**計測日時**: __________
**環境**: macOS / Linux / Windows
**Java バージョン**: __________

---

## 📚 参考情報

### 公式ドキュメント

- [Quarkus公式サイト](https://quarkus.io/)
- [Spring Boot公式サイト](https://spring.io/projects/spring-boot)

### 本デモで実装されている機能

#### 共通機能
- ✅ REST API (Todo CRUD)
- ✅ JPA/Hibernate (H2データベース)
- ✅ Bean Validation
- ✅ OpenAPI/Swagger UI
- ✅ Health Check (Liveness/Readiness)
- ✅ Prometheus Metrics

#### API エンドポイント
- `POST /api/todos` - Todo作成
- `GET /api/todos` - 一覧取得（フィルタ、ページング対応）
- `GET /api/todos/{id}` - 単体取得
- `PUT /api/todos/{id}` - 全更新
- `PATCH /api/todos/{id}` - 部分更新
- `DELETE /api/todos/{id}` - 削除

---

## ✅ チェックリスト

デモ実行前の確認事項：

- [ ] Java 21 がインストールされている
- [ ] Maven 3.8+ がインストールされている
- [ ] 両アプリケーションがビルド済み
- [ ] ポート 8081, 8082 が空いている
- [ ] `bench/` のスクリプトに実行権限がある (`chmod +x bench/*.sh`)
- [ ] ディスク容量が十分にある（500MB以上）

デモ実行後の確認事項：

- [ ] `results/` ディレクトリにCSVファイルが生成された
- [ ] `logs/` ディレクトリにログファイルが生成された
- [ ] `./bench/summary.sh` で結果が表示される
- [ ] 起動時間、メモリ、CPUの数値が妥当

---

## 🎓 まとめ

このデモでは、QuarkusとSpring Bootの実際のパフォーマンス差を、**定量的**かつ**再現可能**な方法で示すことができます。

**重要なポイント**:
1. 同じ機能を実装して公平に比較
2. 実際の数値で客観的に評価
3. 環境によらず再現可能

**次のステップ**:
- ネイティブイメージ（GraalVM）での比較
- 負荷テスト時のパフォーマンス比較
- コンテナ環境での実行

---

**Document Version**: 1.0
**Last Updated**: 2026-02-22
**Author**: Claude Code Demo

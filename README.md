# Quarkus vs Spring Boot 比較デモ（3-Way版）

このプロジェクトは、Quarkus Native Image、Quarkus JVM、Spring Boot JVMの3種類で同等機能のTodo CRUDアプリケーションを実装し、起動時間、メモリ使用量、CPU使用率を比較するデモです。

## 📋 目次

- [前提条件](#前提条件)
- [プロジェクト構成](#プロジェクト構成)
- [クイックスタート](#クイックスタート)
- [3種類の実行モード](#3種類の実行モード)
- [ビルド方法](#ビルド方法)
- [ベンチマーク実行](#ベンチマーク実行)
- [比較結果](#比較結果)
- [API仕様](#api仕様)

## 🔧 前提条件

- **OpenJDK 21**
- **Maven 3.8+**
- **Docker** (Native Imageビルド用、推奨)
- **GraalVM 21** (オプション、Dockerがない場合)
- curl、bc（ベンチマーク用）

### JDKバージョン確認

```bash
java -version
# openjdk version "21.x.x" が表示されることを確認
```

## 📁 プロジェクト構成

```
.
├── quarkus-todo/          # Quarkus実装 → README.md参照 ⭐
│   ├── src/
│   ├── pom.xml           # nativeプロファイル含む
│   ├── README.md         # Quarkus詳細ガイド
│   └── target/
│       ├── quarkus-app/  # JVMモード用
│       └── *-runner      # Native Image
├── spring-todo/           # Spring Boot実装 → README.md参照 ⭐
│   ├── src/
│   ├── pom.xml
│   └── README.md         # Spring Boot詳細ガイド
├── bench/                 # ベンチマーク & テストスクリプト
│   ├── run_benchmark.sh   # 3-Way自動ベンチマーク ⭐
│   ├── run_quarkus_native.sh
│   ├── run_quarkus.sh
│   ├── run_spring.sh
│   ├── summary.sh         # 3-Way結果表示
│   ├── smoke_test.sh      # クイックAPIテスト ⭐
│   ├── test_api.sh        # 詳細APIテスト
│   ├── test_all_modes.sh  # 全モード自動テスト
│   └── ...
├── build_native.sh        # Native Imageビルドスクリプト
├── results/               # 計測結果（CSV）
├── logs/                  # アプリケーションログ
├── README.md             # このファイル
└── demo_exe.md           # 詳細な実行ガイド
```

## 🚀 クイックスタート

### 1. ビルド

```bash
# JVMモードのビルド
cd quarkus-todo && mvn clean package -DskipTests && cd ..
cd spring-todo && mvn clean package -DskipTests && cd ..

# Native Imageのビルド（オプション、Dockerが必要）
./build_native.sh
```

### 2. ベンチマーク実行

```bash
# 3種類を自動で計測
./bench/run_benchmark.sh
```

### 3. 結果確認

ベンチマーク実行後、自動的に結果が表示されます。
または手動で：

```bash
./bench/summary.sh
```

## 🎯 3種類の実行モード

| モード | 起動時間 | メモリ | 最適な用途 |
|--------|---------|--------|----------|
| **Quarkus Native** | 10-20ms ⚡⚡⚡ | 30-60MB 💚💚💚 | サーバーレス、K8s |
| **Quarkus JVM** | 50-200ms ⚡⚡ | 200-300MB 💚💚 | 開発、一般的な本番 |
| **Spring Boot JVM** | 500-1500ms ⚡ | 300-450MB 💚 | 既存Spring環境 |

### Quarkus Native Image

**特徴**:
- GraalVMでAOTコンパイル
- JVMランタイム不要
- 起動が超高速、メモリ極小

**使用例**:
```bash
# 直接実行（JVMオプション不要）
./quarkus-todo/target/quarkus-todo-1.0.0-SNAPSHOT-runner
```

### Quarkus JVM

**特徴**:
- 標準JVM上で実行
- ビルド時最適化済み
- 全Javaライブラリ利用可能

**使用例**:
```bash
java -Xms128m -Xmx512m -jar quarkus-todo/target/quarkus-app/quarkus-run.jar
```

### Spring Boot JVM

**特徴**:
- 標準Spring Bootアプリケーション
- 豊富なエコシステム
- 実績あるフレームワーク

**使用例**:
```bash
java -Xms128m -Xmx512m -jar spring-todo/target/spring-todo-0.0.1-SNAPSHOT.jar
```

## 🏗️ ビルド方法

### JVMモードのビルド

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

### Native Imageのビルド

#### 方法1: Docker使用（推奨）

```bash
./build_native.sh
```

このスクリプトは：
- Dockerが利用可能ならコンテナ内でビルド
- GraalVMがあればローカルでビルド
- 約3-10分かかります

#### 方法2: 手動ビルド

```bash
cd quarkus-todo
# Dockerでビルド
mvn package -Pnative -Dquarkus.native.container-build=true

# またはローカルGraalVMでビルド
mvn package -Pnative
cd ..
```

**ビルド成果物の確認**:
```bash
ls -lh quarkus-todo/target/quarkus-todo-1.0.0-SNAPSHOT-runner
# 出力例: 60-80 MB
```

## 📊 ベンチマーク実行

### 自動3-Wayベンチマーク（推奨）

```bash
./bench/run_benchmark.sh
```

このスクリプトは自動的に：
1. Quarkus Native起動 → 60秒計測 → 停止
2. Quarkus JVM起動 → 60秒計測 → 停止
3. Spring Boot JVM起動 → 60秒計測 → 停止
4. 結果サマリー表示

**実行時間**: 約4-5分

**Native Imageがない場合**:
- Quarkus Nativeをスキップ
- 2-Way比較（Quarkus JVM vs Spring Boot JVM）を実行

### 手動で個別実行

詳細は [demo_exe.md](demo_exe.md) を参照してください。

## 📈 比較結果

### 典型的な結果例

```
=========================================
  Quarkus vs Spring Boot Benchmark Summary
  (3-Way Comparison)
=========================================

Quarkus Native Startup Time: 15ms
Quarkus JVM Startup Time: 51ms
Spring Boot JVM Startup Time: 712ms

-----------------------------------------
Memory Usage (Idle)
-----------------------------------------
Quarkus Native: 48 MB
Quarkus JVM:    224 MB
Spring JVM:     316 MB

-----------------------------------------
Summary Comparison:
-----------------------------------------
Startup Time:
  Quarkus Native: 15ms (1.0x baseline)
  Quarkus JVM:    51ms (3.4x slower)
  Spring JVM:     712ms (47.5x slower)

Memory Savings:
  Native saves 78.6% vs Quarkus JVM
  Native saves 84.8% vs Spring JVM
=========================================
```

### 比較まとめ

| 比較 | 起動時間 | メモリ削減 | 主な理由 |
|------|---------|-----------|---------|
| **Native vs JVM** | 約3-4倍 | 約78% | JVMランタイム不要 |
| **Quarkus JVM vs Spring JVM** | 約10-14倍 | 約29% | ビルド時最適化 |
| **Native vs Spring JVM** | 約40-70倍 | 約85% | トータル効果 |

### ビジネスインパクト

**Kubernetes環境（100ポッド）の場合**:

| モード | メモリ総量 | 必要ノード数 (16GB/node) |
|--------|-----------|------------------------|
| Spring Boot JVM | 31.6 GB | 2ノード |
| Quarkus JVM | 22.4 GB | 2ノード |
| **Quarkus Native** | **4.8 GB** | **1ノード** |

→ **ノード数50%削減、コスト約50%削減**

## 🔌 API仕様

両アプリケーション（3モード全て）で完全に同じAPIを提供します。

### エンドポイント一覧

| メソッド | パス | 説明 |
|---------|------|------|
| POST | `/api/todos` | Todo作成 |
| GET | `/api/todos` | 一覧取得 |
| GET | `/api/todos/{id}` | 単体取得 |
| PUT | `/api/todos/{id}` | 全更新 |
| PATCH | `/api/todos/{id}` | 部分更新 |
| DELETE | `/api/todos/{id}` | 削除 |

### Health & Metrics

#### Quarkus（Native / JVM共通）
- **Liveness**: `http://localhost:8081/health/live`
- **Readiness**: `http://localhost:8081/health/ready`
- **Metrics**: `http://localhost:8081/q/metrics`
- **Swagger UI**: `http://localhost:8081/swagger-ui`

#### Spring Boot
- **Liveness**: `http://localhost:8082/health/live`
- **Readiness**: `http://localhost:8082/health/ready`
- **Metrics**: `http://localhost:8082/actuator/prometheus`
- **Swagger UI**: `http://localhost:8082/swagger-ui`

### リクエスト例

```bash
# Todoを作成
curl -X POST http://localhost:8081/api/todos \
  -H "Content-Type: application/json" \
  -d '{
    "title": "サンプルTodo",
    "description": "説明文",
    "completed": false
  }'

# 一覧取得
curl http://localhost:8081/api/todos

# 検索（未完了のTodoのみ）
curl "http://localhost:8081/api/todos?completed=false"
```

## 🧪 APIテスト

ビルド後、APIが正しく動作するかテストできます。

💡 **手動でcurlコマンドを使ってテストしたい場合**: [MANUAL_TEST_GUIDE.md](MANUAL_TEST_GUIDE.md) を参照してください。

### クイックスモークテスト（推奨）

アプリを起動してから：

```bash
# Quarkusをテスト（ポート8081）
./bench/smoke_test.sh

# Spring Bootをテスト（ポート8082）
./bench/smoke_test.sh 8082
```

**実行時間**: 約2秒
**テスト内容**: Health check、CRUD基本操作、バリデーション

### 全CRUD操作の詳細テスト

```bash
# Quarkusをテスト
./bench/test_api.sh

# Spring Bootをテスト
./bench/test_api.sh 8082
```

このスクリプトは以下をテストします：
- ✅ CREATE（POST）- Todoの作成
- ✅ READ（GET）- 全取得と個別取得
- ✅ UPDATE（PUT/PATCH）- 全更新と部分更新
- ✅ DELETE - 削除と削除確認
- ✅ バリデーションテスト（不正データ）

**実行時間**: 約5秒

### 全モード自動テスト

3つのモード全てを自動的にテスト：

```bash
./bench/test_all_modes.sh
```

このスクリプトは各モードを順番に起動→テスト→停止します。

**実行時間**: 約2分
**用途**: ビルド後の自動テスト、CI/CD統合

## 🗄️ データベース

3つのモード全てで同じH2データベースを使用：

- **URL**: `jdbc:h2:file:./data/todo-db`
- **Mode**: PostgreSQL互換
- **Schema**: 起動時に自動生成

データのクリーンアップ：
```bash
rm -rf data/
```

## 🎯 各モードの使い分け

### Quarkus Native Imageを選ぶ場合

- ✅ Kubernetes/コンテナ環境
- ✅ サーバーレス（AWS Lambda等）
- ✅ マイクロサービス
- ✅ 頻繁なスケーリング
- ✅ リソース制約がある環境

### Quarkus JVMを選ぶ場合

- ✅ 開発環境
- ✅ Native Imageの制約が問題になる場合
- ✅ リフレクション多用
- ✅ 高速起動が必要だが、Nativeビルドは避けたい

### Spring Boot JVMを選ぶ場合

- ✅ 既存Springエコシステムとの統合
- ✅ Spring固有機能が必須
- ✅ チームがSpringに精通
- ✅ 大規模な既存Springアプリケーション

## 📝 詳細ドキュメント

### アプリケーションガイド

- **[quarkus-todo/README.md](quarkus-todo/README.md)** - Quarkusアプリケーション詳細ガイド⭐
- **[spring-todo/README.md](spring-todo/README.md)** - Spring Bootアプリケーション詳細ガイド⭐

### ユーザーガイド

- **[MANUAL_TEST_GUIDE.md](MANUAL_TEST_GUIDE.md)** - 手動APIテストガイド（curlコマンド、Swagger UI使い方）⭐
- **[bench/TEST_README.md](bench/TEST_README.md)** - 自動テストスクリプトの使い方
- **[demo_exe.md](demo_exe.md)** - 詳細な実行ガイド、期待値、トラブルシューティング

### スクリプト解説（開発者向け）

**メインスクリプト**:
- **[guides/build_all.md](guides/build_all.md)** - `build_all.sh` スクリプトの詳細解説
- **[guides/test_all_modes.md](guides/test_all_modes.md)** - `test_all_modes.sh` スクリプトの詳細解説
- **[guides/run_benchmark.md](guides/run_benchmark.md)** - `run_benchmark.sh` スクリプトの詳細解説

**テストスクリプト**:
- **[guides/smoke_test.md](guides/smoke_test.md)** - `smoke_test.sh` スクリプトの詳細解説（基本CRUD）
- **[guides/test_api.md](guides/test_api.md)** - `test_api.sh` スクリプトの詳細解説（包括的テスト）

**依存関係**:
- **[guides/script_dependencies.md](guides/script_dependencies.md)** - スクリプト間の依存関係マップ

### 設計ドキュメント

- **[sample_app_design.md](sample_app_design.md)** - 元の設計ドキュメント

## 🔍 トラブルシューティング

### Native Imageビルドが失敗

```bash
# Dockerを確認
docker --version

# Dockerがない場合はGraalVMをインストール
# macOS
brew install --cask graalvm-jdk
```

### ポートが既に使用されている

```bash
# ポート確認
lsof -i :8081
lsof -i :8082

# プロセスを停止
kill <PID>
```

### ベンチマークがタイムアウト

```bash
# ログを確認
tail -f logs/quarkus-native.log
tail -f logs/quarkus.log
tail -f logs/spring.log
```

## 📚 参考情報

### 公式ドキュメント

- [Quarkus](https://quarkus.io/)
- [GraalVM Native Image](https://www.graalvm.org/latest/reference-manual/native-image/)
- [Spring Boot](https://spring.io/projects/spring-boot)

### ベンチマーク手法

本デモの計測方法：
- **起動時間**: `/health/ready`が200を返すまでの時間
- **メモリ**: `ps`コマンドでRSS（常駐メモリ）を1秒ごとに60秒計測
- **CPU**: `ps`コマンドで%CPUを1秒ごとに60秒計測

全て同一JVMオプションで実行：
```bash
-Xms128m -Xmx512m -Dfile.encoding=UTF-8
```
※ Native Imageはネイティブ実行のためJVMオプション不要

## 🎓 まとめ

このデモで分かること：

1. **Quarkus Nativeの圧倒的優位性**
   - 起動時間: Spring Bootの約40-70倍高速
   - メモリ: Spring Bootの約15-20%

2. **Quarkus JVMも優秀**
   - 起動時間: Spring Bootの約10-14倍高速
   - メモリ: Spring Bootの約70%

3. **用途に応じた選択が重要**
   - クラウドネイティブ → Quarkus Native
   - 開発・互換性重視 → Quarkus JVM or Spring Boot

## 📞 サポート

問題が発生した場合は、[demo_exe.md](demo_exe.md) のトラブルシューティングセクションを参照してください。

---

**プロジェクトバージョン**: 2.0 (3-Way Comparison)
**最終更新**: 2026-02-22

# run_benchmark.sh スクリプト解説

## 概要

`run_benchmark.sh` は、Quarkus Native、Quarkus JVM、Spring Boot JVMの3種類のアプリケーションの性能を自動的に計測するベンチマークスクリプトです。

**計測項目**:
- **起動時間**: アプリがReady状態になるまでの時間
- **メモリ使用量**: 60秒間の平均RSS（常駐メモリサイズ）
- **CPU使用率**: 60秒間の平均CPU使用率

## 実行方法

```bash
./bench/run_benchmark.sh
```

**実行時間**: 約4-5分（3モード × 約90秒）

## スクリプトの全体構造

```
1. ビルド成果物の事前確認
2. ログ/結果ディレクトリの作成
3. 既存プロセスのクリーンアップ
4. 各モードのベンチマーク（順番に実行）:
   a. Quarkus Native
      - データベースクリーンアップ
      - 起動
      - Ready待機（起動時間計測）
      - 60秒間のアイドル計測（メモリ・CPU）
      - 停止
   b. Quarkus JVM（同様）
   c. Spring Boot JVM（同様）
5. サマリー表示
```

---

## 詳細解説

### 1. 初期設定とパス解決（1-11行目）

```bash
#!/bin/bash
set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(dirname "$SCRIPT_DIR")"
```

**`${BASH_SOURCE[0]}`とは？**
- 現在実行中のスクリプトのパス
- `$0` よりも確実（sourceで実行された場合も正しく動作）

**パス構造**:
```
ROOT_DIR=/Users/kamori/vscode/customer/subaru
SCRIPT_DIR=/Users/kamori/vscode/customer/subaru/bench
```

---

### 2. ビルド成果物の事前確認（13-39行目）

```bash
echo "Checking build artifacts..."
QUARKUS_NATIVE="$ROOT_DIR/quarkus-todo/target/quarkus-todo-1.0.0-SNAPSHOT-runner"
QUARKUS_JVM="$ROOT_DIR/quarkus-todo/target/quarkus-app/quarkus-run.jar"
SPRING_JVM="$ROOT_DIR/spring-todo/target/spring-todo-0.0.1-SNAPSHOT.jar"

HAS_NATIVE=false
HAS_QUARKUS_JVM=false
HAS_SPRING_JVM=false

[ -f "$QUARKUS_NATIVE" ] && HAS_NATIVE=true
[ -f "$QUARKUS_JVM" ] && HAS_QUARKUS_JVM=true
[ -f "$SPRING_JVM" ] && HAS_SPRING_JVM=true
```

**存在確認の表示**:
```bash
echo "  Quarkus Native: $([ "$HAS_NATIVE" = true ] && echo "✅ Found" || echo "❌ Not found")"
```

**三項演算子風の構文**:
- `条件 && 真の場合 || 偽の場合`
- Bashには真の三項演算子がないため、この構文を使用

**必須チェック**:
```bash
if [ "$HAS_QUARKUS_JVM" = false ] || [ "$HAS_SPRING_JVM" = false ]; then
    echo "Error: Missing required build artifacts."
    echo ""
    echo "Please run the build script first:"
    echo "  ./build_all.sh"
    echo ""
    exit 1
fi
```

**重要なポイント**:
- Quarkus JVMとSpring JVMは**必須**
- Quarkus Nativeは**オプション**（なければスキップ）
- 最低でも2-Way比較（Quarkus JVM vs Spring JVM）は実行可能

---

### 3. ベンチマーク内容の表示（41-50行目）

```bash
echo "This benchmark will measure:"
if [ "$HAS_NATIVE" = true ]; then
    echo "  1. Quarkus Native Image ⚡"
    echo "  2. Quarkus JVM"
    echo "  3. Spring Boot JVM"
else
    echo "  1. Quarkus JVM (Native skipped)"
    echo "  2. Spring Boot JVM"
fi
```

**ユーザーへの明確な情報提供**:
- どのモードが計測されるか事前に表示
- Nativeがスキップされる場合も明示

---

### 4. ディレクトリ作成（52-54行目）

```bash
mkdir -p "$ROOT_DIR/logs"
mkdir -p "$ROOT_DIR/results"
```

**`mkdir -p`の意味**:
- `-p`: 親ディレクトリも含めて作成
- 既に存在する場合はエラーにならない

**ディレクトリの用途**:
- `logs/`: アプリケーションの起動ログ
- `results/`: ベンチマーク結果のCSVファイル

---

### 5. クリーンアップ関数（56-69行目）

```bash
cleanup_processes() {
    for pidfile in quarkus-native.pid quarkus.pid spring.pid; do
        if [ -f "$SCRIPT_DIR/$pidfile" ]; then
            PID=$(cat "$SCRIPT_DIR/$pidfile")
            if ps -p $PID > /dev/null 2>&1; then
                echo "Stopping existing process (PID: $PID)..."
                kill $PID
                sleep 2
            fi
            rm "$SCRIPT_DIR/$pidfile"
        fi
    done
}

cleanup_processes
```

**動作**:
1. 3つのPIDファイル（`quarkus-native.pid`, `quarkus.pid`, `spring.pid`）をループ
2. PIDファイルが存在するかチェック
3. 存在すればPIDを読み込み
4. そのプロセスが実行中かチェック（`ps -p $PID`）
5. 実行中なら終了（`kill $PID`）
6. 2秒待機
7. PIDファイルを削除

**なぜ必要？**
- 前回のベンチマークが異常終了してプロセスが残っている場合の対策
- ポート競合を防ぐ

**`ps -p $PID`の説明**:
- `-p`: プロセスIDを指定
- 指定したPIDのプロセスが存在するかチェック
- 存在すれば終了コード0、存在しなければ非0

---

### 6. Nativeバイナリの詳細チェック（73-99行目）

```bash
NATIVE_BINARY="$ROOT_DIR/quarkus-todo/target/quarkus-todo-1.0.0-SNAPSHOT-runner"
SKIP_NATIVE=false

if [ ! -f "$NATIVE_BINARY" ]; then
    echo "Warning: Quarkus Native binary not found."
    echo "Skipping Quarkus Native benchmark."
    echo "To build native image for macOS, run: ./build_native_macos.sh"
    echo ""
    SKIP_NATIVE=true
else
    # バイナリの実行可能性をチェック
    BINARY_TYPE=$(file "$NATIVE_BINARY" | grep -o "Mach-O\|ELF")

    if [ "$BINARY_TYPE" = "ELF" ]; then
        echo "Warning: Native binary is a Linux executable (ELF)."
        echo "This was built with Docker and cannot run on macOS."
        echo "Skipping Quarkus Native benchmark."
        echo ""
        echo "To build for macOS:"
        echo "  ./build_native_macos.sh"
        echo ""
        echo "Or continue with 2-way benchmark (Quarkus JVM vs Spring JVM)"
        echo ""
        SKIP_NATIVE=true
    fi
fi
```

**2段階のチェック**:

#### チェック1: ファイルの存在
```bash
if [ ! -f "$NATIVE_BINARY" ]; then
```
- バイナリファイルが存在しない場合はスキップ

#### チェック2: バイナリの種類
```bash
BINARY_TYPE=$(file "$NATIVE_BINARY" | grep -o "Mach-O\|ELF")
```

**`file`コマンドとは？**
- ファイルの種類を判定するコマンド
- バイナリファイルの場合、実行形式の種類も表示

**出力例**:
```bash
# macOSバイナリ
$ file quarkus-todo-1.0.0-SNAPSHOT-runner
quarkus-todo-1.0.0-SNAPSHOT-runner: Mach-O 64-bit executable arm64

# Linuxバイナリ
$ file quarkus-todo-1.0.0-SNAPSHOT-runner
quarkus-todo-1.0.0-SNAPSHOT-runner: ELF 64-bit LSB executable, x86-64
```

**`grep -o "Mach-O\|ELF"`の説明**:
- `-o`: マッチした部分だけを出力
- `"Mach-O\|ELF"`: Mach-OまたはELFにマッチ

**なぜこのチェックが必要？**
- Dockerでビルドした場合、LinuxのELFバイナリが生成される
- macOS上ではELFバイナリは実行できない
- 実行を試みると "cannot execute binary file" エラー

---

### 7. Quarkus Nativeのベンチマーク（101-137行目）

```bash
if [ "$SKIP_NATIVE" = false ]; then
    echo ""
    echo "========================================="
    echo "  1/3: Testing Quarkus Native Image"
    echo "========================================="
    echo ""

    # データディレクトリをクリーンアップ
    echo "Cleaning up data directory..."
    rm -rf "$ROOT_DIR/data"

    # Quarkus Nativeを起動
    bash "$SCRIPT_DIR/run_quarkus_native.sh"
    sleep 2

    # Ready待機
    bash "$SCRIPT_DIR/wait_ready.sh" "http://localhost:8081/health/ready"

    # アイドル計測
    QUARKUS_NATIVE_PID=$(cat "$SCRIPT_DIR/quarkus-native.pid")
    echo "Measuring idle metrics for 60 seconds..."
    bash "$SCRIPT_DIR/measure_idle.sh" "$QUARKUS_NATIVE_PID" 60 "$ROOT_DIR/results/quarkus-native_idle.csv"

    # 停止
    echo "Stopping Quarkus Native..."
    kill $QUARKUS_NATIVE_PID
    sleep 3
fi
```

**ベンチマークの流れ**:

#### ステップ1: データクリーンアップ
```bash
echo "Cleaning up data directory..."
rm -rf "$ROOT_DIR/data"
```

**なぜ必要？**
- 各ベンチマークで新規のデータベースを使用
- 公平な比較のため（データベースファイルのサイズの影響を排除）

#### ステップ2: アプリ起動
```bash
bash "$SCRIPT_DIR/run_quarkus_native.sh"
sleep 2
```

**`run_quarkus_native.sh`の役割**:
- Nativeバイナリをバックグラウンドで起動
- PIDを `quarkus-native.pid` に保存
- ログを `logs/quarkus-native.log` に出力

#### ステップ3: Ready待機
```bash
bash "$SCRIPT_DIR/wait_ready.sh" "http://localhost:8081/health/ready"
```

**`wait_ready.sh`の役割**:
- ヘルスチェックエンドポイントを定期的にチェック
- Ready状態になるまでの時間を計測
- **起動時間**として記録

**内部動作（推測）**:
```bash
# wait_ready.shの擬似コード
start_time=$(date +%s%3N)  # ミリ秒単位のタイムスタンプ

while true; do
    if curl -s -f "$1" > /dev/null 2>&1; then
        end_time=$(date +%s%3N)
        startup_time=$((end_time - start_time))
        echo "Startup time: ${startup_time}ms"
        break
    fi
    sleep 0.1
done
```

#### ステップ4: アイドル計測
```bash
QUARKUS_NATIVE_PID=$(cat "$SCRIPT_DIR/quarkus-native.pid")
echo "Measuring idle metrics for 60 seconds..."
bash "$SCRIPT_DIR/measure_idle.sh" "$QUARKUS_NATIVE_PID" 60 "$ROOT_DIR/results/quarkus-native_idle.csv"
```

**`measure_idle.sh`の役割**:
- 指定されたPIDのプロセスを60秒間監視
- 1秒ごとにメモリ（RSS）とCPU使用率を取得
- CSVファイルに保存

**パラメータ**:
1. `$QUARKUS_NATIVE_PID`: 監視対象のプロセスID
2. `60`: 計測時間（秒）
3. `$ROOT_DIR/results/quarkus-native_idle.csv`: 出力先CSVファイル

**measure_idle.shの内部動作（推測）**:
```bash
# 擬似コード
pid=$1
duration=$2
output=$3

echo "timestamp,rss_kb,cpu_percent" > "$output"

for i in $(seq 1 $duration); do
    # psコマンドでメモリとCPUを取得
    stats=$(ps -p $pid -o rss=,pcpu=)
    rss=$(echo $stats | awk '{print $1}')
    cpu=$(echo $stats | awk '{print $2}')

    timestamp=$(date +%s)
    echo "$timestamp,$rss,$cpu" >> "$output"

    sleep 1
done
```

**CSVファイルの例**:
```csv
timestamp,rss_kb,cpu_percent
1709017200,68432,0.0
1709017201,68456,0.1
1709017202,68440,0.0
...
```

#### ステップ5: 停止
```bash
echo "Stopping Quarkus Native..."
kill $QUARKUS_NATIVE_PID
sleep 3
```

**`sleep 3`の理由**:
- プロセスが完全に終了するまで待機
- ポートが完全に解放されることを保証
- 次のベンチマーク前に余裕を持たせる

---

### 8. Quarkus JVMのベンチマーク（139-167行目）

```bash
echo ""
echo "========================================="
echo "  2/3: Testing Quarkus JVM"
echo "========================================="
echo ""

# データディレクトリをクリーンアップ
echo "Cleaning up data directory..."
rm -rf "$ROOT_DIR/data"

# Quarkus JVMを起動
bash "$SCRIPT_DIR/run_quarkus.sh"
sleep 2

# Ready待機
bash "$SCRIPT_DIR/wait_ready.sh" "http://localhost:8081/health/ready"

# アイドル計測
QUARKUS_PID=$(cat "$SCRIPT_DIR/quarkus.pid")
echo "Measuring idle metrics for 60 seconds..."
bash "$SCRIPT_DIR/measure_idle.sh" "$QUARKUS_PID" 60 "$ROOT_DIR/results/quarkus_idle.csv"

# 停止
echo "Stopping Quarkus JVM..."
kill $QUARKUS_PID
sleep 3
```

**Quarkus Nativeとの違い**:
- 起動スクリプトが `run_quarkus.sh`（JVMモード）
- PIDファイルが `quarkus.pid`
- 結果ファイルが `quarkus_idle.csv`
- それ以外の流れは同じ

---

### 9. Spring Boot JVMのベンチマーク（169-197行目）

```bash
echo ""
echo "========================================="
echo "  3/3: Testing Spring Boot JVM"
echo "========================================="
echo ""

# データディレクトリをクリーンアップ
echo "Cleaning up data directory..."
rm -rf "$ROOT_DIR/data"

# Spring Bootを起動
bash "$SCRIPT_DIR/run_spring.sh"
sleep 2

# Ready待機
bash "$SCRIPT_DIR/wait_ready.sh" "http://localhost:8082/health/ready"

# アイドル計測
SPRING_PID=$(cat "$SCRIPT_DIR/spring.pid")
echo "Measuring idle metrics for 60 seconds..."
bash "$SCRIPT_DIR/measure_idle.sh" "$SPRING_PID" 60 "$ROOT_DIR/results/spring_idle.csv"

# 停止
echo "Stopping Spring Boot JVM..."
kill $SPRING_PID
sleep 3
```

**Quarkus JVMとの違い**:
- 起動スクリプトが `run_spring.sh`
- ヘルスチェックのポートが **8082**
- PIDファイルが `spring.pid`
- 結果ファイルが `spring_idle.csv`

---

### 10. サマリー表示（199-207行目）

```bash
echo ""
echo "========================================="
echo "  Benchmark Complete"
echo "========================================="
echo ""

# サマリー表示
bash "$SCRIPT_DIR/summary.sh"
```

**`summary.sh`の役割**:
- 各CSVファイルを読み込み
- 平均値を計算
- 3つのモードを比較したサマリーを表示

**サマリーの内容**:
- 起動時間の比較
- メモリ使用量の比較（平均RSS）
- CPU使用率の比較（平均%CPU）
- 倍率の計算（NativeをベースラインとしてJVMモードが何倍か）
- メモリ削減率の計算

---

## 計測される指標の詳細

### 1. 起動時間（Startup Time）

**定義**: アプリが `/health/ready` に応答するまでの時間

**計測方法**:
```bash
# wait_ready.shが内部で計測
start=$(date +%s%3N)  # ミリ秒
# ... ヘルスチェックループ ...
end=$(date +%s%3N)
startup_time=$((end - start))  # ms単位
```

**典型的な値**:
- Quarkus Native: 1～20ms
- Quarkus JVM: 50～200ms
- Spring Boot JVM: 500～1500ms

**何を意味するか？**
- コンテナのスケーリング速度
- サーバーレス関数のコールドスタート時間
- 開発時の再起動の快適さ

### 2. メモリ使用量（Memory Usage）

**定義**: RSS（Resident Set Size）の60秒間の平均値

**計測方法**:
```bash
# psコマンドでRSSを取得
ps -p $PID -o rss=
# RSS: 実際に物理メモリに常駐しているメモリ量（KB単位）
```

**RSSとは？**
- 仮想メモリではなく、実際に使用している物理メモリ
- プロセスが占有している実メモリの量
- Kubernetesのメモリlimitで制限されるのはこの値

**典型的な値**:
- Quarkus Native: 50～70 MB
- Quarkus JVM: 200～300 MB
- Spring Boot JVM: 300～450 MB

**何を意味するか？**
- クラウド環境のコスト（メモリ課金）
- コンテナ密度（1ノードに何ポッド配置できるか）
- 最小メモリ要件

### 3. CPU使用率（CPU Usage）

**定義**: %CPUの60秒間の平均値

**計測方法**:
```bash
# psコマンドで%CPUを取得
ps -p $PID -o pcpu=
# %CPU: CPUコアの使用率（100% = 1コア分）
```

**典型的な値（アイドル状態）**:
- Quarkus Native: 0.0～0.2%
- Quarkus JVM: 0.5～2.0%
- Spring Boot JVM: 0.5～2.0%

**なぜJVMの方がCPU使用率が高い？**
- JIT（Just-In-Time）コンパイラが実行中にコードを最適化
- ガベージコレクション（GC）のバックグラウンド処理
- リフレクションやプロキシの処理

**Nativeが低い理由**:
- AOT（Ahead-Of-Time）コンパイル済み（JITなし）
- 最小限のGC（メモリ使用量が少ないため）
- リフレクションやプロキシを事前処理済み

---

## 実行時の出力例

```
=========================================
  Quarkus vs Spring Boot Benchmark
  (3-Way Comparison)
=========================================

Checking build artifacts...
  Quarkus Native: ✅ Found
  Quarkus JVM:    ✅ Found
  Spring JVM:     ✅ Found

This benchmark will measure:
  1. Quarkus Native Image ⚡
  2. Quarkus JVM
  3. Spring Boot JVM

=========================================
  1/3: Testing Quarkus Native Image
=========================================

Cleaning up data directory...
Starting Quarkus Native...
Waiting for server to be ready...
Server is ready! (Startup time: 15ms)
Measuring idle metrics for 60 seconds...
Progress: [===================>  ] 95%
Stopping Quarkus Native...

=========================================
  2/3: Testing Quarkus JVM
=========================================

Cleaning up data directory...
Starting Quarkus JVM...
Waiting for server to be ready...
Server is ready! (Startup time: 51ms)
Measuring idle metrics for 60 seconds...
Progress: [===================>  ] 95%
Stopping Quarkus JVM...

=========================================
  3/3: Testing Spring Boot JVM
=========================================

Cleaning up data directory...
Starting Spring Boot...
Waiting for server to be ready...
Server is ready! (Startup time: 712ms)
Measuring idle metrics for 60 seconds...
Progress: [===================>  ] 95%
Stopping Spring Boot JVM...

=========================================
  Benchmark Complete
=========================================

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
  Quarkus JVM:    51ms (3.4x slower than Native)
  Spring JVM:     712ms (47.5x slower than Native)

Memory Savings:
  Native saves 78.6% vs Quarkus JVM
  Native saves 84.8% vs Spring JVM
=========================================
```

---

## よくある問題と解決方法

### 問題1: ベンチマークが途中で止まる

**症状**:
```
Starting Quarkus JVM...
Waiting for server to be ready...
（ここで止まる）
```

**原因**: アプリが起動に失敗している

**確認方法**:
```bash
# ログを確認
tail -f logs/quarkus.log
```

**よくある原因**:
1. **ポートが既に使用中**
   ```bash
   lsof -i :8081
   lsof -i :8082
   kill <PID>
   ```

2. **データベースファイルが壊れている**
   ```bash
   rm -rf data/
   ./bench/run_benchmark.sh
   ```

### 問題2: "Missing required build artifacts"

**症状**:
```
Error: Missing required build artifacts.
Please run the build script first:
  ./build_all.sh
```

**解決方法**:
```bash
./build_all.sh
./bench/run_benchmark.sh
```

### 問題3: Native binaryがスキップされる

**症状**:
```
Warning: Native binary is a Linux executable (ELF).
This was built with Docker and cannot run on macOS.
Skipping Quarkus Native benchmark.
```

**解決方法**:
```bash
# macOS用にローカルビルド
./build_native_direct.sh

# 再度ベンチマーク
./bench/run_benchmark.sh
```

### 問題4: メモリ計測値が異常

**症状**: メモリ使用量が10MB未満や1GB以上など、明らかにおかしい値

**原因**: プロセスIDが間違っている、またはプロセスが終了している

**確認方法**:
```bash
# PIDファイルの確認
cat bench/quarkus.pid
cat bench/spring.pid

# プロセスが実行中か確認
ps -p <PID>
```

---

## 生成されるファイル

### ログファイル（logs/）

```
logs/
├── quarkus-native.log    # Quarkus Native起動ログ
├── quarkus.log           # Quarkus JVM起動ログ
└── spring.log            # Spring Boot起動ログ
```

**内容**: アプリケーションの標準出力とエラー出力

### 結果ファイル（results/）

```
results/
├── quarkus-native_idle.csv  # Native計測データ
├── quarkus_idle.csv         # Quarkus JVM計測データ
└── spring_idle.csv          # Spring Boot計測データ
```

**CSV形式**:
```csv
timestamp,rss_kb,cpu_percent
1709017200,68432,0.0
1709017201,68456,0.1
...
```

### PIDファイル（bench/）

```
bench/
├── quarkus-native.pid   # Nativeプロセスのpid
├── quarkus.pid          # Quarkus JVMプロセスのPID
└── spring.pid           # Spring BootプロセスのPID
```

**内容**: プロセスIDの数値のみ（例: `12345`）

---

## スクリプトの工夫点まとめ

1. **柔軟性**
   - Nativeがなくても2-Wayベンチマーク可能
   - バイナリの種類をチェック（ELF vs Mach-O）

2. **公平性**
   - 各ベンチマーク前にデータベースをクリーンアップ
   - 同じ条件で計測（60秒間のアイドル状態）

3. **堅牢性**
   - 既存プロセスの自動クリーンアップ
   - PIDファイルによる確実なプロセス管理
   - エラー時の自動終了（`set -e`）

4. **可視性**
   - 進捗状況の明確な表示
   - ログファイルの保存
   - 最後にサマリーを自動表示

5. **再現性**
   - CSVファイルで生データを保存
   - 後からサマリーを再表示可能（`./bench/summary.sh`）

---

## 使用例

### 基本的な使い方

```bash
# ビルド
./build_all.sh

# ベンチマーク実行
./bench/run_benchmark.sh

# 結果を再表示
./bench/summary.sh
```

### 結果の分析

```bash
# CSVファイルを確認
cat results/quarkus-native_idle.csv
cat results/quarkus_idle.csv
cat results/spring_idle.csv

# Excelやスプレッドシートで開いてグラフ化も可能
open results/quarkus-native_idle.csv
```

### ログの確認

```bash
# 各アプリの起動ログを確認
less logs/quarkus-native.log
less logs/quarkus.log
less logs/spring.log

# エラーメッセージを検索
grep -i error logs/*.log
```

---

## まとめ

`run_benchmark.sh` は、以下を実現する包括的なベンチマークツールです：

✅ **自動化**（起動→計測→停止を全自動）
✅ **公平な比較**（データベースクリーンアップ、同一条件）
✅ **詳細な計測**（起動時間、メモリ、CPU）
✅ **柔軟な実行**（Nativeなしでも2-Way比較可能）
✅ **データ保存**（CSV形式で後から分析可能）
✅ **明確な結果**（サマリー自動表示）

このスクリプトにより、Quarkus Native ImageとJVMモードの性能差を客観的に計測できます。

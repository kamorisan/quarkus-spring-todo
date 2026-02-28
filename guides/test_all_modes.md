# test_all_modes.sh スクリプト解説

## 概要

`test_all_modes.sh` は、3つのモード（Quarkus Native、Quarkus JVM、Spring Boot JVM）を自動的に起動→テスト→停止するスクリプトです。

**特徴**: ユーザーが手動でアプリを起動する必要なく、全モードのAPIテストを自動実行します。

## 実行方法

```bash
./bench/test_all_modes.sh
```

**実行時間**: 約2分

## スクリプトの全体構造

```
1. ビルド成果物の確認
2. 各モードごとに順番に実行:
   a. Quarkus Native
      - 起動
      - 準備完了待機
      - スモークテスト実行
      - 停止
   b. Quarkus JVM（同様）
   c. Spring Boot JVM（同様）
3. 全体結果の表示
```

---

## 詳細解説

### 1. 初期設定とパス解決（1-6行目）

```bash
#!/bin/bash
set -e

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
```

**`set -e`の意味**:
- エラーが発生したら即座にスクリプトを終了
- テストが失敗したら後続のテストを実行しない

**パス解決のトリック**:
```bash
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
# スクリプトが配置されているディレクトリの絶対パスを取得
# 例: /Users/kamori/vscode/customer/subaru/bench

PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
# プロジェクトルートの絶対パスを取得
# 例: /Users/kamori/vscode/customer/subaru
```

**なぜ絶対パスが必要？**
- スクリプトがどこから実行されても正しく動作するため
- 相対パスだと、カレントディレクトリに依存してしまう

---

### 2. ビルド成果物の確認（13-29行目）

```bash
QUARKUS_NATIVE="$PROJECT_ROOT/quarkus-todo/target/quarkus-todo-1.0.0-SNAPSHOT-runner"
QUARKUS_JVM="$PROJECT_ROOT/quarkus-todo/target/quarkus-app/quarkus-run.jar"
SPRING_JVM="$PROJECT_ROOT/spring-todo/target/spring-todo-0.0.1-SNAPSHOT.jar"

HAS_NATIVE=false
HAS_QUARKUS_JVM=false
HAS_SPRING_JVM=false

[ -f "$QUARKUS_NATIVE" ] && HAS_NATIVE=true
[ -f "$QUARKUS_JVM" ] && HAS_QUARKUS_JVM=true
[ -f "$SPRING_JVM" ] && HAS_SPRING_JVM=true
```

**Bash短縮構文の説明**:
```bash
[ -f "$QUARKUS_NATIVE" ] && HAS_NATIVE=true
```

これは以下と同じ意味：
```bash
if [ -f "$QUARKUS_NATIVE" ]; then
    HAS_NATIVE=true
fi
```

**動作**:
- 各ファイルの存在を確認
- 存在すれば対応するフラグを `true` に設定

```bash
echo "Available modes:"
echo "  Quarkus Native: $($HAS_NATIVE && echo "✓" || echo "✗")"
echo "  Quarkus JVM:    $($HAS_QUARKUS_JVM && echo "✓" || echo "✗")"
echo "  Spring JVM:     $($HAS_SPRING_JVM && echo "✓" || echo "✗")"
```

**出力例**:
```
Available modes:
  Quarkus Native: ✓
  Quarkus JVM:    ✓
  Spring JVM:     ✓
```

**エラーチェック**:
```bash
if ! $HAS_NATIVE && ! $HAS_QUARKUS_JVM && ! $HAS_SPRING_JVM; then
    echo "Error: No build artifacts found"
    echo "Run ./build_all.sh first"
    exit 1
fi
```

- 全てのビルド成果物がない場合はエラー終了
- 少なくとも1つあればテストを継続

---

### 3. ヘルパー関数: wait_for_server（31-45行目）

```bash
wait_for_server() {
    local port=$1
    local max_wait=30
    local count=0

    while [ $count -lt $max_wait ]; do
        if curl -s -f "http://localhost:$port/q/health/ready" > /dev/null 2>&1 || \
           curl -s -f "http://localhost:$port/actuator/health" > /dev/null 2>&1; then
            return 0
        fi
        sleep 1
        count=$((count + 1))
    done
    return 1
}
```

**役割**: サーバーが起動して準備完了になるまで待機

**パラメータ**:
- `$1`: ポート番号（8081 or 8082）

**動作フロー**:
1. 最大30秒間ループ
2. 1秒ごとにヘルスチェックを試行
3. Quarkusの `/q/health/ready` または Spring Bootの `/actuator/health` をチェック
4. 成功したら `return 0`（正常終了）
5. 30秒経過しても準備完了にならなければ `return 1`（失敗）

**curlオプションの説明**:
- `-s`: サイレントモード（進捗表示なし）
- `-f`: HTTPエラーがあれば失敗（404、500など）
- `> /dev/null 2>&1`: 標準出力と標準エラー出力を破棄

**なぜ2つのエンドポイントをチェック？**
- Quarkus: `/q/health/ready`
- Spring Boot: `/actuator/health`
- どちらか一方が成功すればOK（フレームワークに依存しない）

---

### 4. Quarkus Nativeのテスト（47-80行目）

```bash
if $HAS_NATIVE; then
    echo "========================================="
    echo "  Testing Quarkus Native"
    echo "========================================="
    echo ""

    echo "Starting Quarkus Native..."
    "$QUARKUS_NATIVE" > /tmp/quarkus-native-test.log 2>&1 &
    NATIVE_PID=$!

    if wait_for_server 8081; then
        echo "Running tests..."
        "$SCRIPT_DIR/smoke_test.sh" 8081
        echo ""
    else
        echo "Failed to start Quarkus Native"
        kill $NATIVE_PID 2>/dev/null || true
        exit 1
    fi

    echo "Stopping Quarkus Native..."
    kill $NATIVE_PID 2>/dev/null || true
    wait $NATIVE_PID 2>/dev/null || true
    sleep 2
    echo ""
fi
```

**ステップバイステップ解説**:

#### ステップ1: 起動

```bash
"$QUARKUS_NATIVE" > /tmp/quarkus-native-test.log 2>&1 &
NATIVE_PID=$!
```

**解説**:
- `"$QUARKUS_NATIVE"`: Nativeバイナリを実行
- `> /tmp/quarkus-native-test.log`: 標準出力をログファイルにリダイレクト
- `2>&1`: 標準エラー出力も同じログファイルに
- `&`: バックグラウンドで実行
- `$!`: 直前のバックグラウンドプロセスのPIDを取得

**結果**:
- アプリがバックグラウンドで起動
- ログは `/tmp/quarkus-native-test.log` に保存
- `NATIVE_PID` にプロセスIDが格納される

#### ステップ2: 準備完了待機

```bash
if wait_for_server 8081; then
```

- 上で定義した `wait_for_server` 関数を呼び出し
- ポート8081のヘルスチェックが成功するまで最大30秒待機

#### ステップ3: テスト実行

```bash
echo "Running tests..."
"$SCRIPT_DIR/smoke_test.sh" 8081
```

- `smoke_test.sh` スクリプトを実行
- 引数にポート番号（8081）を渡す
- テストが失敗すると `set -e` により自動終了

#### ステップ4: エラーハンドリング

```bash
else
    echo "Failed to start Quarkus Native"
    kill $NATIVE_PID 2>/dev/null || true
    exit 1
fi
```

- サーバーが起動しなかった場合
- プロセスをkillしてから終了
- `2>/dev/null || true`: killが失敗してもエラーにしない

#### ステップ5: 停止

```bash
echo "Stopping Quarkus Native..."
kill $NATIVE_PID 2>/dev/null || true
wait $NATIVE_PID 2>/dev/null || true
sleep 2
```

**解説**:
- `kill $NATIVE_PID`: プロセスにSIGTERMを送信
- `2>/dev/null || true`: プロセスが既に終了していてもエラーにしない
- `wait $NATIVE_PID`: プロセスが完全に終了するまで待機
- `sleep 2`: 次のテストまで2秒待機（ポートの解放を確実にするため）

---

### 5. Quarkus JVMのテスト（82-115行目）

```bash
if $HAS_QUARKUS_JVM; then
    echo "========================================="
    echo "  Testing Quarkus JVM"
    echo "========================================="
    echo ""

    echo "Starting Quarkus JVM..."
    java -Xms128m -Xmx512m -jar "$QUARKUS_JVM" > /tmp/quarkus-jvm-test.log 2>&1 &
    JVM_PID=$!

    if wait_for_server 8081; then
        echo "Running tests..."
        "$SCRIPT_DIR/smoke_test.sh" 8081
        echo ""
    else
        echo "Failed to start Quarkus JVM"
        kill $JVM_PID 2>/dev/null || true
        exit 1
    fi

    echo "Stopping Quarkus JVM..."
    kill $JVM_PID 2>/dev/null || true
    wait $JVM_PID 2>/dev/null || true
    sleep 2
    echo ""
fi
```

**Quarkus Nativeとの違い**:
- 起動コマンドが `java -jar` を使用
- JVMオプション `-Xms128m -Xmx512m` を指定
  - `-Xms128m`: 初期ヒープサイズ128MB
  - `-Xmx512m`: 最大ヒープサイズ512MB
- それ以外の流れは同じ

---

### 6. Spring Boot JVMのテスト（117-150行目）

```bash
if $HAS_SPRING_JVM; then
    echo "========================================="
    echo "  Testing Spring Boot JVM"
    echo "========================================="
    echo ""

    echo "Starting Spring Boot..."
    java -Xms128m -Xmx512m -jar "$SPRING_JVM" > /tmp/spring-jvm-test.log 2>&1 &
    SPRING_PID=$!

    if wait_for_server 8082; then
        echo "Running tests..."
        "$SCRIPT_DIR/smoke_test.sh" 8082
        echo ""
    else
        echo "Failed to start Spring Boot"
        kill $SPRING_PID 2>/dev/null || true
        exit 1
    fi

    echo "Stopping Spring Boot..."
    kill $SPRING_PID 2>/dev/null || true
    wait $SPRING_PID 2>/dev/null || true
    sleep 2
    echo ""
fi
```

**Quarkus JVMとの違い**:
- ポート番号が **8082**（Spring Bootのデフォルト設定）
- それ以外は同じ

---

### 7. 完了メッセージ（152-158行目）

```bash
echo "========================================="
echo "  All Tests Complete!"
echo "========================================="
echo ""
echo "All modes passed smoke tests ✓"
echo ""
```

- 全てのテストが成功した場合のみここに到達
- `set -e` によりエラーがあれば途中で終了しているため

---

## 実行フロー全体図

```
スタート
  ↓
ビルド成果物の確認
  ↓
[Quarkus Native がある？]
  ├─ Yes → Quarkus Native起動
  │          ↓
  │        準備完了待機（最大30秒）
  │          ↓
  │        スモークテスト実行
  │          ↓
  │        停止（2秒待機）
  │
  └─ No → スキップ
  ↓
[Quarkus JVM がある？]
  ├─ Yes → Quarkus JVM起動
  │          ↓
  │        準備完了待機（最大30秒）
  │          ↓
  │        スモークテスト実行
  │          ↓
  │        停止（2秒待機）
  │
  └─ No → スキップ
  ↓
[Spring JVM がある？]
  ├─ Yes → Spring Boot起動
  │          ↓
  │        準備完了待機（最大30秒）
  │          ↓
  │        スモークテスト実行
  │          ↓
  │        停止（2秒待機）
  │
  └─ No → スキップ
  ↓
全テスト完了メッセージ
  ↓
終了
```

---

## 実行時の出力例

```
=========================================
  API Tests for All Modes
  (3-Way Test Runner)
=========================================

Available modes:
  Quarkus Native: ✓
  Quarkus JVM:    ✓
  Spring JVM:     ✓

=========================================
  Testing Quarkus Native
=========================================

Starting Quarkus Native...
Running tests...
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

Stopping Quarkus Native...

=========================================
  Testing Quarkus JVM
=========================================

Starting Quarkus JVM...
Running tests...
（スモークテスト結果）
Stopping Quarkus JVM...

=========================================
  Testing Spring Boot JVM
=========================================

Starting Spring Boot...
Running tests...
（スモークテスト結果）
Stopping Spring Boot...

=========================================
  All Tests Complete!
=========================================

All modes passed smoke tests ✓
```

---

## よくある問題と解決方法

### 問題1: "Failed to start Quarkus Native"

**症状**:
```
Starting Quarkus Native...
Failed to start Quarkus Native
```

**原因**: 30秒以内にアプリが起動しなかった

**確認方法**:
```bash
# ログを確認
cat /tmp/quarkus-native-test.log
```

**よくある原因**:
1. **ポートが既に使用中**
   ```bash
   lsof -i :8081
   kill <PID>
   ```

2. **バイナリが実行できない**
   ```bash
   # 実行権限の確認
   ls -l quarkus-todo/target/quarkus-todo-1.0.0-SNAPSHOT-runner

   # 実行権限の付与
   chmod +x quarkus-todo/target/quarkus-todo-1.0.0-SNAPSHOT-runner
   ```

3. **データベースファイルが壊れている**
   ```bash
   rm -rf data/
   ./bench/test_all_modes.sh
   ```

### 問題2: "No build artifacts found"

**症状**:
```
Available modes:
  Quarkus Native: ✗
  Quarkus JVM:    ✗
  Spring JVM:     ✗

Error: No build artifacts found
Run ./build_all.sh first
```

**解決方法**:
```bash
# ビルドを実行
./build_all.sh

# 再度テスト
./bench/test_all_modes.sh
```

### 問題3: テストが途中で失敗する

**症状**:
```
1. Health check... ✓
2. Create todo... ✗ (HTTP 500)
```

**原因**: API実装にバグがある

**確認方法**:
```bash
# アプリのログを確認
cat /tmp/quarkus-native-test.log
cat /tmp/quarkus-jvm-test.log
cat /tmp/spring-jvm-test.log
```

**デバッグ方法**:
```bash
# 手動でアプリを起動して詳細ログを見る
./quarkus-todo/target/quarkus-todo-1.0.0-SNAPSHOT-runner

# 別ターミナルで手動テスト
curl -v -X POST http://localhost:8081/api/todos \
  -H "Content-Type: application/json" \
  -d '{"title":"test"}'
```

### 問題4: 前のプロセスが残っている

**症状**:
```
Starting Quarkus JVM...
Failed to start Quarkus JVM
```

**原因**: 前のテストのプロセスが完全に終了していない

**解決方法**:
```bash
# 全てのJavaプロセスを確認
ps aux | grep java

# Quarkusプロセスを強制終了
pkill -f quarkus-todo

# Springプロセスを強制終了
pkill -f spring-todo

# 再度テスト
./bench/test_all_modes.sh
```

---

## スクリプトの工夫点まとめ

1. **自動化**
   - ユーザーが手動でアプリを起動する必要なし
   - 起動→テスト→停止を全自動で実行

2. **柔軟性**
   - ビルド成果物がないモードは自動的にスキップ
   - 1つでも成果物があればテスト実行可能

3. **堅牢性**
   - `wait_for_server` で確実に準備完了を待機
   - エラー時は確実にプロセスをクリーンアップ
   - `set -e` でエラーの連鎖を防止

4. **ログ保存**
   - 各モードのログを `/tmp/` に保存
   - トラブル時の調査が容易

5. **ポート管理**
   - Quarkus: 8081
   - Spring Boot: 8082
   - ポート競合を回避

---

## 使用例

### 基本的な使い方

```bash
# 1. ビルド
./build_all.sh

# 2. 全モード自動テスト
./bench/test_all_modes.sh
```

### ログ確認

```bash
# テスト実行後、ログを確認
cat /tmp/quarkus-native-test.log
cat /tmp/quarkus-jvm-test.log
cat /tmp/spring-jvm-test.log
```

### CI/CDでの利用

```bash
#!/bin/bash
set -e

# ビルド
./build_all.sh

# テスト（失敗したら自動的にexit 1）
./bench/test_all_modes.sh

# ベンチマーク
./bench/run_benchmark.sh
```

---

## まとめ

`test_all_modes.sh` は、以下を実現する便利なテストランナーです：

✅ **完全自動化**（起動→テスト→停止を自動実行）
✅ **柔軟な実行**（利用可能なモードのみテスト）
✅ **堅牢なエラーハンドリング**（プロセスクリーンアップ、タイムアウト）
✅ **デバッグ支援**（ログファイル保存）
✅ **CI/CD対応**（エラー時の自動終了）

このスクリプトにより、ビルド後の動作確認が簡単かつ確実に行えます。

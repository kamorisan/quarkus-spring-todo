# build_all.sh スクリプト解説

## 概要

`build_all.sh` は、Quarkus JVMモードとNativeモードの両方をビルドし、さらにSpring Boot JVMもビルドする統合ビルドスクリプトです。

**最大の特徴**: JVMとNativeの成果物を**両方とも保持**する賢い仕組みを実装しています。

## 実行方法

```bash
./build_all.sh
```

## スクリプトの全体構造

```
1. GraalVMの存在確認
2. Quarkus JVMモードのビルド
3. JVM成果物の一時退避
4. Quarkus Nativeモードのビルド
5. JVM成果物の復元
6. Spring Boot JVMのビルド（なければ）
7. ビルド成果物の確認と表示
```

---

## 詳細解説

### 1. 初期設定（1-22行目）

```bash
#!/bin/bash
set -e
```

**`set -e`の意味**:
- エラーが発生したら即座にスクリプトを終了
- ビルド失敗時に後続の処理を実行しないための安全機構

```bash
GRAALVM_HOME="/Library/Java/JavaVirtualMachines/graalvm-21.jdk/Contents/Home"

if [ ! -d "$GRAALVM_HOME" ]; then
    echo "Warning: GraalVM 21 not found at $GRAALVM_HOME"
    echo "Native image build will be skipped."
    BUILD_NATIVE=false
else
    BUILD_NATIVE=true
    export JAVA_HOME="$GRAALVM_HOME"
    export PATH="$GRAALVM_HOME/bin:$PATH"
fi
```

**ポイント**:
- GraalVMの存在を確認
- 存在しない場合は `BUILD_NATIVE=false` にしてNativeビルドをスキップ
- 存在する場合は環境変数を設定（`JAVA_HOME`と`PATH`）

**なぜ環境変数を設定するのか？**
- MavenがGraalVMを確実に使うため
- native-imageコマンドがPATHに含まれるようにするため

---

### 2. Quarkus JVMモードのビルド（24-42行目）

```bash
cd quarkus-todo

# JVMモードをビルド
mvn clean package -DskipTests

JVM_JAR="target/quarkus-app/quarkus-run.jar"
if [ -f "$JVM_JAR" ]; then
    echo "✅ JVM JAR created: $(du -h $JVM_JAR | cut -f1)"
else
    echo "❌ Error: JVM JAR not found"
    cd ..
    exit 1
fi
```

**重要な点**:
- `mvn clean package` で通常のJVMモードをビルド
- `-DskipTests` でテストをスキップして高速化
- ビルド成果物の存在を確認し、失敗時はエラーで終了

**成果物の場所**:
- `quarkus-todo/target/quarkus-app/quarkus-run.jar`
- `quarkus-todo/target/quarkus-app/` ディレクトリ全体（依存関係含む）

---

### 3. 核心部分: JVM成果物の一時退避（49-73行目）

これがこのスクリプトの**最重要ポイント**です。

#### 問題の背景

通常、以下の順序でビルドすると問題が発生します：

```bash
# 1. JVMモードをビルド
mvn clean package

# 2. Nativeモードをビルド
mvn clean package -Pnative  # ← "mvn clean" でJVM成果物が削除される！
```

`mvn clean` を実行すると `target/` ディレクトリが削除されるため、せっかく作ったJVM成果物が消えてしまいます。

#### 解決策: 一時退避と復元

```bash
if [ "$BUILD_NATIVE" = true ]; then
    # JVM JAR一式を一時退避
    TEMP_DIR="$(mktemp -d)"
    echo "Backing up JVM artifacts to: $TEMP_DIR"
    cp -r quarkus-todo/target/quarkus-app "$TEMP_DIR/"

    # Nativeビルド
    cd quarkus-todo

    JAVA_HOME="$GRAALVM_HOME" \
      mvn clean package -Pnative \
      -Djava.home="$GRAALVM_HOME" \
      -Dquarkus.native.java-home="$GRAALVM_HOME"

    NATIVE_BINARY="target/quarkus-todo-1.0.0-SNAPSHOT-runner"

    if [ -f "$NATIVE_BINARY" ]; then
        echo "✅ Native binary created: $(du -h $NATIVE_BINARY | cut -f1)"

        # JVM JARを復元
        echo "Restoring JVM artifacts..."
        cp -r "$TEMP_DIR/quarkus-app" target/

        # 一時ディレクトリを削除
        rm -rf "$TEMP_DIR"

        echo "✅ Both JVM and Native artifacts are ready!"
    else
        echo "❌ Error: Native binary not found"
        # JVM JARを復元
        cp -r "$TEMP_DIR/quarkus-app" target/
        rm -rf "$TEMP_DIR"
        cd ..
        exit 1
    fi

    cd ..
fi
```

**ステップバイステップ**:

1. **一時ディレクトリ作成**
   ```bash
   TEMP_DIR="$(mktemp -d)"
   # 例: /var/folders/xx/yyyy/T/tmp.XXXXXXXX
   ```

2. **JVM成果物をバックアップ**
   ```bash
   cp -r quarkus-todo/target/quarkus-app "$TEMP_DIR/"
   ```

3. **Nativeビルド実行**
   ```bash
   JAVA_HOME="$GRAALVM_HOME" \
     mvn clean package -Pnative \
     -Djava.home="$GRAALVM_HOME" \
     -Dquarkus.native.java-home="$GRAALVM_HOME"
   ```

   **環境変数を3箇所で指定する理由**:
   - `JAVA_HOME`: シェルの環境変数
   - `-Djava.home`: Maven fork プロセスが使うJava
   - `-Dquarkus.native.java-home`: Quarkus Nativeビルドが使うGraalVM

4. **Nativeバイナリの確認**
   ```bash
   if [ -f "$NATIVE_BINARY" ]; then
   ```

5. **JVM成果物を復元**
   ```bash
   cp -r "$TEMP_DIR/quarkus-app" target/
   ```

6. **一時ディレクトリを削除**
   ```bash
   rm -rf "$TEMP_DIR"
   ```

**結果**:
- `target/quarkus-app/quarkus-run.jar` （JVM用）
- `target/quarkus-todo-1.0.0-SNAPSHOT-runner` （Native用）

**両方が同時に存在！**

---

### 4. Spring Boot JVMのビルド（112-124行目）

```bash
if [ -f "spring-todo/target/spring-todo-0.0.1-SNAPSHOT.jar" ]; then
    echo "✅ Spring Boot JVM:"
    ls -lh spring-todo/target/spring-todo-0.0.1-SNAPSHOT.jar
else
    echo "⚠️  Spring Boot JAR not found. Building..."
    cd spring-todo
    mvn clean package -DskipTests
    cd ..
    if [ -f "spring-todo/target/spring-todo-0.0.1-SNAPSHOT.jar" ]; then
        echo "✅ Spring Boot JVM:"
        ls -lh spring-todo/target/spring-todo-0.0.1-SNAPSHOT.jar
    fi
fi
```

**動作**:
- Spring Boot JARが既に存在するかチェック
- 存在しない場合のみビルド（不要なビルドを避ける）
- ビルド後に再度確認

---

### 5. ビルド成果物の確認（97-124行目）

```bash
echo "Build artifacts:"
echo ""

if [ -f "quarkus-todo/target/quarkus-app/quarkus-run.jar" ]; then
    echo "✅ Quarkus JVM:"
    ls -lh quarkus-todo/target/quarkus-app/quarkus-run.jar
fi

if [ -f "quarkus-todo/target/quarkus-todo-1.0.0-SNAPSHOT-runner" ]; then
    echo "✅ Quarkus Native:"
    ls -lh quarkus-todo/target/quarkus-todo-1.0.0-SNAPSHOT-runner
    echo "   Type: $(file quarkus-todo/target/quarkus-todo-1.0.0-SNAPSHOT-runner | grep -o 'Mach-O\|ELF')"
fi
```

**ポイント**:
- 各成果物のファイルサイズを表示
- Nativeバイナリの種類を表示（Mach-O=macOS、ELF=Linux）

**出力例**:
```
Build artifacts:

✅ Quarkus JVM:
-rw-r--r--  1 user  staff   1.2M Feb 27 10:30 quarkus-todo/target/quarkus-app/quarkus-run.jar
✅ Quarkus Native:
-rwxr-xr-x  1 user  staff   120M Feb 27 10:45 quarkus-todo/target/quarkus-todo-1.0.0-SNAPSHOT-runner
   Type: Mach-O
✅ Spring Boot JVM:
-rw-r--r--  1 user  staff   35M Feb 27 10:20 spring-todo/target/spring-todo-0.0.1-SNAPSHOT.jar
```

---

### 6. 次のステップの案内（126-145行目）

```bash
if [ "$BUILD_NATIVE" = true ]; then
    echo "Run 3-way benchmark:"
    echo "  ./bench/run_benchmark.sh"
else
    echo "Run 2-way benchmark (JVM only):"
    echo "  ./bench/run_benchmark.sh"
    echo ""
    echo "To enable Native image:"
    echo "  1. Install GraalVM 21:"
    echo "     brew install --cask graalvm-jdk21"
    echo "  2. Re-run this script:"
    echo "     ./build_all.sh"
fi
```

**動作**:
- Nativeビルドが成功した場合: 3-Wayベンチマークを案内
- Nativeビルドがスキップされた場合: GraalVMのインストール方法を案内

---

## ビルド時間の目安

| モード | 時間 | CPU使用率 |
|-------|------|----------|
| Quarkus JVM | 30秒～1分 | 中 |
| Quarkus Native | 3～10分 | 高（100%に近い） |
| Spring Boot JVM | 30秒～1分 | 中 |

**合計**: 約5～15分（Nativeビルド含む）

---

## よくある問題と解決方法

### 問題1: Nativeビルドが失敗する

**エラー例**:
```
Error: Version mismatch: GraalVM 22.3.1 found, but Quarkus requires 23.1.0+
```

**解決方法**:
```bash
# GraalVM 21をインストール
brew install --cask graalvm-jdk21

# 環境変数を再設定
export JAVA_HOME=/Library/Java/JavaVirtualMachines/graalvm-21.jdk/Contents/Home
export PATH=$JAVA_HOME/bin:$PATH

# 再ビルド
./build_all.sh
```

### 問題2: JVM成果物が消えている

**症状**: `quarkus-run.jar` が見つからない

**原因**: 手動で `mvn clean` を実行した

**解決方法**:
```bash
# このスクリプトを再実行
./build_all.sh
```

このスクリプトを使えば常に両方の成果物が保持されます。

### 問題3: メモリ不足でNativeビルドが失敗

**エラー例**:
```
java.lang.OutOfMemoryError: GC overhead limit exceeded
```

**解決方法**:
```bash
# Mavenのメモリ設定を増やす
export MAVEN_OPTS="-Xmx4g"

# 再ビルド
./build_all.sh
```

---

## スクリプトの工夫点まとめ

1. **一時退避メカニズム**
   - JVMとNativeの成果物を両方保持
   - `mktemp -d` で安全な一時ディレクトリを作成
   - ビルド成功・失敗どちらでも復元を保証

2. **柔軟な動作**
   - GraalVMがない場合はJVMのみビルド
   - Spring Bootが既にビルド済みなら再ビルドしない

3. **明確なフィードバック**
   - 各ステップの進捗を表示
   - 成果物のサイズを表示
   - 次のステップを案内

4. **エラーハンドリング**
   - `set -e` で異常終了を保証
   - 各ビルドステップで成果物の存在を確認
   - 失敗時はJVM成果物を復元してから終了

---

## 使用例

### 基本的な使い方

```bash
# ビルド
./build_all.sh

# 成果物の確認
ls -lh quarkus-todo/target/quarkus-app/quarkus-run.jar
ls -lh quarkus-todo/target/quarkus-todo-1.0.0-SNAPSHOT-runner
ls -lh spring-todo/target/spring-todo-0.0.1-SNAPSHOT.jar

# ベンチマーク実行
./bench/run_benchmark.sh
```

### GraalVMなしでビルド（JVMのみ）

```bash
# GraalVMが検出されなくても実行可能
./build_all.sh

# 結果: Quarkus JVMとSpring Boot JVMのみビルド
# 2-Wayベンチマークが可能
```

---

## まとめ

`build_all.sh` は、以下を実現する賢いビルドスクリプトです：

✅ **JVMとNativeの両方を保持**（一時退避メカニズム）
✅ **環境に応じた柔軟な動作**（GraalVMの有無に対応）
✅ **明確なフィードバック**（進捗、サイズ、次のステップ）
✅ **安全性**（エラーハンドリング、成果物の確認）

このスクリプト1つで、3種類のビルド成果物を確実に作成できます。

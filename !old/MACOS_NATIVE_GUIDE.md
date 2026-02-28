# macOSでのNative Imageビルドガイド

## 🍎 macOS特有の問題

### Dockerビルドの制限

Dockerでビルドすると**Linuxバイナリ**が生成され、macOSでは実行できません。

```bash
# Dockerビルドの結果
file quarkus-todo/target/*-runner
# → ELF 64-bit LSB executable (Linux用)
# → macOSでは実行不可 ❌
```

### macOS用バイナリを作るには

**ローカルGraalVMが必須**です。

---

## ✅ macOS用Native Imageのビルド手順

### ステップ1: 現在のGraalVMバージョンを確認

```bash
java -version
```

出力例：
```
openjdk version "17.0.6" 2023-01-17
OpenJDK Runtime Environment GraalVM CE 22.3.1 (build 17.0.6+10-jvmci-22.3-b13)
```

### ステップ2: GraalVM 23.1.0 (Java 21) をインストール

#### 方法A: Homebrewでインストール（推奨）

```bash
# GraalVMをインストール
brew install --cask graalvm-jdk21

# インストール先を確認
ls /Library/Java/JavaVirtualMachines/
# graalvm-jdk-21.jdk が表示されるはず
```

#### 方法B: 手動ダウンロード

1. https://www.graalvm.org/downloads/ にアクセス
2. **GraalVM Community Edition 23.1+ for Java 21** をダウンロード
3. macOS (aarch64) または (x64) を選択
4. ダウンロードしたファイルを解凍して `/Library/Java/JavaVirtualMachines/` に配置

### ステップ3: JAVA_HOMEを設定

```bash
# 一時的に設定（現在のターミナルセッションのみ）
export JAVA_HOME=/Library/Java/JavaVirtualMachines/graalvm-jdk-21/Contents/Home
export PATH=$JAVA_HOME/bin:$PATH

# 確認
java -version
# GraalVM CE 23.x.x と表示されればOK

native-image --version
# GraalVM 23.x.x と表示されればOK
```

### ステップ4: 永続的にJAVA_HOMEを設定（推奨）

```bash
# .zshrc に追加（zshの場合）
echo 'export JAVA_HOME=/Library/Java/JavaVirtualMachines/graalvm-jdk-21/Contents/Home' >> ~/.zshrc
echo 'export PATH=$JAVA_HOME/bin:$PATH' >> ~/.zshrc

# 設定を反映
source ~/.zshrc

# または .bash_profile に追加（bashの場合）
echo 'export JAVA_HOME=/Library/Java/JavaVirtualMachines/graalvm-jdk-21/Contents/Home' >> ~/.bash_profile
echo 'export PATH=$JAVA_HOME/bin:$PATH' >> ~/.bash_profile
source ~/.bash_profile
```

### ステップ5: macOS用Native Imageをビルド

```bash
# 専用スクリプトを使用
./build_native_macos.sh
```

または手動で：

```bash
cd quarkus-todo
mvn clean package -Pnative
cd ..
```

**ビルド時間**: 3-10分（マシンスペックによる）

### ステップ6: ビルド結果を確認

```bash
# バイナリタイプを確認
file quarkus-todo/target/quarkus-todo-1.0.0-SNAPSHOT-runner

# 出力例（macOS用の場合）:
# Mach-O 64-bit executable arm64
```

✅ "Mach-O" が表示されればmacOS用バイナリです！

### ステップ7: 実行テスト

```bash
# 直接実行
./quarkus-todo/target/quarkus-todo-1.0.0-SNAPSHOT-runner

# 別ターミナルで確認
curl http://localhost:8081/health/ready
# {"status":"UP",...} が返ればOK

# 停止: Ctrl+C
```

### ステップ8: 3-Wayベンチマーク実行

```bash
./bench/run_benchmark.sh
```

---

## 🎯 簡易版手順（コピペ用）

```bash
# 1. GraalVMインストール
brew install --cask graalvm-jdk21

# 2. 環境変数設定
export JAVA_HOME=/Library/Java/JavaVirtualMachines/graalvm-jdk-21/Contents/Home
export PATH=$JAVA_HOME/bin:$PATH

# 3. バージョン確認
java -version
native-image --version

# 4. macOS用ビルド
./build_native_macos.sh

# 5. ベンチマーク実行
./bench/run_benchmark.sh
```

---

## ⚠️ トラブルシューティング

### GraalVMが見つからない

```bash
# インストール済みのJavaを確認
/usr/libexec/java_home -V

# GraalVMのパスを確認
ls /Library/Java/JavaVirtualMachines/
```

### ビルドエラー: "Cannot run program native-image"

```bash
# native-imageが含まれているか確認
ls $JAVA_HOME/bin/native-image

# なければ、JAVA_HOMEが正しく設定されていない
echo $JAVA_HOME
```

### 古いGraalVMバージョンエラー

```bash
Error: Out of date version of GraalVM detected: 22.3.1
```

**解決**: GraalVM 23.1.0以上をインストール（上記手順参照）

### メモリ不足エラー

Native Imageビルドは大量のメモリを使用します。

```bash
# システムの空きメモリ確認
vm_stat | head -10

# 他のアプリを閉じてから再試行
./build_native_macos.sh
```

---

## 💡 代替案: 2-Wayベンチマークで進める

Native Imageのビルドが難しい場合、**2-Way比較でもデモ可能**です：

```bash
# Native Imageなしで実行（自動的にスキップ）
./bench/run_benchmark.sh
```

結果例：
```
Quarkus JVM:  51ms,  224MB
Spring JVM:   712ms, 316MB
→ 14倍高速、29%メモリ削減
```

これだけでも十分インパクトがあります！

---

## 📊 完成後の期待結果

macOS用Native Imageビルド完了後：

```
=========================================
  Quarkus vs Spring Boot Benchmark Summary
  (3-Way Comparison)
=========================================

Quarkus Native Startup Time: 15ms   ⚡⚡⚡
Quarkus JVM Startup Time: 51ms      ⚡⚡
Spring Boot JVM Startup Time: 712ms ⚡

-----------------------------------------
Memory Usage (Idle)
-----------------------------------------
Quarkus Native: 48 MB   💚💚💚
Quarkus JVM:    224 MB  💚💚
Spring JVM:     316 MB  💚

→ Nativeは47倍高速、85%メモリ削減！
```

---

## 🎓 まとめ

### macOSでNative Imageを作るには

1. **ローカルGraalVM 23.1.0以上が必須**
2. Dockerビルドは**Linux用バイナリ**になるため不可
3. ビルドには**3-10分**かかる

### 推奨フロー

```
Option A (完全版):
  GraalVMインストール
  → macOS用Native Imageビルド
  → 3-Wayベンチマーク
  → 圧倒的な差を見せる ⭐

Option B (簡易版):
  現在のまま
  → 2-Wayベンチマーク
  → 十分なインパクト
```

どちらも有効なデモです！

---

**参考リンク**:
- [GraalVM Downloads](https://www.graalvm.org/downloads/)
- [Quarkus Native Build Guide](https://quarkus.io/guides/building-native-image)

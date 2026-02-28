# クイックフィックス: GraalVMバージョン問題

## 🔴 問題

Mavenが古いGraalVM (22.3.1) を使用しています。
新しいGraalVM (21.0.10) はインストール済みですが、環境変数が反映されていません。

---

## ✅ 解決方法（3つの選択肢）

### 方法1: 新しいターミナルを開く（最も簡単） ⭐推奨

```bash
# 1. 現在のターミナルを閉じる
# 2. 新しいターミナルを開く
# 3. 環境変数を設定
export JAVA_HOME=/Library/Java/JavaVirtualMachines/graalvm-jdk-21.jdk/Contents/Home
export PATH=$JAVA_HOME/bin:$PATH

# 4. 確認
java -version
# → Oracle GraalVM 21.0.10 が表示されればOK

# 5. ビルド
cd /Users/kamori/vscode/customer/subaru
./build_native_macos.sh
```

---

### 方法2: 現在のターミナルで環境変数を再設定

```bash
# 1. 環境変数を明示的に設定
export JAVA_HOME=/Library/Java/JavaVirtualMachines/graalvm-jdk-21.jdk/Contents/Home
export PATH=$JAVA_HOME/bin:$PATH

# 2. Maven設定をリセット
unset MAVEN_OPTS

# 3. 確認
java -version
echo $JAVA_HOME
which java

# 4. Mavenキャッシュをクリア
rm -rf ~/.m2/repository/io/quarkus

# 5. ビルド
./build_native_macos.sh
```

---

### 方法3: 修正版スクリプトを使用

```bash
# 修正版スクリプトを実行（JAVA_HOMEを明示的に指定）
./build_native_macos_fixed.sh
```

このスクリプトは：
- JAVA_HOMEを自動設定
- Mavenに明示的にJAVA_HOMEを渡す
- より詳細なデバッグ情報を表示

---

## 🔍 診断: システムのJava確認

現在のシステムにインストールされているJavaを確認：

```bash
# すべてのJavaバージョンを表示
/usr/libexec/java_home -V

# 出力例:
# Matching Java Virtual Machines (2):
#     21.0.10 (arm64) "Oracle Corporation" - "Java SE 21.0.10" /Library/Java/JavaVirtualMachines/graalvm-jdk-21.jdk/Contents/Home
#     17.0.6 (arm64) "GraalVM Community" - "GraalVM CE 22.3.1" /Library/Java/JavaVirtualMachines/graalvm-ce-java17-22.3.1/Contents/Home
```

---

## 📋 推奨手順（コピペ用）

```bash
# ターミナルで実行

# 1. 環境変数設定
export JAVA_HOME=/Library/Java/JavaVirtualMachines/graalvm-jdk-21.jdk/Contents/Home
export PATH=$JAVA_HOME/bin:$PATH

# 2. 確認
java -version
# → "21.0.10" と "Oracle GraalVM" が表示されることを確認

native-image --version
# → "GraalVM 21.0.10" が表示されることを確認

# 3. プロジェクトディレクトリに移動
cd /Users/kamori/vscode/customer/subaru

# 4. Mavenキャッシュクリア
rm -rf ~/.m2/repository/io/quarkus

# 5. ビルド実行
./build_native_macos.sh
```

---

## ⚠️ トラブルシューティング

### それでも古いGraalVMが使われる場合

```bash
# Maven設定ファイルを確認
cat ~/.mavenrc 2>/dev/null

# Maven JVM設定を確認
echo $MAVEN_OPTS

# これらが設定されている場合は削除
unset MAVEN_OPTS
rm ~/.mavenrc
```

### Homebrewでインストールしたパスが異なる場合

```bash
# 実際のインストールパスを確認
ls -la /Library/Java/JavaVirtualMachines/

# graalvm-jdk-21.jdk が見つからない場合
# graalvm-ce-21.jdk などの名前かもしれません
# その場合、JAVA_HOMEを調整：
export JAVA_HOME=/Library/Java/JavaVirtualMachines/graalvm-ce-21.jdk/Contents/Home
```

---

## ✅ 成功の確認

ビルドが成功すると、以下のように表示されます：

```
========================================
  Native Build Complete!
========================================

Native binary created:
-rwxr-xr-x  1 user  staff   65M  Feb 22 17:10 target/quarkus-todo-1.0.0-SNAPSHOT-runner

Binary type:
Mach-O 64-bit executable arm64

File size: 65M
```

"Mach-O" が表示されればmacOS用バイナリです！

---

## 🚀 ビルド成功後

```bash
# 3-Wayベンチマーク実行
./bench/run_benchmark.sh
```

期待される結果：
```
Quarkus Native: 15ms,  48MB   ⚡⚡⚡
Quarkus JVM:    51ms,  224MB  ⚡⚡
Spring JVM:     712ms, 316MB  ⚡

→ Nativeは47倍高速、85%メモリ削減！
```

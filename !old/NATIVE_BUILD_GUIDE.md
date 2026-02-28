# Native Imageビルドガイド

## 🔴 発生したエラー

```
Out of date version of GraalVM or Mandrel detected: 22.3.1
Quarkus currently supports 23.1.0
```

### 原因

お使いのシステムにインストールされているGraalVM（バージョン22.3.1、JDK 17）が古すぎます。
Quarkus 3.17.0はGraalVM 23.1.0以上（JDK 21対応）を必要とします。

---

## ✅ 解決方法（推奨順）

### 方法1: Dockerを使う（最も簡単） ⭐推奨

この方法なら、GraalVMのバージョンを気にする必要がありません。

#### ステップ1: Docker Desktopを起動

```bash
# macOSの場合
open -a Docker

# またはアプリケーションフォルダからDocker Desktopを起動
```

Docker Desktopが起動するまで30秒ほど待ちます。

#### ステップ2: Dockerが起動したことを確認

```bash
docker ps
# エラーが出なければOK
```

#### ステップ3: Native Imageをビルド

```bash
./build_native.sh
```

スクリプトが自動的にDockerを検出し、コンテナ内でビルドします。

**ビルド時間**: 約3-10分

---

### 方法2: GraalVMをアップグレード

この方法はビルドが高速ですが、セットアップが必要です。

#### ステップ1: 現在のGraalVMバージョン確認

```bash
java -version
native-image --version
```

#### ステップ2: GraalVM 23.1.0以上をインストール

```bash
# Homebrewの場合
brew install --cask graalvm-jdk

# 手動インストールの場合
# https://www.graalvm.org/downloads/ からダウンロード
```

#### ステップ3: JAVA_HOMEを設定

```bash
# .zshrc または .bash_profile に追加
export JAVA_HOME=/Library/Java/JavaVirtualMachines/graalvm-jdk-21/Contents/Home
export PATH=$JAVA_HOME/bin:$PATH

# 設定を反映
source ~/.zshrc  # または source ~/.bash_profile
```

#### ステップ4: バージョン確認

```bash
java -version
# GraalVM CE 23.x.x を確認

native-image --version
# GraalVM 23.x.x を確認
```

#### ステップ5: Native Imageをビルド

```bash
./build_native.sh
```

---

## 🐳 Dockerビルドの詳細

### メリット

- ✅ GraalVMのインストール不要
- ✅ 常に正しいバージョンでビルド
- ✅ 環境に依存しない
- ✅ CI/CDと同じ環境

### デメリット

- ❌ 初回ビルドはイメージダウンロードが必要
- ❌ ローカルビルドより少し遅い

### 仕組み

```bash
mvn package -Pnative -Dquarkus.native.container-build=true
```

このコマンドは：
1. Quarkus公式のGraalVMコンテナイメージをpull
2. コンテナ内でNative Imageをビルド
3. ビルド成果物をホストにコピー

---

## 📊 ビルド後の確認

### 成功したら

```bash
# Native binaryが生成される
ls -lh quarkus-todo/target/quarkus-todo-1.0.0-SNAPSHOT-runner

# 出力例:
# -rwxr-xr-x  1 user  staff   65M  Feb 22 16:45 quarkus-todo-1.0.0-SNAPSHOT-runner
```

### 実行テスト

```bash
# 直接実行してみる
./quarkus-todo/target/quarkus-todo-1.0.0-SNAPSHOT-runner

# 別ターミナルで確認
curl http://localhost:8081/health/ready

# 停止
# Ctrl+C
```

---

## 🚀 ビルド完了後

Native Imageビルドが成功したら、3-Wayベンチマークを実行できます：

```bash
./bench/run_benchmark.sh
```

期待される結果：

```
Quarkus Native Startup Time: 15ms
Quarkus JVM Startup Time: 51ms
Spring Boot JVM Startup Time: 712ms

Quarkus Native: 48 MB
Quarkus JVM:    224 MB
Spring JVM:     316 MB

→ Nativeは47倍高速、85%メモリ削減！
```

---

## ⚠️ よくある問題

### Docker起動エラー

**エラー**: `Cannot connect to the Docker daemon`

**解決**:
```bash
# Docker Desktopを起動
open -a Docker

# 30秒待ってから確認
docker ps

# 再実行
./build_native.sh
```

### Dockerメモリ不足

**エラー**: ビルド中にメモリ不足でクラッシュ

**解決**:
1. Docker Desktop → Settings → Resources
2. Memory を 8GB以上に設定
3. Apply & Restart
4. `./build_native.sh` を再実行

### ビルドが非常に遅い

**原因**: Dockerのエミュレーション

**解決**:
- Apple Silicon (M1/M2)の場合、Rosettaを有効化
- Docker Desktop → Settings → General
- "Use Rosetta for x86/amd64 emulation" をチェック

### ディスク容量不足

Native Imageビルドは約5-10GBの一時ディスク容量が必要です。

```bash
# 空き容量確認
df -h .

# Dockerイメージクリーンアップ
docker system prune -a
```

---

## 🎯 まとめ

### 推奨手順

1. **Docker Desktopを起動** （最も簡単）
2. `./build_native.sh` を実行
3. 3-10分待つ
4. `./bench/run_benchmark.sh` で3-Way比較

### デモ実行の選択肢

| 選択肢 | 準備時間 | デモ効果 |
|--------|---------|---------|
| **2-Way (JVMのみ)** | 0分（準備済み） | Good (14倍差) |
| **3-Way (Native含む)** | 3-10分 | Excellent (47倍差) ⭐ |

Native Imageがあると、デモのインパクトが劇的に向上します！

---

## 📞 サポート

それでも問題が解決しない場合：

1. エラーログ全体を確認
2. [QUICKSTART.md](QUICKSTART.md) を参照
3. Docker/GraalVMのバージョンを確認

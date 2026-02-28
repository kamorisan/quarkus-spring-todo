# クイックスタートガイド

## 🚀 すぐに始める（3ステップ）

### ステップ1: JVMモードで2-Way比較（5分）

```bash
# 既にビルド済みなので、すぐに実行可能
./bench/run_benchmark.sh
```

これで **Quarkus JVM vs Spring Boot JVM** の比較が完了します。

### ステップ2: Native Imageビルド（3-10分）

```bash
# Dockerを使って自動ビルド
./build_native.sh
```

### ステップ3: 3-Way比較を実行（5分）

```bash
# 3種類全てを自動計測
./bench/run_benchmark.sh
```

---

## ⚠️ GraalVMバージョン問題の解決

### 問題

ローカルGraalVMが古い場合、以下のエラーが出ます：

```
Out of date version of GraalVM or Mandrel detected: 22.3.1
Quarkus currently supports 23.1.0
```

### 解決策1: Dockerを使う（推奨）✅

```bash
# Dockerが起動していることを確認
docker ps

# ビルド実行（自動的にDockerを使用）
./build_native.sh
```

**メリット**:
- GraalVMのインストール不要
- 常に正しいバージョンでビルド
- クロスプラットフォーム対応

### 解決策2: GraalVMをアップグレード

```bash
# 現在のバージョン確認
native-image --version

# GraalVM 23.1.0以上をインストール
brew install --cask graalvm-jdk

# 環境変数設定
export JAVA_HOME=/Library/Java/JavaVirtualMachines/graalvm-jdk-21/Contents/Home

# ビルド実行
./build_native.sh
```

---

## 🐳 Docker使用時の注意点

### Dockerが起動していない場合

```bash
# エラー例
Cannot connect to the Docker daemon

# 解決: Docker Desktopを起動
open -a Docker
# しばらく待ってから再実行
./build_native.sh
```

### Dockerのメモリ不足

Native Imageビルドは多くのメモリを使います。

**Docker Desktop設定**:
1. Docker Desktop → Settings → Resources
2. Memory を 8GB以上に設定
3. Apply & Restart

---

## 📊 期待される結果

### 2-Way比較（Native なし）

```
Quarkus JVM:    51ms,  224MB
Spring JVM:     712ms, 316MB
→ 14倍高速、29%メモリ削減
```

### 3-Way比較（Native あり）

```
Quarkus Native: 15ms,  48MB   ⚡⚡⚡
Quarkus JVM:    51ms,  224MB  ⚡⚡
Spring JVM:     712ms, 316MB  ⚡
→ Nativeは47倍高速、85%メモリ削減！
```

---

## 🔍 トラブルシューティング

### ビルドが失敗する

```bash
# ログを確認
tail -f quarkus-todo/target/maven-status/maven-compiler-plugin/compile/default-compile/inputFiles.lst

# クリーンしてリトライ
cd quarkus-todo
mvn clean
cd ..
./build_native.sh
```

### ベンチマークが動かない

```bash
# 実行権限を確認
chmod +x bench/*.sh
chmod +x build_native.sh

# プロセスをクリーンアップ
pkill -f quarkus-todo
pkill -f spring-todo

# 再実行
./bench/run_benchmark.sh
```

### ポートが使われている

```bash
# ポート8081/8082を使用しているプロセスを確認
lsof -i :8081
lsof -i :8082

# プロセスを停止
kill <PID>
```

---

## ✅ チェックリスト

### 前提条件
- [x] Java 21インストール済み
- [x] Maven 3.8+インストール済み
- [x] JVMモードビルド完了
- [ ] Docker起動中（Native用）
- [ ] ディスク容量1GB以上

### Native Image用（オプション）
- [ ] Docker Desktop起動
- [ ] Dockerメモリ8GB以上設定
- [ ] またはGraalVM 23.1.0+インストール

---

## 📚 詳細情報

詳しい手順は以下を参照：
- **[demo_exe.md](demo_exe.md)** - 詳細な実行ガイド
- **[README.md](README.md)** - プロジェクト概要

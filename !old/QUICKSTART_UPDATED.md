# クイックスタートガイド（更新版）

## 🚀 3ステップで3-Wayベンチマーク

### ステップ1: 環境変数を設定（GraalVM使用時）

```bash
export JAVA_HOME=/Library/Java/JavaVirtualMachines/graalvm-21.jdk/Contents/Home
export PATH=$JAVA_HOME/bin:$PATH
```

### ステップ2: 全てビルド（JVM + Native）

```bash
./build_all.sh
```

このスクリプトは：
- ✅ Quarkus JVMモードをビルド
- ✅ Quarkus Nativeモードをビルド
- ✅ Spring Boot JVMをビルド（必要に応じて）
- ✅ **両方のバイナリを保持**（賢い方法で）

**ビルド時間**: 約5-15分（Nativeビルド含む）

### ステップ3: 3-Wayベンチマーク実行

```bash
./bench/run_benchmark.sh
```

**実行時間**: 約4-5分

---

## 📊 期待される結果

```
=========================================
  Quarkus vs Spring Boot Benchmark Summary
  (3-Way Comparison)
=========================================

Quarkus Native Startup Time: 1ms
Quarkus JVM Startup Time: 53ms
Spring Boot JVM Startup Time: 747ms

-----------------------------------------
Memory Usage (Idle)
-----------------------------------------
Quarkus Native: 67 MB
Quarkus JVM:    232 MB
Spring JVM:     323 MB

-----------------------------------------
Summary Comparison:
-----------------------------------------
Startup Time:
  Quarkus Native: 1ms (1.0x baseline)
  Quarkus JVM:    53ms (53x slower than Native)
  Spring JVM:     747ms (747x slower than Native)

Memory Savings:
  Native saves 71% vs Quarkus JVM
  Native saves 79% vs Spring JVM
=========================================
```

---

## 🔄 再ベンチマーク

結果をいつでも再表示できます：

```bash
./bench/summary.sh
```

---

## 💡 個別ビルド（必要に応じて）

### JVMモードのみ再ビルド

```bash
cd quarkus-todo
mvn package -DskipTests
cd ..
```

### Nativeのみ再ビルド

```bash
./build_native_direct.sh
```

---

## ⚠️ トラブルシューティング

### ビルド成果物が消えた

`mvn clean` を実行すると全て削除されます。
`./build_all.sh` を再実行してください。

### Nativeビルドが失敗する

1. GraalVMバージョン確認:
   ```bash
   java -version
   native-image --version
   ```

2. JAVA_HOMEを確認:
   ```bash
   echo $JAVA_HOME
   ```

3. 環境変数を再設定:
   ```bash
   export JAVA_HOME=/Library/Java/JavaVirtualMachines/graalvm-21.jdk/Contents/Home
   export PATH=$JAVA_HOME/bin:$PATH
   ```

---

## 📝 スクリプト一覧

| スクリプト | 用途 | 時間 |
|----------|------|------|
| `./build_all.sh` | JVM + Native 両方ビルド | 5-15分 |
| `./build_native_direct.sh` | Nativeのみビルド | 3-10分 |
| `./bench/run_benchmark.sh` | 3-Wayベンチマーク実行 | 4-5分 |
| `./bench/summary.sh` | 結果を再表示 | <1秒 |

---

## ✅ まとめ

**最も簡単な方法**:

```bash
# 1回だけ実行（環境変数設定）
export JAVA_HOME=/Library/Java/JavaVirtualMachines/graalvm-21.jdk/Contents/Home
export PATH=$JAVA_HOME/bin:$PATH

# ビルド + ベンチマーク（ワンライナー）
./build_all.sh && ./bench/run_benchmark.sh
```

これで完了です！🎉

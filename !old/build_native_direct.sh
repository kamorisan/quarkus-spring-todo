#!/bin/bash
set -e

echo "========================================="
echo "  Building Quarkus Native Image for macOS"
echo "  (Direct Method - Explicit JAVA_HOME)"
echo "========================================="
echo ""

# GraalVM 21のパスを明示的に設定
GRAALVM_HOME="/Library/Java/JavaVirtualMachines/graalvm-21.jdk/Contents/Home"

if [ ! -d "$GRAALVM_HOME" ]; then
    echo "Error: GraalVM not found at $GRAALVM_HOME"
    echo ""
    echo "Available Java installations:"
    ls -la /Library/Java/JavaVirtualMachines/
    echo ""
    exit 1
fi

echo "Using GraalVM: $GRAALVM_HOME"
echo ""

# バージョン確認
echo "=== Java Version ==="
$GRAALVM_HOME/bin/java -version 2>&1
echo ""

echo "=== native-image Version ==="
$GRAALVM_HOME/bin/native-image --version 2>&1
echo ""

# 環境変数をエクスポート
export JAVA_HOME="$GRAALVM_HOME"
export PATH="$GRAALVM_HOME/bin:$PATH"

echo "Environment variables:"
echo "  JAVA_HOME=$JAVA_HOME"
echo "  PATH (first entry): $(echo $PATH | cut -d: -f1)"
echo ""

echo "Building native image..."
echo "This will take 3-10 minutes. Please wait..."
echo ""

cd quarkus-todo

# Maven に明示的に JAVA_HOME を渡す
# -Djava.home で Maven Fork プロセスの Java を指定
JAVA_HOME="$GRAALVM_HOME" \
  mvn clean package -Pnative \
  -Djava.home="$GRAALVM_HOME" \
  -Dquarkus.native.java-home="$GRAALVM_HOME"

BUILD_STATUS=$?

cd ..

if [ $BUILD_STATUS -ne 0 ]; then
    echo ""
    echo "========================================="
    echo "  Build Failed"
    echo "========================================="
    echo ""
    echo "Please run the diagnosis tool for more information:"
    echo "  ./diagnose_graalvm.sh"
    echo ""
    exit 1
fi

echo ""
echo "========================================="
echo "  Native Build Complete!"
echo "========================================="
echo ""

NATIVE_BINARY="quarkus-todo/target/quarkus-todo-1.0.0-SNAPSHOT-runner"

if [ -f "$NATIVE_BINARY" ]; then
    echo "✅ Native binary successfully created!"
    echo ""
    ls -lh "$NATIVE_BINARY"
    echo ""

    echo "Binary type:"
    file "$NATIVE_BINARY"
    echo ""

    echo "File size: $(du -h "$NATIVE_BINARY" | cut -f1)"
    echo ""

    chmod +x "$NATIVE_BINARY"

    echo "Testing the binary..."
    if "$NATIVE_BINARY" --version 2>/dev/null; then
        echo "Binary is executable ✅"
    else
        echo "(Version check not supported, but binary exists)"
    fi
    echo ""

    echo "========================================="
    echo "  Next Steps"
    echo "========================================="
    echo ""
    echo "Run the 3-way benchmark:"
    echo "  ./bench/run_benchmark.sh"
    echo ""
    echo "Or test the native binary directly:"
    echo "  ./quarkus-todo/target/quarkus-todo-1.0.0-SNAPSHOT-runner"
    echo ""
else
    echo "❌ Error: Native binary not found"
    echo ""
    echo "Expected location: $NATIVE_BINARY"
    echo ""
    exit 1
fi

#!/bin/bash
set -e

echo "========================================="
echo "  Building Quarkus Native Image for macOS"
echo "========================================="
echo ""

# GraalVMのチェック
if ! command -v native-image &> /dev/null; then
    echo "Error: native-image command not found."
    echo ""
    echo "To build native image for macOS, you need GraalVM."
    echo ""
    echo "Installation steps:"
    echo "  1. Install GraalVM 23.1.0 for Java 21:"
    echo "     brew install --cask graalvm-jdk21"
    echo ""
    echo "  2. Set JAVA_HOME:"
    echo "     export JAVA_HOME=/Library/Java/JavaVirtualMachines/graalvm-jdk-21.jdk/Contents/Home"
    echo "     export PATH=\$JAVA_HOME/bin:\$PATH"
    echo ""
    exit 1
fi

# JAVA_HOMEが設定されているか確認
if [ -z "$JAVA_HOME" ]; then
    echo "JAVA_HOME is not set. Setting it now..."
    export JAVA_HOME=/Library/Java/JavaVirtualMachines/graalvm-21.jdk/Contents/Home
    export PATH=$JAVA_HOME/bin:$PATH
fi

echo "Using JAVA_HOME: $JAVA_HOME"
echo ""
echo "Checking Java version..."
$JAVA_HOME/bin/java -version
echo ""

echo "Checking native-image version..."
$JAVA_HOME/bin/native-image --version
echo ""

# バージョンチェック
JAVA_VERSION=$($JAVA_HOME/bin/java -version 2>&1 | head -1 | grep -oE '[0-9]+' | head -1)
if [ "$JAVA_VERSION" -lt 21 ]; then
    echo "Error: Java version $JAVA_VERSION is too old."
    echo "Quarkus 3.17.0 requires Java 21 or later."
    echo ""
    exit 1
fi

echo "Building native image for macOS (Apple Silicon)..."
echo "This will take 3-10 minutes..."
echo ""

cd quarkus-todo

# Mavenに明示的にJAVA_HOMEを渡してビルド
JAVA_HOME=$JAVA_HOME mvn clean package -Pnative

cd ..

echo ""
echo "========================================="
echo "  Native Build Complete!"
echo "========================================="
echo ""

NATIVE_BINARY="target/quarkus-todo-1.0.0-SNAPSHOT-runner"

if [ -f "quarkus-todo/$NATIVE_BINARY" ]; then
    echo "Native binary created:"
    ls -lh "quarkus-todo/$NATIVE_BINARY"
    echo ""

    # バイナリ情報を表示
    echo "Binary type:"
    file "quarkus-todo/$NATIVE_BINARY"
    echo ""

    echo "File size: $(du -h "quarkus-todo/$NATIVE_BINARY" | cut -f1)"
    echo ""

    # 実行権限を付与
    chmod +x "quarkus-todo/$NATIVE_BINARY"

    echo "Testing binary..."
    "quarkus-todo/$NATIVE_BINARY" --version || echo "(version check not supported)"
    echo ""

    echo "✅ Success! You can now run the 3-way benchmark:"
    echo "  ./bench/run_benchmark.sh"
    echo ""
    echo "Or test the native binary directly:"
    echo "  ./quarkus-todo/$NATIVE_BINARY"
else
    echo "Error: Native binary not found at quarkus-todo/$NATIVE_BINARY"
    exit 1
fi

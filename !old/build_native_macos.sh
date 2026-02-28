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
    echo "     export JAVA_HOME=/Library/Java/JavaVirtualMachines/graalvm-jdk-21/Contents/Home"
    echo "     export PATH=\$JAVA_HOME/bin:\$PATH"
    echo ""
    echo "  3. Add to ~/.zshrc or ~/.bash_profile to make it permanent"
    echo ""
    echo "Alternative: Skip native build and run 2-way benchmark"
    echo "  ./bench/run_benchmark.sh (will skip native automatically)"
    echo ""
    exit 1
fi

echo "Checking GraalVM version..."
java -version
echo ""

# バージョンチェック（簡易版）
JAVA_VERSION=$(java -version 2>&1 | head -1 | grep -oE '[0-9]+' | head -1)
if [ "$JAVA_VERSION" -lt 21 ]; then
    echo "Error: Java version $JAVA_VERSION is too old."
    echo "Quarkus 3.17.0 requires Java 21 or later."
    echo ""
    echo "Please install GraalVM for Java 21:"
    echo "  brew install --cask graalvm-jdk21"
    echo ""
    exit 1
fi

echo "Building native image for macOS (Apple Silicon)..."
echo "This will take 3-10 minutes..."
echo ""

cd quarkus-todo

# macOS用にビルド
mvn clean package -Pnative

cd ..

echo ""
echo "========================================="
echo "  Native Build Complete!"
echo "========================================="
echo ""

NATIVE_BINARY="quarkus-todo/target/quarkus-todo-1.0.0-SNAPSHOT-runner"

if [ -f "$NATIVE_BINARY" ]; then
    echo "Native binary created:"
    ls -lh "$NATIVE_BINARY"
    echo ""

    # バイナリ情報を表示
    echo "Binary type:"
    file "$NATIVE_BINARY"
    echo ""

    echo "File size: $(du -h "$NATIVE_BINARY" | cut -f1)"
    echo ""

    # 実行権限を付与
    chmod +x "$NATIVE_BINARY"

    echo "You can now run the 3-way benchmark:"
    echo "  ./bench/run_benchmark.sh"
    echo ""
    echo "Or test the native binary directly:"
    echo "  $NATIVE_BINARY"
else
    echo "Error: Native binary not found at $NATIVE_BINARY"
    exit 1
fi

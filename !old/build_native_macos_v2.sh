#!/bin/bash
set -e

echo "========================================="
echo "  Building Quarkus Native Image for macOS"
echo "  (Version 2: Explicit native-image path)"
echo "========================================="
echo ""

# GraalVM 21のパスを明示的に設定
GRAALVM_HOME=/Library/Java/JavaVirtualMachines/graalvm-21.jdk/Contents/Home

# native-imageの存在確認
NATIVE_IMAGE_PATH="$GRAALVM_HOME/bin/native-image"

if [ ! -f "$NATIVE_IMAGE_PATH" ]; then
    echo "Error: native-image not found at $NATIVE_IMAGE_PATH"
    echo ""
    echo "Please verify GraalVM installation:"
    echo "  ls -la /Library/Java/JavaVirtualMachines/"
    echo ""
    exit 1
fi

echo "Using GraalVM: $GRAALVM_HOME"
echo ""

# バージョン確認
echo "Java version:"
$GRAALVM_HOME/bin/java -version
echo ""

echo "native-image version:"
$NATIVE_IMAGE_PATH --version
echo ""

# 環境変数を設定
export JAVA_HOME=$GRAALVM_HOME
export PATH=$GRAALVM_HOME/bin:$PATH
export GRAALVM_HOME=$GRAALVM_HOME

echo "Building native image for macOS..."
echo "This will take 3-10 minutes..."
echo ""

cd quarkus-todo

# Quarkusに明示的にnative-imageのパスを指定してビルド
mvn clean package -Pnative \
    -Dquarkus.native.native-image-xmx=4g \
    -Dquarkus.native.additional-build-args="--verbose" \
    -Djava.home=$GRAALVM_HOME

BUILD_EXIT_CODE=$?

cd ..

if [ $BUILD_EXIT_CODE -ne 0 ]; then
    echo ""
    echo "========================================="
    echo "  Build Failed"
    echo "========================================="
    echo ""
    echo "Diagnostics:"
    echo "  JAVA_HOME: $JAVA_HOME"
    echo "  GRAALVM_HOME: $GRAALVM_HOME"
    echo "  native-image path: $NATIVE_IMAGE_PATH"
    echo ""
    echo "Which native-image is being used:"
    which native-image
    echo ""
    echo "All Java installations:"
    /usr/libexec/java_home -V
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
    echo "Native binary created:"
    ls -lh "$NATIVE_BINARY"
    echo ""

    echo "Binary type:"
    file "$NATIVE_BINARY"
    echo ""

    echo "File size: $(du -h "$NATIVE_BINARY" | cut -f1)"
    echo ""

    chmod +x "$NATIVE_BINARY"

    echo "✅ Success! You can now run the 3-way benchmark:"
    echo "  ./bench/run_benchmark.sh"
else
    echo "Error: Native binary not found at $NATIVE_BINARY"
    exit 1
fi

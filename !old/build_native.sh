#!/bin/bash
set -e

echo "========================================="
echo "  Building Quarkus Native Image"
echo "========================================="
echo ""

cd quarkus-todo

# Dockerが利用可能かチェック
if command -v docker &> /dev/null; then
    echo "Docker detected. Using container build (recommended)..."
    echo "This ensures compatibility with Quarkus 3.17.0 requirements."
    echo ""

    echo "Building with Docker/Podman container..."
    echo "This may take 3-10 minutes depending on your machine..."
    echo ""

    mvn clean package -Pnative -Dquarkus.native.container-build=true

elif command -v native-image &> /dev/null; then
    echo "Warning: Docker not found. Using local GraalVM..."
    echo ""

    # GraalVMのバージョンチェック
    GRAALVM_VERSION=$(native-image --version | grep -oE 'GraalVM [0-9]+\.[0-9]+\.[0-9]+' | grep -oE '[0-9]+\.[0-9]+\.[0-9]+')
    echo "Detected GraalVM version: $GRAALVM_VERSION"

    # バージョン番号を比較（簡易版）
    MAJOR_VERSION=$(echo $GRAALVM_VERSION | cut -d. -f1)
    MINOR_VERSION=$(echo $GRAALVM_VERSION | cut -d. -f2)

    if [ "$MAJOR_VERSION" -lt 23 ]; then
        echo ""
        echo "ERROR: GraalVM version $GRAALVM_VERSION is too old."
        echo "Quarkus 3.17.0 requires GraalVM 23.1.0 or later."
        echo ""
        echo "Solutions:"
        echo "  1. Install Docker and re-run this script (recommended)"
        echo "  2. Upgrade GraalVM to version 23.1.0 or later"
        echo ""
        echo "To install Docker:"
        echo "  macOS: brew install --cask docker"
        echo "  or download from https://www.docker.com/products/docker-desktop"
        echo ""
        exit 1
    fi

    echo "Building with local GraalVM $GRAALVM_VERSION..."
    mvn clean package -Pnative

else
    echo "Error: Neither Docker nor GraalVM native-image found."
    echo ""
    echo "To build native image, you need either:"
    echo "  1. Docker (recommended) - brew install --cask docker"
    echo "  2. GraalVM 23.1.0+ - brew install --cask graalvm-jdk"
    echo ""
    echo "Docker is recommended as it ensures compatibility."
    exit 1
fi

echo ""
echo "========================================="
echo "  Native Build Complete!"
echo "========================================="
echo ""

NATIVE_BINARY="target/quarkus-todo-1.0.0-SNAPSHOT-runner"

if [ -f "$NATIVE_BINARY" ]; then
    echo "Native binary created:"
    ls -lh "$NATIVE_BINARY"
    echo ""
    echo "File size: $(du -h "$NATIVE_BINARY" | cut -f1)"
    echo ""
    echo "You can now run the 3-way benchmark:"
    echo "  ./bench/run_benchmark.sh"
else
    echo "Error: Native binary not found at $NATIVE_BINARY"
    exit 1
fi

cd ..

#!/bin/bash
set -e

echo "========================================="
echo "  Building Both JVM and Native Images"
echo "  for 3-Way Benchmark"
echo "========================================="
echo ""

# GraalVM確認
GRAALVM_HOME="/Library/Java/JavaVirtualMachines/graalvm-21.jdk/Contents/Home"

if [ ! -d "$GRAALVM_HOME" ]; then
    echo "Warning: GraalVM 21 not found at $GRAALVM_HOME"
    echo "Native image build will be skipped."
    echo ""
    BUILD_NATIVE=false
else
    BUILD_NATIVE=true
    export JAVA_HOME="$GRAALVM_HOME"
    export PATH="$GRAALVM_HOME/bin:$PATH"
fi

echo "Step 1/2: Building Quarkus JVM mode..."
echo "========================================="
echo ""

cd quarkus-todo

# JVMモードをビルド
mvn clean package -DskipTests

JVM_JAR="target/quarkus-app/quarkus-run.jar"
if [ -f "$JVM_JAR" ]; then
    echo "✅ JVM JAR created: $(du -h $JVM_JAR | cut -f1)"
else
    echo "❌ Error: JVM JAR not found"
    cd ..
    exit 1
fi

cd ..

echo ""
echo "Step 2/2: Building Quarkus Native image..."
echo "========================================="
echo ""

if [ "$BUILD_NATIVE" = true ]; then
    # JVM JAR一式を一時退避
    TEMP_DIR="$(mktemp -d)"
    echo "Backing up JVM artifacts to: $TEMP_DIR"
    cp -r quarkus-todo/target/quarkus-app "$TEMP_DIR/"

    # Nativeビルド
    cd quarkus-todo

    JAVA_HOME="$GRAALVM_HOME" \
      mvn clean package -Pnative \
      -Djava.home="$GRAALVM_HOME" \
      -Dquarkus.native.java-home="$GRAALVM_HOME"

    NATIVE_BINARY="target/quarkus-todo-1.0.0-SNAPSHOT-runner"

    if [ -f "$NATIVE_BINARY" ]; then
        echo "✅ Native binary created: $(du -h $NATIVE_BINARY | cut -f1)"

        # JVM JARを復元
        echo "Restoring JVM artifacts..."
        cp -r "$TEMP_DIR/quarkus-app" target/

        # 一時ディレクトリを削除
        rm -rf "$TEMP_DIR"

        echo "✅ Both JVM and Native artifacts are ready!"
    else
        echo "❌ Error: Native binary not found"
        # JVM JARを復元
        cp -r "$TEMP_DIR/quarkus-app" target/
        rm -rf "$TEMP_DIR"
        cd ..
        exit 1
    fi

    cd ..
else
    echo "Skipping Native image build (GraalVM not found)"
    echo "JVM mode is ready for 2-way benchmark"
fi

echo ""
echo "========================================="
echo "  Build Complete!"
echo "========================================="
echo ""

# 成果物の確認
echo "Build artifacts:"
echo ""

if [ -f "quarkus-todo/target/quarkus-app/quarkus-run.jar" ]; then
    echo "✅ Quarkus JVM:"
    ls -lh quarkus-todo/target/quarkus-app/quarkus-run.jar
fi

if [ -f "quarkus-todo/target/quarkus-todo-1.0.0-SNAPSHOT-runner" ]; then
    echo "✅ Quarkus Native:"
    ls -lh quarkus-todo/target/quarkus-todo-1.0.0-SNAPSHOT-runner
    echo "   Type: $(file quarkus-todo/target/quarkus-todo-1.0.0-SNAPSHOT-runner | grep -o 'Mach-O\|ELF')"
fi

if [ -f "spring-todo/target/spring-todo-0.0.1-SNAPSHOT.jar" ]; then
    echo "✅ Spring Boot JVM:"
    ls -lh spring-todo/target/spring-todo-0.0.1-SNAPSHOT.jar
else
    echo "⚠️  Spring Boot JAR not found. Building..."
    cd spring-todo
    mvn clean package -DskipTests
    cd ..
    if [ -f "spring-todo/target/spring-todo-0.0.1-SNAPSHOT.jar" ]; then
        echo "✅ Spring Boot JVM:"
        ls -lh spring-todo/target/spring-todo-0.0.1-SNAPSHOT.jar
    fi
fi

echo ""
echo "========================================="
echo "  Next Steps"
echo "========================================="
echo ""

if [ "$BUILD_NATIVE" = true ]; then
    echo "Run 3-way benchmark:"
    echo "  ./bench/run_benchmark.sh"
else
    echo "Run 2-way benchmark (JVM only):"
    echo "  ./bench/run_benchmark.sh"
    echo ""
    echo "To enable Native image:"
    echo "  1. Install GraalVM 21:"
    echo "     brew install --cask graalvm-jdk21"
    echo "  2. Re-run this script:"
    echo "     ./build_all.sh"
fi
echo ""

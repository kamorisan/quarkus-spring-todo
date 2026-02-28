#!/bin/bash

echo "========================================="
echo "  GraalVM Diagnosis Tool"
echo "========================================="
echo ""

echo "1. Current JAVA_HOME:"
echo "   $JAVA_HOME"
echo ""

echo "2. Java version (using 'java' command):"
java -version 2>&1
echo ""

echo "3. Which java:"
which java
echo ""

echo "4. native-image version:"
if command -v native-image &> /dev/null; then
    native-image --version 2>&1
else
    echo "   native-image command not found"
fi
echo ""

echo "5. Which native-image:"
which native-image 2>&1 || echo "   native-image not found in PATH"
echo ""

echo "6. All Java installations:"
/usr/libexec/java_home -V 2>&1
echo ""

echo "7. GraalVM installations in /Library/Java/JavaVirtualMachines/:"
ls -la /Library/Java/JavaVirtualMachines/ | grep -i graal || echo "   No GraalVM found"
echo ""

echo "8. Current PATH:"
echo "   $PATH" | tr ':' '\n' | grep -i java
echo ""

echo "9. Check for native-image in common locations:"
for dir in /Library/Java/JavaVirtualMachines/*/Contents/Home/bin; do
    if [ -f "$dir/native-image" ]; then
        echo "   Found: $dir/native-image"
        $dir/native-image --version 2>&1 | head -1
    fi
done
echo ""

echo "========================================="
echo "  Diagnosis Complete"
echo "========================================="
echo ""

echo "Recommendations:"
echo ""

# 古いGraalVMがある場合の警告
if ls /Library/Java/JavaVirtualMachines/ 2>/dev/null | grep -q "graalvm-ce-java17\|22.3.1"; then
    echo "⚠️  Old GraalVM detected (22.3.1)"
    echo "   Consider removing it:"
    echo "   sudo rm -rf /Library/Java/JavaVirtualMachines/graalvm-ce-java17-22.3.1"
    echo ""
fi

# GraalVM 21が正しく設定されているか確認
if [ -d "/Library/Java/JavaVirtualMachines/graalvm-21.jdk" ]; then
    echo "✅ GraalVM 21 is installed"
    echo "   Path: /Library/Java/JavaVirtualMachines/graalvm-21.jdk"
    echo ""
    echo "   To use it, set:"
    echo "   export JAVA_HOME=/Library/Java/JavaVirtualMachines/graalvm-21.jdk/Contents/Home"
    echo "   export PATH=\$JAVA_HOME/bin:\$PATH"
    echo ""
fi

# native-imageのバージョン不一致を検出
JAVA_VER=$(java -version 2>&1 | head -1 | grep -oE '[0-9]+\.[0-9]+\.[0-9]+' | head -1)
if command -v native-image &> /dev/null; then
    NATIVE_VER=$(native-image --version 2>&1 | head -1)
    echo "Current versions:"
    echo "  java:         $JAVA_VER"
    echo "  native-image: $NATIVE_VER"
    echo ""

    if ! echo "$NATIVE_VER" | grep -q "21.0"; then
        echo "⚠️  Version mismatch detected!"
        echo "   java is version 21, but native-image is not."
        echo "   This will cause build failures."
        echo ""
    fi
fi

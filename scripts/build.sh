#!/bin/bash
# build.sh - 构建 Start 和 Controller 应用
# 使用环境变量: AI_NAME, WORKSPACE_PATH, OUTPUT_PATH

set -e

# 默认值
AI_NAME="${AI_NAME:-Tony}"
WORKSPACE_PATH="${WORKSPACE_PATH:-$HOME/.openclaw/workspace}"
OUTPUT_PATH="${OUTPUT_PATH:-$HOME/Desktop}"

echo "🚀 构建 OpenClaw 启动工具..."
echo "  AI 名字: $AI_NAME"
echo "  工作区: $WORKSPACE_PATH"
echo "  输出路径: $OUTPUT_PATH"

# 创建临时目录
TMP_DIR=$(mktemp -d)
trap "rm -rf $TMP_DIR" EXIT

# ========== 构建 Start.app ==========
echo ""
echo "📦 构建 Start.app..."

# 替换占位符
sed -e "s|{AI_NAME}|$AI_NAME|g" \
    -e "s|{WORKSPACE_PATH}|$WORKSPACE_PATH|g" \
    "$(dirname "$0")/../src/Start/main.swift" > "$TMP_DIR/main.swift"

# 编译
cd "$TMP_DIR"
swiftc -o "Start" main.swift

# 打包 .app
mkdir -p "$OUTPUT_PATH/Start.app/Contents/MacOS"
cp "Start" "$OUTPUT_PATH/Start.app/Contents/MacOS/"

# 创建 Info.plist
cat > "$OUTPUT_PATH/Start.app/Contents/Info.plist" << EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>CFBundleExecutable</key>
    <string>Start</string>
    <key>CFBundleIdentifier</key>
    <string>com.openclaw.start</string>
    <key>CFBundleName</key>
    <string>Start</string>
    <key>CFBundlePackageType</key>
    <string>APPL</string>
    <key>LSUIElement</key>
    <true/>
</dict>
</plist>
EOF

echo "  ✅ Start.app 已创建"

# ========== 构建 Controller.app（可选）==========
if [ "$BUILD_CONTROLLER" = "1" ]; then
    echo ""
    echo "📦 构建 Controller.app..."
    
    # 替换占位符
    sed -e "s|{AI_NAME}|$AI_NAME|g" \
        -e "s|{WORKSPACE_PATH}|$WORKSPACE_PATH|g" \
        "$(dirname "$0")/../src/Controller/Controller.swift" > "$TMP_DIR/Controller.swift"
    
    # 编译（需要 Swift Package）
    mkdir -p "$TMP_DIR/Controller"
    cd "$TMP_DIR/Controller"
    
    swift package init --type executable --name Controller
    cp "$TMP_DIR/Controller.swift" Sources/Controller/main.swift
    
    # 添加依赖
    cat > Package.swift << 'EOF'
// swift-tools-version:5.9
import PackageDescription

let package = Package(
    name: "Controller",
    platforms: [.macOS(.v14)],
    products: [.executable(name: "Controller", targets: ["Controller"])],
    targets: [.executableTarget(name: "Controller")]
)
EOF
    
    swift build -c release
    
    # 打包
    mkdir -p "$OUTPUT_PATH/$AI_NAME Controller.app/Contents/MacOS"
    cp .build/release/Controller "$OUTPUT_PATH/$AI_NAME Controller.app/Contents/MacOS/"
    
    # Info.plist
    cat > "$OUTPUT_PATH/$AI_NAME Controller.app/Contents/Info.plist" << EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>CFBundleExecutable</key>
    <string>Controller</string>
    <key>CFBundleIdentifier</key>
    <string>com.openclaw.controller</string>
    <key>CFBundleName</key>
    <string>$AI_NAME Controller</string>
    <key>CFBundlePackageType</key>
    <string>APPL</string>
    <key>LSUIElement</key>
    <true/>
</dict>
</plist>
EOF
    
    echo "  ✅ $AI_NAME Controller.app 已创建"
fi

# ========== 完成 ==========
echo ""
echo "✅ 构建完成！"
echo "  输出位置: $OUTPUT_PATH"
echo ""
echo "使用说明:"
echo "  1. 双击 Start.app 启动/重启 Gateway"
echo "  2. 首次运行需要授权 Terminal 完全磁盘访问权限"

if [ "$BUILD_CONTROLLER" = "1" ]; then
    echo "  3. $AI_NAME Controller.app 会在状态栏显示监控图标"
fi

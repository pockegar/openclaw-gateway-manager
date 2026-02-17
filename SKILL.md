---
name: start-openclaw-app
description: 创建 macOS 应用来启动和管理 OpenClaw Gateway。包含智能启动器（自动判断启动/重启）和可选的状态监控器（Menu Bar 图标）。
---

# Start OpenClaw App

创建 macOS 应用来启动和管理 OpenClaw Gateway。

## 包含的应用

| 应用 | 功能 | 适用场景 |
|------|------|---------|
| **Start.app** | 智能启动/重启 Gateway | 必需基础工具 |
| **{AI_NAME} Controller.app** | 状态栏监控 + 一键重启 | 可选增强功能 |

## 功能特点

### Start.app
- 🚀 智能判断：Gateway 运行中→重启，未运行→启动
- 🔒 通过 Terminal 启动，保持完全磁盘访问权限
- 📱 可选 iMessage 启动通知
- 🦞 可自定义图标和名称

### Controller.app（可选）
- 🦞 状态栏图标显示 Gateway 状态
- 🟢🟡🔴 彩色状态指示（运行/警告/停止）
- 🔄 一键重启 Gateway
- 📊 快速打开 Dashboard

## 使用方式

### 快速开始

```bash
# 设置你的 AI 助手名字（可选，默认 Tony）
export AI_NAME="Tony"

# 设置工作区路径（可选，默认 ~/.openclaw/workspace）
export WORKSPACE_PATH="$HOME/.openclaw/workspace"

# 设置输出路径（可选，默认 ~/Desktop）
export OUTPUT_PATH="$HOME/Desktop"

# 构建 Start.app
cd /path/to/start-openclaw-app
./scripts/build.sh

# 同时构建 Controller.app
BUILD_CONTROLLER=1 ./scripts/build.sh
```

### 手动创建（AppleScript 方式）

如果不想使用 Swift 版本，可以使用 AppleScript 创建简单的启动器：

```bash
# 创建 Start.app（AppleScript 版本）
osascript -e '
tell application "Terminal"
    do script "cd ~/.openclaw/workspace && nohup openclaw gateway > /tmp/openclaw.log 2>&1 &"
    activate
end tell
'
osacompile -o "$HOME/Desktop/Start.app"
```

## 首次使用配置

### 1. 给 Terminal 完全磁盘访问权限

**为什么需要：**
- Gateway 需要访问 iMessage 数据库（`/Users/{user}/Library/Messages/chat.db`）
- 只有 Terminal 能正确获取此权限

**设置步骤：**
1. 系统设置 → 隐私与安全性 → 完全磁盘访问权限
2. 点击 + 添加 Terminal.app
3. 重启 Gateway（通过 Start.app）

### 2. 禁用 LaunchAgent（避免权限冲突）

```bash
launchctl unload ~/Library/LaunchAgents/ai.openclaw.gateway.plist 2>/dev/null
rm ~/Library/LaunchAgents/ai.openclaw.gateway.plist 2>/dev/null
```

**原因：** LaunchAgent 启动的 Gateway 没有 Terminal 的完全磁盘权限，iMessage 会失效。

## 配置说明

### 环境变量

| 变量 | 默认值 | 说明 |
|------|--------|------|
| `AI_NAME` | `Tony` | AI 助手名字，用于应用命名和消息 |
| `WORKSPACE_PATH` | `~/.openclaw/workspace` | OpenClaw 工作区路径 |
| `OUTPUT_PATH` | `~/Desktop` | 应用输出位置 |
| `BUILD_CONTROLLER` | `0` | 是否同时构建 Controller.app (0/1) |

### 自定义 iMessage 通知

编辑 `src/Start/main.swift`，取消注释并修改：

```swift
// 发送 iMessage 通知（可选）
func sendNotification(aiName: String, recipient: String) {
    let message = "🦞 \(aiName) 已上线待命"
    // ... iMessage 发送逻辑
}
```

## 添加到开机启动（可选）

```bash
# Start.app
osascript -e 'tell application "System Events" to make login item at end with properties {path:"'$HOME'/Desktop/Start.app", name:"Start", hidden:false}'

# Controller.app（可选）
osascript -e 'tell application "System Events" to make login item at end with properties {path:"'$HOME'/Desktop/'$AI_NAME' Controller.app", name:"'$AI_NAME' Controller", hidden:false}'
```

## 故障排除

### iMessage 显示"未配置"

**症状：** Gateway 运行但 iMessage 通道显示错误

**解决：**
1. 确认 Terminal 有完全磁盘访问权限
2. 使用 Start.app 重启 Gateway
3. 检查 `openclaw status` 中 iMessage 状态

### 双击 Start.app 无反应

**检查：**
1. 查看 `/tmp/openclaw.log` 错误日志
2. 确认 `openclaw` 命令在 PATH 中
3. 确认工作区路径正确

### Controller.app 不显示图标

**可能原因：**
- 状态栏图标被其他应用挤到"..."菜单中
- 尝试点击状态栏空白区域查看

## 源码结构

```
start-openclaw-app/
├── SKILL.md                    # 本文件
├── scripts/
│   └── build.sh               # 构建脚本
└── src/
    ├── Start/
    │   └── main.swift         # Start.app 源码
    └── Controller/
        └── Controller.swift   # Controller.app 源码
```

## 许可证

MIT License - 可自由修改和分享

## 致谢

基于 OpenClaw 官方文档和最佳实践构建

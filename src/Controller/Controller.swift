// Controller.swift - 通用 OpenClaw Gateway 状态监控器
// 使用占位符: {AI_NAME}, {WORKSPACE_PATH}

import SwiftUI
import AppKit

class MenuBarController: ObservableObject {
    private var statusItem: NSStatusItem!
    private var gatewayManager: GatewayManager!
    private var statusCheckTimer: Timer?
    
    @Published var gatewayRunning: Bool = false
    let aiName = "{AI_NAME}"
    
    init() {
        gatewayManager = GatewayManager()
        
        // 创建状态栏图标（使用系统共享实例）
        let statusBar = NSStatusBar.system
        statusItem = statusBar.statusItem(withLength: NSStatusItem.variableLength)
        
        if let button = statusItem.button {
            // 使用文字作为图标（最可靠的方式）
            button.title = "🦞"
            button.action = #selector(showMenu)
            button.target = self
        }
        
        // 初始检查状态
        checkStatus()
        
        // 定时检查状态（每5秒）
        statusCheckTimer = Timer.scheduledTimer(withTimeInterval: 5.0, repeats: true) { [weak self] _ in
            self?.checkStatus()
        }
    }
    
    @objc func showMenu() {
        // 创建菜单
        let menu = NSMenu()
        
        // 标题项（不可点击）
        let titleItem = NSMenuItem()
        titleItem.title = "🦞 \(aiName) Controller"
        titleItem.isEnabled = false
        menu.addItem(titleItem)
        
        menu.addItem(NSMenuItem.separator())
        
        // 状态显示项
        let statusItem = NSMenuItem()
        statusItem.title = gatewayRunning ? "Gateway: 运行中 ✅" : "Gateway: 已停止 ❌"
        statusItem.isEnabled = false
        menu.addItem(statusItem)
        
        menu.addItem(NSMenuItem.separator())
        
        // 重启 Gateway
        let restartItem = NSMenuItem(
            title: "重启 Gateway",
            action: #selector(restartGateway),
            keyEquivalent: ""
        )
        restartItem.target = self
        menu.addItem(restartItem)
        
        // 打开 Dashboard
        let dashboardItem = NSMenuItem(
            title: "打开 Dashboard",
            action: #selector(openDashboard),
            keyEquivalent: ""
        )
        dashboardItem.target = self
        menu.addItem(dashboardItem)
        
        menu.addItem(NSMenuItem.separator())
        
        // 退出
        let quitItem = NSMenuItem(
            title: "退出",
            action: #selector(quitApp),
            keyEquivalent: "q"
        )
        quitItem.target = self
        menu.addItem(quitItem)
        
        // 显示菜单
        self.statusItem.menu = menu
        self.statusItem.button?.performClick(nil)
        self.statusItem.menu = nil
    }
    
    func checkStatus() {
        gatewayRunning = gatewayManager.isGatewayRunning()
        updateIcon()
    }
    
    func updateIcon() {
        // 图标使用 emoji，无需额外配置
    }
    
    @objc func restartGateway() {
        gatewayManager.restartGateway()
        // 5秒后检查状态（给 Gateway 足够启动时间）
        DispatchQueue.main.asyncAfter(deadline: .now() + 5) {
            self.checkStatus()
        }
    }
    
    @objc func openDashboard() {
        if let url = URL(string: "http://127.0.0.1:18789") {
            NSWorkspace.shared.open(url)
        }
    }
    
    @objc func quitApp() {
        NSApplication.shared.terminate(nil)
    }
}

class GatewayManager {
    let workspacePath = "{WORKSPACE_PATH}"
    
    func isGatewayRunning() -> Bool {
        let task = Process()
        task.launchPath = "/usr/bin/pgrep"
        task.arguments = ["-f", "openclaw-gateway"]
        
        do {
            try task.run()
            task.waitUntilExit()
            return task.terminationStatus == 0
        } catch {
            return false
        }
    }
    
    func restartGateway() {
        // 使用 New Start.app 相同的完整 bash 脚本
        let bashScript = """
        echo '🔍 检查 OpenClaw Gateway 状态...'
        
        # 检查是否有 Gateway 在运行
        PID=$(ps aux | grep 'openclaw-gateway' | grep -v grep | awk '{print $2}' | head -1)
        
        if [ -n "$PID" ]; then
            echo "🛑 发现 Gateway 正在运行 (PID: $PID)，准备重启..."
            kill $PID 2>/dev/null
            sleep 3
            # 确认是否已停止
            if ps -p $PID > /dev/null 2>&1; then
                echo '⚠️  强制终止...'
                kill -9 $PID 2>/dev/null
                sleep 1
            fi
            echo '✅ 已停止旧进程'
        else
            echo '🚀 未发现运行中的 Gateway，准备启动...'
        fi
        
        echo '📁 切换到工作目录...'
        cd \(workspacePath)
        
        echo '🚀 启动 Gateway...'
        nohup openclaw gateway > /tmp/openclaw.log 2>&1 &
        
        sleep 2
        
        # 检查是否启动成功
        NEW_PID=$(ps aux | grep 'openclaw-gateway' | grep -v grep | awk '{print $2}' | head -1)
        
        if [ -n "$NEW_PID" ]; then
            echo "✅ Gateway 启动成功！PID: $NEW_PID"
        else
            echo '❌ Gateway 启动失败，请检查日志: /tmp/openclaw.log'
        fi

        # 自动关闭 Terminal（方案 B）
        echo '🎉 完成！窗口将在 3 秒后关闭...'
        sleep 3
        exit
        """
        
        // 使用 osascript 执行 AppleScript，发送到 Terminal
        let appleScript = """
        tell application "Terminal"
            if not running then launch
            do script "\(bashScript)"
        end tell
        """
        
        let task = Process()
        task.launchPath = "/usr/bin/osascript"
        task.arguments = ["-e", appleScript]
        
        // 捕获输出用于调试
        let outputPipe = Pipe()
        let errorPipe = Pipe()
        task.standardOutput = outputPipe
        task.standardError = errorPipe
        
        do {
            try task.run()
            task.waitUntilExit()
            
            let outputData = outputPipe.fileHandleForReading.readDataToEndOfFile()
            let errorData = errorPipe.fileHandleForReading.readDataToEndOfFile()
            let output = String(data: outputData, encoding: .utf8) ?? ""
            let error = String(data: errorData, encoding: .utf8) ?? ""
            
            if task.terminationStatus == 0 {
                NSLog("✅ AppleScript 执行成功")
                if !output.isEmpty { NSLog("输出: \(output)") }
            } else {
                NSLog("❌ AppleScript 执行失败，退出码: \(task.terminationStatus)")
                if !error.isEmpty { NSLog("错误: \(error)") }
            }
        } catch {
            NSLog("❌ 执行失败: \(error)")
        }
    }
}

@main
struct ControllerApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    
    var body: some Scene {
        Settings {
            EmptyView()
        }
    }
}

class AppDelegate: NSObject, NSApplicationDelegate {
    var menuBarController: MenuBarController!
    
    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.setActivationPolicy(.accessory)
        menuBarController = MenuBarController()
    }
}

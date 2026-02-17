// Start.swift - 通用 OpenClaw Gateway 启动器
// 使用占位符: {WORKSPACE_PATH}, {AI_NAME}

import Foundation

class GatewayLauncher {
    
    static func main() {
        let workspacePath = "{WORKSPACE_PATH}"
        let aiName = "{AI_NAME}"
        
        print("🚀 Starting OpenClaw Gateway...")
        
        // 检查 Gateway 是否已在运行
        let isRunning = checkGatewayStatus()
        
        if isRunning {
            print("🛑 Gateway already running, restarting...")
            killGateway()
            Thread.sleep(forTimeInterval: 2)
        } else {
            print("🚀 Gateway not running, starting...")
        }
        
        // 启动 Gateway
        startGateway(workspacePath: workspacePath)
        
        print("✅ Gateway started successfully!")
        
        // 可选：发送 iMessage 通知
        // sendNotification(aiName: aiName, recipient: "{RECIPIENT}")
        
        // 保持运行（LSUIElement 需要）
        RunLoop.main.run()
    }
    
    static func checkGatewayStatus() -> Bool {
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
    
    static func killGateway() {
        let task = Process()
        task.launchPath = "/usr/bin/pkill"
        task.arguments = ["-f", "openclaw-gateway"]
        try? task.run()
    }
    
    static func startGateway(workspacePath: String) {
        let script = """
        cd \(workspacePath) && nohup openclaw gateway > /tmp/openclaw.log 2>&1 &
        """
        
        let task = Process()
        task.launchPath = "/bin/bash"
        task.arguments = ["-c", script]
        
        do {
            try task.run()
        } catch {
            print("❌ Failed to start Gateway: \(error)")
        }
    }
}

GatewayLauncher.main()

import SwiftUI

@main
struct KeyKeyApp: App {
    init() {
        // 啟動 HID 管理器熱插拔監聽
        _ = HIDManager.shared
    }

    var body: some Scene {
        WindowGroup {
            MainView()
        }
        .windowStyle(.titleBar)
        .windowToolbarStyle(.unified(showsTitle: true))
        .commands {
            SidebarCommands()
        }
    }
}

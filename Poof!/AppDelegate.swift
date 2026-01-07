import Cocoa

class AppDelegate: NSObject, NSApplicationDelegate {
    var menuBarController: MenuBarController?
    var dockMonitor: DockMonitor?
    
    func applicationDidFinishLaunching(_ aNotification: Notification) {
        // Hide Dock icon
        NSApp.setActivationPolicy(.accessory)
        
        // Hide the main window immediately without showing it
        if let window = NSApplication.shared.windows.first {
            window.setIsVisible(false)
        }
        
        // Create menu bar controller
        menuBarController = MenuBarController()
        menuBarController?.setup()
        
        // Check accessibility permissions
        checkAccessibilityPermissions()
    }
    
    func checkAccessibilityPermissions() {
        
        let options: NSDictionary = [kAXTrustedCheckOptionPrompt.takeUnretainedValue() as String: true]
        let accessEnabled = AXIsProcessTrustedWithOptions(options)
        
        menuBarController?.updatePermissionStatus()
        
        if accessEnabled {
            dockMonitor = DockMonitor()
            dockMonitor?.startMonitoring()
        } else {
            DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                self.recheckAccessibilityPermissions()
            }
        }
    }
    
    func recheckAccessibilityPermissions() {
        let accessEnabled = AXIsProcessTrusted()
        
        menuBarController?.updatePermissionStatus()
        
        if accessEnabled {
            dockMonitor = DockMonitor()
            dockMonitor?.startMonitoring()
        } else {
            DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                self.recheckAccessibilityPermissions()
            }
        }
    }
}

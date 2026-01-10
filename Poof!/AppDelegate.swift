import Cocoa

class AppDelegate: NSObject, NSApplicationDelegate {

    private var menuBarController: MenuBarController?
    private var dockMonitor: DockMonitor?

    func applicationDidFinishLaunching(_ aNotification: Notification) {
        // Menu bar–only app
        NSApp.setActivationPolicy(.accessory)

        // Hide any automatically created window
        if let window = NSApplication.shared.windows.first {
            window.setIsVisible(false)
        }

        // Defer *all* UI and permission work until the system is ready
        DispatchQueue.main.asyncAfter(deadline: .now() + 30) {
            self.startApplication()
        }
    }

    private func startApplication() {
        // Create menu bar UI
        menuBarController = MenuBarController()
        menuBarController?.setup()

        // Start permission flow only after UI exists and system is stable
        checkAccessibilityPermissions()
    }

    // MARK: - Accessibility

    private func checkAccessibilityPermissions() {
        let options: NSDictionary = [
            kAXTrustedCheckOptionPrompt.takeUnretainedValue() as String: true
        ]

        let accessEnabled = AXIsProcessTrustedWithOptions(options)

        menuBarController?.updatePermissionStatus()

        if accessEnabled {
            startDockMonitoring()
        } else {
            scheduleAccessibilityRecheck()
        }
    }

    func recheckAccessibilityPermissions() {
        let accessEnabled = AXIsProcessTrusted()

        menuBarController?.updatePermissionStatus()

        if accessEnabled {
            startDockMonitoring()
        } else {
            scheduleAccessibilityRecheck()
        }
    }

    private func scheduleAccessibilityRecheck() {
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
            self.recheckAccessibilityPermissions()
        }
    }

    private func startDockMonitoring() {
        guard dockMonitor == nil else { return }
        dockMonitor = DockMonitor()
        dockMonitor?.startMonitoring()
    }
}

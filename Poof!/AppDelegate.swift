import Cocoa

class AppDelegate: NSObject, NSApplicationDelegate {

    private var menuBarController: MenuBarController?
    private var dockMonitor: DockMonitor?

    func applicationDidFinishLaunching(_ aNotification: Notification) {

        DispatchQueue.main.asyncAfter(deadline: .now() + 30) {
            NSApp.setActivationPolicy(.accessory)
            self.startApplication()
        }
    }

    private func startApplication() {
        menuBarController = MenuBarController()
        menuBarController?.setup()

        checkAccessibilityPermissions()
    }

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

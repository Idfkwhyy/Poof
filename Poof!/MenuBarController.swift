import Cocoa
import ServiceManagement

class MenuBarController: NSObject {
    private var statusItem: NSStatusItem?
    
    func setup() {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        
        if let button = statusItem?.button {
            updateMenuBarIcon()
            button.action = #selector(statusBarButtonClicked)
            button.target = self
        }
        
        updateMenu()
    }
    
    func updateMenu() {
        let menu = NSMenu()
        
        let aboutItem = NSMenuItem(title: "About", action: #selector(showAbout), keyEquivalent: "")
        aboutItem.target = self
        menu.addItem(aboutItem)
        
        menu.addItem(NSMenuItem.separator())
        
        let permissionItem = NSMenuItem(title: "Accessibility Permission", action: #selector(requestPermissions), keyEquivalent: "")
        permissionItem.target = self
        permissionItem.state = AXIsProcessTrusted() ? .on : .off
        menu.addItem(permissionItem)
        
        let launchAtLoginItem = NSMenuItem(title: "Launch at Login", action: #selector(toggleLaunchAtLogin), keyEquivalent: "")
        launchAtLoginItem.target = self
        menu.addItem(launchAtLoginItem)
        
        menu.addItem(NSMenuItem.separator())
        
        menu.addItem(NSMenuItem(title: "Quit", action: #selector(NSApplication.terminate(_:)), keyEquivalent: "q"))
        
        statusItem?.menu = menu
    }
    
    func updateMenuBarIcon() {
        guard let button = statusItem?.button else { return }
        
        let isEnabled = AXIsProcessTrusted()
        let iconName = isEnabled ? "iconEnabled" : "iconDisabled"
        
        if let icon = NSImage(named: iconName) {
            icon.isTemplate = true
            button.image = icon
        } else {
            print("Could not load \(iconName)")
            button.image = NSImage(systemSymbolName: isEnabled ? "checkmark.circle.fill" : "xmark.circle.fill",
                                  accessibilityDescription: "Poof!")
        }
    }
    
    func updatePermissionStatus() {
        guard let menu = statusItem?.menu else { return }
        
        if menu.items.count > 2 {
            let permissionItem = menu.items[2]
            let isEnabled = AXIsProcessTrusted()
            
            permissionItem.title = "Accessibility Permission"
            permissionItem.state = isEnabled ? .on : .off
        }
        
        updateMenuBarIcon()
    }
    
    @objc func statusBarButtonClicked() {
        statusItem?.menu?.popUp(positioning: nil, at: NSEvent.mouseLocation, in: nil)
    }
    
    @objc func showAbout() {
        let windowWidth: CGFloat = 280
        let windowHeight: CGFloat = 150
        
        let aboutWindow = NSWindow(
            contentRect: NSMakeRect(0, 0, windowWidth, windowHeight),
            styleMask: [.titled, .closable],
            backing: .buffered,
            defer: false
        )
        
        aboutWindow.title = ""
        aboutWindow.isReleasedWhenClosed = false
        aboutWindow.level = .floating
        aboutWindow.center()
        
        let contentView = NSView(frame: NSMakeRect(0, 0, windowWidth, windowHeight))
        
        let info = Bundle.main.infoDictionary
        
        let appName =
            info?["CFBundleDisplayName"] as? String ??
            info?["CFBundleName"] as? String ??
            "Poof!"
        
        let version =
            info?["CFBundleShortVersionString"] as? String ?? "1.0"
        
        let build =
            info?["CFBundleVersion"] as? String ?? "1"
        
        let developer =
            info?["DeveloperName"] as? String ?? "Unknown Developer"
        
        let iconSize: CGFloat = 60
        let spacing: CGFloat = 4
        let totalContentHeight = iconSize + 45
        let startY = (windowHeight - totalContentHeight) / 2 + iconSize
        
        let appIcon = NSImageView(
            frame: NSRect(
                x: (windowWidth - iconSize) / 2,
                y: startY,
                width: iconSize,
                height: iconSize
            )
        )
        appIcon.image = NSApp.applicationIconImage
        
        let appNameLabel = NSTextField(labelWithString: appName)
        appNameLabel.frame = NSRect(
            x: 0,
            y: startY - (20 + spacing),
            width: windowWidth,
            height: 20
        )
        appNameLabel.alignment = .center
        appNameLabel.font = NSFont.boldSystemFont(ofSize: 14)
        
        let versionLabel = NSTextField(
            labelWithString: "Version \(version) (\(build))"
        )
        versionLabel.frame = NSRect(
            x: 0,
            y: startY - (40 + 2 * spacing),
            width: windowWidth,
            height: 20
        )
        versionLabel.alignment = .center
        versionLabel.font = NSFont.systemFont(ofSize: 10)
        
        let authorLabel = NSTextField(
            labelWithString: "by \(developer)"
        )
        authorLabel.frame = NSRect(
            x: 0,
            y: startY - (65 + 3 * spacing),
            width: windowWidth,
            height: 20
        )
        authorLabel.alignment = .center
        authorLabel.font = NSFont.systemFont(ofSize: 10)
        authorLabel.textColor = .secondaryLabelColor
        
        contentView.addSubview(appIcon)
        contentView.addSubview(appNameLabel)
        contentView.addSubview(versionLabel)
        contentView.addSubview(authorLabel)
        
        aboutWindow.contentView = contentView
        aboutWindow.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
    }
    
    @objc func requestPermissions() {
        
        let currentlyEnabled = AXIsProcessTrusted()
        
        if currentlyEnabled {
            let alert = NSAlert()
            alert.messageText = "Accessibility Permission"
            alert.informativeText = "Poof! already has accessibility permission and is working correctly."
            alert.alertStyle = .informational
            alert.addButton(withTitle: "OK")
            alert.runModal()
        } else {
            let alert = NSAlert()
            alert.messageText = "Accessibility Permission Required"
            alert.informativeText = "Poof! needs accessibility permission to detect dock item removal.\n\nClick 'Open System Preferences' to grant permission."
            alert.alertStyle = .warning
            alert.addButton(withTitle: "Open System Preferences")
            alert.addButton(withTitle: "Cancel")
            
            let response = alert.runModal()
            
            if response == .alertFirstButtonReturn {
                let prefpaneUrl = "x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility"
                if let url = URL(string: prefpaneUrl) {
                    NSWorkspace.shared.open(url)
                }
                
                if let appDelegate = NSApplication.shared.delegate as? AppDelegate {
                    appDelegate.recheckAccessibilityPermissions()
                }
            }
        }
    }
    
    @objc func toggleLaunchAtLogin() {
        showManualLaunchAtLoginInstructions()
    }
    
    private func showManualLaunchAtLoginInstructions() {
        let alert = NSAlert()
        alert.messageText = "Launch at Login"
        alert.informativeText = "To keep the app free of dependencies and give the user full control, if you want to enable Launch at Login:\n\n1. Open System Preferences/Settings\n2. Go to Users & Groups (or General → Login Items on macOS 13+)\n3. Click on your username\n4. Select 'Login Items'\n5. Click the '+' button and add Poof!\n\nWould you like to open Login Items now?"
        alert.alertStyle = .informational
        alert.addButton(withTitle: "Open Login Items")
        alert.addButton(withTitle: "Cancel")
        
        let response = alert.runModal()
        
        if response == .alertFirstButtonReturn {
            if #available(macOS 13.0, *) {
                if let url = URL(string: "x-apple.systempreferences:com.apple.LoginItems-Settings.extension") {
                    NSWorkspace.shared.open(url)
                }
            } else {
                let script = """
                tell application "System Preferences"
                    activate
                    set current pane to pane "com.apple.preferences.users"
                    reveal anchor "loginItems" of pane "com.apple.preferences.users"
                end tell
                """
                
                if let appleScript = NSAppleScript(source: script) {
                    var error: NSDictionary?
                    appleScript.executeAndReturnError(&error)
                    
                    if let error = error {
                        print("AppleScript error: \(error)")
                        // Fallback: just open System Preferences
                        NSWorkspace.shared.open(URL(fileURLWithPath: "/System/Applications/System Preferences.app"))
                    }
                }
            }
        }
    }
}

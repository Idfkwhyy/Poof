import Cocoa
import ApplicationServices

class DockMonitor {
    private var mouseDownMonitor: Any?
    private var mouseDragMonitor: Any?
    private var mouseUpMonitor: Any?
    private var dragStartLocation: NSPoint?
    private var isDraggingFromDock = false
    private var currentPoofWindow: PoofWindow?
    private var dockPID: pid_t = 0
    private var isHoveringDock = false
    
    private let removeThreshold: CGFloat = 100.0
    
    func startMonitoring() {
        
        if let dockApp = NSRunningApplication.runningApplications(withBundleIdentifier: "com.apple.dock").first {
            dockPID = dockApp.processIdentifier
        }
        
        startMouseMonitoring()
    }
    
    private func startMouseMonitoring() {
        mouseDownMonitor = NSEvent.addGlobalMonitorForEvents(matching: [.leftMouseDown]) { [weak self] event in
            let location = NSEvent.mouseLocation
            self?.handleMouseDown(at: location)
        }
        
        mouseDragMonitor = NSEvent.addGlobalMonitorForEvents(matching: [.leftMouseDragged]) { [weak self] event in
            let location = NSEvent.mouseLocation
            self?.handleMouseDragged(at: location)
        }
        
        mouseUpMonitor = NSEvent.addGlobalMonitorForEvents(matching: [.leftMouseUp]) { [weak self] event in
            let location = NSEvent.mouseLocation
            self?.handleMouseUp(at: location)
        }
    }
    
    private func handleMouseDown(at location: NSPoint) {
        guard let screen = NSScreen.main else { return }
        let dockRect = getDockRect(for: screen)
        
        if dockRect.contains(location) {
            if isDockElementAtLocation(location) {
                dragStartLocation = location
                isDraggingFromDock = true
                isHoveringDock = true
            } else {
                isDraggingFromDock = false
                isHoveringDock = false
            }
        } else {
            isDraggingFromDock = false
            isHoveringDock = false
        }
    }
    
    private func isDockElementAtLocation(_ location: NSPoint) -> Bool {
        let systemLocation = CGPoint(x: location.x, y: CGFloat(NSScreen.main?.frame.height ?? 0) - location.y)
        
        var element: AXUIElement?
        let result = AXUIElementCopyElementAtPosition(
            AXUIElementCreateSystemWide(),
            Float(systemLocation.x),
            Float(systemLocation.y),
            &element
        )
        
        guard result == .success, let element = element else {
            return false
        }
        
        var pid: pid_t = 0
        let pidResult = AXUIElementGetPid(element, &pid)
        
        return pidResult == .success && pid == dockPID
    }
    
    private func handleMouseDragged(at location: NSPoint) {
        if isDraggingFromDock {
            guard let screen = NSScreen.main else { return }
            let dockRect = getDockRect(for: screen)
            
            if !dockRect.insetBy(dx: -30, dy: -30).contains(location) {
            }
        }
    }
    
    private func handleMouseUp(at location: NSPoint) {
        guard isDraggingFromDock else {
            isHoveringDock = false
            return
        }
        
        guard let screen = NSScreen.main else { return }
        let dockRect = getDockRect(for: screen)
        
        if !dockRect.contains(location) && isBeyondRemoveThreshold(location, dockRect: dockRect) {
            let iconSize = getDockIconSize(magnified: true)
            showPoofAnimation(at: location, size: iconSize)
        } else {
        }
        
        isDraggingFromDock = false
        isHoveringDock = false
        dragStartLocation = nil
    }
    
    private func isBeyondRemoveThreshold(_ location: NSPoint, dockRect: NSRect) -> Bool {
        let dockOrientation = getDockOrientation()
        
        switch dockOrientation {
        case .bottom:
            let distanceFromDock = location.y - dockRect.maxY
            return distanceFromDock > removeThreshold
            
        case .left:
            let distanceFromDock = location.x - dockRect.maxX
            return distanceFromDock > removeThreshold
            
        case .right:
            let distanceFromDock = dockRect.minX - location.x
            return distanceFromDock > removeThreshold
        }
    }
    
    private func getDockIconSize(magnified: Bool = false) -> CGFloat {
        CFPreferencesAppSynchronize("com.apple.dock" as CFString)
        
        guard let dockPlist = UserDefaults.standard.persistentDomain(forName: "com.apple.dock") else {
            return 77.0
        }
        
        let baseSize = dockPlist["tilesize"] as? CGFloat ?? 57.0
        
        if magnified {
            let magnificationEnabled = dockPlist["magnification"] as? Bool ?? false
            
            if magnificationEnabled {
                let largeSize = dockPlist["largesize"] as? CGFloat ?? 128.0
                return largeSize + 20
            }
        }
        
        return baseSize + 20
    }
    
    private func getDockRect(for screen: NSScreen) -> NSRect {
        let screenFrame = screen.frame
        let dockOrientation = getDockOrientation()
        let dockSize: CGFloat = 80
        
        switch dockOrientation {
        case .bottom:
            return NSRect(x: 0, y: 0, width: screenFrame.width, height: dockSize)
        case .left:
            return NSRect(x: 0, y: 0, width: dockSize, height: screenFrame.height)
        case .right:
            return NSRect(x: screenFrame.width - dockSize, y: 0, width: dockSize, height: screenFrame.height)
        }
    }
    
    private enum DockOrientation {
        case bottom, left, right
    }
    
    private func getDockOrientation() -> DockOrientation {
        if let orientation = UserDefaults.standard.persistentDomain(forName: "com.apple.dock")?["orientation"] as? String {
            switch orientation {
            case "left": return .left
            case "right": return .right
            default: return .bottom
            }
        }
        return .bottom
    }
    
    private func showPoofAnimation(at point: NSPoint, size: CGFloat) {
        
        if let existingWindow = currentPoofWindow {
            existingWindow.orderOut(nil)
            currentPoofWindow = nil
        }
        
        currentPoofWindow = PoofWindow(at: point, size: size)
        guard let window = currentPoofWindow else {
            return
        }
        
        window.makeKeyAndOrderFront(nil)
        
        let strongWindow = window
        
        window.playAnimation { [weak self] in
            DispatchQueue.main.async {
                strongWindow.orderOut(nil)
                
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
                    self?.currentPoofWindow = nil
                }
            }
        }
    }
    
    deinit {
        if let monitor = mouseDownMonitor {
            NSEvent.removeMonitor(monitor)
        }
        if let monitor = mouseDragMonitor {
            NSEvent.removeMonitor(monitor)
        }
        if let monitor = mouseUpMonitor {
            NSEvent.removeMonitor(monitor)
        }
    }
}

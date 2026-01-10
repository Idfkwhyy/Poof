import SwiftUI

@main
struct Poof_App: App {

    @NSApplicationDelegateAdaptor(AppDelegate.self)
    private var appDelegate

    var body: some Scene {
        // No windows; menu bar app only
        Settings {
            EmptyView()
                .hidden()
        }
    }
}

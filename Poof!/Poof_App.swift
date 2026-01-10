import SwiftUI

@main
struct Poof_App: App {

    @NSApplicationDelegateAdaptor(AppDelegate.self)
    private var appDelegate

    var body: some Scene {
        Settings {
            EmptyView()
                .hidden()
        }
    }
}

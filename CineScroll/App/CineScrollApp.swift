import SwiftUI

/// SwiftUI entry point for the CineScroll application.
@main
struct CineScrollApp: App {
    private let dependencies: AppDependencies = {
        UITestConfiguration.applyIfNeeded()
        return UITestConfiguration.isActive ? .uiTest() : .live()
    }()

    var body: some Scene {
        WindowGroup {
            RootView()
                .environment(\.appDependencies, dependencies)
        }
    }
}

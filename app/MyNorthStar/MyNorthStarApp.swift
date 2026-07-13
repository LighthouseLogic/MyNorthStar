import SwiftUI
import SwiftData

@main
struct MyNorthStarApp: App {
    /// A dedicated store file so MyNorthStar never shares SwiftData's default
    /// store with other apps when running unsandboxed during development.
    private static let container: ModelContainer = {
        let base = URL.applicationSupportDirectory.appending(path: "MyNorthStar", directoryHint: .isDirectory)
        try? FileManager.default.createDirectory(at: base, withIntermediateDirectories: true)
        let configuration = ModelConfiguration(url: base.appending(path: "MyNorthStar.store"))
        do {
            return try ModelContainer(for: Project.self, configurations: configuration)
        } catch {
            fatalError("Could not create the MyNorthStar data store: \(error)")
        }
    }()

    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .modelContainer(Self.container)

        #if os(macOS)
        Settings {
            SettingsView()
                .frame(minWidth: 480, minHeight: 420)
        }
        #endif
    }
}

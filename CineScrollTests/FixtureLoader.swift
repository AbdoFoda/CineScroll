import Foundation

/// Loads JSON fixtures from the `Fixtures` directory next to this source file.
enum FixtureLoader {
    static func data(named name: String) throws -> Data {
        let url = URL(fileURLWithPath: #filePath)
            .deletingLastPathComponent()
            .appendingPathComponent("Fixtures/\(name).json")
        return try Data(contentsOf: url)
    }
}

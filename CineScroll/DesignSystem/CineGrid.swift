import SwiftUI

/// Shared grid configuration for movie collections.
enum CineGrid {
    static let columnCount = 2

    static var movieColumns: [GridItem] {
        Array(
            repeating: GridItem(.flexible(), spacing: CineSpacing.md),
            count: columnCount
        )
    }
}

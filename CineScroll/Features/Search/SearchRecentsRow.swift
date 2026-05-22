import SwiftUI

/// Horizontal strip of recent search chips.
struct SearchRecentsRow: View {
    let queries: [String]
    let onSelect: (String) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: CineSpacing.sm) {
            Text("Recent")
                .font(.headline)
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: CineSpacing.sm) {
                    ForEach(queries, id: \.self) { query in
                        Button { onSelect(query) } label: {
                            Text(query)
                                .font(.subheadline)
                                .padding(.horizontal, CineSpacing.md)
                                .padding(.vertical, CineSpacing.sm)
                                .background(.thinMaterial, in: Capsule())
                        }
                        .buttonStyle(.plain)
                        .accessibilityElement(children: .ignore)
                        .accessibilityLabel(query)
                        .accessibilityAddTraits(.isButton)
                        .cineAccessibility(AccessibilityID.recentChip(query))
                    }
                }
            }
        }
    }
}

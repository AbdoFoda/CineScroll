import SwiftUI

extension View {
    func cineZoomSource(id: Int, in namespace: Namespace.ID) -> some View {
        navigationTransition(.zoom(sourceID: id, in: namespace))
    }
}

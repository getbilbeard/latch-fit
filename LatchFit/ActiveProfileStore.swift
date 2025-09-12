import SwiftUI

final class ActiveProfileStore: ObservableObject {
    @AppStorage("activeProfileID") var activeProfileID: String?

    func setActive(_ id: String) {
        activeProfileID = id
        objectWillChange.send()
    }
}


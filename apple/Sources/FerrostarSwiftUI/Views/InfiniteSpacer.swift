import SwiftUI

public struct InfiniteSpacer: View {
    public init() {}

    public var body: some View {
        EmptyView()
            .frame(minWidth: 0,
                   maxWidth: .infinity,
                   minHeight: 0,
                   maxHeight: .infinity)
    }
}

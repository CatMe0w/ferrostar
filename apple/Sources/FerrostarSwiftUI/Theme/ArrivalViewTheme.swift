import SwiftUI

public enum ArrivalViewStyle: Equatable {
    /// The simplified/default which only shows actual values
    case simplified

    /// An expanded informational arrival view that labels each value.
    case informational
}

public protocol ArrivalViewTheme: Equatable {
    /// The style of the arrival view controls the general theme.
    var style: ArrivalViewStyle { get }

    /// The color for the measurement values (top row)
    var measurementColor: Color { get }

    /// The font for the measurement values (top row)
    var measurementFont: Font { get }

    /// The color for the secondary text.
    var secondaryColor: Color { get }

    /// The font for the secondary text.
    var secondaryFont: Font { get }

    /// The color of the background.
    var backgroundColor: Color { get }
}

public struct DefaultArrivalViewTheme: ArrivalViewTheme {
    public var style: ArrivalViewStyle = .simplified
    public var measurementColor: Color = .primary
    public var measurementFont: Font = .title2.bold()
    public var secondaryColor: Color = .secondary
    public var secondaryFont: Font = .subheadline
    public var backgroundColor: Color = .init(.systemBackground)

    public init() {}
}

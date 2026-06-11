// MARK: - FrameStyling

/// Defines how the dashboard frame and its visual elements are rendered.
///
/// Inject a custom implementation via `Application.override(\.frameStyling, with: …)`
/// to change the visual appearance without touching rendering logic.
public protocol FrameStyling: Sendable {

    /// The character used to draw horizontal borders.
    var horizontalBorder: Character { get }

    /// The character used to draw vertical borders.
    var verticalBorder: Character { get }

    /// The character used for the top-left corner.
    var cornerTopLeft: Character { get }

    /// The character used for the top-right corner.
    var cornerTopRight: Character { get }

    /// The character used for the bottom-left corner.
    var cornerBottomLeft: Character { get }

    /// The character used for the bottom-right corner.
    var cornerBottomRight: Character { get }

    /// The character used to fill the filled portion of a gauge bar.
    var gaugeFilled: Character { get }

    /// The character used to fill the empty portion of a gauge bar.
    var gaugeEmpty: Character { get }

    /// The total width of the dashboard frame (characters).
    var frameWidth: Int { get }

    /// The total number of bar segments in a gauge.
    var gaugeWidth: Int { get }
}

// MARK: - DefaultFrameStyling

/// The default ASCII-art styling for the live dashboard.
public struct DefaultFrameStyling: FrameStyling {

    /// Creates a new `DefaultFrameStyling`.
    public init() {}

    public var horizontalBorder: Character { "─" }
    public var verticalBorder: Character { "│" }
    public var cornerTopLeft: Character { "╭" }
    public var cornerTopRight: Character { "╮" }
    public var cornerBottomLeft: Character { "╰" }
    public var cornerBottomRight: Character { "╯" }
    public var gaugeFilled: Character { "█" }
    public var gaugeEmpty: Character { "░" }
    public var frameWidth: Int { 50 }
    public var gaugeWidth: Int { 30 }
}

// MARK: - PlainFrameStyling

/// A plain ASCII fallback styling with 7-bit characters, suitable for environments
/// that lack Unicode box-drawing support.
public struct PlainFrameStyling: FrameStyling {

    /// Creates a new `PlainFrameStyling`.
    public init() {}

    public var horizontalBorder: Character { "-" }
    public var verticalBorder: Character { "|" }
    public var cornerTopLeft: Character { "+" }
    public var cornerTopRight: Character { "+" }
    public var cornerBottomLeft: Character { "+" }
    public var cornerBottomRight: Character { "+" }
    public var gaugeFilled: Character { "#" }
    public var gaugeEmpty: Character { "." }
    public var frameWidth: Int { 50 }
    public var gaugeWidth: Int { 30 }
}

import Foundation

enum ValhallaError: Error, Hashable {
    case encodingNotUtf8(String)
    case valhallaError(Int, String)

    /// Thrown by the default `ValhallaProviding` implementations, so a
    /// conformer that predates an action reports it as unsupported rather
    /// than being forced to implement it.
    case unsupportedAction(String)
}

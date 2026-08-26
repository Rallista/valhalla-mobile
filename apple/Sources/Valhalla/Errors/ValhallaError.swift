import Foundation

/// Everything ``Valhalla`` throws.
///
/// The cases mirror Android's `ValhallaException` hierarchy so the two platforms
/// report the same failures under the same names:
///
/// | Swift | Kotlin |
/// | --- | --- |
/// | ``valhallaError(_:_:)`` | `ValhallaException.Internal` |
/// | ``notSupported(_:)`` | `ValhallaException.NotSupported` |
/// | ``closed`` | `IllegalStateException` from the closed guard |
/// | ``encodingNotUtf8(_:)`` | handled in `ValhallaActor.decode` |
/// | ``tzdataUnavailable(_:)`` | no equivalent; iOS ships its own tzdata |
public enum ValhallaError: Error, Hashable {

    /// A string could not be carried across the bridge as UTF-8.
    ///
    /// - Parameter field: which value failed, for diagnosis.
    case encodingNotUtf8(String)

    /// An error returned by the routing engine itself.
    ///
    /// See [Valhalla's internal error codes](https://valhalla.github.io/valhalla/api/turn-by-turn/api-reference/#internal-error-codes-and-conditions).
    /// A code of `-1` is the wrapper's own, used for failures Valhalla has no code for.
    ///
    /// - Parameters:
    ///   - code: Valhalla's error code, or `-1`.
    ///   - message: the message Valhalla produced. It may contain caller-supplied text.
    case valhallaError(Int, String)

    /// The requested response format cannot cross this bridge.
    ///
    /// `pbf` is protobuf rather than text, and `gpx` is not JSON, so neither can be
    /// decoded into the generated response types. Reach both through the raw methods.
    ///
    /// - Parameter format: the format that was asked for.
    case notSupported(String)

    /// An action was attempted after ``Valhalla/close()``.
    case closed

    /// The bundled timezone database could not be installed.
    ///
    /// Valhalla needs it for time-dependent routing. See <doc:/documentation/Valhalla>
    /// and <https://howardhinnant.github.io/date/tz.html#Installation>.
    ///
    /// - Parameter reason: what went wrong while installing it.
    case tzdataUnavailable(String)
}

extension ValhallaError: LocalizedError {

    public var errorDescription: String? {
        switch self {
        case .encodingNotUtf8(let field):
            return "\(field) could not be encoded as UTF-8."
        case .valhallaError(let code, let message):
            return "Valhalla error \(code): \(message)"
        case .notSupported(let format):
            return "The \(format) format is not currently supported."
        case .closed:
            return "This Valhalla instance is closed."
        case .tzdataUnavailable(let reason):
            return "The timezone database could not be installed: \(reason)"
        }
    }
}

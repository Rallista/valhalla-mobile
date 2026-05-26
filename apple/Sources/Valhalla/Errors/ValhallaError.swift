import Foundation

public enum ValhallaError: Error, Hashable {
    case encodingNotUtf8(String)
    case valhallaError(Int, String)
}

extension ValhallaError: LocalizedError {
    public var errorDescription: String? {
        switch self {
        case .encodingNotUtf8(let context):
            return "Encoding error (not UTF-8): \(context)"
        case .valhallaError(let code, let message):
            return "Valhalla error \(code): \(message)"
        }
    }
}

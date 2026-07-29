import ValhallaObjc
import ValhallaModels
import ValhallaConfigModels

public protocol ValhallaProviding {

    init(_ config: ValhallaConfig) throws

    init(configPath: String) throws

    func route(request: RouteRequest) throws -> RouteResponse

    /// Map-matches a GPS trace against the road graph
    /// and returns narrative maneuvers for it.
    func traceRoute(request: MapMatchRequest) throws -> MapMatchRouteResponse

    /// Map-matches a GPS trace and returns the matched edges
    /// and their attributes, rather than narrative directions.
    func traceAttributes(request: TraceAttributesRequest) throws -> TraceAttributesResponse

    /// Samples terrain heights under a shape.
    func height(request: HeightRequest) throws -> HeightResponse
}

/// Defaults that keep the three newer actions additive.
///
/// A conformer written against an earlier version, including a test double
/// that only ever needed `route`, still compiles untouched and reports the
/// action as unsupported rather than silently returning nothing.
public extension ValhallaProviding {

    func traceRoute(request: MapMatchRequest) throws -> MapMatchRouteResponse {
        throw ValhallaError.unsupportedAction("trace_route")
    }

    func traceAttributes(request: TraceAttributesRequest) throws -> TraceAttributesResponse {
        throw ValhallaError.unsupportedAction("trace_attributes")
    }

    func height(request: HeightRequest) throws -> HeightResponse {
        throw ValhallaError.unsupportedAction("height")
    }
}

public final class Valhalla: ValhallaProviding {
    private let actor: ValhallaWrapper?
    private let configPath: String

    public convenience init(_ config: ValhallaConfig) throws {
        let configURL = try ValhallaFileManager.saveConfigTo(config)
        try self.init(configPath: configURL.relativePath)
    }

    public required init(configPath: String) throws {
        do {
            try ValhallaFileManager.injectTzdataIntoLibrary()
        } catch {
            // If you're circumventing this libraries injection, download tzdata.tar and put in your bundle. https://www.iana.org/time-zones
            fatalError("tzdata was not inject into Bundle.main. This can be avoided by including tzdata.tar in your main bundle.")
        }

        self.configPath = configPath
        do {
            self.actor = try ValhallaWrapper(configPath: configPath)
        } catch let error as NSError {
            throw ValhallaError.valhallaError(error.code, error.domain)
        } catch {
            throw ValhallaError.valhallaError(-1, error.localizedDescription)
        }
    }
    
    /// Encode a request, hand it to one of the raw actions, and decode what
    /// comes back.
    ///
    /// Every action reports failure as a `ValhallaErrorModel` rather than by a
    /// separate channel, so the error check has to happen before the success
    /// decode for all of them alike.
    private func perform<Request: Encodable, Response: Decodable>(
        _ request: Request,
        action: (String) -> String
    ) throws -> Response {
        let requestData = try JSONEncoder().encode(request)
        guard let requestStr = String(data: requestData, encoding: .utf8) else {
            throw ValhallaError.encodingNotUtf8("requestStr")
        }

        let resultStr = action(requestStr)
        guard let resultData = resultStr.data(using: .utf8) else {
            throw ValhallaError.encodingNotUtf8("resultData")
        }

        if let error = try? JSONDecoder().decode(ValhallaErrorModel.self, from: resultData) {
            throw ValhallaError.valhallaError(error.code, error.message)
        }

        return try JSONDecoder().decode(Response.self, from: resultData)
    }

    public func route(request: RouteRequest) throws -> RouteResponse {
        try perform(request) { self.route(rawRequest: $0) }
    }

    /// Map-matches a GPS trace against the road graph and returns narrative
    /// maneuvers for it.
    public func traceRoute(request: MapMatchRequest) throws -> MapMatchRouteResponse {
        try perform(request) { self.traceRoute(rawRequest: $0) }
    }

    /// Map-matches a GPS trace and returns the matched edges and their
    /// attributes rather than narrative directions.
    public func traceAttributes(
        request: TraceAttributesRequest
    ) throws -> TraceAttributesResponse {
        try perform(request) { self.traceAttributes(rawRequest: $0) }
    }

    /// Samples terrain heights under a shape.
    ///
    /// Build the config with `ValhallaConfig(tileExtractTar:elevationDir:)`,
    /// or every point comes back with no data.
    ///
    /// Three documented Valhalla responses cannot be represented by the pinned
    /// `HeightResponse`, and throw `DecodingError` rather than a
    /// `ValhallaError`: a point outside elevation coverage, which serializes as
    /// `null`; `heightPrecision` of 1 or 2, which serializes decimals; and
    /// `range: true`, which has the same two problems in `rangeHeight`. The
    /// model types both arrays as non-optional integers. Use
    /// `height(rawRequest:)` if a shape may leave coverage or needs sub-metre
    /// precision, until the model is fixed upstream.
    public func height(request: HeightRequest) throws -> HeightResponse {
        try perform(request) { self.height(rawRequest: $0) }
    }

    public func route(rawRequest request: String) -> String {
        actor!.route(request)
    }

    /// The raw form of `traceRoute(request:)`.
    ///
    /// Like `route(rawRequest:)`, the raw actions stay off `ValhallaProviding`,
    /// which declares the typed actions only. Use them when a request or
    /// response needs a field the pinned models cannot represent yet.
    public func traceRoute(rawRequest request: String) -> String {
        actor!.traceRoute(request)
    }

    /// The raw form of `traceAttributes(request:)`.
    public func traceAttributes(rawRequest request: String) -> String {
        actor!.traceAttributes(request)
    }

    /// The raw form of `height(request:)`.
    public func height(rawRequest request: String) -> String {
        actor!.height(request)
    }
}

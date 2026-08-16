import ValhallaObjc
import ValhallaModels
import ValhallaConfigModels

public protocol ValhallaProviding {

    init(_ config: ValhallaConfig) throws

    init(configPath: String) throws

    func route(request: RouteRequest) throws -> RouteResponse

    func traceRoute(request: MapMatchRequest) throws -> MapMatchRouteResponse

    func traceAttributes(request: TraceAttributesRequest) throws -> TraceAttributesResponse
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

    public func route(request: RouteRequest) throws -> RouteResponse {
        try perform(request) { self.route(rawRequest: $0) }
    }

    /// Map-matches a GPS trace onto the road network and returns a route along the matched path.
    ///
    /// The trace is supplied either as `shape` or as an `encodedPolyline`
    /// (with six digits of precision, not the usual five).
    ///
    /// - Note: Only Valhalla's own JSON response is decodable here.
    ///   A request whose `directionsOptions.format` asks for `osrm`, `gpx`, or `pbf`
    ///   produces a payload that ``MapMatchRouteResponse`` cannot represent —
    ///   use ``traceRoute(rawRequest:)`` for those.
    /// - Parameter request: the trace to match, the costing model, and how to match it.
    /// - Returns: the matched trip.
    /// - Throws: ``ValhallaError/valhallaError(_:_:)`` when Valhalla rejects the request or
    ///   cannot match the trace, or a `DecodingError` when the response cannot be decoded.
    public func traceRoute(request: MapMatchRequest) throws -> MapMatchRouteResponse {
        try perform(request) { self.traceRoute(rawRequest: $0) }
    }

    /// Map-matches a GPS trace onto the road network and returns the attributes of every
    /// edge along the matched path.
    ///
    /// Use this instead of ``traceRoute(request:)`` when you need the road network itself —
    /// edge identifiers, road classes, speeds, names — rather than turn-by-turn directions.
    /// Narrow the response with the request's `filters`; by default Valhalla returns every
    /// attribute it has, which is a lot of JSON for a long trace.
    ///
    /// - Note: This action always answers with Valhalla's own JSON. The `format` option
    ///   does not apply to it.
    /// - Important: Exclude `matched.edge_index` from the request's `filters` when matching with
    ///   `shapeMatch: .mapSnap`. Valhalla never populates that field for this action, so it emits
    ///   the `size_t` sentinel — 18446744073709551615 — which no signed 64-bit type can hold, and
    ///   the whole response becomes undecodable rather than just that one field.
    /// - Parameter request: the trace to match, the costing model, and which attributes to return.
    /// - Returns: the matched edges, points, and the admins they reference.
    /// - Throws: ``ValhallaError/valhallaError(_:_:)`` when Valhalla rejects the request or
    ///   cannot match the trace, or a `DecodingError` when the response cannot be decoded.
    public func traceAttributes(request: TraceAttributesRequest) throws -> TraceAttributesResponse {
        try perform(request) { self.traceAttributes(rawRequest: $0) }
    }

    public func route(rawRequest request: String) -> String {
        actor!.route(request)
    }

    /// Runs a `trace_route` request supplied as JSON and returns the raw response.
    ///
    /// This is the escape hatch for response formats ``MapMatchRouteResponse`` cannot
    /// model, and for request options the generated models do not yet carry.
    /// Errors are returned in the body as `{"code": <int>, "message": "<string>"}`
    /// rather than thrown.
    public func traceRoute(rawRequest request: String) -> String {
        actor!.traceRoute(request)
    }

    /// Runs a `trace_attributes` request supplied as JSON and returns the raw response.
    ///
    /// Errors are returned in the body as `{"code": <int>, "message": "<string>"}`
    /// rather than thrown.
    public func traceAttributes(rawRequest request: String) -> String {
        actor!.traceAttributes(request)
    }

    /// Shared body of the typed actions: encode the request, run it, and decode the
    /// response — surfacing the wrapper's error envelope as a thrown ``ValhallaError``.
    ///
    /// - Parameters:
    ///   - request: the typed request to encode.
    ///   - action: the raw action that carries the request across to the C++ wrapper.
    private func perform<Request: Encodable, Response: Decodable>(
        _ request: Request,
        _ action: (String) -> String
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
}

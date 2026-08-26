import Foundation
import ValhallaObjc
import ValhallaModels
import ValhallaConfigModels

public protocol ValhallaProviding {

    init(_ config: ValhallaConfig) throws

    init(configPath: String) throws

    func route(request: RouteRequest) throws -> RouteResponse

    func traceRoute(request: MapMatchRequest) throws -> MapMatchRouteResponse

    func traceAttributes(request: TraceAttributesRequest) throws -> TraceAttributesResponse

    func height(request: HeightRequest) throws -> HeightResponse

    func route(rawRequest: String) throws -> String

    func traceRoute(rawRequest: String) throws -> String

    func traceAttributes(rawRequest: String) throws -> String

    func height(rawRequest: String) throws -> String

    func close()
}

/// The Valhalla routing engine, running against tiles already on the device.
///
/// One instance holds one native actor, including the mmapped tile extract, for its
/// whole lifetime. Building it is expensive and happens during initialization, so reuse
/// a single instance across many requests. Call ``close()`` when done to release the
/// actor early; otherwise `deinit` releases it.
public final class Valhalla: ValhallaProviding {

    /// Where ``init(_:)`` writes the config it is given.
    ///
    /// Every instance created that way shares this one file, so a second instance
    /// overwrites the first's config. Use ``init(_:configName:)`` to give each
    /// instance its own, the way Android's `ValhallaConfigManager` accepts a
    /// `ValhallaFile`.
    public static let defaultConfigName = "valhalla-config.json"

    private let actor: ValhallaWrapper
    private let configPath: String

    /// Guards ``isClosed`` and is held across every native call, so ``close()``
    /// cannot free the actor mid-request. This is the same guarantee Android's
    /// `ValhallaActor` gets from `synchronized(lock)`.
    private let lock = NSLock()
    private var isClosed = false

    /// Writes `config` to ``defaultConfigName`` in Application Support, then builds
    /// the engine from it.
    public convenience init(_ config: ValhallaConfig) throws {
        try self.init(config, configName: Self.defaultConfigName)
    }

    /// Writes `config` to `configName` in Application Support, then builds the engine
    /// from it.
    ///
    /// - Parameters:
    ///   - config: the configuration to write.
    ///   - configName: the file name to write it under. Give each instance its own
    ///     name when more than one is alive at a time.
    public convenience init(_ config: ValhallaConfig, configName: String) throws {
        let configURL = try ValhallaFileManager.saveConfigTo(config, named: configName)
        try self.init(configPath: configURL.relativePath)
    }

    /// Builds the engine from a config file already on disk.
    ///
    /// - Parameter configPath: absolute path to a valhalla config JSON whose tile
    ///   paths are correct for this device.
    /// - Throws: ``ValhallaError/tzdataUnavailable(_:)`` when the bundled timezone
    ///   database cannot be installed, or ``ValhallaError/valhallaError(_:_:)`` when
    ///   the engine cannot be built.
    public required init(configPath: String) throws {
        do {
            try ValhallaFileManager.injectTzdataIntoLibrary()
        } catch {
            // Circumventing this library's injection is possible: download tzdata.tar
            // and put it in your bundle. https://www.iana.org/time-zones
            throw ValhallaError.tzdataUnavailable(String(describing: error))
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

    /// Computes a route between the given locations.
    ///
    /// - Note: Only Valhalla's own JSON response is decodable here. A request whose
    ///   `format` asks for `osrm` produces a payload ``RouteResponse`` cannot
    ///   represent — use ``route(rawRequest:)`` for it.
    /// - Parameter request: the locations, the costing model, and the options.
    /// - Returns: the trip.
    /// - Throws: ``ValhallaError/notSupported(_:)`` for `gpx` and `pbf`,
    ///   ``ValhallaError/valhallaError(_:_:)`` when Valhalla rejects the request, or a
    ///   `DecodingError` when the response cannot be decoded.
    public func route(request: RouteRequest) throws -> RouteResponse {
        // gpx is not JSON and pbf is not even text, so neither can be decoded into
        // RouteResponse. Rejecting them here reports the real problem, rather than
        // letting the caller work backwards from a decode failure.
        switch request.format {
        case .gpx, .pbf:
            throw ValhallaError.notSupported(request.format?.rawValue ?? "unknown")
        default:
            break
        }

        return try decode(try route(rawRequest: try encode(request)))
    }

    /// Map-matches a GPS trace onto the road network and returns a route along the matched path.
    ///
    /// The trace is supplied either as `shape` or as an `encodedPolyline`
    /// (with six digits of precision, not the usual five).
    ///
    /// - Note: Only Valhalla's own JSON response is decodable here.
    ///   A request whose `directionsOptions.format` asks for `osrm` or `gpx`
    ///   produces a payload that ``MapMatchRouteResponse`` cannot represent —
    ///   use ``traceRoute(rawRequest:)`` for those. `pbf` is binary and cannot
    ///   cross this bridge at all; it comes back as an error.
    /// - Parameter request: the trace to match, the costing model, and how to match it.
    /// - Returns: the matched trip.
    /// - Throws: ``ValhallaError/notSupported(_:)`` when the request asks for a format
    ///   other than JSON, ``ValhallaError/valhallaError(_:_:)`` when Valhalla rejects the
    ///   request or cannot match the trace, or a `DecodingError` when the response cannot
    ///   be decoded.
    public func traceRoute(request: MapMatchRequest) throws -> MapMatchRouteResponse {
        switch request.directionsOptions?.format {
        case .none, .some(.json):
            break
        case .some(let format):
            throw ValhallaError.notSupported(format.rawValue)
        }

        return try decode(try traceRoute(rawRequest: try encode(request)))
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
    ///   `shapeMatch: .mapSnap`. Valhalla leaves that field unpopulated for some matched points
    ///   while still reporting a valid edge id, so it emits the `size_t` sentinel —
    ///   18446744073709551615 — which no signed 64-bit type can hold, and the whole response
    ///   becomes undecodable rather than just that one field. Tracked upstream as
    ///   valhalla/valhalla#3699, with a fix proposed in valhalla/valhalla#6278.
    /// - Parameter request: the trace to match, the costing model, and which attributes to return.
    /// - Returns: the matched edges, points, and the admins they reference.
    /// - Throws: ``ValhallaError/valhallaError(_:_:)`` when Valhalla rejects the request or
    ///   cannot match the trace, or a `DecodingError` when the response cannot be decoded.
    public func traceAttributes(request: TraceAttributesRequest) throws -> TraceAttributesResponse {
        try decode(try traceAttributes(rawRequest: try encode(request)))
    }

    /// Samples terrain heights under a shape, from the elevation tiles in
    /// `additionalData.elevation`. Without them every height is null.
    ///
    /// - Note: `HeightResponse` cannot represent a null height; use
    ///   ``height(rawRequest:)`` when a point may have no data.
    /// - Throws: ``ValhallaError/valhallaError(_:_:)`` when Valhalla rejects the
    ///   request, or a `DecodingError` when the response cannot be decoded.
    public func height(request: HeightRequest) throws -> HeightResponse {
        try decode(try height(rawRequest: try encode(request)))
    }

    /// Runs a `route` request supplied as JSON and returns the raw response.
    ///
    /// This is the escape hatch for response formats ``RouteResponse`` cannot model —
    /// `osrm` and `gpx` — and for request options the generated models do not yet carry.
    ///
    /// - Returns: the raw response body, in whichever format the request asked for.
    /// - Throws: ``ValhallaError/valhallaError(_:_:)`` when Valhalla rejects the request,
    ///   or ``ValhallaError/closed`` after ``close()``.
    public func route(rawRequest request: String) throws -> String {
        try checkForError(try withActor { $0.route(request) })
    }

    /// Runs a `trace_route` request supplied as JSON and returns the raw response.
    ///
    /// This is the escape hatch for response formats ``MapMatchRouteResponse`` cannot
    /// model, and for request options the generated models do not yet carry.
    ///
    /// - Throws: ``ValhallaError/valhallaError(_:_:)`` when Valhalla rejects the request,
    ///   or ``ValhallaError/closed`` after ``close()``.
    public func traceRoute(rawRequest request: String) throws -> String {
        try checkForError(try withActor { $0.traceRoute(request) })
    }

    /// Runs a `trace_attributes` request supplied as JSON and returns the raw response.
    ///
    /// - Throws: ``ValhallaError/valhallaError(_:_:)`` when Valhalla rejects the request,
    ///   or ``ValhallaError/closed`` after ``close()``.
    public func traceAttributes(rawRequest request: String) throws -> String {
        try checkForError(try withActor { $0.traceAttributes(request) })
    }

    /// Runs a `height` request supplied as JSON and returns the raw response.
    ///
    /// - Throws: ``ValhallaError/valhallaError(_:_:)`` when Valhalla rejects the request,
    ///   or ``ValhallaError/closed`` after ``close()``.
    public func height(rawRequest request: String) throws -> String {
        try checkForError(try withActor { $0.height(request) })
    }

    /// Releases the native actor held by this instance, and with it the mmapped tile
    /// extract. Safe to call more than once.
    ///
    /// Any action attempted afterwards throws ``ValhallaError/closed``.
    public func close() {
        lock.lock()
        defer { lock.unlock() }

        guard !isClosed else { return }
        isClosed = true
        actor.close()
    }

    // No `deinit` is needed: releasing the last reference to `actor` runs
    // ValhallaWrapper's own dealloc, which frees the native actor.

    /// Runs one action against the native actor while holding ``lock``.
    ///
    /// Holding it across the call is what keeps ``close()`` from freeing the actor
    /// mid-request, and serialises concurrent callers — the actor is not safe to use
    /// from several threads at once.
    private func withActor<T>(_ action: (ValhallaWrapper) -> T) throws -> T {
        lock.lock()
        defer { lock.unlock() }

        guard !isClosed else { throw ValhallaError.closed }
        return action(actor)
    }

    /// Encodes a typed request as the JSON string the wrapper expects.
    private func encode<Request: Encodable>(_ request: Request) throws -> String {
        let requestData = try JSONEncoder().encode(request)
        guard let requestStr = String(data: requestData, encoding: .utf8) else {
            throw ValhallaError.encodingNotUtf8("requestStr")
        }
        return requestStr
    }

    /// Decodes a successful response. The error envelope has already been ruled out by
    /// ``checkForError(_:)``, so anything undecodable here is a real decode failure.
    private func decode<Response: Decodable>(_ rawResponse: String) throws -> Response {
        guard let resultData = rawResponse.data(using: .utf8) else {
            throw ValhallaError.encodingNotUtf8("resultData")
        }
        return try JSONDecoder().decode(Response.self, from: resultData)
    }

    /// Returns `rawResponse` unchanged, unless it is the wrapper's error envelope —
    /// in which case the error it carries is thrown.
    ///
    /// The envelope is `{"code": <int>, "message": "<string>"}` and nothing else. Both
    /// the key count and the value types have to match, because `JSONDecoder` ignores
    /// unknown keys: decoding into a two-field type would otherwise report any payload
    /// carrying an int `code` and a string `message` as an error. That is the same test
    /// Android makes with Moshi's `failOnUnknown`.
    private func checkForError(_ rawResponse: String) throws -> String {
        guard let data = rawResponse.data(using: .utf8) else {
            throw ValhallaError.encodingNotUtf8("rawResponse")
        }

        guard let object = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              object.count == 2,
              let code = object["code"] as? Int,
              let message = object["message"] as? String
        else {
            return rawResponse
        }

        throw ValhallaError.valhallaError(code, message)
    }
}

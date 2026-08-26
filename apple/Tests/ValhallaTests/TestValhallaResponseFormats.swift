import XCTest
import ValhallaModels
import ValhallaConfigModels
@testable import Valhalla

/// Which response formats the typed methods can decode, which they refuse, and how the
/// wrapper's error envelope is told apart from a payload that merely resembles it.
final class TestValhallaResponseFormats: XCTestCase {

    private var valhalla: Valhalla!

    override func setUp() async throws {
        let tilesTarURL = Bundle.module.url(forResource: "TestData/valhalla_tiles", withExtension: "tar")!
        valhalla = try Valhalla(
            try ValhallaConfig(tileExtractTar: tilesTarURL),
            configName: "response-formats-test.json"
        )
    }

    private var andorraRoute: RouteRequest {
        RouteRequest(
            locations: [
                RoutingWaypoint(lat: 42.5063, lon: 1.5218),
                RoutingWaypoint(lat: 42.5086, lon: 1.5394)
            ],
            costing: .auto,
            units: .mi
        )
    }

    /// `gpx` is not JSON and `pbf` is not text, so neither can be decoded into `RouteResponse`.
    /// Refusing them up front reports the real problem, instead of leaving the caller to work
    /// backwards from a `DecodingError`.
    func testRouteRejectsUndecodableFormats() throws {
        for format in [RouteRequest.Format.gpx, .pbf] {
            var request = andorraRoute
            request.format = format

            XCTAssertThrowsError(try valhalla.route(request: request)) { error in
                XCTAssertEqual(error as? ValhallaError, .notSupported(format.rawValue))
            }
        }
    }

    /// `trace_route` answers OSRM under `matchings`, which `MapMatchRouteResponse` cannot
    /// represent, so the typed method takes JSON only.
    func testTraceRouteRejectsNonJsonFormats() throws {
        for format in [DirectionsOptions.Format.gpx, .osrm, .pbf] {
            let request = MapMatchRequest(
                encodedPolyline: try routeShape(),
                costing: .auto,
                directionsOptions: DirectionsOptions(format: format)
            )

            XCTAssertThrowsError(try valhalla.traceRoute(request: request)) { error in
                XCTAssertEqual(error as? ValhallaError, .notSupported(format.rawValue))
            }
        }
    }

    /// What the typed method refuses, the raw method still carries. That is the whole point of
    /// having a raw method.
    func testOsrmIsReachableThroughTheRawMethod() throws {
        var request = andorraRoute
        request.format = .osrm

        let raw = try valhalla.route(rawRequest: try encode(request))

        let json = try XCTUnwrap(JSONSerialization.jsonObject(with: Data(raw.utf8)) as? [String: Any])
        XCTAssertNotNil(json["routes"], "an OSRM response reports its routes under `routes`")
    }

    /// A successful payload that happens to carry `code` and `message` is not an error.
    ///
    /// `JSONDecoder` ignores unknown keys, so decoding into a two-field type would report any
    /// such payload as a failure. The envelope test has to check the key count as well, which is
    /// what Moshi's `failOnUnknown` does for Android. An OSRM response is the case that matters:
    /// it carries a top-level `code` of its own.
    func testEnvelopeCheckRequiresExactlyTheTwoKeys() throws {
        var request = andorraRoute
        request.format = .osrm

        let raw = try valhalla.route(rawRequest: try encode(request))

        XCTAssertTrue(raw.contains("\"code\""), "the fixture only means something if `code` is present")
        // Returning at all is the assertion: an over-eager envelope check would have thrown.
    }

    private func encode<Request: Encodable>(_ request: Request) throws -> String {
        String(data: try JSONEncoder().encode(request), encoding: .utf8)!
    }

    /// The shape of a known-good route through the fixture, as a polyline with six digits of
    /// precision — which is what the trace actions expect.
    private func routeShape() throws -> String {
        try XCTUnwrap(try valhalla.route(request: andorraRoute).trip.legs.first?.shape)
    }
}

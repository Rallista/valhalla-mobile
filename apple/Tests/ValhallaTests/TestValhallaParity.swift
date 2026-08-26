import XCTest
import ValhallaModels
import ValhallaConfigModels
@testable import Valhalla

/// The behaviour iOS gained to match Android: an explicit `close`, a typed rejection of the
/// formats that cannot be decoded, and a config file name per instance.
final class TestValhallaParity: XCTestCase {

    private var config: ValhallaConfig!

    override func setUp() async throws {
        let tilesTarURL = Bundle.module.url(forResource: "TestData/valhalla_tiles", withExtension: "tar")!
        config = try ValhallaConfig(tileExtractTar: tilesTarURL)
    }

    private func makeValhalla(configName: String = "parity-test.json") throws -> Valhalla {
        try Valhalla(config, configName: configName)
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

    // MARK: - close

    /// Every action refuses to run after `close`, rather than reaching a freed actor.
    func testActionsThrowAfterClose() throws {
        let valhalla = try makeValhalla()

        valhalla.close()

        XCTAssertThrowsError(try valhalla.route(request: andorraRoute)) { error in
            XCTAssertEqual(error as? ValhallaError, .closed)
        }
        XCTAssertThrowsError(try valhalla.route(rawRequest: "{}")) { error in
            XCTAssertEqual(error as? ValhallaError, .closed)
        }
        XCTAssertThrowsError(try valhalla.traceRoute(rawRequest: "{}")) { error in
            XCTAssertEqual(error as? ValhallaError, .closed)
        }
        XCTAssertThrowsError(try valhalla.traceAttributes(rawRequest: "{}")) { error in
            XCTAssertEqual(error as? ValhallaError, .closed)
        }
        XCTAssertThrowsError(try valhalla.height(rawRequest: "{}")) { error in
            XCTAssertEqual(error as? ValhallaError, .closed)
        }
    }

    /// Closing twice is not an error, the way Android's `close` is safe to repeat.
    func testCloseIsIdempotent() throws {
        let valhalla = try makeValhalla()

        valhalla.close()
        valhalla.close()

        XCTAssertThrowsError(try valhalla.route(request: andorraRoute))
    }

    /// An instance that is never closed still works; `close` is an early release, not a requirement.
    func testRoutingWorksWithoutClosing() throws {
        let valhalla = try makeValhalla()

        let response = try valhalla.route(request: andorraRoute)

        XCTAssertEqual(response.trip.statusMessage, "Found route between points")
    }

    // MARK: - unsupported formats

    /// `gpx` and `pbf` cannot be decoded into `RouteResponse`, so they are refused up front with a
    /// typed error rather than surfacing as an opaque decode failure. Android's `route` throws
    /// `ValhallaException.NotSupported` for exactly these two.
    func testRouteRejectsUndecodableFormats() throws {
        let valhalla = try makeValhalla()

        for format in [RouteRequest.Format.gpx, .pbf] {
            var request = andorraRoute
            request.format = format

            XCTAssertThrowsError(try valhalla.route(request: request)) { error in
                XCTAssertEqual(error as? ValhallaError, .notSupported(format.rawValue))
            }
        }
    }

    /// The trace actions refuse anything but JSON, matching Android.
    func testTraceRouteRejectsNonJsonFormats() throws {
        let valhalla = try makeValhalla()

        for format in [DirectionsOptions.Format.gpx, .osrm, .pbf] {
            let request = MapMatchRequest(
                encodedPolyline: try routeShape(valhalla),
                costing: .auto,
                directionsOptions: DirectionsOptions(format: format)
            )

            XCTAssertThrowsError(try valhalla.traceRoute(request: request)) { error in
                XCTAssertEqual(error as? ValhallaError, .notSupported(format.rawValue))
            }
        }
    }

    /// `osrm` is refused only by the typed method; the raw one still carries it, which is the
    /// whole point of having a raw method.
    func testOsrmIsReachableThroughTheRawMethod() throws {
        let valhalla = try makeValhalla()
        var request = andorraRoute
        request.format = .osrm

        let raw = try valhalla.route(rawRequest: try encode(request))

        let json = try XCTUnwrap(JSONSerialization.jsonObject(with: Data(raw.utf8)) as? [String: Any])
        XCTAssertNotNil(json["routes"], "an OSRM response reports its routes under `routes`")
    }

    // MARK: - the error envelope

    /// A successful payload that happens to carry `code` and `message` is not an error.
    ///
    /// `JSONDecoder` ignores unknown keys, so decoding into a two-field type would report any such
    /// payload as a failure. The envelope test has to check the key count too — this is the iOS
    /// equivalent of Moshi's `failOnUnknown`.
    func testEnvelopeCheckRequiresExactlyTheTwoKeys() throws {
        let valhalla = try makeValhalla()

        // An OSRM response carries a top-level `code`, and Valhalla's own errors carry an int one.
        var request = andorraRoute
        request.format = .osrm
        let raw = try valhalla.route(rawRequest: try encode(request))

        XCTAssertTrue(raw.contains("\"code\""), "the fixture only means something if `code` is present")
        // Reaching here at all is the assertion: an over-eager envelope check would have thrown.
    }

    // MARK: - config naming

    /// Two live instances can hold two different configs, which the shared default file forbids.
    /// Android gets this by passing a `ValhallaFile` to its `ValhallaConfigManager`.
    func testEachInstanceCanHaveItsOwnConfigFile() throws {
        let tilesDirectoryURL = Bundle.module.resourceURL!.appendingPathComponent("TestData/valhalla_tiles", isDirectory: true)

        let fromTar = try makeValhalla(configName: "parity-tar.json")
        let fromDir = try Valhalla(try ValhallaConfig(tilesDir: tilesDirectoryURL), configName: "parity-dir.json")

        // Both still route, so neither overwrote the other's config on the way in.
        XCTAssertEqual(try fromTar.route(request: andorraRoute).trip.statusMessage, "Found route between points")
        XCTAssertEqual(try fromDir.route(request: andorraRoute).trip.statusMessage, "Found route between points")
    }

    // MARK: - helpers

    private func encode<Request: Encodable>(_ request: Request) throws -> String {
        String(data: try JSONEncoder().encode(request), encoding: .utf8)!
    }

    private func routeShape(_ valhalla: Valhalla) throws -> String {
        try XCTUnwrap(try valhalla.route(request: andorraRoute).trip.legs.first?.shape)
    }
}

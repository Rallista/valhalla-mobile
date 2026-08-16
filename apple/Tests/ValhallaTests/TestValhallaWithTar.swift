import XCTest
import ValhallaModels
import ValhallaConfigModels
@testable import Valhalla

final class TestValhallaWithTar: XCTestCase {
    var defaultConfig: ValhallaConfig!
    
    override func setUp() async throws {
        let tilesTarUrl = Bundle.module.url(forResource: "TestData/valhalla_tiles", withExtension: "tar")!
        defaultConfig = try ValhallaConfig(tileExtractTar: tilesTarUrl)
        
        let encoded = try JSONEncoder().encode(defaultConfig)
        print(String(data: encoded, encoding: .utf8)!)
    }
    
    /// Validate an incorrect configuration (config file not found).
    func testNoConfigFile() throws {
        do {
            let valhalla = try Valhalla(configPath: "missing.json")

            let request = RouteRequest(
                locations: [
                    RoutingWaypoint(lat: 42.5063, lon: 1.5218),
                    RoutingWaypoint(lat: 42.5086, lon: 1.5394)
                ],
                costing: .auto,
                units: .mi,
            )
        
            let _ = try valhalla.route(request: request)
            XCTFail("route should throw cannot open file missing.json")
        } catch let error as ValhallaError {
            XCTAssertEqual(error, .valhallaError(-1, "Cannot open file missing.json"))
        }
    }

    /// Validate a valhalla error that requires all configuration to be set up properly.
    func testNoSuitableEdges() throws {
        let valhalla = try Valhalla(defaultConfig)

        let request = RouteRequest(
            locations: [
                RoutingWaypoint(lat: 45.843812, lon: -123.768205),
                RoutingWaypoint(lat: 45.869701, lon: -123.766121)
            ],
            costing: .auto,
            units: .mi,
        )
        
        do {
            let _ = try valhalla.route(request: request)
            XCTFail("route should throw no suitable edges")
        } catch let error as ValhallaError {
            XCTAssertEqual(error, .valhallaError(171, "No suitable edges near location"))
        }
    }

    /// Validate a successful route fetch.
    func testSuccessfulRoute() throws {
        let valhalla = try Valhalla(defaultConfig)

        let request = RouteRequest(
            locations: [
                RoutingWaypoint(lat: 42.5063, lon: 1.5218),
                RoutingWaypoint(lat: 42.5086, lon: 1.5394)
            ],
            costing: .auto,
            units: .mi,
        )
        
        let response = try valhalla.route(request: request)

        XCTAssertEqual(response.trip.statusMessage, "Found route between points")
        XCTAssertEqual(response.trip.legs.first?.shape.count, 656)
    }

    /// The shape of a known-good route through the fixture, as a polyline with six digits of
    /// precision — which is what the trace actions expect.
    ///
    /// Taking the trace off the graph itself, rather than writing coordinates by hand, keeps the
    /// map matching tests about matching instead of about how faithfully some invented points
    /// happen to sit on an Andorran road.
    private func routeShape(_ valhalla: Valhalla) throws -> String {
        let request = RouteRequest(
            locations: [
                RoutingWaypoint(lat: 42.5063, lon: 1.5218),
                RoutingWaypoint(lat: 42.5086, lon: 1.5394)
            ],
            costing: .auto,
            units: .mi,
        )

        let response = try valhalla.route(request: request)

        return try XCTUnwrap(response.trip.legs.first?.shape)
    }

    /// Validate a successful map match that returns a route along the matched path.
    func testSuccessfulTraceRoute() throws {
        let valhalla = try Valhalla(defaultConfig)

        let request = MapMatchRequest(
            encodedPolyline: try routeShape(valhalla),
            costing: .auto
        )

        let response = try valhalla.traceRoute(request: request)

        XCTAssertEqual(response.trip.status, 0)
        XCTAssertEqual(response.trip.statusMessage, "Found route between points")
        XCTAssertFalse(response.trip.legs.isEmpty)
    }

    /// Validate a valhalla error when the trace is nowhere near the tiles we have.
    ///
    /// The code is not pinned: it depends on how far the matcher gets before giving up, since Loki
    /// can reject the locations outright and Meili can fail to find a path.
    func testTraceRouteNoMatch() throws {
        let valhalla = try Valhalla(defaultConfig)

        let request = MapMatchRequest(
            shape: [
                MapMatchWaypoint(lat: 45.843812, lon: -123.768205),
                MapMatchWaypoint(lat: 45.869701, lon: -123.766121)
            ],
            costing: .auto
        )

        do {
            let _ = try valhalla.traceRoute(request: request)
            XCTFail("traceRoute should throw for a trace outside the tiles")
        } catch let error as ValhallaError {
            guard case .valhallaError = error else {
                return XCTFail("expected a valhalla error, got \(error)")
            }
        }
    }

    /// Validate a successful map match that returns the attributes of the matched edges.
    ///
    /// The trace is the exact shape of a prior route, so Valhalla walks the edges instead of
    /// running Meili, and there are no `matchedPoints` — `testMapSnapTraceAttributes` covers those.
    func testSuccessfulTraceAttributes() throws {
        let valhalla = try Valhalla(defaultConfig)

        let request = TraceAttributesRequest(
            encodedPolyline: try routeShape(valhalla),
            costing: .auto
        )

        let response = try valhalla.traceAttributes(request: request)

        XCTAssertFalse(try XCTUnwrap(response.edges).isEmpty)
        XCTAssertNotNil(response.shape)
        XCTAssertNil(response.matchedPoints)
    }

    /// Validate the map-snapping path, which is the one that reports how each input point matched.
    func testMapSnapTraceAttributes() throws {
        let valhalla = try Valhalla(defaultConfig)

        let request = TraceAttributesRequest(
            encodedPolyline: try routeShape(valhalla),
            costing: .auto,
            shapeMatch: .mapSnap
        )

        let response = try valhalla.traceAttributes(request: request)

        XCTAssertFalse(try XCTUnwrap(response.edges).isEmpty)
        XCTAssertFalse(try XCTUnwrap(response.matchedPoints).isEmpty)
    }

    /// Validate that a filter narrows the response to just the attributes that were asked for.
    func testFilteredTraceAttributes() throws {
        let valhalla = try Valhalla(defaultConfig)

        let request = TraceAttributesRequest(
            encodedPolyline: try routeShape(valhalla),
            costing: .auto,
            filters: TraceAttributeFilterOptions(
                attributes: [.edgePeriodSpeed, .edgePeriodNames],
                action: .include
            )
        )

        let response = try valhalla.traceAttributes(request: request)

        XCTAssertFalse(try XCTUnwrap(response.edges).isEmpty)
        XCTAssertNil(response.shape)
    }
}

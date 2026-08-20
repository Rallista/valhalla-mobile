import XCTest
import ValhallaModels
import ValhallaConfigModels
@testable import Valhalla

final class TestValhallaWithFolder: XCTestCase {
    var defaultConfig: ValhallaConfig!
    
    override func setUp() async throws {
        let tilesDirectoryURL = Bundle.module.resourceURL!.appendingPathComponent("TestData/valhalla_tiles", isDirectory: true)
        defaultConfig = try ValhallaConfig(tilesDir: tilesDirectoryURL)
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

    /// Validate that map matching also works against a tile directory, not just a tile extract.
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

    /// Validate that trace attributes also work against a tile directory.
    func testSuccessfulTraceAttributes() throws {
        let valhalla = try Valhalla(defaultConfig)

        let request = TraceAttributesRequest(
            encodedPolyline: try routeShape(valhalla),
            costing: .auto
        )

        let response = try valhalla.traceAttributes(request: request)

        XCTAssertFalse(try XCTUnwrap(response.edges).isEmpty)
        XCTAssertNotNil(response.shape)
    }
}

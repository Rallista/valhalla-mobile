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
                directionsOptions: DirectionsOptions(units: .mi)
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
            directionsOptions: DirectionsOptions(units: .mi)
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
            directionsOptions: DirectionsOptions(units: .mi)
        )
        
        let response = try valhalla.route(request: request)

        XCTAssertEqual(response.trip.statusMessage, "Found route between points")
        XCTAssertNotNil(response.trip.legs.first?.shape)
    }
}

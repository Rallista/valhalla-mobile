import ValhallaModels
@testable import Valhalla
import XCTest

final class TestValhallaActor: XCTestCase {
    var defaultConfig = ValhallaConfig(tileExtract: Bundle.module.url(forResource: "TestData/valhalla_tiles", withExtension: "tar"))
    
    /// Validate an incorrect configuration (config file not found).
    func testNoConfigFile() throws {
        let valhalla = Valhalla(configPath: "missing.json")

        let request = RouteRequest(
            locations: [
                RoutingWaypoint(lat: 38.429719, lon: -108.827425),
                RoutingWaypoint(lat: 38.4604331, lon: -108.8817009)
            ],
            costing: .auto,
            directionsOptions: DirectionsOptions(units: .mi)
        )
        
        do {
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
                RoutingWaypoint(lat: 38.429719, lon: -108.827425),
                RoutingWaypoint(lat: 38.4604331, lon: -108.8817009)
            ],
            costing: .auto,
            directionsOptions: DirectionsOptions(units: .mi)
        )
        
        let response = try valhalla.route(request: request)

        XCTAssertEqual(response.trip.statusMessage, "Found route between points")
    }
}

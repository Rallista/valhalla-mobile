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

    /// Validate that caller text in an error message cannot break the payload.
    ///
    /// Valhalla quotes an unknown costing name back to the caller in error 125
    /// (src/valhalla/src/worker.cc:823). The wrapper must escape that message.
    /// Without the escape the payload is not valid JSON, the error decode
    /// fails, and this library reports a decode failure in place of the real
    /// error.
    func testErrorMessageEscapesCallerText() throws {
        let valhalla = try Valhalla(defaultConfig)

        // A costing name with the three characters that broke the payload.
        let costingName = "auto\"\\\nevil"

        let payload: [String: Any] = [
            "locations": [
                ["lat": 42.5063, "lon": 1.5218],
                ["lat": 42.5086, "lon": 1.5394]
            ],
            "costing": costingName,
            "units": "miles"
        ]
        let requestData = try JSONSerialization.data(withJSONObject: payload)
        let rawRequest = String(data: requestData, encoding: .utf8)!

        let rawResponse = valhalla.route(rawRequest: rawRequest)

        // The decode throws if the wrapper did not escape the message.
        let error = try JSONDecoder().decode(
            ValhallaErrorModel.self,
            from: Data(rawResponse.utf8)
        )

        XCTAssertEqual(error.code, 125)
        XCTAssertTrue(
            error.message.contains(costingName),
            "the message must carry the costing name unchanged, got: \(error.message)"
        )
    }
}

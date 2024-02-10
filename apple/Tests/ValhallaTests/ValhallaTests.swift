import XCTest
@testable import Valhalla

final class TestValhallaActor: ValhallaTestCase {
    
    var configPath: String!
    
    override func setUp() async throws {
        configPath = try configPath()
    }
    
    /// Validate an incorrect configuration (config file not found).
    func testNoConfigFile() {
        let valhalla = Valhalla(configPath: "missing.json")
        
        let request = "{\"locations\":[{\"lat\":38.429719,\"lon\":-108.827425},{\"lat\":38.4604331,\"lon\":-108.8817009}],\"costing\":\"auto\",\"units\":\"miles\"}"
        let response = valhalla.route(request: request)
        
        XCTAssertEqual(response, "{\"code\":-1,\"message\":\"Cannot open file missing.json\"}")
    }
    
    /// Validate a valhalla error that requires all configuration to be set up properly.
    func testNoSuitableEdges() {
        let valhalla = Valhalla(configPath: configPath)
        
        let request = "{\"locations\":[{\"lat\":45.843812,\"lon\":-123.768205},{\"lat\":45.869701,\"lon\":-123.766121}],\"costing\":\"auto\",\"units\":\"miles\"}"
        let response = valhalla.route(request: request)
        
        XCTAssertEqual(response, "{\"code\":171,\"message\":\"No suitable edges near location\"}")
    }
    
    /// Validate a successful route fetch.
    func testSuccessfulRoute() throws {
        let valhalla = Valhalla(configPath: configPath)
        
        let request = "{\"locations\":[{\"lat\":38.429719,\"lon\":-108.827425},{\"lat\":38.4604331,\"lon\":-108.8817009}],\"costing\":\"auto\",\"units\":\"miles\"}"
        let response = valhalla.route(request: request)
        
        guard let data = response.data(using: .utf8) else {
            print(response)
            XCTFail("Response could not be converted to utf8 data for parsing.")
            return
        }
        
        guard let statusMessage = try? serializeValue(data, keys: "trip", "status_message") else {
            print(response)
            XCTFail("Could not parse status message from response.")
            return
        }

        XCTAssertEqual(statusMessage, "Found route between points")
    }
}

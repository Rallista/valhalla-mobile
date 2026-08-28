import XCTest
import ValhallaModels
import ValhallaConfigModels
@testable import Valhalla

/// `TestData/elevation` holds a synthetic SRTM tile whose height is
/// `10800 * (lat - 42) + 3600 * (lon - 1)` metres, so heights can be
/// asserted exactly.
final class TestValhallaHeight: XCTestCase {
    private var valhalla: Valhalla!
    private var valhallaWithElevation: Valhalla!

    override func setUp() async throws {
        let tilesTarURL = Bundle.module.url(forResource: "TestData/valhalla_tiles", withExtension: "tar")!
        let elevationURL = Bundle.module.resourceURL!.appendingPathComponent("TestData/elevation")

        valhalla = try makeValhalla(
            try ValhallaConfig(tileExtractTar: tilesTarURL),
            configName: "valhalla-no-height.json"
        )
        valhallaWithElevation = try makeValhalla(
            try ValhallaConfig(tileExtractTar: tilesTarURL, elevationDir: elevationURL),
            configName: "valhalla-height.json"
        )
    }

    /// Each instance gets its own config file, since the convenience
    /// initializer writes every config to one shared path.
    private func makeValhalla(_ config: ValhallaConfig, configName: String) throws -> Valhalla {
        let url = FileManager.default.temporaryDirectory.appendingPathComponent(configName)
        try JSONEncoder().encode(config).write(to: url)
        return try Valhalla(configPath: url.path)
    }

    func testHeight() throws {
        let oneRow = 1.0 / 3600.0
        let request = HeightRequest(shape: [
            Coordinate(lat: 42.5, lon: 1.5),
            Coordinate(lat: 42.5 + oneRow, lon: 1.5),
            Coordinate(lat: 42.5, lon: 1.2),
            Coordinate(lat: 42.5063, lon: 1.5218),
        ])

        let response = try valhallaWithElevation.height(request: request)

        XCTAssertEqual(response.height, [7200, 7203, 6120, 7347])
    }

    func testHeightWithNoShapeThrows() {
        XCTAssertThrowsError(try valhallaWithElevation.height(request: HeightRequest())) { error in
            guard case ValhallaError.valhallaError = error else {
                return XCTFail("expected a valhalla error, got \(error)")
            }
        }
    }

    /// Without elevation data every height is null, which the typed
    /// `HeightResponse` cannot represent, so this goes through the raw method.
    func testHeightWithoutElevationDataIsNull() throws {
        let raw = try valhalla.height(rawRequest: #"{"shape":[{"lat":42.5,"lon":1.5}]}"#)

        let json = try XCTUnwrap(JSONSerialization.jsonObject(with: Data(raw.utf8)) as? [String: Any])
        XCTAssertEqual(json["height"] as? [NSNull], [NSNull()])
    }
}

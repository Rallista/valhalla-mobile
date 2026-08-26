import XCTest
import ValhallaModels
import ValhallaConfigModels
@testable import Valhalla

final class TestFileSystemConfig: XCTestCase {

    var valhalla: Valhalla!

    override func setUp() async throws {
        let tilesDirectoryURL = Bundle.module.resourceURL!.appendingPathComponent("TestData/valhalla_tiles", isDirectory: true)
        let defaultConfig = try ValhallaConfig(tilesDir: tilesDirectoryURL)
        valhalla = try Valhalla(defaultConfig)
    }

    func testTzDataExists() throws {
        let libraryDir = FileManager.default.urls(for: .libraryDirectory, in: .userDomainMask).first
        let tzDataURL = libraryDir!.appendingPathComponent("tzdata")
        XCTAssertTrue(FileManager.default.fileExists(atPath: tzDataURL.path))
    }

    /// Two live instances can hold two different configs.
    ///
    /// `init(_:)` writes every config to one shared file, so without a name per instance the
    /// second one overwrites the first's config before the first has read it.
    func testEachInstanceCanHaveItsOwnConfigFile() throws {
        let tilesDirectoryURL = Bundle.module.resourceURL!.appendingPathComponent("TestData/valhalla_tiles", isDirectory: true)
        let tilesTarURL = Bundle.module.url(forResource: "TestData/valhalla_tiles", withExtension: "tar")!

        let fromDir = try Valhalla(try ValhallaConfig(tilesDir: tilesDirectoryURL), configName: "config-dir.json")
        let fromTar = try Valhalla(try ValhallaConfig(tileExtractTar: tilesTarURL), configName: "config-tar.json")

        let request = RouteRequest(
            locations: [
                RoutingWaypoint(lat: 42.5063, lon: 1.5218),
                RoutingWaypoint(lat: 42.5086, lon: 1.5394)
            ],
            costing: .auto,
            units: .mi
        )

        // Both still route, so neither overwrote the other's config on the way in.
        XCTAssertEqual(try fromDir.route(request: request).trip.statusMessage, "Found route between points")
        XCTAssertEqual(try fromTar.route(request: request).trip.statusMessage, "Found route between points")
    }
}

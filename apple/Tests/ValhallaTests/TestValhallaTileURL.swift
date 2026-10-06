import Foundation
import XCTest
import ValhallaModels
import ValhallaConfigModels
@testable import Valhalla

/// Answers tile requests from the test fixtures, without a network.
///
/// Registered globally, so the `NSURLSession.sharedSession` behind `ValhallaWrapper` uses it.
/// Bodies are plain, as NSURLSession hands them over after decompressing.
final class FixtureTileProtocol: URLProtocol {

    override class func canInit(with request: URLRequest) -> Bool {
        request.url?.host == "tiles.invalid"
    }

    override class func canonicalRequest(for request: URLRequest) -> URLRequest {
        request
    }

    override func startLoading() {
        guard let url = request.url else { return }
        let tiles = Bundle.module.resourceURL!.appendingPathComponent("TestData/valhalla_tiles")
        let tile = try? Data(contentsOf: tiles.appendingPathComponent(url.path))
        let response = HTTPURLResponse(
            url: url, statusCode: tile == nil ? 404 : 200, httpVersion: "HTTP/1.1", headerFields: nil)!
        client?.urlProtocol(self, didReceive: response, cacheStoragePolicy: .notAllowed)
        if let tile {
            client?.urlProtocol(self, didLoad: tile)
        }
        client?.urlProtocolDidFinishLoading(self)
    }

    override func stopLoading() {}
}

/// `mjolnir.tile_url_gz` on iOS, where the tile getter has to gzip what NSURLSession inflated.
final class TestValhallaTileURL: XCTestCase {

    private var tilesDir: URL!

    override func setUpWithError() throws {
        URLProtocol.registerClass(FixtureTileProtocol.self)
        tilesDir = FileManager.default.temporaryDirectory
            .appendingPathComponent("tile-url-\(UUID().uuidString)", isDirectory: true)
        try FileManager.default.createDirectory(at: tilesDir, withIntermediateDirectories: true)
    }

    override func tearDownWithError() throws {
        URLProtocol.unregisterClass(FixtureTileProtocol.self)
        if let tilesDir {
            try? FileManager.default.removeItem(at: tilesDir)
        }
    }

    func testStoresTilesGzipped() throws {
        let config = try ValhallaConfig(
            tilesUrl: "http://tiles.invalid/{tilePath}", tilesDir: tilesDir, tilesAreGzFiles: true)
        let request = RouteRequest(
            locations: [
                RoutingWaypoint(lat: 42.5063, lon: 1.5218),
                RoutingWaypoint(lat: 42.5086, lon: 1.5394)
            ],
            costing: .auto,
            units: .mi)

        let trip = try Valhalla(config, configName: "tile-url.json").route(request: request).trip
        XCTAssertEqual(trip.statusMessage, "Found route between points")

        let stored = (FileManager.default.enumerator(at: tilesDir, includingPropertiesForKeys: nil)?
            .allObjects as? [URL] ?? []).filter { $0.path.contains(".gph") }
        XCTAssertFalse(stored.isEmpty, "nothing was stored")
        for tile in stored {
            XCTAssertTrue(tile.path.hasSuffix(".gph.gz"), tile.path)
            XCTAssertEqual(try Data(contentsOf: tile).prefix(2), Data([0x1f, 0x8b]), tile.path)
        }
    }
}

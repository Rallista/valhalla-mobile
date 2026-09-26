import Foundation
import XCTest
import ValhallaModels
import ValhallaConfigModels
@testable import Valhalla

/// ``Valhalla/cancel()`` on iOS, where the flag it sets belongs to the Obj-C wrapper.
final class TestValhallaCancel: XCTestCase {

    private var tilesDir: URL!

    private let request = RouteRequest(
        locations: [
            RoutingWaypoint(lat: 42.5063, lon: 1.5218),
            RoutingWaypoint(lat: 42.5086, lon: 1.5394)
        ],
        costing: .auto,
        units: .mi)

    override func setUpWithError() throws {
        URLProtocol.registerClass(FixtureTileProtocol.self)
        tilesDir = FileManager.default.temporaryDirectory
            .appendingPathComponent("cancel-\(UUID().uuidString)", isDirectory: true)
        try FileManager.default.createDirectory(at: tilesDir, withIntermediateDirectories: true)
    }

    override func tearDownWithError() throws {
        FixtureTileProtocol.beforeAnswering = nil
        URLProtocol.unregisterClass(FixtureTileProtocol.self)
        if let tilesDir {
            try? FileManager.default.removeItem(at: tilesDir)
        }
    }

    func testCancelStopsARunningActionUntilResumed() throws {
        let fetching = DispatchSemaphore(value: 0)
        let release = DispatchSemaphore(value: 0)
        FixtureTileProtocol.beforeAnswering = {
            fetching.signal()
            _ = release.wait(timeout: .now() + 10)
        }
        let config = try ValhallaConfig(tilesUrl: "http://tiles.invalid/{tilePath}", tilesDir: tilesDir)
        let valhalla = try Valhalla(config, configName: "cancel.json")

        let returned = expectation(description: "the running route returned")
        var running: Result<RouteResponse, Error>?
        DispatchQueue.global().async { [request] in
            running = Result { try valhalla.route(request: request) }
            returned.fulfill()
        }
        XCTAssertEqual(fetching.wait(timeout: .now() + 10), .success)

        // The route holds the lock every other method takes, and cancel must not wait for it.
        valhalla.cancel()
        FixtureTileProtocol.beforeAnswering = nil
        release.signal()
        wait(for: [returned], timeout: 10)
        XCTAssertThrowsError(try running?.get()) { error in
            XCTAssertEqual(error as? ValhallaError, .valhallaError(-1, "valhalla-mobile: cancelled"))
        }

        valhalla.resume()
        XCTAssertEqual(try valhalla.route(request: request).trip.statusMessage, "Found route between points")
    }
}

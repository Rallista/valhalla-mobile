import XCTest
import ValhallaModels
import ValhallaConfigModels
@testable import Valhalla

/// Releasing the native actor, and what happens to an instance that has been closed.
final class TestValhallaLifecycle: XCTestCase {

    private var config: ValhallaConfig!

    override func setUp() async throws {
        let tilesTarURL = Bundle.module.url(forResource: "TestData/valhalla_tiles", withExtension: "tar")!
        config = try ValhallaConfig(tileExtractTar: tilesTarURL)
    }

    /// Each instance gets its own config file, since the shared default name means one
    /// instance would otherwise overwrite another's config.
    private func makeValhalla(configName: String = "lifecycle-test.json") throws -> Valhalla {
        try Valhalla(config, configName: configName)
    }

    private var andorraRoute: RouteRequest {
        RouteRequest(
            locations: [
                RoutingWaypoint(lat: 42.5063, lon: 1.5218),
                RoutingWaypoint(lat: 42.5086, lon: 1.5394)
            ],
            costing: .auto,
            units: .mi
        )
    }

    /// Every action refuses to run after `close`, rather than reaching a freed actor.
    func testActionsThrowAfterClose() throws {
        let valhalla = try makeValhalla()

        valhalla.close()

        XCTAssertThrowsError(try valhalla.route(request: andorraRoute)) { error in
            XCTAssertEqual(error as? ValhallaError, .closed)
        }
        XCTAssertThrowsError(try valhalla.route(rawRequest: "{}")) { error in
            XCTAssertEqual(error as? ValhallaError, .closed)
        }
        XCTAssertThrowsError(try valhalla.traceRoute(rawRequest: "{}")) { error in
            XCTAssertEqual(error as? ValhallaError, .closed)
        }
        XCTAssertThrowsError(try valhalla.traceAttributes(rawRequest: "{}")) { error in
            XCTAssertEqual(error as? ValhallaError, .closed)
        }
        XCTAssertThrowsError(try valhalla.height(rawRequest: "{}")) { error in
            XCTAssertEqual(error as? ValhallaError, .closed)
        }
    }

    /// Closing twice is not an error, so a `defer { close() }` next to an explicit one is safe.
    func testCloseIsIdempotent() throws {
        let valhalla = try makeValhalla()

        valhalla.close()
        valhalla.close()

        XCTAssertThrowsError(try valhalla.route(request: andorraRoute))
    }

    /// An instance that is never closed still works. `close` releases the mmapped tile extract
    /// early; it is not a precondition of using the engine.
    func testRoutingWorksWithoutClosing() throws {
        let valhalla = try makeValhalla()

        let response = try valhalla.route(request: andorraRoute)

        XCTAssertEqual(response.trip.statusMessage, "Found route between points")
    }
}

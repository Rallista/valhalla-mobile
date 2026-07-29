import XCTest
import ValhallaModels
import ValhallaConfigModels
@testable import Valhalla

/// Covers the actions beyond `route`: map matching and elevation.
///
/// The map-matching tests route first and feed the resulting shape back in,
/// so the trace input is guaranteed to lie on the graph in `TestData`.
final class TestValhallaActions: XCTestCase {
    private var tilesTarURL: URL!
    private var elevationURL: URL!
    private var valhalla: Valhalla!
    private var valhallaWithElevation: Valhalla!

    /// Two points on the Andorra extract, the same pair the routing tests use.
    private let start = RoutingWaypoint(lat: 42.5063, lon: 1.5218)
    private let end = RoutingWaypoint(lat: 42.5086, lon: 1.5394)

    override func setUp() async throws {
        tilesTarURL = Bundle.module.url(forResource: "TestData/valhalla_tiles", withExtension: "tar")!
        elevationURL = Bundle.module.resourceURL!
            .appendingPathComponent("TestData/elevation", isDirectory: true)

        // Without this the height tests fail as an opaque decoding error,
        // naming neither the fixture nor the cause.
        let tile = elevationURL.appendingPathComponent("N42/N42E001.hgt.gz")
        XCTAssertTrue(
            FileManager.default.fileExists(atPath: tile.path),
            "elevation fixture missing from the test bundle: \(tile.path)"
        )

        valhalla = try Valhalla(try ValhallaConfig(tileExtractTar: tilesTarURL))
        valhallaWithElevation = try Valhalla(
            try ValhallaConfig(tileExtractTar: tilesTarURL, elevationDir: elevationURL)
        )
    }

    /// Route between the two fixture points and return the encoded shape.
    private func routeShape() throws -> String {
        let response = try valhalla.route(
            request: RouteRequest(locations: [start, end], costing: .auto, units: .mi)
        )
        let shape = try XCTUnwrap(response.trip.legs.first?.shape)
        XCTAssertFalse(shape.isEmpty)
        return shape
    }

    // MARK: - Configuration

    func testElevationConfigCarriesBothPaths() throws {
        let config = try ValhallaConfig(tileExtractTar: tilesTarURL, elevationDir: elevationURL)

        XCTAssertEqual(config.additionalData?.elevation, elevationURL.relativePath)
        XCTAssertEqual(config.mjolnir?.tileExtract, tilesTarURL.relativePath)
        XCTAssertNotNil(config.thor, "the rest of the default config should carry through")
    }

    // MARK: - Map matching

    /// A shape that came from the router walks back onto the same edges and
    /// produces narrative maneuvers.
    func testTraceRouteReturnsManeuvers() throws {
        let shape = try routeShape()

        let response = try valhalla.traceRoute(
            request: MapMatchRequest(
                encodedPolyline: shape,
                costing: .auto,
                shapeMatch: .edgeWalk
            )
        )

        let leg = try XCTUnwrap(response.trip.legs.first)
        XCTAssertFalse(leg.maneuvers.isEmpty, "an edge walk should produce maneuvers")
    }

    /// The same shape through `trace_attributes` returns the matched edges
    /// rather than directions, and matches the shape it was given.
    func testTraceAttributesReturnsMatchedEdges() throws {
        let shape = try routeShape()

        let response = try valhalla.traceAttributes(
            request: TraceAttributesRequest(
                encodedPolyline: shape,
                costing: .auto,
                shapeMatch: .edgeWalk
            )
        )

        XCTAssertFalse(response.edges?.isEmpty ?? true, "the walked shape should match edges")
        XCTAssertEqual(
            response.shape, shape,
            "an edge walk should return the shape it was given"
        )
    }

    /// A shape nowhere near the graph fails as a Valhalla error rather than
    /// crashing the wrapper, which is what catching C++ exceptions at the
    /// boundary is for. Covered for both map-matching actions, since they
    /// reach the boundary independently.
    func testTraceRouteOffTheGraphThrows() throws {
        let shape = [
            MapMatchWaypoint(lat: 45.843812, lon: -123.768205),
            MapMatchWaypoint(lat: 45.869701, lon: -123.766121)
        ]

        XCTAssertThrowsError(
            try valhalla.traceRoute(
                request: MapMatchRequest(shape: shape, costing: .auto, shapeMatch: .edgeWalk)
            )
        ) { error in
            guard case ValhallaError.valhallaError = error else {
                return XCTFail("expected a ValhallaError, got \(error)")
            }
        }
    }

    func testTraceAttributesOffTheGraphThrows() throws {
        let shape = [
            MapMatchWaypoint(lat: 45.843812, lon: -123.768205),
            MapMatchWaypoint(lat: 45.869701, lon: -123.766121)
        ]

        XCTAssertThrowsError(
            try valhalla.traceAttributes(
                request: TraceAttributesRequest(shape: shape, costing: .auto, shapeMatch: .edgeWalk)
            )
        ) { error in
            guard case ValhallaError.valhallaError = error else {
                return XCTFail("expected a ValhallaError, got \(error)")
            }
        }
    }

    /// Repeated calls on one actor keep working. `trace_route` used to crash
    /// on the second call until valhalla's `auto_clean` fix landed, so this
    /// guards the regression across every action that shares that actor.
    func testActionsAreRepeatableOnOneActor() throws {
        let shape = try routeShape()
        let trace = MapMatchRequest(encodedPolyline: shape, costing: .auto, shapeMatch: .edgeWalk)
        let attributes = TraceAttributesRequest(
            encodedPolyline: shape, costing: .auto, shapeMatch: .edgeWalk
        )
        let heights = HeightRequest(shape: [Coordinate(lat: start.lat, lon: start.lon)])

        for attempt in 1...3 {
            XCTAssertFalse(
                try valhallaWithElevation.traceRoute(request: trace).trip.legs.isEmpty,
                "traceRoute call \(attempt) returned no legs"
            )
            XCTAssertFalse(
                try valhallaWithElevation.traceAttributes(request: attributes).edges?.isEmpty ?? true,
                "traceAttributes call \(attempt) returned no edges"
            )
            XCTAssertFalse(
                try valhallaWithElevation.height(request: heights).height?.isEmpty ?? true,
                "height call \(attempt) returned no heights"
            )
        }
    }

    // MARK: - Elevation

    /// `TestData/elevation` holds a synthetic tile written by
    /// `scripts/create_elevation_fixture.py`, whose height is exactly
    /// `10800 * (lat - 42) + 3600 * (lon - 1)` metres. Real terrain cannot
    /// support exact assertions, and a real SRTM tile is five times the size
    /// of the whole fixture directory.
    ///
    /// The two coefficients differ so that a row/column mix-up, an off-by-one
    /// in either axis, and a swapped lat/lon pair all change the answer.
    private func expectedHeight(lat: Double, lon: Double) -> Double {
        10800.0 * (lat - 42.0) + 3600.0 * (lon - 1.0)
    }

    func testHeightReturnsElevationsFromConfiguredTiles() throws {
        let shape = [
            Coordinate(lat: start.lat, lon: start.lon),
            Coordinate(lat: end.lat, lon: end.lon)
        ]

        let response = try valhallaWithElevation.height(request: HeightRequest(shape: shape))

        let heights = try XCTUnwrap(response.height)
        XCTAssertEqual(heights.count, shape.count)

        for (coordinate, height) in zip(shape, heights) {
            XCTAssertEqual(
                Double(height),
                expectedHeight(lat: coordinate.lat, lon: coordinate.lon),
                accuracy: 1.0
            )
        }
    }

    /// Latitude resolves to the individual row. One row is 1/3600 of a degree
    /// and the fixture climbs 3 m per row, so an off-by-one row is visible.
    func testHeightResolvesAdjacentRows() throws {
        let oneRow = 1.0 / 3600.0
        let shape = [
            Coordinate(lat: 42.5, lon: 1.5),
            Coordinate(lat: 42.5 + oneRow, lon: 1.5)
        ]

        let heights = try XCTUnwrap(
            valhallaWithElevation.height(request: HeightRequest(shape: shape)).height
        )

        XCTAssertEqual(Double(heights[1] - heights[0]), 3.0, accuracy: 1.0)
    }

    /// Longitude is read too. Same latitude, far apart in longitude, so a
    /// column that is ignored or mis-indexed cannot pass.
    func testHeightVariesWithLongitude() throws {
        let shape = [
            Coordinate(lat: 42.5, lon: 1.20),
            Coordinate(lat: 42.5, lon: 1.80)
        ]

        let heights = try XCTUnwrap(
            valhallaWithElevation.height(request: HeightRequest(shape: shape)).height
        )

        XCTAssertEqual(Double(heights[0]), expectedHeight(lat: 42.5, lon: 1.20), accuracy: 1.0)
        XCTAssertEqual(Double(heights[1]), expectedHeight(lat: 42.5, lon: 1.80), accuracy: 1.0)
        XCTAssertNotEqual(heights[0], heights[1], "longitude must change the sample")
    }

    /// Without an elevation directory the action still succeeds, and answers
    /// null for every point. This is the trap that
    /// `ValhallaConfig(tileExtractTar:elevationDir:)` exists to avoid: a
    /// caller deriving grades sees flat ground rather than an error.
    ///
    /// Asserted through the raw method because `HeightResponse.height` is
    /// typed `[Int]?` in valhalla-openapi-models-swift while its own
    /// documentation says null entries mean missing data. The typed decode
    /// therefore throws on any shape that leaves elevation coverage. Worth
    /// fixing there as `[Int?]?`.
    func testHeightWithoutElevationDataReturnsNulls() throws {
        let request = HeightRequest(shape: [Coordinate(lat: start.lat, lon: start.lon)])
        let requestStr = try XCTUnwrap(String(data: try JSONEncoder().encode(request), encoding: .utf8))

        let raw = valhalla.height(rawRequest: requestStr)
        let json = try JSONSerialization.jsonObject(with: Data(raw.utf8)) as? [String: Any]
        let heights = try XCTUnwrap(json?["height"] as? [Any])

        XCTAssertEqual(heights.count, 1)
        XCTAssertTrue(
            heights.allSatisfy { $0 is NSNull },
            "a graph with no elevation directory should answer null, got \(heights)"
        )
    }
}

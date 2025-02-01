import XCTest
import ValhallaModels
import ValhallaConfigModels
@testable import Valhalla

final class TestValhallaWithTar: XCTestCase {
    var defaultConfig: ValhallaConfig!
    
    override func setUp() async throws {
        let tilesTarUrl = Bundle.module.url(forResource: "TestData/valhalla_tiles", withExtension: "tar")!
        defaultConfig = try ValhallaConfig(tileExtractTar: tilesTarUrl)
    }
    
    /// Validate an incorrect configuration (config file not found).
    func testNoConfigFile() throws {
        do {
            let valhalla = try Valhalla(configPath: "missing.json")

            let request = RouteRequest(
                locations: [
                    RoutingWaypoint(lat: 38.429719, lon: -108.827425),
                    RoutingWaypoint(lat: 38.4604331, lon: -108.8817009)
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
                RoutingWaypoint(lat: 38.429719, lon: -108.827425),
                RoutingWaypoint(lat: 38.4604331, lon: -108.8817009)
            ],
            costing: .auto,
            directionsOptions: DirectionsOptions(units: .mi)
        )
        
        let response = try valhalla.route(request: request)

        XCTAssertEqual(response.trip.statusMessage, "Found route between points")
        XCTAssertEqual(response.trip.legs.first?.shape, "sarhhAlthqnERzHxDvsAx@fa@c@|[uDpn@iJ~h@sMte@yQxd@oUl^ei@nm@sq@rx@sqAzvA}LfN_OdLsZrRo|@l\\ea@jReWbQoSjXiIvKyPf[cJrPaCnEsBfEup@ltAyS|b@oUp`@m~@fuA}\\fa@iQ|NqFtEw_@xSkl@pRc~@bV_a@`H{Qt@oNi@qUsFq|@q]qMsGw]{VqUeTsSmV_Uud@iOqc@ae@idBmXu|@_P}e@oLsWyMcRqNcLoNeIgMyEuOoDgLq@iUg@cVpAm]pFed@`NkWjJ_XjPwQlToOpX{K`^wF~Y_Gfz@wKjcB{Adg@b@nc@nB|UvDvWrJj^z`B`hDtQnYbMdR`p@lq@n^hh@|}AloC~Oja@~Id^~G|g@vBxe@]ji@{Efa@yLzm@sUpi@eQpX_`@ve@}^vc@utAz~AuWpZuLjMsR~I{RlFqU[ic@wLu}Aux@{]gP}WaHua@uE}a@bB{N`Cca@pQe[|WyRjYoPj_@{XfhAiK~`AsDbhAEbt@vFnqA~Fvp@~Lbr@nNf^hR|XvYrXfSpL~TlH~UtElXpItUhKl\\vS~W|W~Zrl@rQpq@jCpW`@vY}Ani@kAvYi@zY|Aph@pBzo@nBxg@fApQhBbPrClMfFjOxIrPzHbKvUvXdIxJ`HhJnInMlG`M`CnGrCfJhClL|@lHnApNb@tRSpSg@fKo@|GuCfPoCfKuCnIcFlLqFnJkHbJkF~EeIbGgL`GoIzCuGtAwGlA{FZgJLiJ_@}K_BgJ}BwJgE{JaGqS_O{hAuz@oxAcdAeNiFq^eI{AQ")
    }
}

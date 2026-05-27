import ValhallaObjc
import ValhallaModels
import ValhallaConfigModels

public protocol ValhallaProviding {
    
    init(_ config: ValhallaConfig) throws
    
    init(configPath: String) throws

    func route(request: RouteRequest) throws -> RouteResponse
}

public final class Valhalla: ValhallaProviding {
    private let actor: ValhallaWrapper?
    private let configPath: String

    public convenience init(_ config: ValhallaConfig) throws {
        let configURL = try ValhallaFileManager.saveConfigTo(config)
        try self.init(configPath: configURL.relativePath)
    }

    public required init(configPath: String) throws {
        do {
            try ValhallaFileManager.injectTzdataIntoLibrary()
        } catch {
            // If you're circumventing this libraries injection, download tzdata.tar and put in your bundle. https://www.iana.org/time-zones
            fatalError("tzdata was not inject into Bundle.main. This can be avoided by including tzdata.tar in your main bundle.")
        }

        self.configPath = configPath
        do {
            self.actor = try ValhallaWrapper(configPath: configPath)
        } catch let error as NSError {
            throw ValhallaError.valhallaError(error.code, error.domain)
        } catch {
            throw ValhallaError.valhallaError(-1, error.localizedDescription)
        }
    }
    
    public func route(request: RouteRequest) throws -> RouteResponse {
        let requestData = try JSONEncoder().encode(request)
        guard let requestStr = String(data: requestData, encoding: .utf8) else {
            throw ValhallaError.encodingNotUtf8("requestStr")
        }
        
        let resultStr = route(rawRequest: requestStr)
        guard let resultData = resultStr.data(using: .utf8) else {
            throw ValhallaError.encodingNotUtf8("resultData")
        }
        
        if let error = try? JSONDecoder().decode(ValhallaErrorModel.self, from: resultData) {
            throw ValhallaError.valhallaError(error.code, error.message)
        }
        
        return try JSONDecoder().decode(RouteResponse.self, from: resultData)
    }

    public func route(rawRequest request: String) -> String {
        actor!.route(request)
    }

    /// Pass-through to Valhalla's locate action. Request body is the
    /// standard locate JSON (see
    /// https://github.com/valhalla/valhalla/blob/master/docs/docs/api/locate/api-reference.md).
    /// Returns the locate response JSON as a string — typically a JSON
    /// array, one entry per input location, each carrying an `edges[]`
    /// list. Pass `verbose: true` in the request to include
    /// `edge_info.shape` (the edge's graph-exact polyline at precision 6),
    /// which is what consumers like GhostRoute need to construct
    /// `linear_cost_factors` shapes that pass the engine's exact
    /// edge-walker (Thor RouteMatcher::FormPath).
    public func locate(rawRequest request: String) -> String {
        actor!.locate(request)
    }
}

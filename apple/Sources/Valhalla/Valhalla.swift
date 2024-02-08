import ValhallaObjc

public protocol ValhallaProtocol {
    init(configPath: String)
    func route(request: String) -> String
}

class Valhalla: ValhallaProtocol {
    
    private let actor = ValhallaWrapper()
    private var configPath: String
    
    public required init(configPath: String) {
        self.configPath = configPath
    }
    
    public func route(request: String) -> String {
        actor!.route(request, configPath: configPath)
    }
}

import ValhallaObjc

public protocol ValhallaProviding {
    init(configPath: String)
    func route(request: String) -> String
}

public final class Valhalla: ValhallaProviding {
    
    private let actor = ValhallaWrapper()
    private var configPath: String
    
    public required init(configPath: String) {
        do {
            try TZDatabaseManager.injectIntoLibrary()
        } catch {
            // If you're circumventing this libraries injection, download tzdata.tar and put in your bundle. https://www.iana.org/time-zones
            assertionFailure("tzdata was not inject into Bundle.main. This can be avoided by including tzdata.tar in your main bundle.")
        }
        
        self.configPath = configPath
    }
    
    public func route(request: String) -> String {
        actor!.route(request, configPath: configPath)
    }
}

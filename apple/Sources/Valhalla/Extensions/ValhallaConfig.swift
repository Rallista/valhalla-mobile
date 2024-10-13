import Foundation
import ValhallaConfigModels

extension ValhallaConfig {
    
    init(data: Data) throws {
        self = try JSONDecoder().decode(ValhallaConfig.self, from: data)
    }

    init(_ json: String, using encoding: String.Encoding = .utf8) throws {
        guard let data = json.data(using: encoding) else {
            throw NSError(domain: "JSONDecoding", code: 0, userInfo: nil)
        }
        try self.init(data: data)
    }

    init(fromURL url: URL) throws {
        try self.init(data: try Data(contentsOf: url))
    }
    
    /// Generate a ValhallaConfig using the defaults provided by the valhalla build scripts.
    ///
    /// This can be used to manipulate select values as a var.
    init() {
        guard let configJsonURL = Bundle.module.url(forResource: "default", withExtension: "json") else {
            fatalError("ValhallaConfig default.json config resource not found in module bundle.")
        }
        
        do {
            try self.init(fromURL: configJsonURL)
        } catch {
            fatalError("ValhallaConfig default.json config resource invalid json.")
        }
    }
    
    init(tileExtractTar: URL) throws {
        let defaultConfig = ValhallaConfig.loadDefault()
        
        var mjolnir = defaultConfig.mjolnir
        mjolnir?.tileExtract = tileExtractTar.relativePath
        
        self.init(additionalData: defaultConfig.additionalData,
                  httpd: defaultConfig.httpd,
                  loki: defaultConfig.loki,
                  meili: defaultConfig.meili,
                  mjolnir: mjolnir,
                  odin: defaultConfig.odin,
                  serviceLimits: defaultConfig.serviceLimits,
                  statsd: defaultConfig.statsd,
                  thor: defaultConfig.thor)
    }
    
    init(tilesDir: URL) throws {
        let defaultConfig = ValhallaConfig.loadDefault()
        
        var mjolnir = defaultConfig.mjolnir
        mjolnir?.tileDir = tilesDir.relativePath
        
        self.init(additionalData: defaultConfig.additionalData,
                  httpd: defaultConfig.httpd,
                  loki: defaultConfig.loki,
                  meili: defaultConfig.meili,
                  mjolnir: mjolnir,
                  odin: defaultConfig.odin,
                  serviceLimits: defaultConfig.serviceLimits,
                  statsd: defaultConfig.statsd,
                  thor: defaultConfig.thor)
    }
    
    static func loadDefault() -> ValhallaConfig {
        guard let configJsonURL = Bundle.module.url(forResource: "default", withExtension: "json") else {
            fatalError("ValhallaConfig default.json config resource not found in module bundle.")
        }
        
        do {
            return try ValhallaConfig(fromURL: configJsonURL)
        } catch {
            fatalError("ValhallaConfig default.json config resource invalid json.")
        }
    }
}

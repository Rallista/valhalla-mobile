import Foundation
import ValhallaConfigModels

extension ValhallaConfig {
    
    /// Initialize ValhallaConfig directly from JSON Data.
    ///
    /// Important! Using this method, you must have functional valhalla config json with
    /// the correct local path to a tiles folder or tar inside the json.
    ///
    /// The ``init(tileExtractTar:)`` or ``init(tilesDir:)`` automate this process
    /// by setting the path in the default valhalla json config (as produced by the valhalla build scripts).
    ///
    /// - Parameter data: A data representation of the valhalla config json.
    public init(data: Data) throws {
        self = try JSONDecoder().decode(ValhallaConfig.self, from: data)
    }

    /// Initialize ValhallaConfig directly from a JSON string.
    ///
    /// Important! Using this method, you must have functional valhalla config json with
    /// the correct local path to a tiles folder or tar inside the json.
    ///
    /// The ``init(tileExtractTar:)`` or ``init(tilesDir:)`` automate this process
    /// by setting the path in the default valhalla json config (as produced by the valhalla build scripts).
    ///
    /// - Parameters:
    ///   - json: The valhalla config json string.
    ///   - encoding: The json's encoding. Default's to utf8
    public init(_ json: String, using encoding: String.Encoding = .utf8) throws {
        guard let data = json.data(using: encoding) else {
            throw NSError(domain: "JSONDecoding", code: 0, userInfo: nil)
        }
        try self.init(data: data)
    }
    
    /// Initialize ValhallaConfig from a local file url.
    ///
    /// Important! Using this method, the file path must point to a functional valhalla config json with
    /// the correct local path to a tiles folder or tar inside the json.
    ///
    /// The ``init(tileExtractTar:)`` or ``init(tilesDir:)`` automate this process
    /// by setting the path in the default valhalla json config (as produced by the valhalla build scripts).
    ///
    /// - Parameter url: The path of the valhalla config json file.
    public init(fromURL url: URL) throws {
        try self.init(data: try Data(contentsOf: url))
    }
    
    /// Initialize ValhallaConfig using the defaults provided by the valhalla build scripts.
    ///
    /// This can be used to manipulate select values as a var.
    public init() {
        guard let configJsonURL = Bundle.module.url(forResource: "default", withExtension: "json") else {
            fatalError("ValhallaConfig default.json config resource not found in module bundle.")
        }
        
        do {
            try self.init(fromURL: configJsonURL)
        } catch {
            fatalError("ValhallaConfig default.json config resource invalid json.")
        }
    }
    
    /// Initialize ValhallaConfig for a specific tar file.
    ///
    /// This injects a tile tarball file path into the default valhalla config.
    ///
    /// - Parameter tileExtractTar: The local file path URL for the tiles tar file.
    public init(tileExtractTar: URL) throws {
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
    
    /// Initialize ValhallaConfig for a specific tiles directory.
    ///
    /// This injects a tile folder path into the default valhalla config.
    ///
    /// - Parameter tileExtractTar: The local folder path URL for the tiles directory.
    public init(tilesDir: URL) throws {
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

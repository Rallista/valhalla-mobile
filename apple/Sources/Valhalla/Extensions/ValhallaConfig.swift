import Foundation
import ValhallaModels

extension ValhallaConfig {
    
    /// Generate a ValhallaConfig using the defaults provided by the valhalla build scripts.
    ///
    /// This can be used to manipulate select values as a var.
    init() {
        guard let configJsonURL = Bundle.module.url(forResource: "SupportData/default", withExtension: "json") else {
            fatalError("ValhallaConfig SupportData/default.json config resource not found in module bundle.")
        }
        
        do {
            try self.init(fromURL: configJsonURL)
        } catch {
            fatalError("ValhallaConfig default.json config resource invalid json.")
        }
    }
    
    init(tileExtractTar: URL) throws {
        let defaultConfig = ValhallaConfig.loadDefault()
        
        let mjolnir = Mjolnir(admin: defaultConfig.mjolnir.admin,
                              dataProcessing: defaultConfig.mjolnir.dataProcessing,
                              globalSynchronizedCache: defaultConfig.mjolnir.globalSynchronizedCache,
                              hierarchy: defaultConfig.mjolnir.hierarchy,
                              idTableSize: defaultConfig.mjolnir.idTableSize,
                              importBikeShareStations: defaultConfig.mjolnir.importBikeShareStations,
                              includeBicycle: defaultConfig.mjolnir.includeBicycle,
                              includeConstruction: defaultConfig.mjolnir.includeConstruction,
                              includeDriveways: defaultConfig.mjolnir.includeDriveways,
                              includeDriving: defaultConfig.mjolnir.includeDriving,
                              includePedestrian: defaultConfig.mjolnir.includePedestrian,
                              logging: defaultConfig.mjolnir.logging,
                              lruMemCacheHardControl: defaultConfig.mjolnir.lruMemCacheHardControl,
                              maxCacheSize: defaultConfig.mjolnir.maxCacheSize,
                              maxConcurrentReaderUsers: defaultConfig.mjolnir.maxConcurrentReaderUsers,
                              reclassifyLinks: defaultConfig.mjolnir.reclassifyLinks,
                              shortcuts: defaultConfig.mjolnir.shortcuts,
                              tileDir: defaultConfig.mjolnir.tileDir,
                              tileExtract: tileExtractTar.relativePath,
                              timezone: defaultConfig.mjolnir.timezone,
                              trafficExtract: defaultConfig.mjolnir.trafficExtract,
                              transitDir: defaultConfig.mjolnir.transitDir,
                              transitFeedsDir: defaultConfig.mjolnir.transitFeedsDir,
                              useLRUMemCache: defaultConfig.mjolnir.useLRUMemCache,
                              useSimpleMemCache: defaultConfig.mjolnir.useSimpleMemCache)
        
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
        
        let mjolnir = Mjolnir(admin: defaultConfig.mjolnir.admin,
                              dataProcessing: defaultConfig.mjolnir.dataProcessing,
                              globalSynchronizedCache: defaultConfig.mjolnir.globalSynchronizedCache,
                              hierarchy: defaultConfig.mjolnir.hierarchy,
                              idTableSize: defaultConfig.mjolnir.idTableSize,
                              importBikeShareStations: defaultConfig.mjolnir.importBikeShareStations,
                              includeBicycle: defaultConfig.mjolnir.includeBicycle,
                              includeConstruction: defaultConfig.mjolnir.includeConstruction,
                              includeDriveways: defaultConfig.mjolnir.includeDriveways,
                              includeDriving: defaultConfig.mjolnir.includeDriving,
                              includePedestrian: defaultConfig.mjolnir.includePedestrian,
                              logging: defaultConfig.mjolnir.logging,
                              lruMemCacheHardControl: defaultConfig.mjolnir.lruMemCacheHardControl,
                              maxCacheSize: defaultConfig.mjolnir.maxCacheSize,
                              maxConcurrentReaderUsers: defaultConfig.mjolnir.maxConcurrentReaderUsers,
                              reclassifyLinks: defaultConfig.mjolnir.reclassifyLinks,
                              shortcuts: defaultConfig.mjolnir.shortcuts,
                              tileDir: tilesDir.relativePath,
                              tileExtract: defaultConfig.mjolnir.tileExtract,
                              timezone: defaultConfig.mjolnir.timezone,
                              trafficExtract: defaultConfig.mjolnir.trafficExtract,
                              transitDir: defaultConfig.mjolnir.transitDir,
                              transitFeedsDir: defaultConfig.mjolnir.transitFeedsDir,
                              useLRUMemCache: defaultConfig.mjolnir.useLRUMemCache,
                              useSimpleMemCache: defaultConfig.mjolnir.useSimpleMemCache)
        
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
        guard let configJsonURL = Bundle.module.url(forResource: "SupportData/default", withExtension: "json") else {
            fatalError("ValhallaConfig SupportData/default.json config resource not found in module bundle.")
        }
        
        do {
            return try ValhallaConfig(fromURL: configJsonURL)
        } catch {
            fatalError("ValhallaConfig default.json config resource invalid json.")
        }
    }
}

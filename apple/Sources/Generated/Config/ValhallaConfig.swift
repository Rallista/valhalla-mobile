// This file was generated from JSON Schema using quicktype, do not modify it directly.
// To parse the JSON, add this file to your project and do:
//
//   let valhallaConfig = try ValhallaConfig(json)

import Foundation

// MARK: - ValhallaConfig
public struct ValhallaConfig: Codable {
    public let additionalData: AdditionalData
    public let httpd: Httpd
    public let loki: Loki
    public let meili: Meili
    public let mjolnir: Mjolnir
    public let odin: Odin
    public let serviceLimits: ServiceLimits
    public let statsd: Statsd
    public let thor: Thor

    enum CodingKeys: String, CodingKey {
        case additionalData = "additional_data"
        case httpd, loki, meili, mjolnir, odin
        case serviceLimits = "service_limits"
        case statsd, thor
    }

    public init(additionalData: AdditionalData, httpd: Httpd, loki: Loki, meili: Meili, mjolnir: Mjolnir, odin: Odin, serviceLimits: ServiceLimits, statsd: Statsd, thor: Thor) {
        self.additionalData = additionalData
        self.httpd = httpd
        self.loki = loki
        self.meili = meili
        self.mjolnir = mjolnir
        self.odin = odin
        self.serviceLimits = serviceLimits
        self.statsd = statsd
        self.thor = thor
    }
}

// MARK: ValhallaConfig convenience initializers and mutators

public extension ValhallaConfig {
    init(data: Data) throws {
        self = try newJSONDecoder().decode(ValhallaConfig.self, from: data)
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

    func with(
        additionalData: AdditionalData? = nil,
        httpd: Httpd? = nil,
        loki: Loki? = nil,
        meili: Meili? = nil,
        mjolnir: Mjolnir? = nil,
        odin: Odin? = nil,
        serviceLimits: ServiceLimits? = nil,
        statsd: Statsd? = nil,
        thor: Thor? = nil
    ) -> ValhallaConfig {
        return ValhallaConfig(
            additionalData: additionalData ?? self.additionalData,
            httpd: httpd ?? self.httpd,
            loki: loki ?? self.loki,
            meili: meili ?? self.meili,
            mjolnir: mjolnir ?? self.mjolnir,
            odin: odin ?? self.odin,
            serviceLimits: serviceLimits ?? self.serviceLimits,
            statsd: statsd ?? self.statsd,
            thor: thor ?? self.thor
        )
    }

    func jsonData() throws -> Data {
        return try newJSONEncoder().encode(self)
    }

    func jsonString(encoding: String.Encoding = .utf8) throws -> String? {
        return String(data: try self.jsonData(), encoding: encoding)
    }
}

// MARK: - AdditionalData
public struct AdditionalData: Codable {
    public let elevation: String

    public init(elevation: String) {
        self.elevation = elevation
    }
}

// MARK: AdditionalData convenience initializers and mutators

public extension AdditionalData {
    init(data: Data) throws {
        self = try newJSONDecoder().decode(AdditionalData.self, from: data)
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

    func with(
        elevation: String? = nil
    ) -> AdditionalData {
        return AdditionalData(
            elevation: elevation ?? self.elevation
        )
    }

    func jsonData() throws -> Data {
        return try newJSONEncoder().encode(self)
    }

    func jsonString(encoding: String.Encoding = .utf8) throws -> String? {
        return String(data: try self.jsonData(), encoding: encoding)
    }
}

// MARK: - Httpd
public struct Httpd: Codable {
    public let service: HttpdService

    public init(service: HttpdService) {
        self.service = service
    }
}

// MARK: Httpd convenience initializers and mutators

public extension Httpd {
    init(data: Data) throws {
        self = try newJSONDecoder().decode(Httpd.self, from: data)
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

    func with(
        service: HttpdService? = nil
    ) -> Httpd {
        return Httpd(
            service: service ?? self.service
        )
    }

    func jsonData() throws -> Data {
        return try newJSONEncoder().encode(self)
    }

    func jsonString(encoding: String.Encoding = .utf8) throws -> String? {
        return String(data: try self.jsonData(), encoding: encoding)
    }
}

// MARK: - HttpdService
public struct HttpdService: Codable {
    public let drainSeconds: Int
    public let interrupt, listen, loopback: String
    public let shutdownSeconds: Int

    enum CodingKeys: String, CodingKey {
        case drainSeconds = "drain_seconds"
        case interrupt, listen, loopback
        case shutdownSeconds = "shutdown_seconds"
    }

    public init(drainSeconds: Int, interrupt: String, listen: String, loopback: String, shutdownSeconds: Int) {
        self.drainSeconds = drainSeconds
        self.interrupt = interrupt
        self.listen = listen
        self.loopback = loopback
        self.shutdownSeconds = shutdownSeconds
    }
}

// MARK: HttpdService convenience initializers and mutators

public extension HttpdService {
    init(data: Data) throws {
        self = try newJSONDecoder().decode(HttpdService.self, from: data)
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

    func with(
        drainSeconds: Int? = nil,
        interrupt: String? = nil,
        listen: String? = nil,
        loopback: String? = nil,
        shutdownSeconds: Int? = nil
    ) -> HttpdService {
        return HttpdService(
            drainSeconds: drainSeconds ?? self.drainSeconds,
            interrupt: interrupt ?? self.interrupt,
            listen: listen ?? self.listen,
            loopback: loopback ?? self.loopback,
            shutdownSeconds: shutdownSeconds ?? self.shutdownSeconds
        )
    }

    func jsonData() throws -> Data {
        return try newJSONEncoder().encode(self)
    }

    func jsonString(encoding: String.Encoding = .utf8) throws -> String? {
        return String(data: try self.jsonData(), encoding: encoding)
    }
}

// MARK: - Loki
public struct Loki: Codable {
    public let actions: [String]
    public let logging: Logging
    public let service: LokiService
    public let serviceDefaults: ServiceDefaults
    public let useConnectivity: Bool

    enum CodingKeys: String, CodingKey {
        case actions, logging, service
        case serviceDefaults = "service_defaults"
        case useConnectivity = "use_connectivity"
    }

    public init(actions: [String], logging: Logging, service: LokiService, serviceDefaults: ServiceDefaults, useConnectivity: Bool) {
        self.actions = actions
        self.logging = logging
        self.service = service
        self.serviceDefaults = serviceDefaults
        self.useConnectivity = useConnectivity
    }
}

// MARK: Loki convenience initializers and mutators

public extension Loki {
    init(data: Data) throws {
        self = try newJSONDecoder().decode(Loki.self, from: data)
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

    func with(
        actions: [String]? = nil,
        logging: Logging? = nil,
        service: LokiService? = nil,
        serviceDefaults: ServiceDefaults? = nil,
        useConnectivity: Bool? = nil
    ) -> Loki {
        return Loki(
            actions: actions ?? self.actions,
            logging: logging ?? self.logging,
            service: service ?? self.service,
            serviceDefaults: serviceDefaults ?? self.serviceDefaults,
            useConnectivity: useConnectivity ?? self.useConnectivity
        )
    }

    func jsonData() throws -> Data {
        return try newJSONEncoder().encode(self)
    }

    func jsonString(encoding: String.Encoding = .utf8) throws -> String? {
        return String(data: try self.jsonData(), encoding: encoding)
    }
}

// MARK: - Logging
public struct Logging: Codable {
    public let color: Bool
    public let fileName: String
    public let longRequest: Int?
    public let type: String

    enum CodingKeys: String, CodingKey {
        case color
        case fileName = "file_name"
        case longRequest = "long_request"
        case type
    }

    public init(color: Bool, fileName: String, longRequest: Int?, type: String) {
        self.color = color
        self.fileName = fileName
        self.longRequest = longRequest
        self.type = type
    }
}

// MARK: Logging convenience initializers and mutators

public extension Logging {
    init(data: Data) throws {
        self = try newJSONDecoder().decode(Logging.self, from: data)
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

    func with(
        color: Bool? = nil,
        fileName: String? = nil,
        longRequest: Int?? = nil,
        type: String? = nil
    ) -> Logging {
        return Logging(
            color: color ?? self.color,
            fileName: fileName ?? self.fileName,
            longRequest: longRequest ?? self.longRequest,
            type: type ?? self.type
        )
    }

    func jsonData() throws -> Data {
        return try newJSONEncoder().encode(self)
    }

    func jsonString(encoding: String.Encoding = .utf8) throws -> String? {
        return String(data: try self.jsonData(), encoding: encoding)
    }
}

// MARK: - LokiService
public struct LokiService: Codable {
    public let proxy: String

    public init(proxy: String) {
        self.proxy = proxy
    }
}

// MARK: LokiService convenience initializers and mutators

public extension LokiService {
    init(data: Data) throws {
        self = try newJSONDecoder().decode(LokiService.self, from: data)
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

    func with(
        proxy: String? = nil
    ) -> LokiService {
        return LokiService(
            proxy: proxy ?? self.proxy
        )
    }

    func jsonData() throws -> Data {
        return try newJSONEncoder().encode(self)
    }

    func jsonString(encoding: String.Encoding = .utf8) throws -> String? {
        return String(data: try self.jsonData(), encoding: encoding)
    }
}

// MARK: - ServiceDefaults
public struct ServiceDefaults: Codable {
    public let headingTolerance, minimumReachability, nodeSnapTolerance, radius: Int
    public let searchCutoff, streetSideMaxDistance, streetSideTolerance: Int

    enum CodingKeys: String, CodingKey {
        case headingTolerance = "heading_tolerance"
        case minimumReachability = "minimum_reachability"
        case nodeSnapTolerance = "node_snap_tolerance"
        case radius
        case searchCutoff = "search_cutoff"
        case streetSideMaxDistance = "street_side_max_distance"
        case streetSideTolerance = "street_side_tolerance"
    }

    public init(headingTolerance: Int, minimumReachability: Int, nodeSnapTolerance: Int, radius: Int, searchCutoff: Int, streetSideMaxDistance: Int, streetSideTolerance: Int) {
        self.headingTolerance = headingTolerance
        self.minimumReachability = minimumReachability
        self.nodeSnapTolerance = nodeSnapTolerance
        self.radius = radius
        self.searchCutoff = searchCutoff
        self.streetSideMaxDistance = streetSideMaxDistance
        self.streetSideTolerance = streetSideTolerance
    }
}

// MARK: ServiceDefaults convenience initializers and mutators

public extension ServiceDefaults {
    init(data: Data) throws {
        self = try newJSONDecoder().decode(ServiceDefaults.self, from: data)
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

    func with(
        headingTolerance: Int? = nil,
        minimumReachability: Int? = nil,
        nodeSnapTolerance: Int? = nil,
        radius: Int? = nil,
        searchCutoff: Int? = nil,
        streetSideMaxDistance: Int? = nil,
        streetSideTolerance: Int? = nil
    ) -> ServiceDefaults {
        return ServiceDefaults(
            headingTolerance: headingTolerance ?? self.headingTolerance,
            minimumReachability: minimumReachability ?? self.minimumReachability,
            nodeSnapTolerance: nodeSnapTolerance ?? self.nodeSnapTolerance,
            radius: radius ?? self.radius,
            searchCutoff: searchCutoff ?? self.searchCutoff,
            streetSideMaxDistance: streetSideMaxDistance ?? self.streetSideMaxDistance,
            streetSideTolerance: streetSideTolerance ?? self.streetSideTolerance
        )
    }

    func jsonData() throws -> Data {
        return try newJSONEncoder().encode(self)
    }

    func jsonString(encoding: String.Encoding = .utf8) throws -> String? {
        return String(data: try self.jsonData(), encoding: encoding)
    }
}

// MARK: - Meili
public struct Meili: Codable {
    public let auto: PedestrianClass
    public let bicycle: Bicycle
    public let customizable: [String]
    public let meiliDefault: Default
    public let grid: Grid
    public let logging: Logging
    public let mode: String
    public let multimodal: Bicycle
    public let pedestrian: PedestrianClass
    public let service: LokiService
    public let verbose: Bool

    enum CodingKeys: String, CodingKey {
        case auto, bicycle, customizable
        case meiliDefault = "default"
        case grid, logging, mode, multimodal, pedestrian, service, verbose
    }

    public init(auto: PedestrianClass, bicycle: Bicycle, customizable: [String], meiliDefault: Default, grid: Grid, logging: Logging, mode: String, multimodal: Bicycle, pedestrian: PedestrianClass, service: LokiService, verbose: Bool) {
        self.auto = auto
        self.bicycle = bicycle
        self.customizable = customizable
        self.meiliDefault = meiliDefault
        self.grid = grid
        self.logging = logging
        self.mode = mode
        self.multimodal = multimodal
        self.pedestrian = pedestrian
        self.service = service
        self.verbose = verbose
    }
}

// MARK: Meili convenience initializers and mutators

public extension Meili {
    init(data: Data) throws {
        self = try newJSONDecoder().decode(Meili.self, from: data)
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

    func with(
        auto: PedestrianClass? = nil,
        bicycle: Bicycle? = nil,
        customizable: [String]? = nil,
        meiliDefault: Default? = nil,
        grid: Grid? = nil,
        logging: Logging? = nil,
        mode: String? = nil,
        multimodal: Bicycle? = nil,
        pedestrian: PedestrianClass? = nil,
        service: LokiService? = nil,
        verbose: Bool? = nil
    ) -> Meili {
        return Meili(
            auto: auto ?? self.auto,
            bicycle: bicycle ?? self.bicycle,
            customizable: customizable ?? self.customizable,
            meiliDefault: meiliDefault ?? self.meiliDefault,
            grid: grid ?? self.grid,
            logging: logging ?? self.logging,
            mode: mode ?? self.mode,
            multimodal: multimodal ?? self.multimodal,
            pedestrian: pedestrian ?? self.pedestrian,
            service: service ?? self.service,
            verbose: verbose ?? self.verbose
        )
    }

    func jsonData() throws -> Data {
        return try newJSONEncoder().encode(self)
    }

    func jsonString(encoding: String.Encoding = .utf8) throws -> String? {
        return String(data: try self.jsonData(), encoding: encoding)
    }
}

// MARK: - PedestrianClass
public struct PedestrianClass: Codable {
    public let searchRadius, turnPenaltyFactor: Int

    enum CodingKeys: String, CodingKey {
        case searchRadius = "search_radius"
        case turnPenaltyFactor = "turn_penalty_factor"
    }

    public init(searchRadius: Int, turnPenaltyFactor: Int) {
        self.searchRadius = searchRadius
        self.turnPenaltyFactor = turnPenaltyFactor
    }
}

// MARK: PedestrianClass convenience initializers and mutators

public extension PedestrianClass {
    init(data: Data) throws {
        self = try newJSONDecoder().decode(PedestrianClass.self, from: data)
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

    func with(
        searchRadius: Int? = nil,
        turnPenaltyFactor: Int? = nil
    ) -> PedestrianClass {
        return PedestrianClass(
            searchRadius: searchRadius ?? self.searchRadius,
            turnPenaltyFactor: turnPenaltyFactor ?? self.turnPenaltyFactor
        )
    }

    func jsonData() throws -> Data {
        return try newJSONEncoder().encode(self)
    }

    func jsonString(encoding: String.Encoding = .utf8) throws -> String? {
        return String(data: try self.jsonData(), encoding: encoding)
    }
}

// MARK: - Bicycle
public struct Bicycle: Codable {
    public let turnPenaltyFactor: Int

    enum CodingKeys: String, CodingKey {
        case turnPenaltyFactor = "turn_penalty_factor"
    }

    public init(turnPenaltyFactor: Int) {
        self.turnPenaltyFactor = turnPenaltyFactor
    }
}

// MARK: Bicycle convenience initializers and mutators

public extension Bicycle {
    init(data: Data) throws {
        self = try newJSONDecoder().decode(Bicycle.self, from: data)
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

    func with(
        turnPenaltyFactor: Int? = nil
    ) -> Bicycle {
        return Bicycle(
            turnPenaltyFactor: turnPenaltyFactor ?? self.turnPenaltyFactor
        )
    }

    func jsonData() throws -> Data {
        return try newJSONEncoder().encode(self)
    }

    func jsonString(encoding: String.Encoding = .utf8) throws -> String? {
        return String(data: try self.jsonData(), encoding: encoding)
    }
}

// MARK: - Grid
public struct Grid: Codable {
    public let cacheSize, size: Int

    enum CodingKeys: String, CodingKey {
        case cacheSize = "cache_size"
        case size
    }

    public init(cacheSize: Int, size: Int) {
        self.cacheSize = cacheSize
        self.size = size
    }
}

// MARK: Grid convenience initializers and mutators

public extension Grid {
    init(data: Data) throws {
        self = try newJSONDecoder().decode(Grid.self, from: data)
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

    func with(
        cacheSize: Int? = nil,
        size: Int? = nil
    ) -> Grid {
        return Grid(
            cacheSize: cacheSize ?? self.cacheSize,
            size: size ?? self.size
        )
    }

    func jsonData() throws -> Data {
        return try newJSONEncoder().encode(self)
    }

    func jsonString(encoding: String.Encoding = .utf8) throws -> String? {
        return String(data: try self.jsonData(), encoding: encoding)
    }
}

// MARK: - Default
public struct Default: Codable {
    public let beta, breakageDistance: Int
    public let geometry: Bool
    public let gpsAccuracy, interpolationDistance, maxRouteDistanceFactor, maxRouteTimeFactor: Int
    public let maxSearchRadius: Int
    public let route: Bool
    public let searchRadius: Int
    public let sigmaZ: Double
    public let turnPenaltyFactor: Int

    enum CodingKeys: String, CodingKey {
        case beta
        case breakageDistance = "breakage_distance"
        case geometry
        case gpsAccuracy = "gps_accuracy"
        case interpolationDistance = "interpolation_distance"
        case maxRouteDistanceFactor = "max_route_distance_factor"
        case maxRouteTimeFactor = "max_route_time_factor"
        case maxSearchRadius = "max_search_radius"
        case route
        case searchRadius = "search_radius"
        case sigmaZ = "sigma_z"
        case turnPenaltyFactor = "turn_penalty_factor"
    }

    public init(beta: Int, breakageDistance: Int, geometry: Bool, gpsAccuracy: Int, interpolationDistance: Int, maxRouteDistanceFactor: Int, maxRouteTimeFactor: Int, maxSearchRadius: Int, route: Bool, searchRadius: Int, sigmaZ: Double, turnPenaltyFactor: Int) {
        self.beta = beta
        self.breakageDistance = breakageDistance
        self.geometry = geometry
        self.gpsAccuracy = gpsAccuracy
        self.interpolationDistance = interpolationDistance
        self.maxRouteDistanceFactor = maxRouteDistanceFactor
        self.maxRouteTimeFactor = maxRouteTimeFactor
        self.maxSearchRadius = maxSearchRadius
        self.route = route
        self.searchRadius = searchRadius
        self.sigmaZ = sigmaZ
        self.turnPenaltyFactor = turnPenaltyFactor
    }
}

// MARK: Default convenience initializers and mutators

public extension Default {
    init(data: Data) throws {
        self = try newJSONDecoder().decode(Default.self, from: data)
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

    func with(
        beta: Int? = nil,
        breakageDistance: Int? = nil,
        geometry: Bool? = nil,
        gpsAccuracy: Int? = nil,
        interpolationDistance: Int? = nil,
        maxRouteDistanceFactor: Int? = nil,
        maxRouteTimeFactor: Int? = nil,
        maxSearchRadius: Int? = nil,
        route: Bool? = nil,
        searchRadius: Int? = nil,
        sigmaZ: Double? = nil,
        turnPenaltyFactor: Int? = nil
    ) -> Default {
        return Default(
            beta: beta ?? self.beta,
            breakageDistance: breakageDistance ?? self.breakageDistance,
            geometry: geometry ?? self.geometry,
            gpsAccuracy: gpsAccuracy ?? self.gpsAccuracy,
            interpolationDistance: interpolationDistance ?? self.interpolationDistance,
            maxRouteDistanceFactor: maxRouteDistanceFactor ?? self.maxRouteDistanceFactor,
            maxRouteTimeFactor: maxRouteTimeFactor ?? self.maxRouteTimeFactor,
            maxSearchRadius: maxSearchRadius ?? self.maxSearchRadius,
            route: route ?? self.route,
            searchRadius: searchRadius ?? self.searchRadius,
            sigmaZ: sigmaZ ?? self.sigmaZ,
            turnPenaltyFactor: turnPenaltyFactor ?? self.turnPenaltyFactor
        )
    }

    func jsonData() throws -> Data {
        return try newJSONEncoder().encode(self)
    }

    func jsonString(encoding: String.Encoding = .utf8) throws -> String? {
        return String(data: try self.jsonData(), encoding: encoding)
    }
}

// MARK: - Mjolnir
public struct Mjolnir: Codable {
    public let admin: String
    public let dataProcessing: DataProcessing
    public let globalSynchronizedCache, hierarchy: Bool
    public let idTableSize: Int
    public let importBikeShareStations, includeBicycle, includeConstruction, includeDriveways: Bool
    public let includeDriving, includePedestrian: Bool
    public let logging: Logging
    public let lruMemCacheHardControl: Bool
    public let maxCacheSize, maxConcurrentReaderUsers: Int
    public let reclassifyLinks, shortcuts: Bool
    public let tileDir, tileExtract, timezone, trafficExtract: String
    public let transitDir, transitFeedsDir: String
    public let useLRUMemCache, useSimpleMemCache: Bool

    enum CodingKeys: String, CodingKey {
        case admin
        case dataProcessing = "data_processing"
        case globalSynchronizedCache = "global_synchronized_cache"
        case hierarchy
        case idTableSize = "id_table_size"
        case importBikeShareStations = "import_bike_share_stations"
        case includeBicycle = "include_bicycle"
        case includeConstruction = "include_construction"
        case includeDriveways = "include_driveways"
        case includeDriving = "include_driving"
        case includePedestrian = "include_pedestrian"
        case logging
        case lruMemCacheHardControl = "lru_mem_cache_hard_control"
        case maxCacheSize = "max_cache_size"
        case maxConcurrentReaderUsers = "max_concurrent_reader_users"
        case reclassifyLinks = "reclassify_links"
        case shortcuts
        case tileDir = "tile_dir"
        case tileExtract = "tile_extract"
        case timezone
        case trafficExtract = "traffic_extract"
        case transitDir = "transit_dir"
        case transitFeedsDir = "transit_feeds_dir"
        case useLRUMemCache = "use_lru_mem_cache"
        case useSimpleMemCache = "use_simple_mem_cache"
    }

    public init(admin: String, dataProcessing: DataProcessing, globalSynchronizedCache: Bool, hierarchy: Bool, idTableSize: Int, importBikeShareStations: Bool, includeBicycle: Bool, includeConstruction: Bool, includeDriveways: Bool, includeDriving: Bool, includePedestrian: Bool, logging: Logging, lruMemCacheHardControl: Bool, maxCacheSize: Int, maxConcurrentReaderUsers: Int, reclassifyLinks: Bool, shortcuts: Bool, tileDir: String, tileExtract: String, timezone: String, trafficExtract: String, transitDir: String, transitFeedsDir: String, useLRUMemCache: Bool, useSimpleMemCache: Bool) {
        self.admin = admin
        self.dataProcessing = dataProcessing
        self.globalSynchronizedCache = globalSynchronizedCache
        self.hierarchy = hierarchy
        self.idTableSize = idTableSize
        self.importBikeShareStations = importBikeShareStations
        self.includeBicycle = includeBicycle
        self.includeConstruction = includeConstruction
        self.includeDriveways = includeDriveways
        self.includeDriving = includeDriving
        self.includePedestrian = includePedestrian
        self.logging = logging
        self.lruMemCacheHardControl = lruMemCacheHardControl
        self.maxCacheSize = maxCacheSize
        self.maxConcurrentReaderUsers = maxConcurrentReaderUsers
        self.reclassifyLinks = reclassifyLinks
        self.shortcuts = shortcuts
        self.tileDir = tileDir
        self.tileExtract = tileExtract
        self.timezone = timezone
        self.trafficExtract = trafficExtract
        self.transitDir = transitDir
        self.transitFeedsDir = transitFeedsDir
        self.useLRUMemCache = useLRUMemCache
        self.useSimpleMemCache = useSimpleMemCache
    }
}

// MARK: Mjolnir convenience initializers and mutators

public extension Mjolnir {
    init(data: Data) throws {
        self = try newJSONDecoder().decode(Mjolnir.self, from: data)
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

    func with(
        admin: String? = nil,
        dataProcessing: DataProcessing? = nil,
        globalSynchronizedCache: Bool? = nil,
        hierarchy: Bool? = nil,
        idTableSize: Int? = nil,
        importBikeShareStations: Bool? = nil,
        includeBicycle: Bool? = nil,
        includeConstruction: Bool? = nil,
        includeDriveways: Bool? = nil,
        includeDriving: Bool? = nil,
        includePedestrian: Bool? = nil,
        logging: Logging? = nil,
        lruMemCacheHardControl: Bool? = nil,
        maxCacheSize: Int? = nil,
        maxConcurrentReaderUsers: Int? = nil,
        reclassifyLinks: Bool? = nil,
        shortcuts: Bool? = nil,
        tileDir: String? = nil,
        tileExtract: String? = nil,
        timezone: String? = nil,
        trafficExtract: String? = nil,
        transitDir: String? = nil,
        transitFeedsDir: String? = nil,
        useLRUMemCache: Bool? = nil,
        useSimpleMemCache: Bool? = nil
    ) -> Mjolnir {
        return Mjolnir(
            admin: admin ?? self.admin,
            dataProcessing: dataProcessing ?? self.dataProcessing,
            globalSynchronizedCache: globalSynchronizedCache ?? self.globalSynchronizedCache,
            hierarchy: hierarchy ?? self.hierarchy,
            idTableSize: idTableSize ?? self.idTableSize,
            importBikeShareStations: importBikeShareStations ?? self.importBikeShareStations,
            includeBicycle: includeBicycle ?? self.includeBicycle,
            includeConstruction: includeConstruction ?? self.includeConstruction,
            includeDriveways: includeDriveways ?? self.includeDriveways,
            includeDriving: includeDriving ?? self.includeDriving,
            includePedestrian: includePedestrian ?? self.includePedestrian,
            logging: logging ?? self.logging,
            lruMemCacheHardControl: lruMemCacheHardControl ?? self.lruMemCacheHardControl,
            maxCacheSize: maxCacheSize ?? self.maxCacheSize,
            maxConcurrentReaderUsers: maxConcurrentReaderUsers ?? self.maxConcurrentReaderUsers,
            reclassifyLinks: reclassifyLinks ?? self.reclassifyLinks,
            shortcuts: shortcuts ?? self.shortcuts,
            tileDir: tileDir ?? self.tileDir,
            tileExtract: tileExtract ?? self.tileExtract,
            timezone: timezone ?? self.timezone,
            trafficExtract: trafficExtract ?? self.trafficExtract,
            transitDir: transitDir ?? self.transitDir,
            transitFeedsDir: transitFeedsDir ?? self.transitFeedsDir,
            useLRUMemCache: useLRUMemCache ?? self.useLRUMemCache,
            useSimpleMemCache: useSimpleMemCache ?? self.useSimpleMemCache
        )
    }

    func jsonData() throws -> Data {
        return try newJSONEncoder().encode(self)
    }

    func jsonString(encoding: String.Encoding = .utf8) throws -> String? {
        return String(data: try self.jsonData(), encoding: encoding)
    }
}

// MARK: - DataProcessing
public struct DataProcessing: Codable {
    public let allowAltName, applyCountryOverrides, inferInternalIntersections, inferTurnChannels: Bool
    public let scanTar, useAdminDB, useDirectionOnWays, useRESTArea: Bool
    public let useUrbanTag: Bool

    enum CodingKeys: String, CodingKey {
        case allowAltName = "allow_alt_name"
        case applyCountryOverrides = "apply_country_overrides"
        case inferInternalIntersections = "infer_internal_intersections"
        case inferTurnChannels = "infer_turn_channels"
        case scanTar = "scan_tar"
        case useAdminDB = "use_admin_db"
        case useDirectionOnWays = "use_direction_on_ways"
        case useRESTArea = "use_rest_area"
        case useUrbanTag = "use_urban_tag"
    }

    public init(allowAltName: Bool, applyCountryOverrides: Bool, inferInternalIntersections: Bool, inferTurnChannels: Bool, scanTar: Bool, useAdminDB: Bool, useDirectionOnWays: Bool, useRESTArea: Bool, useUrbanTag: Bool) {
        self.allowAltName = allowAltName
        self.applyCountryOverrides = applyCountryOverrides
        self.inferInternalIntersections = inferInternalIntersections
        self.inferTurnChannels = inferTurnChannels
        self.scanTar = scanTar
        self.useAdminDB = useAdminDB
        self.useDirectionOnWays = useDirectionOnWays
        self.useRESTArea = useRESTArea
        self.useUrbanTag = useUrbanTag
    }
}

// MARK: DataProcessing convenience initializers and mutators

public extension DataProcessing {
    init(data: Data) throws {
        self = try newJSONDecoder().decode(DataProcessing.self, from: data)
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

    func with(
        allowAltName: Bool? = nil,
        applyCountryOverrides: Bool? = nil,
        inferInternalIntersections: Bool? = nil,
        inferTurnChannels: Bool? = nil,
        scanTar: Bool? = nil,
        useAdminDB: Bool? = nil,
        useDirectionOnWays: Bool? = nil,
        useRESTArea: Bool? = nil,
        useUrbanTag: Bool? = nil
    ) -> DataProcessing {
        return DataProcessing(
            allowAltName: allowAltName ?? self.allowAltName,
            applyCountryOverrides: applyCountryOverrides ?? self.applyCountryOverrides,
            inferInternalIntersections: inferInternalIntersections ?? self.inferInternalIntersections,
            inferTurnChannels: inferTurnChannels ?? self.inferTurnChannels,
            scanTar: scanTar ?? self.scanTar,
            useAdminDB: useAdminDB ?? self.useAdminDB,
            useDirectionOnWays: useDirectionOnWays ?? self.useDirectionOnWays,
            useRESTArea: useRESTArea ?? self.useRESTArea,
            useUrbanTag: useUrbanTag ?? self.useUrbanTag
        )
    }

    func jsonData() throws -> Data {
        return try newJSONEncoder().encode(self)
    }

    func jsonString(encoding: String.Encoding = .utf8) throws -> String? {
        return String(data: try self.jsonData(), encoding: encoding)
    }
}

// MARK: - Odin
public struct Odin: Codable {
    public let logging: Logging
    public let markupFormatter: MarkupFormatter
    public let service: LokiService

    enum CodingKeys: String, CodingKey {
        case logging
        case markupFormatter = "markup_formatter"
        case service
    }

    public init(logging: Logging, markupFormatter: MarkupFormatter, service: LokiService) {
        self.logging = logging
        self.markupFormatter = markupFormatter
        self.service = service
    }
}

// MARK: Odin convenience initializers and mutators

public extension Odin {
    init(data: Data) throws {
        self = try newJSONDecoder().decode(Odin.self, from: data)
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

    func with(
        logging: Logging? = nil,
        markupFormatter: MarkupFormatter? = nil,
        service: LokiService? = nil
    ) -> Odin {
        return Odin(
            logging: logging ?? self.logging,
            markupFormatter: markupFormatter ?? self.markupFormatter,
            service: service ?? self.service
        )
    }

    func jsonData() throws -> Data {
        return try newJSONEncoder().encode(self)
    }

    func jsonString(encoding: String.Encoding = .utf8) throws -> String? {
        return String(data: try self.jsonData(), encoding: encoding)
    }
}

// MARK: - MarkupFormatter
public struct MarkupFormatter: Codable {
    public let markupEnabled: Bool
    public let phonemeFormat: String

    enum CodingKeys: String, CodingKey {
        case markupEnabled = "markup_enabled"
        case phonemeFormat = "phoneme_format"
    }

    public init(markupEnabled: Bool, phonemeFormat: String) {
        self.markupEnabled = markupEnabled
        self.phonemeFormat = phonemeFormat
    }
}

// MARK: MarkupFormatter convenience initializers and mutators

public extension MarkupFormatter {
    init(data: Data) throws {
        self = try newJSONDecoder().decode(MarkupFormatter.self, from: data)
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

    func with(
        markupEnabled: Bool? = nil,
        phonemeFormat: String? = nil
    ) -> MarkupFormatter {
        return MarkupFormatter(
            markupEnabled: markupEnabled ?? self.markupEnabled,
            phonemeFormat: phonemeFormat ?? self.phonemeFormat
        )
    }

    func jsonData() throws -> Data {
        return try newJSONEncoder().encode(self)
    }

    func jsonString(encoding: String.Encoding = .utf8) throws -> String? {
        return String(data: try self.jsonData(), encoding: encoding)
    }
}

// MARK: - ServiceLimits
public struct ServiceLimits: Codable {
    public let auto, bicycle, bikeshare, bus: BicycleClass
    public let centroid: Centroid
    public let isochrone: Isochrone
    public let maxAlternates, maxExcludeLocations, maxExcludePolygonsLength, maxRadius: Int
    public let maxReachability, maxTimedepDistance, maxTimedepDistanceMatrix: Int
    public let motorScooter, motorcycle, multimodal: BicycleClass
    public let pedestrian: Pedestrian
    public let skadi: Skadi
    public let status: Status
    public let taxi: BicycleClass
    public let trace: Trace
    public let transit, truck: BicycleClass

    enum CodingKeys: String, CodingKey {
        case auto, bicycle, bikeshare, bus, centroid, isochrone
        case maxAlternates = "max_alternates"
        case maxExcludeLocations = "max_exclude_locations"
        case maxExcludePolygonsLength = "max_exclude_polygons_length"
        case maxRadius = "max_radius"
        case maxReachability = "max_reachability"
        case maxTimedepDistance = "max_timedep_distance"
        case maxTimedepDistanceMatrix = "max_timedep_distance_matrix"
        case motorScooter = "motor_scooter"
        case motorcycle, multimodal, pedestrian, skadi, status, taxi, trace, transit, truck
    }

    public init(auto: BicycleClass, bicycle: BicycleClass, bikeshare: BicycleClass, bus: BicycleClass, centroid: Centroid, isochrone: Isochrone, maxAlternates: Int, maxExcludeLocations: Int, maxExcludePolygonsLength: Int, maxRadius: Int, maxReachability: Int, maxTimedepDistance: Int, maxTimedepDistanceMatrix: Int, motorScooter: BicycleClass, motorcycle: BicycleClass, multimodal: BicycleClass, pedestrian: Pedestrian, skadi: Skadi, status: Status, taxi: BicycleClass, trace: Trace, transit: BicycleClass, truck: BicycleClass) {
        self.auto = auto
        self.bicycle = bicycle
        self.bikeshare = bikeshare
        self.bus = bus
        self.centroid = centroid
        self.isochrone = isochrone
        self.maxAlternates = maxAlternates
        self.maxExcludeLocations = maxExcludeLocations
        self.maxExcludePolygonsLength = maxExcludePolygonsLength
        self.maxRadius = maxRadius
        self.maxReachability = maxReachability
        self.maxTimedepDistance = maxTimedepDistance
        self.maxTimedepDistanceMatrix = maxTimedepDistanceMatrix
        self.motorScooter = motorScooter
        self.motorcycle = motorcycle
        self.multimodal = multimodal
        self.pedestrian = pedestrian
        self.skadi = skadi
        self.status = status
        self.taxi = taxi
        self.trace = trace
        self.transit = transit
        self.truck = truck
    }
}

// MARK: ServiceLimits convenience initializers and mutators

public extension ServiceLimits {
    init(data: Data) throws {
        self = try newJSONDecoder().decode(ServiceLimits.self, from: data)
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

    func with(
        auto: BicycleClass? = nil,
        bicycle: BicycleClass? = nil,
        bikeshare: BicycleClass? = nil,
        bus: BicycleClass? = nil,
        centroid: Centroid? = nil,
        isochrone: Isochrone? = nil,
        maxAlternates: Int? = nil,
        maxExcludeLocations: Int? = nil,
        maxExcludePolygonsLength: Int? = nil,
        maxRadius: Int? = nil,
        maxReachability: Int? = nil,
        maxTimedepDistance: Int? = nil,
        maxTimedepDistanceMatrix: Int? = nil,
        motorScooter: BicycleClass? = nil,
        motorcycle: BicycleClass? = nil,
        multimodal: BicycleClass? = nil,
        pedestrian: Pedestrian? = nil,
        skadi: Skadi? = nil,
        status: Status? = nil,
        taxi: BicycleClass? = nil,
        trace: Trace? = nil,
        transit: BicycleClass? = nil,
        truck: BicycleClass? = nil
    ) -> ServiceLimits {
        return ServiceLimits(
            auto: auto ?? self.auto,
            bicycle: bicycle ?? self.bicycle,
            bikeshare: bikeshare ?? self.bikeshare,
            bus: bus ?? self.bus,
            centroid: centroid ?? self.centroid,
            isochrone: isochrone ?? self.isochrone,
            maxAlternates: maxAlternates ?? self.maxAlternates,
            maxExcludeLocations: maxExcludeLocations ?? self.maxExcludeLocations,
            maxExcludePolygonsLength: maxExcludePolygonsLength ?? self.maxExcludePolygonsLength,
            maxRadius: maxRadius ?? self.maxRadius,
            maxReachability: maxReachability ?? self.maxReachability,
            maxTimedepDistance: maxTimedepDistance ?? self.maxTimedepDistance,
            maxTimedepDistanceMatrix: maxTimedepDistanceMatrix ?? self.maxTimedepDistanceMatrix,
            motorScooter: motorScooter ?? self.motorScooter,
            motorcycle: motorcycle ?? self.motorcycle,
            multimodal: multimodal ?? self.multimodal,
            pedestrian: pedestrian ?? self.pedestrian,
            skadi: skadi ?? self.skadi,
            status: status ?? self.status,
            taxi: taxi ?? self.taxi,
            trace: trace ?? self.trace,
            transit: transit ?? self.transit,
            truck: truck ?? self.truck
        )
    }

    func jsonData() throws -> Data {
        return try newJSONEncoder().encode(self)
    }

    func jsonString(encoding: String.Encoding = .utf8) throws -> String? {
        return String(data: try self.jsonData(), encoding: encoding)
    }
}

// MARK: - BicycleClass
public struct BicycleClass: Codable {
    public let maxDistance, maxLocations, maxMatrixDistance, maxMatrixLocationPairs: Int

    enum CodingKeys: String, CodingKey {
        case maxDistance = "max_distance"
        case maxLocations = "max_locations"
        case maxMatrixDistance = "max_matrix_distance"
        case maxMatrixLocationPairs = "max_matrix_location_pairs"
    }

    public init(maxDistance: Int, maxLocations: Int, maxMatrixDistance: Int, maxMatrixLocationPairs: Int) {
        self.maxDistance = maxDistance
        self.maxLocations = maxLocations
        self.maxMatrixDistance = maxMatrixDistance
        self.maxMatrixLocationPairs = maxMatrixLocationPairs
    }
}

// MARK: BicycleClass convenience initializers and mutators

public extension BicycleClass {
    init(data: Data) throws {
        self = try newJSONDecoder().decode(BicycleClass.self, from: data)
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

    func with(
        maxDistance: Int? = nil,
        maxLocations: Int? = nil,
        maxMatrixDistance: Int? = nil,
        maxMatrixLocationPairs: Int? = nil
    ) -> BicycleClass {
        return BicycleClass(
            maxDistance: maxDistance ?? self.maxDistance,
            maxLocations: maxLocations ?? self.maxLocations,
            maxMatrixDistance: maxMatrixDistance ?? self.maxMatrixDistance,
            maxMatrixLocationPairs: maxMatrixLocationPairs ?? self.maxMatrixLocationPairs
        )
    }

    func jsonData() throws -> Data {
        return try newJSONEncoder().encode(self)
    }

    func jsonString(encoding: String.Encoding = .utf8) throws -> String? {
        return String(data: try self.jsonData(), encoding: encoding)
    }
}

// MARK: - Centroid
public struct Centroid: Codable {
    public let maxDistance, maxLocations: Int

    enum CodingKeys: String, CodingKey {
        case maxDistance = "max_distance"
        case maxLocations = "max_locations"
    }

    public init(maxDistance: Int, maxLocations: Int) {
        self.maxDistance = maxDistance
        self.maxLocations = maxLocations
    }
}

// MARK: Centroid convenience initializers and mutators

public extension Centroid {
    init(data: Data) throws {
        self = try newJSONDecoder().decode(Centroid.self, from: data)
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

    func with(
        maxDistance: Int? = nil,
        maxLocations: Int? = nil
    ) -> Centroid {
        return Centroid(
            maxDistance: maxDistance ?? self.maxDistance,
            maxLocations: maxLocations ?? self.maxLocations
        )
    }

    func jsonData() throws -> Data {
        return try newJSONEncoder().encode(self)
    }

    func jsonString(encoding: String.Encoding = .utf8) throws -> String? {
        return String(data: try self.jsonData(), encoding: encoding)
    }
}

// MARK: - Isochrone
public struct Isochrone: Codable {
    public let maxContours, maxDistance, maxDistanceContour, maxLocations: Int
    public let maxTimeContour: Int

    enum CodingKeys: String, CodingKey {
        case maxContours = "max_contours"
        case maxDistance = "max_distance"
        case maxDistanceContour = "max_distance_contour"
        case maxLocations = "max_locations"
        case maxTimeContour = "max_time_contour"
    }

    public init(maxContours: Int, maxDistance: Int, maxDistanceContour: Int, maxLocations: Int, maxTimeContour: Int) {
        self.maxContours = maxContours
        self.maxDistance = maxDistance
        self.maxDistanceContour = maxDistanceContour
        self.maxLocations = maxLocations
        self.maxTimeContour = maxTimeContour
    }
}

// MARK: Isochrone convenience initializers and mutators

public extension Isochrone {
    init(data: Data) throws {
        self = try newJSONDecoder().decode(Isochrone.self, from: data)
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

    func with(
        maxContours: Int? = nil,
        maxDistance: Int? = nil,
        maxDistanceContour: Int? = nil,
        maxLocations: Int? = nil,
        maxTimeContour: Int? = nil
    ) -> Isochrone {
        return Isochrone(
            maxContours: maxContours ?? self.maxContours,
            maxDistance: maxDistance ?? self.maxDistance,
            maxDistanceContour: maxDistanceContour ?? self.maxDistanceContour,
            maxLocations: maxLocations ?? self.maxLocations,
            maxTimeContour: maxTimeContour ?? self.maxTimeContour
        )
    }

    func jsonData() throws -> Data {
        return try newJSONEncoder().encode(self)
    }

    func jsonString(encoding: String.Encoding = .utf8) throws -> String? {
        return String(data: try self.jsonData(), encoding: encoding)
    }
}

// MARK: - Pedestrian
public struct Pedestrian: Codable {
    public let maxDistance, maxLocations, maxMatrixDistance, maxMatrixLocationPairs: Int
    public let maxTransitWalkingDistance, minTransitWalkingDistance: Int

    enum CodingKeys: String, CodingKey {
        case maxDistance = "max_distance"
        case maxLocations = "max_locations"
        case maxMatrixDistance = "max_matrix_distance"
        case maxMatrixLocationPairs = "max_matrix_location_pairs"
        case maxTransitWalkingDistance = "max_transit_walking_distance"
        case minTransitWalkingDistance = "min_transit_walking_distance"
    }

    public init(maxDistance: Int, maxLocations: Int, maxMatrixDistance: Int, maxMatrixLocationPairs: Int, maxTransitWalkingDistance: Int, minTransitWalkingDistance: Int) {
        self.maxDistance = maxDistance
        self.maxLocations = maxLocations
        self.maxMatrixDistance = maxMatrixDistance
        self.maxMatrixLocationPairs = maxMatrixLocationPairs
        self.maxTransitWalkingDistance = maxTransitWalkingDistance
        self.minTransitWalkingDistance = minTransitWalkingDistance
    }
}

// MARK: Pedestrian convenience initializers and mutators

public extension Pedestrian {
    init(data: Data) throws {
        self = try newJSONDecoder().decode(Pedestrian.self, from: data)
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

    func with(
        maxDistance: Int? = nil,
        maxLocations: Int? = nil,
        maxMatrixDistance: Int? = nil,
        maxMatrixLocationPairs: Int? = nil,
        maxTransitWalkingDistance: Int? = nil,
        minTransitWalkingDistance: Int? = nil
    ) -> Pedestrian {
        return Pedestrian(
            maxDistance: maxDistance ?? self.maxDistance,
            maxLocations: maxLocations ?? self.maxLocations,
            maxMatrixDistance: maxMatrixDistance ?? self.maxMatrixDistance,
            maxMatrixLocationPairs: maxMatrixLocationPairs ?? self.maxMatrixLocationPairs,
            maxTransitWalkingDistance: maxTransitWalkingDistance ?? self.maxTransitWalkingDistance,
            minTransitWalkingDistance: minTransitWalkingDistance ?? self.minTransitWalkingDistance
        )
    }

    func jsonData() throws -> Data {
        return try newJSONEncoder().encode(self)
    }

    func jsonString(encoding: String.Encoding = .utf8) throws -> String? {
        return String(data: try self.jsonData(), encoding: encoding)
    }
}

// MARK: - Skadi
public struct Skadi: Codable {
    public let maxShape, minResample: Int

    enum CodingKeys: String, CodingKey {
        case maxShape = "max_shape"
        case minResample = "min_resample"
    }

    public init(maxShape: Int, minResample: Int) {
        self.maxShape = maxShape
        self.minResample = minResample
    }
}

// MARK: Skadi convenience initializers and mutators

public extension Skadi {
    init(data: Data) throws {
        self = try newJSONDecoder().decode(Skadi.self, from: data)
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

    func with(
        maxShape: Int? = nil,
        minResample: Int? = nil
    ) -> Skadi {
        return Skadi(
            maxShape: maxShape ?? self.maxShape,
            minResample: minResample ?? self.minResample
        )
    }

    func jsonData() throws -> Data {
        return try newJSONEncoder().encode(self)
    }

    func jsonString(encoding: String.Encoding = .utf8) throws -> String? {
        return String(data: try self.jsonData(), encoding: encoding)
    }
}

// MARK: - Status
public struct Status: Codable {
    public let allowVerbose: Bool

    enum CodingKeys: String, CodingKey {
        case allowVerbose = "allow_verbose"
    }

    public init(allowVerbose: Bool) {
        self.allowVerbose = allowVerbose
    }
}

// MARK: Status convenience initializers and mutators

public extension Status {
    init(data: Data) throws {
        self = try newJSONDecoder().decode(Status.self, from: data)
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

    func with(
        allowVerbose: Bool? = nil
    ) -> Status {
        return Status(
            allowVerbose: allowVerbose ?? self.allowVerbose
        )
    }

    func jsonData() throws -> Data {
        return try newJSONEncoder().encode(self)
    }

    func jsonString(encoding: String.Encoding = .utf8) throws -> String? {
        return String(data: try self.jsonData(), encoding: encoding)
    }
}

// MARK: - Trace
public struct Trace: Codable {
    public let maxAlternates, maxAlternatesShape, maxDistance, maxGpsAccuracy: Int
    public let maxSearchRadius, maxShape: Int

    enum CodingKeys: String, CodingKey {
        case maxAlternates = "max_alternates"
        case maxAlternatesShape = "max_alternates_shape"
        case maxDistance = "max_distance"
        case maxGpsAccuracy = "max_gps_accuracy"
        case maxSearchRadius = "max_search_radius"
        case maxShape = "max_shape"
    }

    public init(maxAlternates: Int, maxAlternatesShape: Int, maxDistance: Int, maxGpsAccuracy: Int, maxSearchRadius: Int, maxShape: Int) {
        self.maxAlternates = maxAlternates
        self.maxAlternatesShape = maxAlternatesShape
        self.maxDistance = maxDistance
        self.maxGpsAccuracy = maxGpsAccuracy
        self.maxSearchRadius = maxSearchRadius
        self.maxShape = maxShape
    }
}

// MARK: Trace convenience initializers and mutators

public extension Trace {
    init(data: Data) throws {
        self = try newJSONDecoder().decode(Trace.self, from: data)
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

    func with(
        maxAlternates: Int? = nil,
        maxAlternatesShape: Int? = nil,
        maxDistance: Int? = nil,
        maxGpsAccuracy: Int? = nil,
        maxSearchRadius: Int? = nil,
        maxShape: Int? = nil
    ) -> Trace {
        return Trace(
            maxAlternates: maxAlternates ?? self.maxAlternates,
            maxAlternatesShape: maxAlternatesShape ?? self.maxAlternatesShape,
            maxDistance: maxDistance ?? self.maxDistance,
            maxGpsAccuracy: maxGpsAccuracy ?? self.maxGpsAccuracy,
            maxSearchRadius: maxSearchRadius ?? self.maxSearchRadius,
            maxShape: maxShape ?? self.maxShape
        )
    }

    func jsonData() throws -> Data {
        return try newJSONEncoder().encode(self)
    }

    func jsonString(encoding: String.Encoding = .utf8) throws -> String? {
        return String(data: try self.jsonData(), encoding: encoding)
    }
}

// MARK: - Statsd
public struct Statsd: Codable {
    public let port: Int
    public let statsdPrefix: String

    enum CodingKeys: String, CodingKey {
        case port
        case statsdPrefix = "prefix"
    }

    public init(port: Int, statsdPrefix: String) {
        self.port = port
        self.statsdPrefix = statsdPrefix
    }
}

// MARK: Statsd convenience initializers and mutators

public extension Statsd {
    init(data: Data) throws {
        self = try newJSONDecoder().decode(Statsd.self, from: data)
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

    func with(
        port: Int? = nil,
        statsdPrefix: String? = nil
    ) -> Statsd {
        return Statsd(
            port: port ?? self.port,
            statsdPrefix: statsdPrefix ?? self.statsdPrefix
        )
    }

    func jsonData() throws -> Data {
        return try newJSONEncoder().encode(self)
    }

    func jsonString(encoding: String.Encoding = .utf8) throws -> String? {
        return String(data: try self.jsonData(), encoding: encoding)
    }
}

// MARK: - Thor
public struct Thor: Codable {
    public let clearReservedMemory, extendedSearch: Bool
    public let logging: Logging
    public let maxReservedLabelsCount: Int
    public let service: LokiService
    public let sourceToTargetAlgorithm: String

    enum CodingKeys: String, CodingKey {
        case clearReservedMemory = "clear_reserved_memory"
        case extendedSearch = "extended_search"
        case logging
        case maxReservedLabelsCount = "max_reserved_labels_count"
        case service
        case sourceToTargetAlgorithm = "source_to_target_algorithm"
    }

    public init(clearReservedMemory: Bool, extendedSearch: Bool, logging: Logging, maxReservedLabelsCount: Int, service: LokiService, sourceToTargetAlgorithm: String) {
        self.clearReservedMemory = clearReservedMemory
        self.extendedSearch = extendedSearch
        self.logging = logging
        self.maxReservedLabelsCount = maxReservedLabelsCount
        self.service = service
        self.sourceToTargetAlgorithm = sourceToTargetAlgorithm
    }
}

// MARK: Thor convenience initializers and mutators

public extension Thor {
    init(data: Data) throws {
        self = try newJSONDecoder().decode(Thor.self, from: data)
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

    func with(
        clearReservedMemory: Bool? = nil,
        extendedSearch: Bool? = nil,
        logging: Logging? = nil,
        maxReservedLabelsCount: Int? = nil,
        service: LokiService? = nil,
        sourceToTargetAlgorithm: String? = nil
    ) -> Thor {
        return Thor(
            clearReservedMemory: clearReservedMemory ?? self.clearReservedMemory,
            extendedSearch: extendedSearch ?? self.extendedSearch,
            logging: logging ?? self.logging,
            maxReservedLabelsCount: maxReservedLabelsCount ?? self.maxReservedLabelsCount,
            service: service ?? self.service,
            sourceToTargetAlgorithm: sourceToTargetAlgorithm ?? self.sourceToTargetAlgorithm
        )
    }

    func jsonData() throws -> Data {
        return try newJSONEncoder().encode(self)
    }

    func jsonString(encoding: String.Encoding = .utf8) throws -> String? {
        return String(data: try self.jsonData(), encoding: encoding)
    }
}

// MARK: - Helper functions for creating encoders and decoders

func newJSONDecoder() -> JSONDecoder {
    let decoder = JSONDecoder()
    if #available(iOS 10.0, OSX 10.12, tvOS 10.0, watchOS 3.0, *) {
        decoder.dateDecodingStrategy = .iso8601
    }
    return decoder
}

func newJSONEncoder() -> JSONEncoder {
    let encoder = JSONEncoder()
    if #available(iOS 10.0, OSX 10.12, tvOS 10.0, watchOS 3.0, *) {
        encoder.dateEncodingStrategy = .iso8601
    }
    return encoder
}

import XCTest
import ValhallaModels
import ValhallaConfigModels
@testable import Valhalla

final class TestFileSystemConfig: XCTestCase {
    
    var valhalla: Valhalla!
    
    override func setUp() async throws {
        let tilesDirectoryURL = Bundle.module.resourceURL!.appendingPathComponent("TestData/valhalla_tiles", isDirectory: true)
        let defaultConfig = try ValhallaConfig(tilesDir: tilesDirectoryURL)
        valhalla = try Valhalla(defaultConfig)
    }

    func testTzDataExists() throws {
        let libraryDir = FileManager.default.urls(for: .libraryDirectory, in: .userDomainMask).first
        let tzDataURL = libraryDir!.appendingPathComponent("tzdata")
        XCTAssertTrue(FileManager.default.fileExists(atPath: tzDataURL.path))
    }
}

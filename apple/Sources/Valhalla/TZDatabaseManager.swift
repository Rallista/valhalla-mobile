import Foundation
import Light_Swift_Untar

enum TZDatabaseError: Error {
    case tzdataNotFound
    case libraryNotFound
}

final class TZDatabaseManager {
    
    static func injectIntoMain() throws {
        guard let tzdataFileURL = Bundle.module.url(forResource: "SupportData/tzdata", withExtension: "tar") else {
            throw TZDatabaseError.tzdataNotFound
        }
        
        guard let libraryDirectory = FileManager.default.urls(for: .libraryDirectory, in: .userDomainMask).first else {
            throw TZDatabaseError.libraryNotFound
        }
        
        let tzdataFileData = try Data(contentsOf: tzdataFileURL)
        let libraryURL = libraryDirectory.appendingPathComponent("tzdata")
    
        // Write the tar to Library/tzdata
        try FileManager.default.createFilesAndDirectories(url: libraryURL, tarData: tzdataFileData)
    }
}

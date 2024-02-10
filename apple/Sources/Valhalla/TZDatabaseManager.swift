import Foundation
import Light_Swift_Untar

enum TZDatabaseError: Error {
    case tzdataNotFound
    case libraryNotFound
}

final class TZDatabaseManager {
    
    /// Add tzdata to the Library directory
    ///
    /// The HowardHinnant/date library used in valhalla requires the tzdata.tar file to be stored
    /// in Bundle.main. When the tar is manually added that way, the c++ library will extract this 
    /// into the Library directory on run. This function provides a workaround for this by injecting
    /// our own resource tzdata.tar into the Library directory before any balhalla action runs.
    ///
    /// Learn more see <https://github.com/HowardHinnant/date>
    /// and <https://howardhinnant.github.io/date/tz.html#Installation>
    static func injectIntoLibrary() throws {
        guard let tzdataFileURL = Bundle.module.url(forResource: "SupportData/tzdata", withExtension: "tar") else {
            throw TZDatabaseError.tzdataNotFound
        }
        
        guard let libraryDirectory = FileManager.default.urls(for: .libraryDirectory, in: .userDomainMask).first else {
            throw TZDatabaseError.libraryNotFound
        }
        
        let tzdataFileData = try Data(contentsOf: tzdataFileURL)
        let libraryURL = libraryDirectory.appendingPathComponent("tzdata")
    
        // Write the tar to Library/tzdata
        // TODO: We can create our own tar extract here if we want to avoid the dependency
        try FileManager.default.createFilesAndDirectories(url: libraryURL, tarData: tzdataFileData)
    }
}

import Foundation
import ValhallaModels

extension ValhallaConfig {
    
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
}

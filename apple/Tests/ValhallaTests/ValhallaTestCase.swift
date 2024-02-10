import XCTest

enum TestDataError: Error {
    case notFound(String)
    case invalidJsonData(String)
    case invalidValue(key: String)
}

class ValhallaTestCase: XCTestCase {
    
    func configPath() throws -> String {
        guard let url = Bundle.module.url(forResource: "TestData/config", withExtension: "json") else {
            throw TestDataError.notFound("TestData/config.json")
        }
        
        return url.relativePath
    }
    
    func expectedValue<T>(keys: String...) throws -> T {
        guard let url = Bundle.module.url(forResource: "TestData/expected", withExtension: "json") else {
            throw TestDataError.notFound("TestData/expected.json")
        }
        
        let expectedData = try Data(contentsOf: url)
        return try serializeValue(expectedData, keyArray: keys)
    }
    
    func serializeValue<T>(_ data: Data, keys: String...) throws -> T {
        return try serializeValue(data, keyArray: keys)
    }
    
    func serializeValue<T>(_ data: Data, keyArray keys: [String]) throws -> T {
        guard var serialized = try JSONSerialization.jsonObject(with: data) as? [String: Any] else {
            throw TestDataError.invalidJsonData("\(keys)")
        }
        
        for key in keys {
            if let nestedDict = serialized[key] as? [String: Any] {
                serialized = nestedDict
            } else if let value = serialized[key] as? T {
                return value
            } else {
                throw TestDataError.invalidValue(key: key)
            }
        }
        
        throw TestDataError.invalidJsonData("\(keys)")
    }
}

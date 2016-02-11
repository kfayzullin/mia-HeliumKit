import Foundation
import XCTest
@testable import HeliumKit

class AuthenticationTokenGeneratorTests: XCTestCase {

    let authgenerator = AuthenticationKeyGenerator(
        deviceID: "0ef72dcb75803b0e0ba9235328475274",
        secret: "ccc00ebadc3f854b67f199ec09eea9ab",
        secretID: "bbbd94ad33c56f13c2c11c758c611f49",
        authenticationHashFunction: HashFunctions.sha256
    )
    
    func testBasicToken() {
        let url = NSURL(string: "http://stage.api.cmps.sevenventures.de/test/v1/authtest")
        let methode = "GET"
        let timestamp = 500000000000.000//NSDate().timeIntervalSince1970
        let key = authgenerator.createAuthenticationKey(url!, method: methode, body: nil, timeStamp: timestamp)!
        
        XCTAssertEqual(key, "0ef72dcb75803b0e0ba9235328475274bbbd94ad33c56f13c2c11c758c611f4950000000000039178BC339F1A8678BB4DF6D98A1EB1C262AB22A7720E6F0AE370811D47A3B5A".lowercaseString)
    }
    
    func DISABLED_testTokenWithParameters() {
        let url = NSURL(string: "http://stage.api.cmps.sevenventures.de/test/v1/authtest?test=test&bla=234")
        let methode = "GET"
        let timestamp = NSDate().timeIntervalSince1970
        let key = authgenerator.createAuthenticationKey(url!, method: methode, body: nil, timeStamp: timestamp)

        XCTAssertEqual(key!, "0ef72dcb75803b0e0ba9235328475274bbbd94ad33c56f13c2c11c758c611f4950000000000039178bc339f1a8678bb4df6d98a1eb1c262ab22a7720e6f0ae370811d47a3b5a")
    }
    
    func testPerformance() {
        measureBlock { () -> Void in
            for _ in 0...100 {
                let url = NSURL(string: "http://stage.api.cmps.sevenventures.de/test/v1/authtest")
                let methode = "GET"
                let timestamp = 500000000000.000//NSDate().timeIntervalSince1970
                self.authgenerator.createAuthenticationKey(url!, method: methode, body: nil, timeStamp: timestamp)
            }
        }
    }
    
    func testPerformanceWithBody() {
        var body = ["test" : ["test":"test"]]
        
        for index in 0...10000 {
            body["\(index)"] = ["test":"test"]
        }
        
        
        let bodyData = try? NSJSONSerialization.dataWithJSONObject(body, options:  NSJSONWritingOptions(rawValue: 0))
        
        measureBlock { () -> Void in
                let url = NSURL(string: "http://stage.api.cmps.sevenventures.de/test/v1/authtest")
                let methode = "GET"

                let timestamp = 500000000000.000//NSDate().timeIntervalSince1970
                self.authgenerator.createAuthenticationKey(url!, method: methode, body: bodyData, timeStamp: timestamp)
        }
    }
}

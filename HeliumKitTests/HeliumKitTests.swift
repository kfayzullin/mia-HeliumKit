import XCTest
import OHHTTPStubs
@testable import HeliumKit

enum HeliumErrorType {
    
    case noerror, deviceInvalid, keyInvalid
    
}

class HeliumKitTests: XCTestCase {
    
    private var helium: Helium!
    var config : HeliumConfiguration!
    
    //MARK: Lifecycle
    
    override func setUp() {
        super.setUp()
        
        helium = stubbedHelium()
    }
    
    override func tearDown() {
        super.tearDown()
    }
    
    // MARK: Helpers
    
    private func stubbedHelium(acceptableStatusCodes: Range<Int> = 200..<300, errorType: HeliumErrorType = .noerror, headers: [String: AnyObject]? = nil) -> Helium {

        switch errorType {
            
        case .deviceInvalid :
            stubDeviceInvalid(headers)
        case .keyInvalid :
            stubKeyInvalid(headers)
        default:
            stubDeviceToken(headers)
            break
        }
        
        let baseURL = NSURL(string: "http://localhost")!
        let notification = Notification(token: "token", environment: "env")
        let deviceInfo = DeviceInfo(bundle: NSBundle.mainBundle(), carrierName: "", notification: notification)
        
        let persistenceStore = DeviceConfigurationMemoryStore()
        persistenceStore.token = nil
        persistenceStore.deviceInfoHash = deviceInfo.deviceSHA256
        
        let deviceConfiguration = DeviceConfiguration(
            URL: NSURL(string: "http://localhost/demo-auth/v1/devices")!,
            deviceInfo: deviceInfo,
            persistenceStore: persistenceStore
        )
        
        config = HeliumConfiguration(
            secret: "74168c7a1868ddeee3355fab9489914b",
            secretID: "91205b43c5144068ee9979b093925f77",
            baseURL: baseURL,acceptableStatusCodes: acceptableStatusCodes,
            deviceConfiguration: deviceConfiguration
        )
        
        return Helium(configuration: config, authenticationHashFunction: HashFunctions.sha256)
    }
    
    private func stubDeviceToken(headers: [String: AnyObject]? = nil) {

        OHHTTPStubs.stubRequestsPassingTest(
            { request -> Bool in
                return request.URL!.absoluteString == "http://localhost/demo-auth/v1/devices"
            }, withStubResponse: { request -> OHHTTPStubsResponse in
                
                let deviceToken = "a08ada7c88e2bd6c966de2c5cdfafe12"
                let jsonObject = ["status": 200, "response": ["id": deviceToken]]

                return OHHTTPStubsResponse(JSONObject: jsonObject, statusCode: 200, headers: headers)
        })
    }
    
    private func stubValidListResponse(url: NSURL) {
        OHHTTPStubs.stubRequestsPassingTest({ request -> Bool in
            return request.allHTTPHeaderFields?["key"] != nil
            }) { request -> OHHTTPStubsResponse in
                return OHHTTPStubsResponse(JSONObject: ["status":200,"response":[["_id":"1234","name":"todo"],["_id":"1234","name":"todo"],["_id":"1234","name":"todo"]]], statusCode: 200, headers: nil)
        }
    }
    
    private func stubValidItemResponse(url: NSURL) {
        OHHTTPStubs.stubRequestsPassingTest({ request -> Bool in
            return request.allHTTPHeaderFields?["key"] != nil
        }) { request -> OHHTTPStubsResponse in
            return OHHTTPStubsResponse(JSONObject: ["status":200,"response":["_id":"1234","name":"todo"]], statusCode: 200, headers: nil)
        }
    }
    
    private func stubValidServiceResponse(url: NSURL) {
        OHHTTPStubs.stubRequestsPassingTest({ request -> Bool in
            return request.allHTTPHeaderFields?["key"] != nil
        }) { request -> OHHTTPStubsResponse in
            return OHHTTPStubsResponse(JSONObject: ["status":200,"response":[["id":"1234"],["id":"1234"],["id":"1234"]]], statusCode: 200, headers: nil)
        }
    }
    private func stubKeyInvalid(headers: [String: AnyObject]? = nil) {
        
        var didRespondOnce = false
        
        OHHTTPStubs.stubRequestsPassingTest(
            { request -> Bool in
                return request.URL!.absoluteString == "http://localhost/demo-auth/v1/devices"
            },
            withStubResponse: { request -> OHHTTPStubsResponse in
                
                var deviceToken = ""
                if didRespondOnce {
                    deviceToken = "a08ada7c88e2bd6c966de2c5cdfafe12"
                } else {
                    deviceToken = "234234234234234234"
                    didRespondOnce = true
                }
                
                let jsonObject = ["status": 200, "response": ["id": deviceToken]]
                
                return OHHTTPStubsResponse(JSONObject: jsonObject, statusCode: 200, headers: headers)
        })
    }
    
    private func stubDeviceInvalid(headers: [String: AnyObject]? = nil) {
        
        var didRespondOnce = false
        
        OHHTTPStubs.stubRequestsPassingTest(
            { request -> Bool in
                return request.URL!.absoluteString == "http://localhost/demo-auth/v1/devices"
            },
            withStubResponse: { request -> OHHTTPStubsResponse in
                
                var deviceToken = ""
                if didRespondOnce {
                    deviceToken = "a08ada7c88e2bd6c966de2c5cdfafe12"
                } else {
                    deviceToken = "23232323232323232"
                    didRespondOnce = true
                }
                
                let jsonObject = ["status": 200, "response": ["id": deviceToken]]
                
                return OHHTTPStubsResponse(JSONObject: jsonObject, statusCode: 200, headers: headers)
        })
    }
    
    
    //MARK: Tests
    
    func testServicesRequest() {
        let expectation = expectationWithDescription("")
        stubValidServiceResponse(NSURL(string: "")!)
        helium.get("/demo-auth/v1/services", returnType: Services.self).completion { result in
            switch result {
            case .Success(let value, _, _):
                XCTAssertNotNil(value?.serviceArray?.first?.id)
            case .Error(let error, _):
                XCTFail("error: \(error)")
            }
            expectation.fulfill()
        }
        
        self.waitForExpectationsWithTimeout(5) { error -> Void in
            
        }
    }

    
    func testTVShowsRequest() {
        let expectation = expectationWithDescription("")
        stubValidListResponse(NSURL(string: "")!)
        helium.get("/demo-auth/v1/todo", returnType: ToDoes.self).completion { result in
            switch result {
            case .Success(let value, _, _):
                XCTAssertNotNil(value?.toDoes.first?.id)
                XCTAssertNotNil(value?.toDoes.first?.name)
            case .Error(let error, _):
                print(error.jsonResponse, error.responseHeaders)
                
                XCTFail("error: \(error)")
            }
            expectation.fulfill()
        }
     
        self.waitForExpectationsWithTimeout(5) { error -> Void in
            
        }
    }
    
    
    func testTVShowRequest() {
        let expectation = expectationWithDescription("")
        stubValidItemResponse(NSURL(string: "")!)
        helium.get("/demo-auth/v1/todo/id", returnType: Todo.self).pathReplacements(["id": "56b352183037c42936e10d68"]).completion { result in
            switch result {
            case .Success(let value, _, _):
                XCTAssertNotNil(value?.id)
            case .Error(let error, _):
                print(error)
                XCTFail("error: \(error)")
            }
            expectation.fulfill()
        }
     
        self.waitForExpectationsWithTimeout(5) { error -> Void in
            
        }
    }
    
    func testResultValidation() {
        let expectation = expectationWithDescription("")
        
        let helium = stubbedHelium(201..<300)
        stubValidItemResponse(NSURL(string: "")!)
        helium.get("/demo-auth/v1/todo/id", returnType: ToDoes.self).pathReplacements(["id": "56b352183037c42936e10d68"]).completion { result in
            switch result {
            case .Success:
                XCTFail("should not be called")
            case .Error(let error, _):
                XCTAssertNotNil(error)
                XCTAssertNotNil(error.responseData)
                XCTAssertNotNil(error.responseHeaders)
                XCTAssertEqual(error.code, 200)
            }
            
            expectation.fulfill()
        }
        
        self.waitForExpectationsWithTimeout(5) { error -> Void in
            
        }
    }
    
    func testRetry() {
        let expectation = expectationWithDescription("")
        
        let path = "/demo-auth/v1/todo"
        
        let helium = stubbedHelium(200..<300, headers: ["date" : "Tue, 16 Jun 2015 07:36:42 GMT"])
        stubValidListResponse(NSURL(string:"")!)
        helium.get(path, returnType: ToDoes.self).completion { result in
            switch result {
            case .Success(let value, _, _):
                XCTAssertNotNil(value)
            case .Error(let error, _):
                print(error.jsonResponse, error.responseHeaders)
                XCTFail("should not be called")
            }
                expectation.fulfill()
        }
        
        self.waitForExpectationsWithTimeout(5) { error -> Void in
            
        }
    }
    
    func testInvalidKey() {
        
        let expectation = expectationWithDescription("")
        
        let path = "/demo-auth/v1/todo"
        
        let helium = stubbedHelium(200..<300, errorType: .keyInvalid)
        stubValidListResponse(NSURL(string:"")!)
        helium.get(path, returnType: ToDoes.self).completion { result in
            switch result {
            case .Success(let value, _, _):
                XCTAssertNotNil(value)
            case .Error(let error):
                print(error)
                XCTFail("should not be called")
            }
            expectation.fulfill()
        }
        
        self.waitForExpectationsWithTimeout(5) { error -> Void in
            
        }
    }
    
    func testInvalidDevice() {
        
        let expectation = expectationWithDescription("")
        
        let path = "/demo-auth/v1/services"
        
        let helium = stubbedHelium(200..<300, errorType: .deviceInvalid)
        stubValidListResponse(NSURL(string:"")!)
        helium.get(path, returnType: ToDoes.self).completion { result in
            switch result {
            case .Success(let value, _, _):
                XCTAssertNotNil(value)
            case .Error(let error):
                print(error)
                XCTFail("should not be called")
            }
            expectation.fulfill()
        }
        
        self.waitForExpectationsWithTimeout(5) { error -> Void in
            
        }
    }

}

// MARK: Mock Classes

class Services: Encodable, Decodable {
    var serviceArray: [Service]?
    
    required init(serviceArray: [Service]?) {
        self.serviceArray = serviceArray
    }
    
    static func decode(data: NSData) -> Self? {
        guard
            let json = Services.dataToJSON(data),
            let result = json["response"] as? [[String: AnyObject]]
            else {
                return nil
        }
        var serviceArray = [Service]()
        
        for x in result {
            let service = Service(id: x["id"] as? String)
            serviceArray.append(service)
            
        }
        
        return self.init(serviceArray: serviceArray)
    }
    
    func encode() -> NSData? {
        return nil
    }
    
}

struct Service {
    let id: String?
}

class Todo: Decodable {
    let id: String
    let name: String
    
    required init(id: String, name: String) {
        self.id = id
        self.name = name
    }
    
    static func decode(data: NSData) -> Self? {
        guard
            let json = Todo.dataToJSON(data),
            let data = (json["response"] as? [String:AnyObject]),
            let id = data["_id"] as? String,
            let name = data["name"] as? String else {
                return nil
        }
        
        return self.init(id: id, name: name)

    }
}

class ToDoes: Decodable, Encodable {
    let toDoes: [Todo]
    
    required init(toDoes: [Todo]) {
        self.toDoes = toDoes
    }
    
    static func decode(data: NSData) -> Self? {
        guard
            let json = ToDoes.dataToJSON(data),
            let data = (json["response"] as? [[String:AnyObject]])
            else {
                return nil
        }
        var tvShows = [Todo]()
        for item in data {
            guard
                let id = item["_id"] as? String,
                let name =  item["name"] as? String
                else {
                    continue
            }
            
            let listItem = Todo(id: id, name: name)
            tvShows.append(listItem)
        }
        
        return self.init(toDoes: tvShows)
    }
    
    func encode() -> NSData? {
        return nil
    }
}

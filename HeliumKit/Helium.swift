import Foundation
import MIAHydrogenKit

public protocol Decodable {
    static func decode(data: NSData) -> Self?
}

extension Decodable {
    public static func dataToJSON(data: NSData) -> [String: AnyObject]? {
        return try? NSJSONSerialization.JSONObjectWithData(data, options: NSJSONReadingOptions(rawValue: 0)) as! [String : AnyObject]
    }
}

public protocol Encodable {
    func encode() -> NSData?
}

extension Encodable {
    public func JSONtoData(jsonData: [String: AnyObject]) -> NSData? {
        return try? NSJSONSerialization.dataWithJSONObject(jsonData, options: NSJSONWritingOptions())
    }
}

public class RequestBuilder<T: Decodable> {
    
    var path: String?
    var method: MIAHydrogenKit.Method?
    var parameters: [String: AnyObject]?
    var pathReplacements: [String: String]?
    var completion: (Result<T> -> Void)?
    var timeout: Double?
    var retryCount: Int = 2

    private weak var helium: Helium?
    
    init(_ helium: Helium) {
        self.helium = helium
    }
    
    public func get(path: String) -> RequestBuilder<T> {
        self.path = path
        self.method = Method.GET
        
        return self
    }
    
    public func post(path: String, data: NSData?) -> RequestBuilder<T> {
        self.path = path
        self.method = Method.POST(data)
        
        return self
    }
    
    public func put(path: String, data: NSData?) -> RequestBuilder<T> {
        self.path = path
        self.method = Method.PUT(data)
        
        return self
    }
    
    public func delete(path: String) -> RequestBuilder<T> {
        self.path = path
        self.method = Method.DELETE
        
        return self
    }
    
    public func parameters(parameters: [String: AnyObject]?) -> RequestBuilder<T> {
        self.parameters = parameters
        
        return self
    }
    
    public func pathReplacements(pathReplacements: [String: String]?) -> RequestBuilder<T> {
        self.pathReplacements = pathReplacements
        
        return self
    }
    
    public func timeout(timeout: Double) -> RequestBuilder<T> {
        self.timeout = timeout
        
        return self
    }
    
    public func completion(completion: Result<T> -> Void) -> Task {
        self.completion = completion
        
        return helium!.request(self)
    }
}


public enum HeliumError: Int {
    
    case InvalidStatusCode = 1
    case KeyInvalid = 1057
    
    func error() -> NSError {
        return NSError(domain: "Helium", code: self.rawValue, userInfo: nil)
    }
}

public class HeliumConfiguration {
    
    internal let secret: String
    internal let secretID: String
    internal let baseURL: NSURL
    internal let acceptableStatusCodes: Range<Int>
    internal let deviceConfiguration: DeviceConfiguration
    internal let defaultTimeout: NSTimeInterval
    public let debug: Bool
    
    public init(secret: String, secretID: String, baseURL: NSURL, acceptableStatusCodes: Range<Int>, deviceConfiguration: DeviceConfiguration, defaultTimeout: NSTimeInterval = 60.0, debug: Bool = false) {
        self.secret = secret
        self.secretID = secretID
        self.baseURL = baseURL
        self.acceptableStatusCodes = acceptableStatusCodes
        self.deviceConfiguration = deviceConfiguration
        self.defaultTimeout = defaultTimeout
        self.debug = debug

    }
}

public class Helium {
    
    public var debug: Bool {
        return configuration.debug
    }
    public var baseURL: NSURL {
        return configuration.baseURL
    }
    public var deviceToken: String? {
        return configuration.deviceConfiguration.deviceToken
    }
    private let hydrogen: Hydrogen
    private let configuration: HeliumConfiguration
    private let authenticationHashFunction: String? -> String?
    private var lastServerTime: String?
    
    public init(configuration: HeliumConfiguration, authenticationHashFunction: String? -> String?) {
        self.configuration = configuration
        self.authenticationHashFunction = authenticationHashFunction
        
        let config = NSURLSessionConfiguration.defaultSessionConfiguration()
        config.timeoutIntervalForRequest = configuration.defaultTimeout
        
        hydrogen = Hydrogen(config: config, urlRequestBuilder: URLRequestBuilder(), acceptableStatusCodes: configuration.acceptableStatusCodes)
    }
    
    //MARK: Public API
    
    public func get<T: Decodable>(path: String, returnType: T.Type = T.self) -> RequestBuilder<T> {
        return RequestBuilder<T>(self).get(path)
    }
    
    public func post<T: protocol<Encodable, Decodable>>(path: String, object: T? = nil) -> RequestBuilder<T> {
        return RequestBuilder<T>(self).post(path, data: object?.encode())
    }
    
    public func put<T: protocol<Encodable, Decodable>>(path: String, object: T? = nil) -> RequestBuilder<T> {
        return RequestBuilder<T>(self).put(path, data: object?.encode())
    }
    
    public func delete<T>(path: String, returnType: T.Type = T.self) -> RequestBuilder<T> {
        return RequestBuilder<T>(self).delete(path)
    }
    
    func request<T: Decodable>(requestBuilder: RequestBuilder<T>) -> Task {
        let resource = Resource<T>(
            path: requestBuilder.path,
            method: requestBuilder.method!,
            params: requestBuilder.parameters,
            pathReplacements: requestBuilder.pathReplacements,
            parse: { data in
                guard let data = data else {
                    return nil
                }
                return T.decode(data)
            }
        )
        
        let task = hydrogen.request(configuration.baseURL, resource: resource,
            modifyRequest: { mutableRequest in
                if let timeout = requestBuilder.timeout {
                    mutableRequest.timeoutInterval = timeout
                }
                
                self.modifyRequest(mutableRequest)
            }, completion: { result in
                self.completeRequest(requestBuilder, result: result)
        })
        
        task.resume()
        
        return task
    }
    
    private func modifyRequest(mutableRequest: NSMutableURLRequest) {
        let token = configuration.deviceConfiguration.deviceToken
        
        if token == nil {
            return
        }
        
        let keygen = AuthenticationKeyGenerator(deviceID: token!, secret: configuration.secret, secretID: configuration.secretID, authenticationHashFunction: self.authenticationHashFunction)
        let timeStamp = configuration.deviceConfiguration.calculateTimeStamp(lastServerTime)
        
        configuration.deviceConfiguration.updateDeviceInfoIfNeeded(keygen, timeStamp: timeStamp)
        
        let requestHash = keygen.createAuthenticationKey(mutableRequest.URL!, method: mutableRequest.HTTPMethod, body: mutableRequest.HTTPBody, timeStamp: timeStamp)
        mutableRequest.addValue(requestHash!, forHTTPHeaderField: "key")
    }
    
    private func completeRequest<T>(requestBuilder: RequestBuilder<T>, result: Result<T>) {
        switch result {
        case .Success :
            requestBuilder.completion!(result)
        case .Error(let error, _):
            if error.code == 401 && requestBuilder.retryCount > 0 {
                
                guard let jsonResponse = error.jsonResponse as? [String: AnyObject] else {
                    assertionFailure("")
                    return
                }
                if handleExpiredKey(jsonResponse, responseHeaders: error.responseHeaders, requestBuilder: requestBuilder) {
                    return
                } else if handleInvalidKey(jsonResponse, requestBuilder: requestBuilder){
                    return
                }
                
            }
            
            requestBuilder.completion!(result)
        }
    }
    
    //MARK: Handle Session
    
    private func handleExpiredKey<T>(jsonResponse: [String: AnyObject], responseHeaders: [String: AnyObject]?, requestBuilder: RequestBuilder<T>) -> Bool {
        
        guard let responseHeaders = responseHeaders else {
            return false
        }
        
        if let errors = jsonResponse["errors"] as? [[String: AnyObject]],
            error = errors.first,
            errorCode = error["code"] as? String,
            date = responseHeaders["timestamp"] as? String where errorCode == "KeyExpired" {
                lastServerTime = date
                requestBuilder.retryCount = requestBuilder.retryCount - 1
                request(requestBuilder)
                return true
        }
        
        return false
    }
    
    private func handleInvalidKey<T>(jsonResponse: [String: AnyObject], requestBuilder: RequestBuilder<T>) -> Bool {
        if let errors = jsonResponse["errors"] as? [[String: AnyObject]],
            error = errors.first,
            errorCode = error["code"] as? String where errorCode == "KeyInvalid" || errorCode == "DeviceIdInvalid" {
                configuration.deviceConfiguration.invalidateDeviceToken()
                requestBuilder.retryCount = requestBuilder.retryCount - 1
                request(requestBuilder)
                return true
        }
        return false
    }
}

import Foundation

public enum Method {
    
    case GET
    case POST(NSData?)
    case PUT(NSData?)
    case DELETE
    
    public func requestMethod() -> String {
        switch self {
        case .GET:
            return "GET"
        case .POST( _):
            return "POST"
        case .PUT( _):
            return "PUT"
        case .DELETE:
            return "DELETE"
        }
    }
    
    public func requestBody() -> NSData? {
        switch self {
        case .POST(let body):
            return body
        case .PUT(let body):
            return body
        default:
            return nil
        }
    }
}

public struct Resource<A> {

    let path: String?
    var pathReplacements: [String: String]?
    var parameters: [String: AnyObject]?
    let method: Method
    var headers: [String: String]?
    let parse: NSData? -> A?
    
    //MARK: Lifecycle
    
    public init(path: String?, method: Method, params: [String: AnyObject]?, pathReplacements: [String: String]?, headers: [String: String]?, parse: NSData? -> A?) {
        
        self.path = path
        self.pathReplacements = pathReplacements
        self.parameters = params
        self.method = method
        self.headers = headers
        self.parse = parse
    }
    
    public init(path: String?, method: Method, params: [String : AnyObject]?, pathReplacements: [String : String]?, parse: NSData? -> A?) {
        self.init(path: path, method: method, params: params, pathReplacements: pathReplacements, headers: nil, parse: parse)
    }
    
    public init(path: String?, method: Method, params: [String : AnyObject]?, parse: NSData? -> A?) {
        self.init(path: path, method: method, params: params, pathReplacements: nil, parse: parse)
    }
    
    public init(path: String?, method: Method, parse: NSData? -> A?) {
        self.init(path: path, method: method, params: nil, parse: parse)
    }
    
}

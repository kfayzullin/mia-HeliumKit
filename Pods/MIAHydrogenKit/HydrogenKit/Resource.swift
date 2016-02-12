import Foundation

/**
 An Enum describing the 4 basic HTTP methods. Post and put can have a body. 
 - GET:    HTTP method GET
 - POST:   HTTP method POST
 - PUT:    HTTP method PUT
 - DELETE: HTTP method DELETE
 */
public enum Method {
    /// HTTP method GET
    case GET
    
    /// HTTP method POST. The parameter is the data to be sent to the server
    case POST(NSData?)
    
    /// HTTP method PUT. The parameter is the data to be sent to the server
    case PUT(NSData?)
    
    /// HTTP method DELETE
    case DELETE
    
    /// - returns: A string representation of the Method
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
    
    /// - returns: The body of the HTTP method. Only avaiable for Put and Post. Nil otherwise
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

/**
 *  A struct describing a HTTP resource. This also includes the HTTP method used and a function to parse the result.
 The generic parameter describes the return type of the parsed object
 */
public struct Resource<A> {

    /// The path of the resource
    let path: String?
    
    /// Path replacement. Can be used to replace placeholders in the path. E.g. {id} replaced with 1234
    var pathReplacements: [String: String]?
    
    ///  Additional URL parameters
    var parameters: [String: AnyObject]?
    
    /// The HTTP Method used to interact with the resource
    let method: Method
    
    /// Headers
    var headers: [String: String]?
    
    /// Because this parsing might fail, the result is an optional.
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

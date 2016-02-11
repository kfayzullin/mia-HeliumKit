import Foundation

public enum Result<A> {
    
    case Success(A?, Request<A>, Int?)
    case Error(HydrogenKitError, Request<A>)
    
}

public struct HydrogenKitError: ErrorType {
    
    public let code: Int
    public let responseHeaders: [String : AnyObject]?
    public let jsonResponse: AnyObject?
    public let responseData: NSData?
    
}

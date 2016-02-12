import Foundation

/**
 An enum describing the result of a Request
 
 - Success: The request was successful
 - Error:   There was an error during the request
 */
public enum Result<A> {
    /**
     *  The request was successful
     *
     *  - A?         The parsed Object, if applicable
     *  - Request<A> The initial request
     *  - Int?       The server response code, if applicable
     *
     */
    case Success(A?, Request<A>, Int?)
    
    /**
     *  There was an error during the request
     *
     *  - HydrogenKitError The HydrogenKitError that occured
     *  - Request<A>       The initial request
     *
     */
    case Error(HydrogenKitError, Request<A>)
}

/// A struct describing an error that can occur during a request with hydrogen
public struct HydrogenKitError: ErrorType {
    /// The error code. In case of a HTTP error it corresponds to the HTTP status code.
    public let code: Int
    /// The response headers sent back by the server
    public let responseHeaders: [String : AnyObject]?
    /// If there was a JSON server response you can access it here
    public let jsonResponse: AnyObject?
    /// If there was a raw server response you can access it here
    public let responseData: NSData?
}

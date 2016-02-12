import Foundation

/**
 *  Generic struct that describes a HTTP request.
 */
public struct Request<A> {
    /// The requested resource
    let resource: Resource<A>

    /** A block used to modify a request before it is sent to the server. 
      Example usage: add additional header fields (e.g.) before sending that need other parameters of the request to compute
     */
    let modifyRequest: (NSMutableURLRequest -> Void)?
    
    /// Is called when the request finishes. Can be an error or a success. In case of success the result is already parsed
    let completion: Result<A> -> Void
}

import Foundation

public struct Request<A> {
   
    let resource: Resource<A>
    let modifyRequest: (NSMutableURLRequest -> Void)?
    let completion: Result<A> -> Void
    
}

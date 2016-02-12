import Foundation
import UIKit


/// A type-safe HTTP library utilising NSURLSession inspired by http://chris.eidhof.nl/posts/tiny-networking-in-swift.html
public class Hydrogen {
    private let allowedStatusCodesForEmptyResponse = [205, 204]
    
    private let sessionConfig: NSURLSessionConfiguration
    private var session: NSURLSession?
    private var tasks = [Int: Task]()
    private let urlRequestBuilder: URLRequestBuilder
    private let acceptableStatusCodes: Range<Int>
    
    var numberOfActiveTasks: Int {
        return tasks.count
    }
    
    //MARK: Lifecycle
    
    /**
    - parameter config:                NSURLSessionConfiguration used in the requests default: nil
    - parameter urlRequestBuilder:     URLRequestBuilder used to create the Requests default: nil
    - parameter acceptableStatusCodes: A range of HTTP Status codes that is accepted as valid response default: 200..<300
    */
    public init(config: NSURLSessionConfiguration? = nil, urlRequestBuilder: URLRequestBuilder? = nil, acceptableStatusCodes: Range<Int> = 200..<300) {
        sessionConfig = config ?? NSURLSessionConfiguration.defaultSessionConfiguration()
        self.urlRequestBuilder = urlRequestBuilder ?? URLRequestBuilder()
        self.acceptableStatusCodes = acceptableStatusCodes
    }
    
    deinit {
        cancelAll()
    }
    
    /**
     Starts a request to a specified resource
     
     - parameter baseURL:       Base URL of the request
     - parameter resource:      The requested Resource
     - parameter modifyRequest: A block to modify the request just before it is sent
     - parameter completion:    Completion block with Result (either success or error)
     
     - returns: A Task instance that can be used to resume, cancel or suspend the request
     */
    public func request<A>(baseURL: NSURL, resource: Resource<A>, modifyRequest: (NSMutableURLRequest -> Void)?, completion: Result<A> -> Void) -> Task {
        let task = Task()
        
        dispatch_async(dispatch_get_global_queue(QOS_CLASS_UTILITY, 0)) {
            
            guard
                let urlRequest = self.urlRequestBuilder.createURLRequestFromResource(baseURL, resource: resource, modifyRequest: modifyRequest)
                where task.state != NSURLSessionTaskState.Canceling && task.state != NSURLSessionTaskState.Completed
                else {
                    return
            }
            
            let request = Request(resource: resource, modifyRequest: modifyRequest, completion: completion)
            
            task.sessionTask = self.urlSession().dataTaskWithRequest(urlRequest) { [weak self] data, response, error in
                self?.completeTask(task, data: data, request: request, response: response, error: error)
            }
            
            self.tasks[task.sessionTask!.taskIdentifier] = task
            
            if task.state == NSURLSessionTaskState.Running {
                task.resume()
            }
        }
        
        return task
    }
    
    private func completeTask<A>(task: Task, data: NSData?, request: Request<A>, response: NSURLResponse?, error: NSError?) {
        self.tasks.removeValueForKey(task.sessionTask!.taskIdentifier)
        
        let httpResponse = response as! NSHTTPURLResponse?
        let statusCode = httpResponse?.statusCode ?? 0
        
        // Error Present
        if let error = error  {
            let jsonResponse = try? NSJSONSerialization.JSONObjectWithData(data ?? NSData(), options: NSJSONReadingOptions.MutableContainers)
            let hyrogenKitError = HydrogenKitError(code: error.code, responseHeaders: httpResponse?.allHeaderFields as? [String: AnyObject], jsonResponse: jsonResponse, responseData: data)
            request.completion(.Error(hyrogenKitError, request))
        } else if !(acceptableStatusCodes ~= statusCode) { // ~= meaning "Range contains"
            let jsonResponse = try? NSJSONSerialization.JSONObjectWithData(data ?? NSData(), options: NSJSONReadingOptions.MutableContainers)
            let hyrogenKitError = HydrogenKitError(code: statusCode, responseHeaders: httpResponse?.allHeaderFields as? [String: AnyObject], jsonResponse: jsonResponse, responseData: data)
            request.completion(.Error(hyrogenKitError, request))
        } else {
            // parse data
            guard let parsedData = request.resource.parse(data) else {
                // check if empty repsonse allowed
                if allowedStatusCodesForEmptyResponse.contains(statusCode) {
                    request.completion(.Success(nil, request, statusCode))
                } else {
                    let jsonResponse = try? NSJSONSerialization.JSONObjectWithData(data ?? NSData(), options: NSJSONReadingOptions.MutableContainers)
                    let hyrogenKitError = HydrogenKitError(code: 1, responseHeaders: httpResponse?.allHeaderFields as? [String: AnyObject], jsonResponse: jsonResponse, responseData: data)
                    request.completion(.Error(hyrogenKitError, request))
                }
                return
            }
            request.completion(.Success(parsedData, request, statusCode))
        }
    }

    /// see also: `func request<A>(baseURL: NSURL, resource: Resource<A>, modifyRequest: (NSMutableURLRequest -> Void)?, completion: Result<A> -> Void) -> Task`
    public func request<A>(baseURL: NSURL, resource: Resource<A>, completion: Result<A> -> Void) -> Task {
        return request(baseURL, resource: resource, modifyRequest: nil, completion: completion)
    }
    
    /**
     Executes a Request
     
     - parameter baseURL:  Base URL of the request
     - parameter aRequest: The request to be executed
     
     - returns: A Task instance that can be used to resume, cancel or suspend the request
     */
    public func request<A>(baseURL: NSURL, aRequest: Request<A>) -> Task {
        return request(baseURL, resource: aRequest.resource, modifyRequest: aRequest.modifyRequest, completion: aRequest.completion)
    }
    
    private func urlSession() -> NSURLSession {
        session = session ?? NSURLSession(configuration: sessionConfig)
        return session ?? NSURLSession(configuration: sessionConfig)
    }
    
    /**
     Cancels all current Tasks
     */
    public func cancelAll() {
        if let session = session {
            
            session.invalidateAndCancel()
            
            self.session = nil
            
            self.tasks.removeAll(keepCapacity: false)
        }
    }
}

import Foundation
import UIKit

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
    
    public init(config: NSURLSessionConfiguration? = nil, urlRequestBuilder: URLRequestBuilder? = nil, acceptableStatusCodes: Range<Int> = 200..<300) {
        sessionConfig = config ?? NSURLSessionConfiguration.defaultSessionConfiguration()
        self.urlRequestBuilder = urlRequestBuilder ?? URLRequestBuilder()
        self.acceptableStatusCodes = acceptableStatusCodes
    }
    
    deinit {
        cancelAll()
    }
    
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
                // check if empty response allowed
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
    
    public func request<A>(baseURL: NSURL, resource: Resource<A>, completion: Result<A> -> Void) -> Task {
        return request(baseURL, resource: resource, modifyRequest: nil, completion: completion)
    }
    
    public func request<A>(baseURL: NSURL, aRequest: Request<A>) -> Task {
        return request(baseURL, resource: aRequest.resource, modifyRequest: aRequest.modifyRequest, completion: aRequest.completion)
    }
    
    private func urlSession() -> NSURLSession {
        return session ?? NSURLSession(configuration: sessionConfig)
    }
    
    public func cancelAll() {
        if let session = session {
            
            session.invalidateAndCancel()
            
            self.session = nil
            
            self.tasks.removeAll(keepCapacity: false)
        }
    }
}

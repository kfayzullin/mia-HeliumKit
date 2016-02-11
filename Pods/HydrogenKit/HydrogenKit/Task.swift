import Foundation

public class Task {
   
    internal var sessionTask: NSURLSessionTask?
    
    private var taskState: NSURLSessionTaskState = NSURLSessionTaskState.Suspended
    
    internal var state: NSURLSessionTaskState {
        return taskState
    }
    
    public func resume() {
        taskState = NSURLSessionTaskState.Running
        sessionTask?.resume()
    }
    
    public func suspend() {
        taskState = NSURLSessionTaskState.Suspended
        sessionTask?.suspend()
    }
    
    public func cancel() {
        taskState = NSURLSessionTaskState.Canceling
        sessionTask?.cancel()
    }
    
}

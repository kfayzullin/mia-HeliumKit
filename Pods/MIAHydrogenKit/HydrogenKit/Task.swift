import Foundation

/// A class describing a netowrk Task. It can be resumed, suspended or cancelled. It wraps NSURLSessionTask.
public class Task {
   
    internal var sessionTask: NSURLSessionTask?
    
    private var taskState: NSURLSessionTaskState = NSURLSessionTaskState.Suspended
    
    internal var state: NSURLSessionTaskState {
        return taskState
    }
    
    /**
     Resumes the task, if it is suspended.
     */
    public func resume() {
        taskState = NSURLSessionTaskState.Running
        sessionTask?.resume()
    }
    
    /**
     Suspends the task.
     */
    public func suspend() {
        taskState = NSURLSessionTaskState.Suspended
        sessionTask?.suspend()
    }
    
    /**
     Cancels the task.
     */
    public func cancel() {
        taskState = NSURLSessionTaskState.Canceling
        sessionTask?.cancel()
    }
    
}

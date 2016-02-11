import Foundation

public class DeviceConfiguration {
    
    private let request: NSMutableURLRequest
    private let deviceInfo: DeviceInfo
    private let persistenceStore: DeviceConfigurationPersistenceStore
    private let timeout: NSTimeInterval
    
    public init(URL: NSURL, deviceInfo: DeviceInfo, persistenceStore: DeviceConfigurationPersistenceStore, timeout: NSTimeInterval = 60.0) {
        self.request = NSMutableURLRequest(URL: URL)
        self.deviceInfo = deviceInfo
        self.persistenceStore = persistenceStore
        self.timeout = timeout
    }
    
    public var deviceToken: String? {
        get {
            var deviceToken: String?
            
            let lockQueue = dispatch_queue_create("helium.devicetoken.LockQueue", nil)
            dispatch_sync(lockQueue) {
                
                if let token = self.persistenceStore.token {
                    deviceToken = token
                } else {
                    if let token = self.fetchNewDeviceToken() {
                        deviceToken = token
                        self.persistenceStore.token = deviceToken
                        self.persistenceStore.deviceInfoHash = self.deviceInfo.deviceSHA256
                    }
                }
            }
            
            return deviceToken
        }
    }
    
    internal func invalidateDeviceToken() {
        self.persistenceStore.token = nil
    }
    
    // MARK: Offset calculation
    
    internal func calculateTimeStamp(serverTime: String?) -> NSTimeInterval {
        var delta = persistenceStore.timeOffset
        
        if let serverTime = serverTime {
            delta = deltaToServertime(serverTime)
            persistenceStore.timeOffset = delta
        }
        
        let currentTime = NSDate().timeIntervalSince1970
        
        return currentTime + delta
    }
    
    private func deltaToServertime(serverTime: String) -> NSTimeInterval {
        let serverTimeStamp = (serverTime as NSString).doubleValue / 1000
        
        return serverTimeStamp - NSDate().timeIntervalSince1970
    }
    
    // MARK: Handling for synchronous HTTP requests
    
    private func fetchNewDeviceToken() -> String? {
        guard
            let requestURL = request.URL,
            jsonResponse = sendRequest(requestURL, method: "POST"),
            response = jsonResponse["response"] as? [String: AnyObject],
            deviceToken = response["id"] as? String else {
                return nil
        }
        
        return deviceToken
    }
    
    internal func updateDeviceInfoIfNeeded(keygen: AuthenticationKeyGenerator, timeStamp: NSTimeInterval) {
        
        if deviceInfo.deviceSHA256 == persistenceStore.deviceInfoHash {
            return
        }
        
        guard let deviceToken = deviceToken, url = request.URL else {
            return
        }
        
        let putURL = url.URLByAppendingPathComponent(deviceToken)
        let method = "PUT"
        guard
            let key = keygen.createAuthenticationKey(putURL, method: method, body: deviceInfo.encode(), timeStamp: timeStamp),
            _ = sendRequest(putURL, method: method, key: key) else {
                return
        }
        persistenceStore.deviceInfoHash = deviceInfo.deviceSHA256
    }
    
    private func sendRequest(url: NSURL, method: String, key: String? = nil) -> [String: AnyObject]? {
        request.URL = url
        request.HTTPMethod = method
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.HTTPBody = deviceInfo.encode()
        request.timeoutInterval = timeout
        
        if let key = key {
            request.setValue(key, forHTTPHeaderField: "key")
        }
        
        let semaphore = dispatch_semaphore_create(0)
        
        let session = NSURLSession(configuration: NSURLSessionConfiguration.defaultSessionConfiguration())
        var result: [String: AnyObject]?
        let task = session.dataTaskWithRequest(request){ data, response, error in
            defer {
                dispatch_semaphore_signal(semaphore)
            }
            
            guard
                let data = data,
                jsonResult = try? NSJSONSerialization.JSONObjectWithData(data, options: NSJSONReadingOptions(rawValue: 0)) as? [String : AnyObject] else {
                    return
            }
            result = jsonResult
            
            if let httpResponse = response as? NSHTTPURLResponse, timestamp = httpResponse.allHeaderFields["Timestamp"] as? String {
                self.persistenceStore.timeOffset = self.deltaToServertime(timestamp)
            }
        }
        task.resume()

        let semaphoreTimeout = dispatch_time(DISPATCH_TIME_NOW, Int64(NSEC_PER_SEC) * 5)
        if dispatch_semaphore_wait(semaphore, semaphoreTimeout) != 0 {
            return nil
        }
        
        return result
    }
}

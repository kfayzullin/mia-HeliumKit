import Foundation

@objc
public class DeviceConfigurationMemoryStore: NSObject, DeviceConfigurationPersistenceStore {
    
    @objc public var timeOffset: NSTimeInterval = 0.0
    
    @objc public var deviceInfoHash: String?
    
    @objc public var token: String?
    
}

import Foundation


public protocol DeviceConfigurationPersistenceStore: class {
    
    var token: String? { get set }
    var timeOffset: NSTimeInterval { get set } 
    var deviceInfoHash: String? { get set }
    
}

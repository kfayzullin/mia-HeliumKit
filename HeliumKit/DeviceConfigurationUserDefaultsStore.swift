import Foundation

private enum DeviceConfigurationUserDefaultsKey: String {
    
    case DeviceToken = "DeviceConfigurationDeviceToken"
    case TimeOffset = "DeviceConfigurationTimeOffset"
    case DeviceHash = "DeviceConfigurationDeviceHash"
}

@objc 
public class DeviceConfigurationUserDefaultsStore: NSObject, DeviceConfigurationPersistenceStore {
    
    @objc public class func create() -> DeviceConfigurationUserDefaultsStore {
        return DeviceConfigurationUserDefaultsStore()
    }
    
    private var userDefaults: NSUserDefaults {
        return NSUserDefaults.standardUserDefaults()
    }
        
    public var token: String? {
        get {
            return stringForKey(.DeviceToken)
        }
        
        set {
            setString(newValue, forKey: .DeviceToken)
            synchronize()
        }
    }
    
   @objc public var timeOffset: NSTimeInterval {
        get {
            return doubleForKey(.TimeOffset) ?? 0.0
        }
        
        set {
            setDouble(newValue, forKey: .TimeOffset)
            synchronize()
        }
    }
    
    public var deviceInfoHash: String? {
        get {
            return stringForKey(.DeviceHash)
        }
        
        set {
            setString(newValue, forKey: .DeviceHash)
            synchronize()
        }
    }
    
    private func stringForKey(key: DeviceConfigurationUserDefaultsKey) -> String? {
        return userDefaults.stringForKey(key.rawValue)
    }
    
    private func setString(string: String?, forKey key: DeviceConfigurationUserDefaultsKey) {
        userDefaults.setObject(string, forKey: key.rawValue)
    }
    
    private func doubleForKey(key: DeviceConfigurationUserDefaultsKey) -> Double? {
        return userDefaults.doubleForKey(key.rawValue)
    }
    
    private func setDouble(double: Double?, forKey key: DeviceConfigurationUserDefaultsKey) {
        if let double = double {
            userDefaults.setDouble(double, forKey: key.rawValue)
        }
    }
    
    private func synchronize() {
        NSUserDefaults.standardUserDefaults().synchronize()
    }
}

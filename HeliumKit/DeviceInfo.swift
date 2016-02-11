import Foundation
import UIKit
import AdSupport

struct Culture: Equatable, CustomStringConvertible  {
    
    let code: String
    
    var description: String {
        return "Culture: (code: \(code))"
    }
}

struct Os: Equatable, CustomStringConvertible  {
    
    let type: String
    let version: String
    
    var description: String {
        return "Os: (type: \(type) version: \(version))"
    }
}

struct Carrier: Equatable, CustomStringConvertible  {
    
    let type: String?
    
    var description: String {
        return "Carrier: (type: \(type))"
    }
}

struct Screen: Equatable, CustomStringConvertible  {
    
    let resolution: String
    
    var description: String {
        return "Screen: (resolution: \(resolution))"
    }
}

public struct Notification: Equatable, CustomStringConvertible  {
    
    public let token: String
    public let environment: String
    
    public var description: String {
        return "Notification: (token: \(token) environment: \(environment))"
    }
}

struct Device: Equatable, CustomStringConvertible {
    
    let group: String?
    let model: String?
    let os: Os
    let carrier: Carrier
    let screen: Screen
    let notification: Notification?
    
    var description: String {
        return "Device: (os: \(os) carrier: \(carrier) screen: \(screen) notification: \(notification))"
    }
}

struct Vendor: Equatable, CustomStringConvertible  {
    
    let id: String
    
    var description: String {
        return "Vendor: (id: \(id))"
    }
    
}

struct Advertiser: Equatable, CustomStringConvertible  {
    
    let id: String
    
    var description: String {
        return "Advertiser: (id: \(id))"
    }
}

struct App: Equatable, CustomStringConvertible {
    
    let id: String
    let version: String
    let vendor: Vendor
    let advertiser: Advertiser
    
    var description: String {
        return "App: (id: \(id), version: \(version))"
    }
}

public class DeviceInfo: Equatable, CustomStringConvertible  {
    
    let culture: Culture
    let device: Device
    let app: App
    
    public init(bundle: NSBundle, carrierName: String?, notification: Notification? = nil) {
        
        let info = DeviceInfo.gatherDeviceInformation(bundle, carrierName: carrierName, notification: notification)
        self.culture = info.culture
        self.app = info.app
        self.device = info.device
    }
    
    init(culture: Culture, device: Device, app: App) {
        self.culture = culture
        self.device = device
        self.app = app
    }
    
    public var description: String {
        return "DeviceInfo: (device: \(device), app: \(app))"
    }
}

// MARK: DeviceInfo conform to Encodable

extension DeviceInfo: Encodable {
    
    public func encode() -> NSData? {
        
        var deviceDict = [
            "os": [
                "type": self.device.os.type,
                "version": self.device.os.version
            ],
            "carrier": [
                "type": self.device.carrier.type ?? ""
            ],
            "screen": [
                "resolution": self.device.screen.resolution
            ]
            ] as Dictionary<String, AnyObject>
        
        if let notification = self.device.notification {
            let notificationDict = [
                "token": notification.token,
                "environment": notification.environment
            ]
            deviceDict["notification"] = notificationDict
        }
        
        if let group = self.device.group {
            deviceDict["group"] = group
        }
        
        if let model = self.device.model {
            deviceDict["model"] = model
        }
        
        let body = [
            "culture": [
                "code": self.culture.code
            ],
            "app": [
                "id": self.app.id,
                "version": self.app.version,
                "advertiser": [
                    "id": self.app.advertiser.id
                ],
                "vendor": [
                    "id": self.app.vendor.id
                ]
            ],
            "device": deviceDict
        ]
        
        let res = try? NSJSONSerialization.dataWithJSONObject(body, options:  NSJSONWritingOptions(rawValue: 0))
        return res
    }
}

// MARK: Gather device information

internal extension DeviceInfo {
    
    static func gatherDeviceInformation(bundle: NSBundle, carrierName: String?, notification: Notification?) -> (culture: Culture, device: Device, app: App) {
        
        //Culture
        let cultureCode =  NSLocale.currentLocale().localeIdentifier.stringByReplacingOccurrencesOfString("_", withString: "-")
        let culture = Culture(code: cultureCode)
        
        // Os
        let systemVersion = UIDevice.currentDevice().systemVersion
        let osType = UIDevice.currentDevice().systemName
        let os = Os(type: osType, version: systemVersion)
        
        // Carrier
        let carrier = Carrier(type: carrierName)
        
        // Screen
        let bounds = UIScreen.mainScreen().nativeBounds
        let resolution = "\(Int(bounds.height))x\(Int(bounds.width))"
        let screen = Screen(resolution: resolution)
        
        // Group
        let deviceGroup = UIDevice.currentDevice().userInterfaceIdiom.groupDescription()
        
        // Model
        let deviceModel = UIDevice.currentDevice().helium_modelName
        
        // "Assemble" Device
        let device = Device(group: deviceGroup, model: deviceModel, os: os, carrier: carrier, screen: screen, notification: notification)
        
        // AppID
        let appID = bundle.objectForInfoDictionaryKey("CFBundleIdentifier") as? String ?? ""
        
        // AppVersion
        let appVersion = bundle.objectForInfoDictionaryKey("CFBundleShortVersionString") as? String ?? ""
        
        // Vendor
        let vendorId = UIDevice.currentDevice().identifierForVendor?.UUIDString ?? ""
        let vendor = Vendor(id: vendorId)
        
        // Advertiser
        let adId = ASIdentifierManager.sharedManager().advertisingIdentifier.UUIDString
        let advertiser = Advertiser(id: adId)
        
        // "Assemble" App
        let app = App(id: appID, version: appVersion, vendor: vendor, advertiser: advertiser)
        
        return (culture, device, app)
    }
}

// MARK: Add DeviceInfo hash

internal extension DeviceInfo {
    var deviceSHA256: String {
        return self.culture.code + self.device.os.version + self.app.version + (self.device.notification?.token ?? "")
    }
}

// MARK: Map UIUserInterfaceIdioms to Strings

extension UIUserInterfaceIdiom {
    func groupDescription() -> String? {
        switch self {
        case .Unspecified:
            assertionFailure("unknown device. Add the device to the list")
            return nil
        case .Pad:
            return "tablet"
        case .Phone:
            return "phone"
        case .TV:
            return "tv"
        default:
            assertionFailure("unknown device. Add the device to the list")
            return nil
        }
    }
}

// MARK: Equatables

public func ==(lhs: DeviceInfo, rhs: DeviceInfo) -> Bool {
    return lhs.device == rhs.device && lhs.app == rhs.app && lhs.culture == rhs.culture
}

public func ==(lhs: Notification, rhs: Notification) -> Bool {
    return lhs.token == rhs.token || lhs.environment == rhs.environment
}

func ==(lhs: Culture, rhs: Culture) -> Bool {
    return lhs.code == rhs.code
}

func ==(lhs: Os, rhs: Os) -> Bool {
    return lhs.type == rhs.type && lhs.version == rhs.version
}

func ==(lhs: Carrier, rhs: Carrier) -> Bool {
    return lhs.type == rhs.type
}

func ==(lhs: Screen, rhs: Screen) -> Bool {
    return lhs.resolution == rhs.resolution
}

func ==(lhs: Device, rhs: Device) -> Bool {
    return lhs.os == rhs.os && lhs.carrier == rhs.carrier && lhs.screen == rhs.screen && lhs.notification == rhs.notification
}

func ==(lhs: Vendor, rhs: Vendor) -> Bool {
    return lhs.id == rhs.id
}

func ==(lhs: Advertiser, rhs: Advertiser) -> Bool {
    return lhs.id == rhs.id
}

func ==(lhs: App, rhs: App) -> Bool {
    return lhs.id == rhs.id && lhs.version == rhs.version && lhs.vendor == rhs.vendor && lhs.advertiser == rhs.advertiser
}

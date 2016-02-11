import Foundation
import XCTest
@testable import HeliumKit

class DeviceInfoTests: XCTestCase {

    override func setUp() {
        super.setUp()
    }
    
    override func tearDown() {
        super.tearDown()
    }
    
    func testEquality() {
        let notification = Notification(token: "token", environment: "env")
        let deviceInfo1 = DeviceInfo(bundle: NSBundle.mainBundle(), carrierName: "TEST", notification: notification)
        let deviceInfo2 = DeviceInfo(bundle: NSBundle.mainBundle(), carrierName: "TEST", notification: notification)

        XCTAssertEqual(deviceInfo1, deviceInfo2)
    }
}

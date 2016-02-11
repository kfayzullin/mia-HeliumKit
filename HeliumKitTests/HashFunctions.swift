import Foundation

struct HashFunctions {
    
    private static func hash(data: NSData?) -> String? {
        guard let data = data else {
            return nil
        }
    
        let count = data.length / sizeof(UInt8)
        var input = [UInt8](count: count, repeatedValue: 0)
        data.getBytes(&input, length:count * sizeof(UInt8))
        
        var hash = [UInt8](count: Int(CC_SHA256_DIGEST_LENGTH), repeatedValue: 0)
        CC_SHA256(input, CC_LONG(input.count), &hash)
        
        let hashData = NSData(bytes: hash, length: hash.count)
        let hashCount = hashData.length / sizeof(UInt8)
        var hashArray = [UInt8](count: hashCount, repeatedValue: 0)
        hashData.getBytes(&hashArray, length:hashCount * sizeof(UInt8))
        let res = hashArray.reduce("") { $0 + String(format:"%02x", $1) }
        return res
    }
    
    
    static var sha256: String? -> String? = { input in
        guard
            let input = input?.lowercaseString,
            inputData  = input.dataUsingEncoding(NSUTF8StringEncoding) else {
                return nil
        }
        return HashFunctions.hash(inputData)?.lowercaseString
    }
}

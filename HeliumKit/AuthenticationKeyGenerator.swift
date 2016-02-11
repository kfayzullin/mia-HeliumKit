import Foundation

public class AuthenticationKeyGenerator: NSObject {
	
	let deviceID: String
	let secret: String
	let secretID: String
    let authenticationHashFunction: String? -> String?
	
    public init(deviceID: String, secret: String, secretID: String, authenticationHashFunction: String? -> String?) {
		
		self.deviceID = deviceID
		self.secret = secret
		self.secretID = secretID
        self.authenticationHashFunction = authenticationHashFunction
        
		super.init()
	}
	
	public func createAuthenticationKey(url: NSURL, method: String, body: NSData?, timeStamp: NSTimeInterval) -> String? {
		
		let urlComponents = NSURLComponents(URL: url, resolvingAgainstBaseURL: true)!
//		assert(urlComponents.port == nil, "Port should be ignored")

		let timeStampString = String(Int64(timeStamp))
		var signaturString = "\(deviceID)\(secret)\(timeStampString)\(method)\(urlComponents.scheme!)://\(urlComponents.host!)"
        if let port = urlComponents.port {
            signaturString += ":\(port)"
        }
        signaturString += urlComponents.path ?? ""
        signaturString += (urlComponents.percentEncodedQuery != nil) ? "?\(urlComponents.percentEncodedQuery!)" : ""
        signaturString += hashedBodyData(body) ?? ""
        guard let signaturHash = authenticationHashFunction(signaturString) else {
            return nil
        }
        
        return "\(deviceID)\(secretID)\(timeStampString)\(signaturHash)"
	}
	
	private func hashedBodyData(bodyData: NSData?) -> String? {
        guard
            let bodyData = bodyData,
            bodyString = NSString(data: bodyData, encoding: NSUTF8StringEncoding) as? String else {
                return nil
        }
        
        return authenticationHashFunction(bodyString)
	}
}

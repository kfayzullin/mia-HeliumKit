import Foundation

// TODO: This class should not be exposed publicly.
public class URLRequestBuilder {
    
    public init() { }
    
    func createURLRequestFromResource<A>(baseURL: NSURL, resource: Resource<A>, modifyRequest: (NSMutableURLRequest -> Void)?) -> NSURLRequest? {
        let urlComponents = NSURLComponents(URL: baseURL, resolvingAgainstBaseURL: true)
        
        if let urlComponents = urlComponents {
            
            applyPathReplacements(urlComponents, resource: resource)
            addParameters(urlComponents, resource: resource)
            
            let urlRequest = NSMutableURLRequest(URL: urlComponents.URL!)
            
            if let headers = resource.headers {
                
                for header in headers {
                    urlRequest.setValue(header.0, forHTTPHeaderField: header.1)
                }
            }
            
            urlRequest.HTTPMethod = resource.method.requestMethod()
            
            if let body = resource.method.requestBody() {
                urlRequest.HTTPBody = body
            }
            
            if let modifyRequest = modifyRequest {
                modifyRequest(urlRequest)
            }
            
            // should the
            return urlRequest.copy() as? NSURLRequest
        }
        
        return nil
    }
    
    private func applyPathReplacements<A>(urlComponents: NSURLComponents, resource: Resource<A>) {
        var resourcePath = resource.path
        
        if let path = resourcePath {
            if !path.hasPrefix("/") {
                resourcePath = "/\(path)"
            }
        } else {
            resourcePath = ""
        }
        
        if let pathReplacements = resource.pathReplacements {
            
            for replacement in pathReplacements {
                
                if let range = resourcePath!.rangeOfString(replacement.0, options: NSStringCompareOptions.CaseInsensitiveSearch) {
                    resourcePath!.replaceRange(range, with: replacement.1)
                }
            }
        }
        
        urlComponents.path = resourcePath
    }
    
    private func addParameters<A>(urlComponents: NSURLComponents, resource: Resource<A>) {
        if let parameters = resource.parameters {
            
            let sortedParameters = parameters.sort { $0.0 < $1.0 }
            var query = ""
            
            for index in 0..<sortedParameters.count {
                
                let parameter = sortedParameters[index]

                query += "\(parameter.0)=\(parameter.1)"
                
                if index < parameters.count - 1  {
                    query += "&"
                }
            }
            
            urlComponents.query = query
        }
    }
}

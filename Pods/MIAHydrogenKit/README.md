![logo](https://raw.githubusercontent.com/7factory/mia-HydrogenKit/gh-pages/images/hydrogen_400px.png "Hydrogen Logo")

# mia-HydrogenKit

Swift networking library (wrapping NSURLSession).

## Requirements

iOS >= 8.0, Swift

## Setup

Add HydrogenKit to your Podfile.
``` ruby 
pod "HydrogenKit", "~> 2.0"
```
Run `pod install`.

## General Usage

``` swift
let hydrogen = Hydrogen()

let resource = Resource(
  path: "get",
  method: Method.GET,
  parse: { data in
      // perform standard JSON decoding using NSJSONSerialization here
      return "Hello World"
  }
)

let task = hydrogen.request(
  NSURL(string: "http://httpbin.org")!,
  resource: resource,
  completion: { result in
      switch result {
      case let .Success(value, request, statusCode):
        print(value, request, statusCode)
      case let .Error(error, request):
        print(error, request)
      }
  }
)
task.resume()
```

The snippet above uses four main steps to perform a network call:
- An instance of hydrogen is created. **Note:** This instance should be strongly held in a property of your class.
- A resource specifies the path, HTTP method, and a closure that receives an `NSData` instance and returns the parsed result. (For a REST endpoint responding with JSON, the `NSData` could be converted to JSON here.) 
- Hydrogen's request method is called with the base path, the previously configured resource, and a completion closure. The completion closure receives an associated enum that is either `.Success` or `.Error`. In the success case, the first associated value contains the result that was returned from the `parse` function of the resource (i.e., "Hello World"). **Note:** You need to dispatch to the main queue here if you want to update the UI.
- The task is resumed, which starts the network call.

### Configuration
Hydrogen can be configured with three (optional) parameters in its initializer:
- `config`: An `NSURLSessionConfiguration` object. Default is `NSURLSessionConfiguration.defaultSessionConfiguration()`.
- `urlRequestBuilder`: A URLRequestBuilder object that returns configured `NSURLRequest` objects. Default is an instance of Hydrogen's `URLRequestBuilder` class. (TODO: URLRequestBuilder should be a protocol.)
- `acceptableStatusCodes`: A Swift Range specifying the HTTP status codes that are considered as success. Default is `200..<300`. 

### Performing Requests
The `request` method has three different signatures:
- `baseURL: NSURL, resource: Resource<A>, completion: Result<A> -> Void`: Used in the example above.
- `baseURL: NSURL, resource: Resource<A>, modifyRequest: (NSMutableURLRequest -> Void)?, completion: Result<A> -> Void`: Takes an additional closure that may modify the `NSMutableURLRequest` object before the request is started. (This closure runs on a background queue.) 
- `baseURL: NSURL, request: Request<A>`: Can be used to retry a failed request in the completion closure.

### Cancelling Requests
You can either call `cancel` on a `Task` returned from the request method or call `cancelAll` to stop all calls of a Hydrogen instance.


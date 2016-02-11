![logo](https://raw.githubusercontent.com/7factory/mia-HydrogenKit/gh-pages/images/helium_400px.png "Hydrogen Logo")
# HeliumKit

An iOS Middleware access library for Mia-js.

## Requirements

iOS >= 8.0, Swift

## Setup

Add HeliumKit to your Podfile.
``` ruby 
pod "HeliumKit", "~> 1.0"
```
Run `pod install`.

## General Usage

``` swift
// Struct containing a decoded TVShow.
struct TVShow: Decodable, FieldsSelector {
    static var selectionString: String { return "{id,titles{default},images{url}}" }
    
    let id: String
    let title: String
    let imageURL: NSURL
   
    static func decode(data: NSData) -> TVShow? {
        // dataToJSON is a helper method provided by the Decodable protocol.
        let json = dataToJSON(data)
        // Extract properties from decoded JSON here and initialize struct...
        return self.init(
          id: id,
          title: title, 
          imageURL: imageURL
        )
    }
}

// Configuration for device registration.
let deviceConfiguration = DeviceConfiguration(
    URL: NSURL(string: "https://mobileapi-stage.prosiebensat1.com/7tv/mobile/v1/devices")!,
    deviceInfo: DeviceInfo(bundle: NSBundle.mainBundle(), carrierName: ""),
    persistenceStore: DeviceConfigurationUserDefaultsStore()
)

// Create Helium with configuration. 
let config = HeliumConfiguration(
    secret: "YourClientSecret",
    secretID: "YourClientSecretID",
    baseURL: NSURL(string: "https://mobileapi-stage.prosiebensat1.com")!,
    acceptableStatusCodes: 200..<300,
    deviceConfiguration: deviceConfiguration
)

let helium = Helium(configuration: config, authenticationHashFunction: HashFunctions.sha256)

// Perform get call and retrieve decoded TVShow.
let task = helium.get("/7tv/mobile/v1/tvshows/:id", returnType: TVShow.self)
  .pathReplacements(["id": "1032808"])
  .parameters(["limit": 100])
  .completion { result in
    switch result {
    case .Success(let tvShow, _, _):

    case .Error(let error, _):
      
    }
}
```

The snippet above uses four main steps to perform a middleware call:
- A struct is defined that implements the `Decodable` protocol for decoding the middleware JSON response into basic data for a TVShow.
- Configuration objects for device registration and Helium are created. Please contact the ProSiebenSat.1 Mobile Middleware Team to get valid parameters for your use case. 
- An instance of Helium is created with the previously defined configuration object.
- A GET call is performed. The call is configured with the path for a specific TVShow, the return type of the response (the TVShow struct defined in step 1), and GET parameters (e.g., "limit" in this case). The final completion method starts the call and takes a closure that is triggered with an associated enum. The result enum is either `.Success` or `.Error`. In the success case, the first associated value contains the decoded result type. **Note:** You need to dispatch to the main queue if you want to update the UI here. 

### Configuration
Helium must be configured with an instance of `HeliumConfiguration`. Configuration values such as `secret`, `secretID`, and `baseURL` must be obtained from the Middleware Team. `acceptableStatusCodes` is a Swift Range specifying the HTTP status codes that are considered as success.

The `DeviceConfiguration` class is separately configured and passed as parameter to `HeliumConfiguration`. Here, `URL` specifies the endpoint for creating, updating, and deleting devices. (Helium handles registering and updating devices internally.)

For the parameter `deviceInfo`, an instance of the class `DeviceInfo` is injected. This class is configured with the application bundle and an optional carrier name. The class then internally queries various details about the device and OS. Details such as the app identifier and version string are read from the passed in bundle. (Please contact the Middleware Team for valid values.)  

The persistence strategy for how the device token is stored can be configured with the parameter `persistenceStore`. You can choose `DeviceConfigurationUserDefaultsStore`, which stores the token in the user defaults, or create your own store (with Keychain storage, for instance) by implementing the `DeviceConfigurationPersistenceStore` protocol. 

### Decoding / Encoding
In its `get`, `post`, `put` and `delete` methods, Helium allows you to specify a type that the middleware response is decoded to. These types need to conform to the `Decodable` protocol and implement a static `decode` method. This method is called by Helium and receives an `NSData` object. Using the convenience method `dataToJSON`, you can decode the data into JSON, extract the specific values for the struct, and return the initialized value at the end of the method.

In your application, you could, for instance, define a TVShow and a Video struct and then set the metatype value of these structs for the parameter `returnType` (e.g., `helium.get("/7tv/mobile/v1/tvshows/:id", returnType: TVShow.self`). The completion closure then receives a decoded value of this type when the response was successful. 

### Performing Requests
Helium provides a fluent interface that allows you to chain multiple options as needed and then start the call using the `complete` method at the end of the chain. The four main methods are `get`, `post`, `put` and `delete`. The first parameter is the path that is appended to the base path (configured via `HeliumConfiguration`), the second parameter is the metatype value for the return type (see previous section).

You can chain the main methods with calls to `parameters` (a dictionary containing query parameters) and `pathReplacements`(a dictionary with replacements for the `path` parameter). `timeout` allows you to set a per request timeout value for a call. The chain must always be ended with a call to the `completion` method. The completion closure is then triggered with an associated enum for for the success and error cases (see the example). 


### Cancelling Requests
Helium methods return a `Task` object for the final `complete` call. The `Task`provides a `cancel()` method.
 

# LightNetwork Integration Guide

******LightNetwork****** is a Light Weight Network library for Mobile iOS applications.

## Requirements

- iOS 9+
- Swift 4.2+
- Xcode 10.1+

## Installation

##### SPM

```ruby
pod 'LightNetwork'
```
## Features

- A Neat Structure for Network Requests.
- Group Network Requests Depends on Module/Feature.

## Usage
##### Import SDK
```swift
    import LightNetwork
```
## Usage
```swift
    //Create Custom Error Data Structure.
    struct <FirstLetter>Error: NErrorDecoder {
        var code: Int?
        var type: String?
        var localizedDescription: String
    }
```
```swift
    // App Endpoint Default Properties.
    extension <FirstLetter>Endpoint {
        var production         :  Bool  {  <Your  App  Production  Base  URL>  }
        var stag             :  Bool  {  <Your  App  Stag  Base  URL>  }
        var httpHeaders      : HTTPHeaders { <Specify any common HTTPHeader> } // It will disabled when overrides founds.
        var errorTypes         : [NErrorDecoder.Type] { [<FirstLetter>Error.self]
        }
    }
```
```swift
    // Request Group.
    enum Request {
        case login(with: Parameters), info
    }
```
```swift
    extension Request: <FirstLetter>Endpoint {
    var path: String {
        switch self {
            case .login: return "/login"
            case .info: return "/info"
        }
    }

    var parameters: Parameters {
        switch self {
        case.login: return ["username": "",
                            "password": ""]
        case .info: return [:]
        }
    }

    var httpMethod: HTTPMethod {
        switch self {
        case .login: return .post
        case .info: return .get
        }
    }

    var httpBody: HTTPBody? {
        switch self {
        case .login(let parameters): return parameters.encodedQueryStringData
        case .info: return nil
        }
    }

    var    httpHeaders: HTTPHeaders { return [<Custom Headers>] } // This will be overide default declaration.
    }
```
```swift
    // Create a Response Data Structure.
    struct  Response: Decodable {
        let name: String
    }
    // Make a Request.
    Request.info.response { (result: Result<Response, NError>) in
        switch result {
            case .success(let response): // Parse Response.
            case .failure(let error): // Handle Error
        }
    }
```

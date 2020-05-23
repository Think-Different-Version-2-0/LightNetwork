//
//  Endpoint.swift
//  LightNetwork
//
//  Created by sijo on 23/05/20.
//

import Foundation

// MARK: Public Environment
// Injecting Server URLs
// Avalable Environments: Production, Stag and Beta.
//----------------------------------------------------------------------------------------------
public protocol Environment {
    /// Specify the Production URL.
    var production: String { get }
    /// Specify the Staging URL.
    var stag: String { get }
}

// MARK: Public Environment Declaration
//----------------------------------------------------------------------------------------------
/// Favourable environments.
public enum NEnvironment {
    /// Producation environment.
    case production
    /// Stag environment.
    case stag
}

// MARK: Requestable Delaration
//----------------------------------------------------------------------------------------------
public protocol Requestable {
    /// A request with Data response.
    /// - Parameter type       : Specify the type of the request.
    /// - Parameter completion : Completed with Data.
    func response(_ completion: @escaping Response<Data>)
    /// A request with Generic response.
    /// - Parameter type       : Specify the type of the request. Which must be conformed to Codable, at least Decodable protocol.
    /// - Parameter completion : Completed with Generic Model.
    func response(_ completion: @escaping Response<JSON>)
    /// A request with JSON response via Network.
    /// - Parameter type       : Specify the type of the request.
    /// - Parameter completion : Completed with JSON Key String and Value Any Type Dictionary.
    func response<T>(_ completion: @escaping Response<T>) where T : Decodable
}
// MARK: Endpoint Protocol Declarartion
//----------------------------------------------------------------------------------------------
/// This will be the a Request MEndpoint.
public protocol Endpoint: Environment, Requestable {
    /// Returns request path, commonly we call API path.
    var path: String { get }
    /// Returns the request method, We use POST for most of the API's.
    var httpMethod: HTTPMethod { get }
    /// Returns the request parameters.
    var parameters: Parameters { get }
    /// Returns the request headers.
    var httpHeaders: HTTPHeaders { get }
    /// Returns request body.
    var httpBody: HTTPBody? { get }
    /// Returns the request timeout.
    var timeout: TimeInterval { get }
    /// Returns Error Types
    var errorTypes: [NErrorDecoder.Type] { get }
}
// MARK: Host from Environments
//----------------------------------------------------------------------------------------------
extension Endpoint {
    /// Return the enviorment, ex: Production, Stag, Beta.
    public var environment: NEnvironment { return Network.environment }
    /// Returns host
    public var host: String {
        switch environment {
        case .production: return production
        case .stag      : return stag
        }
    }
}
// MARK: Endpoint Default Implementation
//----------------------------------------------------------------------------------------------
extension Endpoint {
    /// Returns the request method, We use POST for most of the API's.
    public var httpMethod: HTTPMethod { return .post }
    /// Returns the request timeout.
    public var timeout: TimeInterval { return Network.requestTimeout }
    /// Returns the request headers.
    public var httpHeaders: HTTPHeaders { return [MHttpHeader.Key.contentType: MHttpHeader.Value.formURLEncoded] }
    /// Specify the Error Models.
    public var errorTypes: [NErrorDecoder.Type] { return [] }
    /// Returns request body.
    public var httpBody: HTTPBody? { return nil }
}
// MARK: Endpoint Helper Properties
//----------------------------------------------------------------------------------------------
extension Endpoint {
    /// Returns Encoded URL.
    private var encodedURL: String { return host + path + "?" + parameters.encodedQueryString.percentEncoding }
    // Returns request URL.
    public var url: URL? { return URL(string: httpMethod == .get ? encodedURL : host + path) }
    /// Returns URL Components.
    public var components: URLComponents {
        /// Initaize a URL Component.
        var components = URLComponents()
        // Set scheme from evironment.
        //components.scheme = environment.scheme
        // Set the host from environment.
        components.host = host
        // Set the path.
        components.path = path
        // Set the query items.
        components.setQueryItems(with: parameters)
        // Returns components.
        return components
    }
    /// Returns URL Request.
    public var request: URLRequest {
        /// Initaize a URL Request.
        var request = URLRequest(url: url!)
        // Set http method.
        request.httpMethod = httpMethod.rawValue
        // Set header.
        request.allHTTPHeaderFields = httpHeaders
        // Set body.
        /// Convert the dictionary key and value to joined with equal sign '='.
        /// Merge the whole string with and sign '&'.
        /// Convert and returns data of string.
        let httpBody = self.httpBody ?? parameters.encodedQueryStringData
        // Restricted Body in GET Request(iOS 13).
        request.httpBody = httpMethod == .get ? nil : httpBody
        /// Set request timeout.
        request.timeoutInterval = timeout
        // Returns the request.
        return request
    }
}

// MARK: Requestable Conformance
//----------------------------------------------------------------------------------------------
extension Endpoint {

    public func response(_ completion: @escaping Response<Data>) {
        Network.request(with: self, completion)
    }

    public func response<T>(_ completion: @escaping Response<T>) where T : Decodable {
        response { (result: Result<Data, NError>) in completion(result.decode()) }
    }

    public func response(_ completion: @escaping Response<JSON>) {
        response { (result: Result<Data, NError>) in completion(result.serialzedJSON()) }
    }
}

extension Parameters {
    /// Returns encoded Query String from Parameters.
    public var encodedQueryString: String { return map { "\($0.key)" + "=" + "\($0.value)" }.joined(separator: "&") }
    /// Returns encoded Query String Data from Parameters.
    public var encodedQueryStringData: Data? { return encodedQueryString.percentEncoding.data }
}

// MARK: Type Alias Declaration for Request
//----------------------------------------------------------------------------------------------
/// Placeholder for HTTPHeader Key String Value String dictionary.
public typealias HTTPHeaders = [String: String]
/// Placeholder for Parameters Key String Value String dictionary.
public typealias Parameters  = [String: String]
/// Placeholder for Data.
public typealias HTTPBody    = Data


// MARK: HTTPMethod Declaration
//----------------------------------------------------------------------------------------------
/// Specify the http methods.
public enum HTTPMethod: String {
    case get    = "GET"
    case post   = "POST"
    case put    = "PUT"
    case delete = "DELETE"
}

public enum MHttpHeader {
    public enum Key {
        public static let userAgent      = "User-Agent"
        public static let contentType    = "Content-Type"
        public static let bundleID       = "X-Bundle-Id"
        public static let clientHash     = "X-Client-Hash"
        public static let clientToken    = "X-Client-Token"
        public static let clientID       = "client_id"
        public static let bearer         = "Bearer "
    }
    
    public enum Value {
        public static let authorization  = "Authorization"
        public static let formURLEncoded = "application/x-www-form-urlencoded"
        public static let json           = "application/json"
        public static let mobile         = "mobile"
    }
}

// MARK: String Helper for Encoding
//----------------------------------------------------------------------------------------------
extension String {
    /// Returns the character set for characters allowed in a query URL component.
    public var percentEncoding: String {
        var encodedString = addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
        encodedString = encodedString.replacingOccurrences(of: "+", with: "%2B")
        return encodedString
    }
}

// MARK: URLCompenent Helper to Generate Query Items
//----------------------------------------------------------------------------------------------
fileprivate extension URLComponents {
    /// Update the query items.
    mutating func setQueryItems(with parameters: [String: String]) {
        self.queryItems = parameters.map { URLQueryItem(name: $0.key, value: $0.value) }
    }
}

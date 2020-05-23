//
//  Network.swift
//  LightNetwork
//
//  Created by sijo on 23/05/20.
//

import Foundation

// MARK: Public Type Alias
//----------------------------------------------------------------------------------------------
/// An alias of Key String Value Any type Dictionary.
public typealias JSON = [String: Any]

/// An alias of Generic Result Type
public typealias Response<T> = (Result<T, NError>) -> Void

// MARK: Network Declaration
//----------------------------------------------------------------------------------------------
public final class Network {
    // MARK: Initialization
    //----------------------------------------------------------------------------------------------
    /// Specify the environment.
    public static var environment: NEnvironment = .production
    /// Specify the request time out.
    public static let requestTimeout: TimeInterval = 30.0
    /// Initialize default session.
    static let session = URLSession.shared
    
    // MARK: Dynamic Return Properties
    //----------------------------------------------------------------------------------------------
    /// Identify the current network is reachable or not.
    public static var isAvailable: Bool { return Reachability()?.connection != Reachability.Connection.none }
    
    // MARK: Methods
    //----------------------------------------------------------------------------------------------
    /// A request with Data response via Network.
    /// - Parameter type       : Specify the type of the request.
    /// - Parameter completion : Completed with Data.
    public static func request<T>(with type: T,
                               _ completion: @escaping Response<Data>) where T : Endpoint {
        
        var localizedError: NError? {
            didSet {
                if let localizedError = localizedError {
                    // Complete with error response.
                    completion(.failure(localizedError.error))
                    print(localizedError)
                }
            }
        }
        
        guard isAvailable else {
            localizedError = Reason.noNetwork.error
            return
        }
        
        /// Verify the request.
        guard let _ = type.url else {
            // Stop the execution the error occurs.
            localizedError = Reason.emptyURL.error
            // Early exit.
            return
        }
        
        /// Initialize data task.
        let task = session.dataTask(with: type.request) { (data, response, error) in
            
            /// Get status code
            let statusCode = (response as? HTTPURLResponse)?.statusCode ?? NError.StatusCode.unknown
            
            // Verify the request  error.
            if let error = error {
                /// Parse the error to NEError.
                localizedError = Reason.custom(error.localizedDescription, statusCode).error
                return
            }
            
            /// Verify the request data.
            guard let data = data else {
                /// Parse the error to NEError.
                localizedError = Reason.emptyData.error
                return
            }
            
            /// Parse data to requested type.
           // guard (200...299).contains(statusCode) else {
            guard (statusCode == 200) else {
                print(data.jsonString)
                localizedError = type.localize(error: data)
                    .append(statusCode)
                return
            }
            // Complete with object.
            completion(.success(data))
        }
        // Resume the task.
        task.resume()
    }
}

extension Result where Success == Data, Failure == NError {
    public func decode<T>() -> Result<T, NError> where T : Decodable {
        do {
            let data = try get()
            let decoded = try JSONDecoder().decode(T.self, from: data)
            return .success(decoded)
        } catch {
            let data = try? get()
            return .failure(error as? NError ?? .init(code: NError.StatusCode.validRequest,
                                                   message: data?.jsonString))
        }
    }
    
    public func serialzedJSON() -> Result<JSON, NError> {
        do {
            let data = try get()
            let json = data.json
            return .success(json)
        } catch {
            let data = try? get()
            return .failure(error as? NError ?? .init(code: NError.StatusCode.validRequest,
                                                   message: data?.jsonString))
        }
    }
}

extension Data {
    public var jsonString: String { return String(data: self, encoding: .utf8)  ?? "No Response" }
    public var json: JSON {
        let json = try? JSONSerialization
            .jsonObject(with: self, options: .allowFragments)
        return (json as? JSON) ?? ["Response": jsonString]
    }
}

fileprivate extension NErrorDecoder {
    static func decode(error data: Data) -> NError? {
        guard let error = try? JSONDecoder()
            .decode(Self.self, from: data) else { return nil }
        return error.error
    }
}

fileprivate extension Endpoint {
    func localize(error data: Data) -> NError {
        guard let error = (errorTypes + [NError.self])
            .compactMap ({ $0.decode(error: data) })
            .first,
            ![NError.Description.unexpectedError,
            NError.Description.unableToParse].contains(error.localizedDescription) else { return Reason.custom(data.jsonString, 0).error }
        return error
    }
}


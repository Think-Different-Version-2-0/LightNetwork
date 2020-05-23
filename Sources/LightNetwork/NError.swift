//
//  NError.swift
//  LightNetwork
//
//  Created by sijo on 23/05/20.
//

import Foundation

// MARK: Reason Implementation
//----------------------------------------------------------------------------------------------
enum Reason: ReasonableError {
    case noNetwork
    case emptyURL
    case emptyData
    case custom(String, Int)
    
    var localizedDescription: String {
        switch self {
        case .noNetwork                 : return NError.Description.noNetwork
        case .emptyURL                  : return NError.Description.emptyURL
        case .emptyData                 : return NError.Description.emptyData
        case .custom(let decsription, _): return decsription
        }
    }
    
    var code: Int? {
        switch self {
        case .noNetwork          : return NError.StatusCode.noNetwork
        case .emptyURL           : return NError.StatusCode.emptyURL
        case .emptyData          : return NError.StatusCode.emptyData
        case .custom(_, let code): return code
        }
    }
    
    var type   : String? { return localizedDescription }
}

// MARK: NError Implementation
//----------------------------------------------------------------------------------------------
/// SDK special error type, which conformed Error Protocol.
/// - Note:  All properties are optional, use guard orif let for parsing.
public class NError: NSObject, NErrorDecoder {
    /// Returns Error Type.
    public let type       : String?
    /// Returns the status code.
    public var code       : Int?
    /// Returns the message.
    public let message    : String?
    
    public var grantTypeError: String?
    
    public var errorDescription: String?
    
    public var recover: Any?
    
    public init(type: String? = nil, code: Int? = NError.StatusCode.unknown, message: String? = NError.Description.InternalServerError, recover: Any? = nil) {
        self.type    = type
        self.code    = code
        self.message = message
        self.recover = recover
    }
    
    // MARK: Custom Coding Keys Declaration
    //----------------------------------------------------------------------------------------------
    private enum CodingKeys: String, CodingKey {
        case type, message, code, grantTypeError = "unsupported_grant_type", errorDescription = "error_dscription"
    }
    
    func append(_ statusCode: Int) -> NError {
        return NError(type: type, code: statusCode, message: message, recover: recover)
    }
    public var localizedDescription: String { return message ?? errorDescription ?? grantTypeError ?? NError.Description.unexpectedError }
}

extension NError {
    var responseType: String { return type ?? "" }
    var responseCode: Int    { return code ?? NError.StatusCode.unknown }
    var responseDescription: String { return localizedDescription }
}

public protocol ReasonableError: Error {
    /// Returns Type of Error
    var type                : String? { get }
    /// Returns Status or Error Code.
    var code                : Int?    { get }
    /// Returns a valid error description.
    var error               : NError  { get }
    /// Returns Status description.
    var localizedDescription: String   { get }
    /// Returns Actual Error.
    var recover             : Any? { get }
}

extension ReasonableError {
    public var error  : NError { return NError(type   : type,
                                               code   : code,
                                               message: localizedDescription,
                                               recover: recover) }
    public var type   : String?  { return nil }
    public var code   : Int?     { return NError.StatusCode.unknown }
    public var recover: Any?     { return self }
}

public protocol NErrorDecoder: Decodable, ReasonableError {}

extension NError {
    public enum StatusCode {
        public static let unknown              = 0
        public static let validRequest         = 200
        public static let badRequest           = 400
        public static let badGateway           = 401
        public static let internalServerError  = 500
        public static let noNetwork            = 1009
        public static let emptyURL             = 1008
        public static let notEnoughJSON        = 1005
        public static let emptyData            = 1006
    }
}

extension NError {
    public enum Description {
        public static let noNetwork           = "The Internet connection appears to be offline"
        public static let badRequest          = "Unable to process request"
        public static let emptyURL            = "URL is empty or incomplete"
        public static let invalidToken        = "Invalid Token"
        public static let malformedJSON       = "Malformed JSON"
        public static let emptyData           = "Data is nil"
        public static let unableToParse       = "Unable to parse"
        public static let unexpectedError     = "Unexpected Error"
        public static let InternalServerError = "Server is offine or not responding"
        public static let somethingWentWrong  = "Something went wrong"
        public static let sessionExpired      = "Session expired"
        public static let sessionNotExist     = "Session not exist"
    }
}


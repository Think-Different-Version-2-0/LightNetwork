//
//  Helpers.swift
//  LightNetwork
//
//  Created by sijo on 23/05/20.
//

import Foundation
import CommonCrypto

/// Placeholder for String, Which lead to code more readable.
fileprivate typealias Wrapper = [String: String]

// MARK: Private Key Generation
//----------------------------------------------------------------------------------------------

public var randomValue: String { return UUID().uuidString }

var boundary: String { return "Boundary-\(randomValue)" }

extension String {
    public var SHA256: String {
        let macOut = data?.SH256Bytes
        var base64Encoded = macOut?.base64EncodedString(options: [])
        base64Encoded = base64Encoded?.replacingOccurrences(of: "/", with: "_")
        base64Encoded = base64Encoded?.replacingOccurrences(of: "=", with: "")
        base64Encoded = base64Encoded?.replacingOccurrences(of: "+", with: "-")
        return base64Encoded ?? ""
    }
}

extension Data {
    
    public var SH256Bytes: Data {
        var hash = [UInt8](repeating: 0, count: Int(CC_SHA256_DIGEST_LENGTH))
        withUnsafeBytes {
            _ = CC_SHA256($0.baseAddress, CC_LONG(count), &hash)
        }
        return Data(hash)
    }
    
    struct HexEncodingOptions: OptionSet {
        let rawValue: Int
        static let upperCase = HexEncodingOptions(rawValue: 1 << 0)
    }
    
    func hexEncodedString(options: HexEncodingOptions = []) -> String {
        let format = options.contains(.upperCase) ? "%02hhX" : "%02hhx"
        return map { String(format: format, $0) }.joined()
    }
}

extension Encodable {
    public var data: Data? { try? JSONEncoder().encode(self) }
    public var encoded: Parameters {
        guard let data = try? JSONEncoder().encode(self),
        let json = try? JSONSerialization.jsonObject(with: data, options: .allowFragments) as? JSON else { return [:] }
        return json.compactMapValues { "\($0)" }
    }
}

extension String {
    public var data: Data? { return data(using: .utf8) }
}

extension Wrapper {
    public var HMAC_MD5: String? {
        let key  = keys.first!
        let base = values.first!
        let cKey = key.cString(using: String.Encoding.utf8)
        let cData = base.cString(using: String.Encoding.utf8)
        var result = [CUnsignedChar](repeating: 0, count: Int(CC_MD5_DIGEST_LENGTH))
        CCHmac(CCHmacAlgorithm(kCCHmacAlgMD5), cKey!, Int(strlen(cKey!)), cData!, Int(strlen(cData!)), &result)
        let hmacData = Data(bytes: result, count: (Int(CC_MD5_DIGEST_LENGTH)))
        return hmacData.hexEncodedString()
    }
}

/// Wrapping Swift.print() within DEBUG flag
///
/// - Note: *print()* might cause [security vulnerabilities](https://codifiedsecurity.com/mobile-app-security-testing-checklist-ios/)
///
/// - Parameter object: The object which is to be logged
///
public func print(_ object: Any...) {
    // Only allowing in DEBUG mode
    #if DEBUG
    Swift.print(object)
    #endif
}

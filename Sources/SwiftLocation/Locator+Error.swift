//
//  Locator+Error.swift
//  SwiftLocation
//
//  Created by Daniele Margutti on 17/09/2020.
//

import Foundation

/// List of all errors produced by the framework.
///
/// - `discardedData`: data was discarded because it was not accepted by the request.
/// - `timeout`: call did fail due timeout interval reached.
/// - `generic`: generic location manager error.
/// - `authorizationNeeded`: no necessary authorization was granted. This typically pops when you set the
///                         `avoidRequestAuthorization = true` for a arequest and no auth is set yet.
/// - `internalError`: failed to build up request due to an error.
/// - `parsingError`: parsing error.
/// - `cancelled`: user cancelled the operation.
/// - `invalidAPIKey`: for external service this means you have inserted an invalid API key
/// - `usageLimitReached`: for external service this means you'r usage limit quota has been reached
/// - `notFound`: resource not found.
/// - `reserved`: for geolocation service this means queried IP address is a bogon (reserved) IP address like private, multicast, etc.
/// - `notSupported`: functionality is not supported on this device.
/// - `invalidPolygon`: invalid polygon passed.
public enum LocatorErrors: LocalizedError, Equatable {
    case discardedData(DataDiscardReason)
    case timeout
    case generic(Error)
    case authorizationNeeded
    case internalError
    case parsingError
    case cancelled
    case invalidAPIKey
    case usageLimitReached
    case notFound
    case reserved
    case other(String)
    case notSupported
    case invalidPolygon

    /// Is a discarded data error.
    internal var isDataDiscarded: Bool {
        switch self {
        case .discardedData: return true
        default:             return false
        }
    }
    
    // MARK: - Public variables
    
    /// Localized error description.
    public var errorDescription: String? {
        switch self {
        case .discardedData(_):     return "Data Discarded"
        case .timeout:              return "Timeout"
        case .generic(let e):       return e.localizedDescription
        case .authorizationNeeded:  return "Authorization Needed"
        case .internalError:        return "Internal Server Error"
        case .parsingError:         return "Parsing Error"
        case .cancelled:            return "User Cancelled"
        case .invalidAPIKey:        return "Invalid/Missing API Key"
        case .usageLimitReached:    return "Quota limit reached"
        case .notFound:             return "Not Found"
        case .reserved:             return "Reserved IP"
        case .notSupported:         return "Not Supported"
        case .invalidPolygon:       return "Invalid polygon. Must be 1 or more points"
        case .other(let e):         return e
        }
    }
    
    public static func == (lhs: LocatorErrors, rhs: LocatorErrors) -> Bool {
        switch (lhs, rhs) {
        case (.generic(let e1), .generic(let e2)):      return e1.localizedDescription == e2.localizedDescription
        case (.other(let l), .other(let r)):            return (l.lowercased() == r.lowercased())

        case (.discardedData, .discardedData):          return true
        case (.timeout, .timeout):                      return true
        case (.internalError, .internalError):          return true
        case (.parsingError, .parsingError):            return true
        case (.cancelled, .cancelled):                  return true
        case (.invalidAPIKey, .invalidAPIKey):          return true
        case (.usageLimitReached, .usageLimitReached):  return true
        case (.notFound, .notFound):                    return true
        case (.reserved, .reserved):                    return true
        case (.notSupported, .notSupported):            return true
        case (.invalidPolygon, .invalidPolygon):        return true

        default:                                        return false
        }
    }
    
}

// MARK: - LocatorLogger

public class LocatorLogger {
    
    static var isEnabled = true
    private static var queue = DispatchQueue(label: "locator.logger", qos: .background)
    
    static func log(_ message: String) {
        guard isEnabled else { return }
        
        queue.sync {
            print(message)
        }
    }
    
}
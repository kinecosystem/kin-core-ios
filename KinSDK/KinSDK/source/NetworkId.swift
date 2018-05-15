//
//  NetworkId.swift
//  KinSDK
//
//  Created by Kin Foundation
//  Copyright © 2017 Kin Foundation. All rights reserved.
//

import Foundation
import StellarKit

/**
 `NetworkId` represents the block chain network to which `KinClient` will connect.
 */
public enum NetworkId {
    /**
     Kik's private Stellar production network.
     */
    case mainNet

    /**
    Kik's private Stellar test network.
     */
    case testNet

    /**
     A network with a custom issuer and Stellar sidentifier.
     */
    case custom(issuer: String, stellarNetworkId: StellarKit.NetworkId)
}

extension NetworkId {
    public var issuer: String {
        switch self {
        case .mainNet:
            return "GBQ3DQOA7NF52FVV7ES3CR3ZMHUEY4LTHDAQKDTO6S546JCLFPEQGCPK"
        case .testNet:
            return "GBQ3DQOA7NF52FVV7ES3CR3ZMHUEY4LTHDAQKDTO6S546JCLFPEQGCPK"
        case .custom (let issuer, _):
            return issuer
        }
    }

    public var stellarNetworkId: StellarKit.NetworkId {
        switch self {
        case .mainNet:
            return StellarKit.NetworkId("private testnet")
        case .testNet:
            return StellarKit.NetworkId("private testnet")
        case .custom(_, let stellarNetworkId):
            return stellarNetworkId
        }
    }
}

extension NetworkId: CustomStringConvertible {
    /// :nodoc:
    public var description: String {
        switch self {
        case .mainNet:
            return "main"
        case .testNet:
            return "test"
        default:
            return "custom network"
        }
    }
}

extension NetworkId: Equatable {
    public static func ==(lhs: NetworkId, rhs: NetworkId) -> Bool {
        switch lhs {
        case .mainNet:
            switch rhs {
            case .mainNet:
                return true
            default:
                return false
            }
        case .testNet:
            switch rhs {
            case .testNet:
                return true
            default:
                return false
            }
        default:
            return false
        }
    }
}
